import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen for admins to create a new Course record in Supabase.
class UploadCourseScreen extends StatefulWidget {
  const UploadCourseScreen({super.key});
  @override
  State<UploadCourseScreen> createState() => _UploadCourseScreenState();
}

class _UploadCourseScreenState extends State<UploadCourseScreen> {
  static const _blue = Color(0xFF1565C0);
  static const _domains = [
    'Technical Services', 'Housekeeping', 'Security', 'Fire Safety',
    'Facade Cleaning', 'Pest Control', 'Helpdesk', 'Accounts',
    'Budgeting', 'Building Compliance', 'Labour Compliance',
    'Vendor Management', 'Store Management', 'Procurement',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _thumbnailCtrl = TextEditingController();

  String _selectedDomain = 'Technical Services';
  String _difficulty = 'Beginner';
  bool _saving = false;
  String? _errorMsg;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    _thumbnailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _errorMsg = null; });
    try {
      await Supabase.instance.client.from('courses').insert({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'domain': _selectedDomain,
        'difficulty': _difficulty,
        'duration_hours': double.tryParse(_durationCtrl.text.trim()) ?? 0,
        'thumbnail_url': _thumbnailCtrl.text.trim().isEmpty ? null : _thumbnailCtrl.text.trim(),
        'lesson_count': 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course created successfully!'), backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
        _titleCtrl.clear(); _descCtrl.clear();
        _durationCtrl.clear(); _thumbnailCtrl.clear();
        setState(() { _selectedDomain = 'Technical Services'; _difficulty = 'Beginner'; });
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
        title: const Text('Upload New Course'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
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
                _field('Course Title *', _titleCtrl, validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 16),
                _field('Description', _descCtrl, maxLines: 3),
                const SizedBox(height: 16),
                _dropdownField('Domain *', _domains, _selectedDomain, (v) => setState(() => _selectedDomain = v!)),
                const SizedBox(height: 16),
                _dropdownField('Difficulty', ['Beginner', 'Intermediate', 'Advanced'], _difficulty, (v) => setState(() => _difficulty = v!)),
                const SizedBox(height: 16),
                _field('Duration (hours)', _durationCtrl, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _field('Thumbnail URL', _thumbnailCtrl),
              ]),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.cloud_upload),
                label: Text(_saving ? 'Creating...' : 'Create Course'),
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

  Widget _field(String label, TextEditingController ctrl,
      {int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0A1628),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white24)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1565C0))),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          dropdownColor: const Color(0xFF1A2744),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0A1628),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ],
    );
  }
}
