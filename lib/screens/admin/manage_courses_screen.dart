import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'upload_lesson_screen.dart';

/// Admin screen: list all courses, tap to expand and see lessons,
/// add lessons per course, delete courses with confirmation.
class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() =>
      _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  static const _blue = Color(0xFF1565C0);

  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;
  String? _error;

  // Tracks which course cards are expanded
  final Set<String> _expandedIds = {};

  // Lessons cache: courseId → list
  final Map<String, List<Map<String, dynamic>>> _lessonsCache = {};

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  Future<void> _loadCourses() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await Supabase.instance.client
          .from('courses')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _courses =
              List<Map<String, dynamic>>.from(data as List);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadLessons(String courseId) async {
    if (_lessonsCache.containsKey(courseId)) return;

    try {
      final data = await Supabase.instance.client
          .from('lessons')
          .select()
          .eq('course_id', courseId)
          .order('order_index');

      if (mounted) {
        setState(() {
          _lessonsCache[courseId] =
              List<Map<String, dynamic>>.from(data as List);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _lessonsCache[courseId] = []);
      }
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _deleteCourse(
      Map<String, dynamic> course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete '
          '"${course['title']}"? '
          'This will also delete all its lessons.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('courses')
          .delete()
          .eq('id', course['id'] as String);

      if (mounted) {
        _lessonsCache.remove(course['id']);
        _loadCourses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteLesson(
      String lessonId, String courseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Lesson'),
        content:
            const Text('Delete this lesson? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('lessons')
          .delete()
          .eq('id', lessonId);

      // Invalidate cache so it reloads
      _lessonsCache.remove(courseId);
      if (mounted) {
        _loadLessons(courseId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addLesson(Map<String, dynamic> course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadLessonScreen(
          preselectedDomain:
              course['domain'] as String?,
        ),
      ),
    ).then((_) {
      // Invalidate this course's lesson cache so it reloads
      _lessonsCache.remove(course['id']);
      if (_expandedIds.contains(course['id'] as String)) {
        _loadLessons(course['id'] as String);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _blue,
        title: const Text(
          'Manage Courses',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white),
            onPressed: () {
              _lessonsCache.clear();
              _loadCourses();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error',
                          style: const TextStyle(
                              color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadCourses,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _courses.isEmpty
                  ? _EmptyState(
                      onAddCourse: () =>
                          Navigator.pop(context),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCourses,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _courses.length,
                        itemBuilder: (ctx, i) {
                          final course = _courses[i];
                          return _CourseCard(
                            course: course,
                            isExpanded: _expandedIds
                                .contains(
                                    course['id'] as String),
                            lessons: _lessonsCache[
                                course['id'] as String],
                            onToggle: () {
                              final id =
                                  course['id'] as String;
                              setState(() {
                                if (_expandedIds
                                    .contains(id)) {
                                  _expandedIds.remove(id);
                                } else {
                                  _expandedIds.add(id);
                                  _loadLessons(id);
                                }
                              });
                            },
                            onDelete: () =>
                                _deleteCourse(course),
                            onAddLesson: () =>
                                _addLesson(course),
                            onDeleteLesson: (lessonId) =>
                                _deleteLesson(
                                    lessonId,
                                    course['id'] as String),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ─── Course Card ───────────────────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isExpanded;
  final List<Map<String, dynamic>>? lessons;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onAddLesson;
  final void Function(String lessonId) onDeleteLesson;

  const _CourseCard({
    required this.course,
    required this.isExpanded,
    required this.lessons,
    required this.onToggle,
    required this.onDelete,
    required this.onAddLesson,
    required this.onDeleteLesson,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1565C0);
    final difficulty = course['difficulty'] as String? ?? 'Beginner';
    final domain = course['domain'] as String? ?? '—';
    final hours =
        (course['duration_hours'] as num?)?.toStringAsFixed(1) ??
            '0';

    Color diffColor;
    switch (difficulty) {
      case 'Intermediate':
        diffColor = const Color(0xFFE65100);
        break;
      case 'Advanced':
        diffColor = const Color(0xFFD84315);
        break;
      default:
        diffColor = const Color(0xFF00897B);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Column(
        children: [
          // ── Header row ─────────────────────────────────────────────────
          InkWell(
            onTap: onToggle,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: blue, size: 22),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['title'] as String? ?? '—',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          domain,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Badge(
                                label: difficulty,
                                color: diffColor),
                            const SizedBox(width: 8),
                            _Badge(
                                label: '$hours h',
                                color: blue),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                            size: 20),
                        onPressed: onDelete,
                        tooltip: 'Delete course',
                      ),
                      Icon(
                        isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded lessons ────────────────────────────────────────────
          if (isExpanded) ...[
            const Divider(height: 1),
            if (lessons == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                    child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2))),
              )
            else ...[
              if (lessons!.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: 16, horizontal: 16),
                  child: Text(
                    'No lessons yet. Add the first one!',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 13),
                  ),
                )
              else
                ...lessons!.asMap().entries.map((entry) {
                  final i = entry.key;
                  final lesson = entry.value;
                  final ct =
                      lesson['content_type'] as String? ?? 'text';
                  final icon = ct == 'video'
                      ? Icons.play_circle_outline_rounded
                      : ct == 'pdf'
                          ? Icons.picture_as_pdf_rounded
                          : Icons.article_rounded;

                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          blue.withOpacity(0.1),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: blue,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      lesson['title'] as String? ??
                          'Lesson ${i + 1}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      '${ct.toUpperCase()} • ${lesson['duration_minutes'] ?? lesson['duration_mins'] ?? 0} min',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            size: 16, color: Colors.grey),
                        IconButton(
                          icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                              size: 16),
                          onPressed: () => onDeleteLesson(
                              lesson['id'] as String),
                          tooltip: 'Delete lesson',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32),
                        ),
                      ],
                    ),
                  );
                }),

              // ── Add lesson button ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    16, 4, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onAddLesson,
                    icon: const Icon(Icons.add_rounded,
                        size: 16),
                    label:
                        const Text('Add Lesson'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: blue,
                      side:
                          const BorderSide(color: blue),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Badge ──────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAddCourse;

  const _EmptyState({required this.onAddCourse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No courses yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Go back and create your first course.',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddCourse,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
