import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'upload_content_screen.dart';
import 'upload_lesson_screen.dart';
import 'manage_courses_screen.dart';

/// Admin-only dashboard — gated by `profiles.is_admin = true`.
/// Accessible via named route `/admin`.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const _blue = Color(0xFF1565C0);
  static const _teal = Color(0xFF00897B);

  // ── Stats ──────────────────────────────────────────────────────────────────
  int _totalCourses = 0;
  int _totalLessons = 0;
  int _totalUsers = 0;
  int _totalEnrollments = 0;
  bool _statsLoading = true;
  String? _statsError;

  // Current admin's name
  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _statsLoading = true;
      _statsError = null;
    });

    try {
      final db = Supabase.instance.client;

      // Sequential awaits — avoids Future.wait mixed-type inference error
      final coursesResp = await db.from('courses').select('id').count();
      final lessonsResp = await db.from('lessons').select('id').count();
      final enrollResp  = await db.from('enrollments').select('id').count();
      final usersResp   = await db.from('profiles').select('id').count();
      final profileResp = await db
          .from('profiles')
          .select('full_name')
          .eq('id', db.auth.currentUser?.id ?? '')
          .maybeSingle();

      if (mounted) {
        setState(() {
          _totalCourses     = (coursesResp as dynamic).count as int? ?? 0;
          _totalLessons     = (lessonsResp as dynamic).count as int? ?? 0;
          _totalEnrollments = (enrollResp  as dynamic).count as int? ?? 0;
          _totalUsers       = (usersResp   as dynamic).count as int? ?? 0;
          _adminName        =
              (profileResp as Map<String, dynamic>?)?['full_name'] as String? ??
              db.auth.currentUser?.email?.split('@').first ??
              'Admin';
          _statsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsLoading = false;
          _statsError = 'Could not load stats: ${e.toString()}';
        });
      }
    }
  }

  // ── Navigation helpers ────────────────────────────────────────────────────
  void _goUploadCourse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadCourseScreen()),
    ).then((_) => _loadStats());
  }

  void _goUploadLesson() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadLessonScreen()),
    ).then((_) => _loadStats());
  }

  void _goManageCourses() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageCoursesScreen()),
    ).then((_) => _loadStats());
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: _blue,
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Admin badge
              Container(
                margin: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh
              IconButton(
                icon:
                    const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _loadStats,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding:
                    const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back, $_adminName',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Stats Grid ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Platform Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_statsError != null)
                    _ErrorBanner(
                      message: _statsError!,
                      onRetry: _loadStats,
                    )
                  else
                    _statsLoading
                        ? const SizedBox(
                            height: 120,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : GridView.count(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.6,
                            children: [
                              _StatTile(
                                label: 'Courses',
                                value: '$_totalCourses',
                                icon: Icons.school_rounded,
                                color: _blue,
                              ),
                              _StatTile(
                                label: 'Lessons',
                                value: '$_totalLessons',
                                icon: Icons.play_lesson_rounded,
                                color: _teal,
                              ),
                              _StatTile(
                                label: 'Users',
                                value: '$_totalUsers',
                                icon: Icons.people_rounded,
                                color: const Color(0xFF6A1B9A),
                              ),
                              _StatTile(
                                label: 'Enrollments',
                                value: '$_totalEnrollments',
                                icon: Icons.how_to_reg_rounded,
                                color: const Color(0xFFE65100),
                              ),
                            ],
                          ),
                ],
              ),
            ),
          ),

          // ── Quick Actions ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Upload New Course',
                    subtitle: 'Add a new FM domain course',
                    color: _blue,
                    onTap: _goUploadCourse,
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.video_library_rounded,
                    title: 'Upload New Lesson',
                    subtitle: 'Add video, PDF or text lesson',
                    color: _teal,
                    onTap: _goUploadLesson,
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.manage_search_rounded,
                    title: 'Manage Courses',
                    subtitle: 'Edit, delete or add lessons',
                    color: const Color(0xFF6A1B9A),
                    onTap: _goManageCourses,
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    icon: Icons.people_outline_rounded,
                    title: 'View Users',
                    subtitle: 'Learner stats and enrollments',
                    color: const Color(0xFFE65100),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'User management coming in next release.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Tile ─────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Action Card ───────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error Banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
