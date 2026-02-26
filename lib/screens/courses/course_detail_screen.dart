import 'package:flutter/material.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _enrolledLessons = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final course = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
    final title = course['title'] as String? ?? 'Course';
    final desc = course['desc'] as String? ?? '';
    final lessons = course['lessons'] as int? ?? 0;
    final duration = course['duration'] as String? ?? '';
    final level = course['level'] as String? ?? '';
    final icon = course['icon'] as IconData? ?? Icons.school;

    final progress = lessons > 0 ? _enrolledLessons / lessons : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1565C0),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Icon(icon, color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Lessons'),
                Tab(text: 'Resources'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(desc: desc, lessons: lessons, duration: duration, level: level, progress: progress),
            _LessonsTab(totalLessons: lessons, enrolled: _enrolledLessons, onProgress: (v) => setState(() => _enrolledLessons = v)),
            _ResourcesTab(title: title),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              if (_enrolledLessons < lessons) _enrolledLessons++;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_enrolledLessons >= lessons ? 'Course completed! Well done!' : 'Progress saved! Keep going!'),
                backgroundColor: const Color(0xFF1565C0),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _enrolledLessons == 0 ? 'Start Course' : (_enrolledLessons >= lessons ? 'Completed!' : 'Continue Learning'),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final String desc, duration, level;
  final int lessons;
  final double progress;
  const _OverviewTab({required this.desc, required this.lessons, required this.duration, required this.level, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (progress > 0) ...[  
            const Text('Your Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: LinearProgressIndicator(value: progress, color: const Color(0xFF1565C0), backgroundColor: Colors.grey.shade200, minHeight: 8, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 10),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
            ]),
            const SizedBox(height: 16),
          ],
          const Text('About this Course', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)),
          const SizedBox(height: 20),
          Row(children: [
            _infoChip(Icons.play_lesson, '$lessons Lessons'),
            const SizedBox(width: 12),
            _infoChip(Icons.schedule, duration),
            const SizedBox(width: 12),
            _infoChip(Icons.signal_cellular_alt, level),
          ]),
          const SizedBox(height: 20),
          const Text('What you\'ll learn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...['Industry best practices', 'Practical hands-on skills', 'Compliance requirements', 'Real-world case studies', 'Assessment & certification'].map((item) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Icon(Icons.check_circle, color: Color(0xFF1565C0), size: 18),
                const SizedBox(width: 8),
                Text(item, style: const TextStyle(fontSize: 14)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: const Color(0xFF1565C0)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0))),
      ]),
    );
  }
}

class _LessonsTab extends StatelessWidget {
  final int totalLessons, enrolled;
  final ValueChanged<int> onProgress;
  const _LessonsTab({required this.totalLessons, required this.enrolled, required this.onProgress});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: totalLessons,
      itemBuilder: (ctx, i) {
        final done = i < enrolled;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
          ),
          child: ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: done ? const Color(0xFF1565C0) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(done ? Icons.check : Icons.play_arrow, color: done ? Colors.white : Colors.grey, size: 18),
            ),
            title: Text('Lesson ${i + 1}: Module ${i + 1}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: done ? const Color(0xFF1565C0) : Colors.black87)),
            subtitle: Text('${8 + i * 2} minutes', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: done ? const Icon(Icons.check_circle, color: Color(0xFF1565C0), size: 20) : const Icon(Icons.lock_open, color: Colors.grey, size: 18),
          ),
        );
      },
    );
  }
}

class _ResourcesTab extends StatelessWidget {
  final String title;
  const _ResourcesTab({required this.title});

  @override
  Widget build(BuildContext context) {
    final resources = [
      {'name': '$title - Study Guide.pdf', 'size': '2.4 MB', 'type': 'PDF'},
      {'name': '$title - Checklist.pdf', 'size': '1.1 MB', 'type': 'PDF'},
      {'name': 'Reference Standards.pdf', 'size': '3.8 MB', 'type': 'PDF'},
      {'name': 'Practice Questions.pdf', 'size': '0.9 MB', 'type': 'PDF'},
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: resources.map((r) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(r['size']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )),
          IconButton(icon: const Icon(Icons.download_outlined, color: Color(0xFF1565C0)), onPressed: () {}),
        ]),
      )).toList(),
    );
  }
}
