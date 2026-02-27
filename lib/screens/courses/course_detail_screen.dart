import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/upload_service.dart';
import '../admin/upload_lesson_screen.dart';

/// Course detail screen — receives a domain map via route arguments.
///
/// Usage:
///   Navigator.pushNamed(context, '/course-detail', arguments: domainMap);
class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isAdmin = false;
  bool _enrolled = false;
  double _progress = 0.0; // 0.0 – 1.0
  List<Map<String, dynamic>> _lessons = [];
  Set<String> _completedLessonIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to read route args here — context is fully wired up.
    final domain =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (domain != null) {
      _loadData(domain['title'] as String? ?? '');
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────
  Future<void> _loadData(String domainTitle) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    await Future.wait([
      _checkAdmin(),
      _loadLessons(domainTitle),
      _loadEnrollment(domainTitle),
    ]);

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _checkAdmin() async {
    final admin = await UploadService.isCurrentUserAdmin();
    if (mounted) setState(() => _isAdmin = admin);
  }

  Future<void> _loadLessons(String domainTitle) async {
    try {
      final db = Supabase.instance.client;
      final data = await db
          .from('lessons')
          .select()
          .eq('domain_title', domainTitle)
          .eq('is_published', true)
          .order('order_index');

      // Also load which lessons this user completed
      final uid = db.auth.currentUser?.id;
      Set<String> completed = {};
      if (uid != null && data.isNotEmpty) {
        final ids = (data as List).map((l) => l['id'] as String).toList();
        final progress = await db
            .from('lesson_progress')
            .select('lesson_id')
            .eq('user_id', uid)
            .eq('completed', true)
            .inFilter('lesson_id', ids);
        completed =
            (progress as List).map((p) => p['lesson_id'] as String).toSet();
      }

      if (mounted) {
        setState(() {
          _lessons = List<Map<String, dynamic>>.from(data as List);
          _completedLessonIds = completed;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _loadEnrollment(String domainTitle) async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      final row = await Supabase.instance.client
          .from('enrollments')
          .select('progress')
          .eq('user_id', uid)
          .eq('domain_title', domainTitle)
          .maybeSingle();

      if (row != null && mounted) {
        setState(() {
          _enrolled = true;
          // DB stores 0–100; we use 0.0–1.0 internally
          _progress = ((row['progress'] as num?) ?? 0).toDouble() / 100.0;
        });
      }
    } catch (_) {
      // Non-fatal
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _enroll(Map<String, dynamic> domain) async {
    setState(() => _enrolled = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('enrollments').upsert({
        'user_id': user.id,
        'domain_title': domain['title'],
        'enrolled_at': DateTime.now().toIso8601String(),
        'progress': 0.0,
      });
    } catch (_) {
      // Non-fatal — enrollment is recorded locally for now
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Enrolled in '${domain['title']}'! Start learning →"),
        backgroundColor: const Color(0xFF00897B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _completeLesson(
      String lessonId, int lessonIndex, String domainTitle) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await Supabase.instance.client.from('lesson_progress').upsert({
        'user_id': uid,
        'lesson_id': lessonId,
        'completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      final newCompleted = {..._completedLessonIds, lessonId};
      final newProgress = _lessons.isEmpty
          ? 0.0
          : newCompleted.length / _lessons.length;

      // Persist progress (0–100) to enrollments
      await Supabase.instance.client
          .from('enrollments')
          .update({'progress': (newProgress * 100).roundToDouble()})
          .eq('user_id', uid)
          .eq('domain_title', domainTitle);

      if (mounted) {
        setState(() {
          _completedLessonIds = newCompleted;
          _progress = newProgress;
        });
      }
    } catch (_) {
      // Non-fatal
    }
  }

  Future<void> _openLesson(Map<String, dynamic> lesson) async {
    final url = lesson['file_url'] as String?;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file attached to this lesson yet.')),
      );
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open lesson file.')),
      );
    }
  }

  Future<void> _openUploadScreen(Map<String, dynamic> domain) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadLessonScreen(
          preselectedDomain: domain['title'] as String,
        ),
      ),
    );
    // Reload lessons after returning from upload
    _loadLessons(domain['title'] as String? ?? '');
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final domain =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (domain == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Detail')),
        body: const Center(child: Text('No course selected.')),
      );
    }

    final color = Color(domain['color'] as int? ?? 0xFF1565C0);
    final title = domain['title'] as String? ?? 'Course';
    final duration = domain['duration'] as String? ?? '3h 00m';
    final lessonCount =
        _lessons.isEmpty ? (domain['lessons'] as int? ?? 8) : _lessons.length;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isAdmin)
                IconButton(
                  icon: const Icon(Icons.cloud_upload_rounded,
                      color: Colors.white),
                  tooltip: 'Upload Content',
                  onPressed: () => _openUploadScreen(domain),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(domain['icon'] as IconData? ?? Icons.book,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Chip(
                            icon: Icons.play_lesson_rounded,
                            label: '$lessonCount lessons'),
                        const SizedBox(width: 12),
                        _Chip(icon: Icons.schedule_rounded, label: duration),
                        const SizedBox(width: 12),
                        const _Chip(
                            icon: Icons.signal_cellular_alt_rounded,
                            label: 'Beginner'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Lessons'),
                Tab(text: 'Resources'),
              ],
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabCtrl,
                children: [
                  // ── Overview tab ─────────────────────────────────────────
                  _OverviewTab(
                    domain: domain,
                    color: color,
                    title: title,
                    enrolled: _enrolled,
                    progress: _progress,
                    onEnroll: () => _enroll(domain),
                  ),

                  // ── Lessons tab ──────────────────────────────────────────
                  _LessonsTab(
                    lessons: _lessons,
                    completedIds: _completedLessonIds,
                    enrolled: _enrolled,
                    color: color,
                    domainTitle: title,
                    onTapLesson: (lesson, index) async {
                      if (!_enrolled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Enrol in this course to start learning.'),
                          ),
                        );
                        return;
                      }
                      await _openLesson(lesson);
                      await _completeLesson(
                          lesson['id'] as String, index, title);
                    },
                  ),

                  // ── Resources tab ────────────────────────────────────────
                  _ResourcesTab(color: color, title: title),
                ],
              ),
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> domain;
  final Color color;
  final String title;
  final bool enrolled;
  final double progress;
  final VoidCallback onEnroll;

  const _OverviewTab({
    required this.domain,
    required this.color,
    required this.title,
    required this.enrolled,
    required this.progress,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar (if enrolled)
          if (enrolled) ...[
            const Text('Your Progress',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            Text(
              '${(progress * 100).round()}% complete',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
          ],

          // About
          const Text(
            'About This Course',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _courseDescription(title),
            style: const TextStyle(
                fontSize: 14, color: Colors.black87, height: 1.6),
          ),
          const SizedBox(height: 24),

          // What you'll learn
          const Text(
            "What You'll Learn",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._learningPoints(title).map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, color: color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(point,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Enrol / Continue button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: enrolled ? null : onEnroll,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFF00897B).withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(enrolled ? '✓ Enrolled' : 'Enrol Now'),
            ),
          ),
        ],
      ),
    );
  }

  String _courseDescription(String t) =>
      'This comprehensive course covers all aspects of $t in the '
      'context of Facility Management operations in India. '
      'Designed for frontline FM professionals, you will gain practical '
      'skills, understand standard procedures, and learn how to apply '
      'best practices in your day-to-day work.';

  List<String> _learningPoints(String t) => [
        'Understand the core principles of $t',
        'Apply industry-standard SOPs and checklists',
        'Handle common issues and escalation procedures',
        'Ensure compliance with Indian regulations and standards',
        'Use checklists and reporting tools effectively',
      ];
}

// ─── Lessons Tab ──────────────────────────────────────────────────────────────
class _LessonsTab extends StatelessWidget {
  final List<Map<String, dynamic>> lessons;
  final Set<String> completedIds;
  final bool enrolled;
  final Color color;
  final String domainTitle;
  final Future<void> Function(Map<String, dynamic> lesson, int index)
      onTapLesson;

  const _LessonsTab({
    required this.lessons,
    required this.completedIds,
    required this.enrolled,
    required this.color,
    required this.domainTitle,
    required this.onTapLesson,
  });

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No lessons uploaded yet.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon!',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final lesson = lessons[i];
        final lessonId = lesson['id'] as String;
        final done = completedIds.contains(lessonId);
        final contentType = lesson['content_type'] as String? ?? 'text';
        final durationMins = lesson['duration_mins'] as int? ?? 0;

        IconData typeIcon;
        switch (contentType) {
          case 'video':
            typeIcon = done
                ? Icons.check_circle_rounded
                : Icons.play_circle_outline_rounded;
            break;
          case 'pdf':
            typeIcon = done
                ? Icons.check_circle_rounded
                : Icons.picture_as_pdf_rounded;
            break;
          default:
            typeIcon =
                done ? Icons.check_circle_rounded : Icons.article_rounded;
        }

        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor:
                done ? const Color(0xFF00897B) : color.withOpacity(0.1),
            child: done
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16)
                : Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          title: Text(
            lesson['title'] as String? ?? 'Lesson ${i + 1}',
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            durationMins > 0 ? '$durationMins min' : contentType.toUpperCase(),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: Icon(
            typeIcon,
            color: done ? const Color(0xFF00897B) : Colors.grey,
          ),
          onTap: () => onTapLesson(lesson, i),
        );
      },
    );
  }
}

// ─── Resources Tab ────────────────────────────────────────────────────────────
class _ResourcesTab extends StatelessWidget {
  final Color color;
  final String title;

  const _ResourcesTab({required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ResourceTile(
          icon: Icons.picture_as_pdf_rounded,
          title: '$title — Study Guide',
          subtitle: 'PDF • 2.4 MB',
          color: color,
        ),
        _ResourceTile(
          icon: Icons.picture_as_pdf_rounded,
          title: '$title — SOP Manual',
          subtitle: 'PDF • 4.1 MB',
          color: color,
        ),
        _ResourceTile(
          icon: Icons.checklist_rounded,
          title: 'Self-Assessment Checklist',
          subtitle: 'PDF • 0.8 MB',
          color: color,
        ),
        _ResourceTile(
          icon: Icons.quiz_rounded,
          title: 'Practice Quiz',
          subtitle: '15 questions',
          color: color,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz coming soon!')),
          ),
        ),
      ],
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _ResourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing:
            Icon(Icons.download_rounded, color: Colors.grey.shade400, size: 20),
        onTap: onTap ??
            () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Resource download coming soon!')),
                ),
      ),
    );
  }
}
