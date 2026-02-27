import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin screen for creating a new Course (INSERT into `courses` table).
///
/// Navigated to from AdminDashboardScreen.
/// Named `UploadCourseScreen` to distinguish from the lesson uploader.
class UploadCourseScreen extends StatefulWidget {
  const UploadCourseScreen({super.key});

  @override
  State<UploadCourseScreen> createState() => _UploadCourseScreenState();
}

class _UploadCourseScreenState extends State<UploadCourseScreen> {
  static const _blue = Color(0xFF1565C0);

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _thumbnailCtrl = TextEditingController();

  String? _selectedDomain;
  String _difficulty = 'Beginner';
  bool _saving = false;
  String? _errorMsg;

  // ── 14 FM Domains ─────────────────────────────────────────────────────────
  static const List<String> _domains = [
    'Technical Services',
    'Housekeeping',
    'Security Management',
    'Fire & Safety',
    'Facade Cleaning',
    'Pest Control',
    'Helpdesk Functions',
    'Accounts Function',
    'Budgeting',
    'Building Compliance',
    'Labour Compliance',
    'Vendor Management',
    'Store Management',
    'Procurement',
  ];

  static const List<String> _difficulties = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    _thumbnailCtrl.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDomain == null) {
      setState(() => _errorMsg = 'Please select a domain.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMsg = null;
    });

    try {
      final uid =
          Supabase.instance.client.auth.currentUser?.id;

      await Supabase.instance.client.from('courses').insert({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'domain': _selectedDomain,
        'difficulty': _difficulty,
        'duration_hours':
            double.tryParse(_durationCtrl.text.trim()) ?? 0,
        'thumbnail_url': _thumbnailCtrl.text.trim().isEmpty
            ? null
            : _thumbnailCtrl.text.trim(),
        'is_published': true,
        'created_by': uid,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Course created successfully!'),
          backgroundColor: Color(0xFF00897B),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _errorMsg = 'Failed to create course: ${e.toString()}';
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
          'Upload New Course',
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
              // ── Error banner ──────────────────────────────────────
              if (_errorMsg != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Course Title ──────────────────────────────────────
              _Label('Course Title *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _deco(
                  hint: 'e.g. Introduction to Technical Services',
                  icon: Icons.title_rounded,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Title is required'
                        : null,
              ),
              const SizedBox(height: 16),

              // ── Description ───────────────────────────────────────
              _Label('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: _deco(
                  hint:
                      'Describe what learners will gain from this course...',
                  icon: Icons.description_rounded,
                ),
              ),
              const SizedBox(height: 16),

              // ── Domain Dropdown ───────────────────────────────────
              _Label('FM Domain *'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDomain,
                hint: const Text('Select domain'),
                decoration: _deco(
                  hint: '',
                  icon: Icons.category_rounded,
                ).copyWith(hintText: null),
                items: _domains
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d,
                              style:
                                  const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedDomain = v),
                validator: (v) =>
                    v == null ? 'Please select a domain' : null,
              ),
              const SizedBox(height: 16),

              // ── Difficulty ────────────────────────────────────────
              _Label('Difficulty'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _difficulty,
                decoration: _deco(
                  hint: '',
                  icon: Icons.signal_cellular_alt_rounded,
                ).copyWith(hintText: null),
                items: _difficulties
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _difficulty = v ?? 'Beginner'),
              ),
              const SizedBox(height: 16),

              // ── Duration ──────────────────────────────────────────
              _Label('Duration (hours)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _durationCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: _deco(
                  hint: 'e.g. 3.5',
                  icon: Icons.schedule_rounded,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Thumbnail URL ─────────────────────────────────────
              _Label('Thumbnail URL (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _thumbnailCtrl,
                keyboardType: TextInputType.url,
                decoration: _deco(
                  hint: 'https://example.com/thumbnail.jpg',
                  icon: Icons.image_rounded,
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2),
                        )
                      : const Icon(Icons.school_rounded),
                  label: Text(
                    _saving
                        ? 'Creating Course...'
                        : 'Create Course',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
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

// ── Section label helper ─────────────────────────────────────────────────────
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
