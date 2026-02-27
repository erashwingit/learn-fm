import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen for admins to add a Lesson to an existing Course.
class UploadLessonScreen extends StatefulWidget {
  const UploadLessonScreen({super.key});
  @override
  State<UploadLessonScreen> createState() => _UploadLessonScreenState();
}

class _UploadLessonScreenState extends State<UploadLessonScreen> {
  static const _blue = Color(0xFF1565C0);

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentUrlCtrl = TextEditingController();
  final _contentTextCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();

  List<Map<String, dynamic>> _courses = [];
  String? _selectedCourseId;
  String _contentType = 'text';
  bool _loading = true;
  bool _saving = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final data = await Supabase.instance.client
          .from('courses')
          .select('id, title')
          .order('title');
      setState(() {
        _courses = List<Map<String, dynamic>>.from(data);
        if (_courses.isNotEmpty) _selectedCourseId = _courses.first['id'] as String;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourseId == null) {
      setState(() => _errorMsg = 'Please select a course');
      return;
    }
    setState(() { _saving = true; _errorMsg = null; });
    try {
      await Supabase.instance.client.from('lessons').insert({
        'course_id': _selectedCourseId,
        'title': _titleCtrl.text.trim(),
        'content_type': _contentType,
        'content_url': _contentUrlCtrl.text.trim().isEmpty ? null : _contentUrlCtrl.text.trim(),
        'content_text': _contentTextCtrl.text.trim().isEmpty ? null : _contentTextCtrl.text.trim(),
        'order_index': int.tryParse(_orderCtrl.text.trim()) ?? 0,
        'duration_minutes': int.tryParse(_durationCtrl.text.trim()) ?? 0,
      });
      // Update lesson_count on course
      await Supabase.instance.client.rpc('increment_lesson_count', params: {'course_id_param': _selectedCourseId}).catchError((_) {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson added successfully!'), backgroundColor: Colors.green),
        );
        _titleCtrl.clear(); _contentUrlCtrl.clear();
        _contentTextCtrl.clear(); _durationCtrl.clear(); _orderCtrl.clear();
        setState(() => _contentType = 'text');
      }
    } on PostgrestException catch (e) {
      setState(() => _errorMsg = e.message);
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text('Add Lesson'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : _courses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.book_outlined, color: Colors.white38, size: 64),
                      const SizedBox(height: 16),
                      const Text('No courses yet.', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
                        child: const Text('Create a Course First'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMsg != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(_errorMsg!, style: TextStyle(color: Colors.red.shade700)),
                          ),
                        _buildCard([
                          _label('Select Course *'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedCourseId,
                            onChanged: (v) => setState(() => _selectedCourseId = v),
                            dropdownColor: const Color(0xFF1A2744),
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(),
                            items: _courses.map((c) => DropdownMenuItem(
                              value: c['id'] as String,
                              child: Text(c['title'] as String, overflow: TextOverflow.ellipsis),
                            )).toList(),
                          ),
                          const SizedBox(height: 16),
                          _field('Lesson Title *', _titleCtrl, validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                          const SizedBox(height: 16),
                          _label('Content Type'),
                          const SizedBox(height: 6),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'text', label: Text('Text'), icon: Icon(Icons.article)),
                              ButtonSegment(value: 'video', label: Text('Video'), icon: Icon(Icons.play_circle)),
                              ButtonSegment(value: 'pdf', label: Text('PDF'), icon: Icon(Icons.picture_as_pdf)),
                            ],
                            selected: {_contentType},
                            onSelectionChanged: (s) => setState(() => _contentType = s.first),
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith((s) =>
                                  s.contains(WidgetState.selected) ? _blue : const Color(0xFF0A1628)),
                              foregroundColor: WidgetStateProperty.all(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_contentType == 'text')
                            _field('Content Text', _contentTextCtrl, maxLines: 6)
                          else
                            _field('Content URL (${_contentType == 'video' ? 'video link' : 'PDF link'})', _contentUrlCtrl),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _field('Order Index', _orderCtrl, keyboardType: TextInputType.number)),
                              const SizedBox(width: 12),
                              Expanded(child: _field('Duration (min)', _durationCtrl, keyboardType: TextInputType.number)),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _saving ? null : _submit,
                          icon: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.add_circle_outline),
                          label: Text(_saving ? 'Adding...' : 'Add Lesson'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13));

  InputDecoration _inputDecoration() => InputDecoration(
    filled: true,
    fillColor: const Color(0xFF0A1628),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1565C0))),
  );

  Widget _field(String label, TextEditingController ctrl,
      {int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(),
        ),
      ],
    );
  }
}
