import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/upload_service.dart';

/// Admin screen for uploading a lesson (video/PDF/text) for a course.
///
/// Can optionally be pre-populated with a [preselectedDomain] so the
/// course dropdown starts on the correct domain.
class UploadLessonScreen extends StatefulWidget {
  /// When navigated from course_detail_screen, we know the domain.
  final String? preselectedDomain;

  const UploadLessonScreen({super.key, this.preselectedDomain});

  @override
  State<UploadLessonScreen> createState() =>
      _UploadLessonScreenState();
}

class _UploadLessonScreenState extends State<UploadLessonScreen> {
  static const _blue = Color(0xFF1565C0);

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentUrlCtrl = TextEditingController();
  final _contentTextCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '1');

  // Courses from DB
  List<Map<String, dynamic>> _courses = [];
  bool _coursesLoading = true;
  String? _selectedCourseId;

  String _contentType = 'video'; // 'video' | 'pdf' | 'text'

  // File upload state
  File? _pickedFile;
  String? _pickedFileName;
  String? _fileError;
  bool _uploading = false;
  double _uploadProgress = 0.0;
  String? _uploadError;
  bool _uploadSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentUrlCtrl.dispose();
    _contentTextCtrl.dispose();
    _durationCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  // ── Load courses from Supabase ────────────────────────────────────────────
  Future<void> _loadCourses() async {
    try {
      final data = await Supabase.instance.client
          .from('courses')
          .select('id, title, domain')
          .order('title');

      if (mounted) {
        final list =
            List<Map<String, dynamic>>.from(data as List);
        setState(() {
          _courses = list;
          _coursesLoading = false;
          // Pre-select if domain matches
          if (widget.preselectedDomain != null) {
            final match = list.firstWhere(
              (c) =>
                  (c['domain'] as String?)
                      ?.toLowerCase() ==
                  widget.preselectedDomain!.toLowerCase(),
              orElse: () => {},
            );
            if (match.isNotEmpty) {
              _selectedCourseId = match['id'] as String?;
            }
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _coursesLoading = false);
    }
  }

  // ── File picker ───────────────────────────────────────────────────────────
  Future<void> _pickFile() async {
    final type =
        _contentType == 'video' ? FileType.video : FileType.custom;
    final allowed = _contentType == 'pdf' ? ['pdf'] : null;

    final result = await FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: allowed,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;

    final file = File(path);
    final err = UploadService.validateFile(file, _contentType);

    setState(() {
      if (err != null) {
        _fileError = err;
        _pickedFile = null;
        _pickedFileName = null;
      } else {
        _fileError = null;
        _pickedFile = file;
        _pickedFileName = result.files.first.name;
      }
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_contentType != 'text' && _pickedFile == null &&
        _contentUrlCtrl.text.trim().isEmpty) {
      setState(() =>
          _fileError = 'Please select a file or enter a URL.');
      return;
    }

    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
      _uploadError = null;
      _uploadSuccess = false;
    });

    String? fileUrl = _contentUrlCtrl.text.trim().isNotEmpty
        ? _contentUrlCtrl.text.trim()
        : null;

    // Upload to Supabase Storage if a file was picked
    if (_pickedFile != null) {
      final domain = _courses.firstWhere(
        (c) => c['id'] == _selectedCourseId,
        orElse: () => {'domain': 'general'},
      )['domain'] as String? ?? 'general';

      final result = await UploadService.upload(
        file: _pickedFile!,
        contentType: _contentType,
        domain: domain,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      if (!result.success) {
        setState(() {
          _uploading = false;
          _uploadError = result.error;
        });
        return;
      }

      fileUrl = result.publicUrl;
    }

    // Insert lesson metadata into DB
    try {
      final uid =
          Supabase.instance.client.auth.currentUser?.id;

      // Find domain_title for backward-compat with existing queries
      final course = _courses.firstWhere(
        (c) => c['id'] == _selectedCourseId,
        orElse: () => {},
      );

      await Supabase.instance.client.from('lessons').insert({
        'course_id': _selectedCourseId,
        'domain_title': course['domain'],
        'title': _titleCtrl.text.trim(),
        'content_type': _contentType,
        'content_url': fileUrl,
        'file_url': fileUrl, // alias for course_detail_screen queries
        'content_text': _contentType == 'text'
            ? _contentTextCtrl.text.trim()
            : null,
        'order_index':
            int.tryParse(_orderCtrl.text.trim()) ?? 1,
        'duration_minutes':
            int.tryParse(_durationCtrl.text.trim()) ?? 0,
        'duration_mins':
            int.tryParse(_durationCtrl.text.trim()) ?? 0,
        'is_published': true,
        'uploaded_by': uid,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _uploading = false;
        _uploadSuccess = true;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Lesson published successfully!'),
          backgroundColor: Color(0xFF00897B),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _uploading = false;
        _uploadError =
            'Failed to save lesson info. Please try again.';
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _blue,
        title: const Text(
          'Upload New Lesson',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Course dropdown ───────────────────────────────────
              _Label('Parent Course *'),
              const SizedBox(height: 8),
              _coursesLoading
                  ? const SizedBox(
                      height: 56,
                      child: Center(
                          child: LinearProgressIndicator()),
                    )
                  : DropdownButtonFormField<String>(
                      value: _selectedCourseId,
                      hint: const Text('Select course'),
                      isExpanded: true,
                      decoration: _deco(
                        hint: '',
                        icon: Icons.school_rounded,
                      ).copyWith(hintText: null),
                      items: _courses
                          .map((c) => DropdownMenuItem(
                                value: c['id'] as String,
                                child: Text(
                                  '${c['title']} (${c['domain'] ?? '—'})',
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(
                          () => _selectedCourseId = v),
                      validator: (v) => v == null
                          ? 'Select a parent course'
                          : null,
                    ),
              const SizedBox(height: 16),

              // ── Content type ──────────────────────────────────────
              _Label('Content Type'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TypeBtn(
                    label: 'Video',
                    icon: Icons.videocam_rounded,
                    selected: _contentType == 'video',
                    onTap: () => setState(() {
                      _contentType = 'video';
                      _pickedFile = null;
                      _pickedFileName = null;
                      _fileError = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _TypeBtn(
                    label: 'PDF',
                    icon: Icons.picture_as_pdf_rounded,
                    selected: _contentType == 'pdf',
                    onTap: () => setState(() {
                      _contentType = 'pdf';
                      _pickedFile = null;
                      _pickedFileName = null;
                      _fileError = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _TypeBtn(
                    label: 'Text',
                    icon: Icons.article_rounded,
                    selected: _contentType == 'text',
                    onTap: () => setState(() {
                      _contentType = 'text';
                      _pickedFile = null;
                      _pickedFileName = null;
                      _fileError = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Lesson Title ──────────────────────────────────────
              _Label('Lesson Title *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: _deco(
                    hint: 'e.g. HVAC Fundamentals',
                    icon: Icons.title_rounded),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
              ),
              const SizedBox(height: 16),

              // ── Duration + Order ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _Label('Duration (mins)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _durationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _deco(
                              hint: 'e.g. 15',
                              icon: Icons.schedule_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _Label('Order Index *'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _orderCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _deco(
                              hint: 'e.g. 1',
                              icon: Icons
                                  .format_list_numbered_rounded),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(v) == null) {
                              return 'Numbers only';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Content URL (for video/pdf) ────────────────────────
              if (_contentType != 'text') ...[
                _Label('Content URL (optional if uploading file)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contentUrlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: _deco(
                      hint: 'https://... or leave blank to upload file',
                      icon: Icons.link_rounded),
                ),
                const SizedBox(height: 16),

                // ── File picker ─────────────────────────────────────
                _Label(_contentType == 'video'
                    ? 'Video File'
                    : 'PDF File'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _uploading ? null : _pickFile,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _pickedFile != null
                          ? _blue.withOpacity(0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _fileError != null
                            ? Colors.red
                            : _pickedFile != null
                                ? _blue
                                : Colors.grey.shade300,
                        width:
                            _pickedFile != null ? 2 : 1,
                      ),
                    ),
                    child: _pickedFile == null
                        ? Column(
                            children: [
                              Icon(
                                _contentType == 'video'
                                    ? Icons.video_file_rounded
                                    : Icons
                                        .picture_as_pdf_rounded,
                                size: 40,
                                color:
                                    Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _contentType == 'video'
                                    ? 'Tap to select video\nMP4, MOV — max 500 MB'
                                    : 'Tap to select PDF\nmax 50 MB',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color:
                                        Colors.grey.shade500,
                                    fontSize: 13),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Icon(
                                _contentType == 'video'
                                    ? Icons.videocam_rounded
                                    : Icons
                                        .picture_as_pdf_rounded,
                                color: _blue,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _pickedFileName ?? '',
                                      style: const TextStyle(
                                          fontWeight:
                                              FontWeight.w600,
                                          fontSize: 14),
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${(_pickedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB',
                                      style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18),
                                onPressed: () => setState(() {
                                  _pickedFile = null;
                                  _pickedFileName = null;
                                }),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_fileError != null)
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 6, left: 4),
                    child: Text(
                      _fileError!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // ── Text content (for text type) ──────────────────────
              if (_contentType == 'text') ...[
                _Label('Lesson Content *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contentTextCtrl,
                  maxLines: 10,
                  decoration: _deco(
                      hint: 'Enter lesson content here...',
                      icon: Icons.article_rounded),
                  validator: (v) => _contentType == 'text' &&
                          (v == null || v.trim().isEmpty)
                      ? 'Content is required for text lessons'
                      : null,
                ),
                const SizedBox(height: 16),
              ],

              // ── Upload progress ───────────────────────────────────
              if (_uploading) ...[
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _uploadProgress < 1.0
                          ? 'Uploading file...'
                          : 'Saving lesson...',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _blue),
                    ),
                    Text(
                      '${(_uploadProgress * 100).round()}%',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _blue),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(_blue),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Upload error ──────────────────────────────────────
              if (_uploadError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: Colors.red.shade600),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _uploadError!,
                          style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Submit button ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      _uploading || _uploadSuccess ? null : _submit,
                  icon: _uploadSuccess
                      ? const Icon(Icons.check_circle_rounded)
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(
                    _uploading
                        ? 'Uploading...'
                        : _uploadSuccess
                            ? 'Published!'
                            : 'Upload & Publish',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _uploadSuccess
                        ? const Color(0xFF00897B)
                        : _blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Retry
              if (_uploadError != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _uploading ? null : _submit,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry Upload'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _blue,
                      side: const BorderSide(color: _blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
          vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: _blue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF37474F),
        ),
      );
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1565C0);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? blue : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? blue : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? Colors.white : Colors.grey,
                  size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
