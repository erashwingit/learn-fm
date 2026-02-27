import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/services/upload_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  int _navIndex = 0;

  String get _userName {
    final meta = _supabase.auth.currentUser?.userMetadata;
    final email = _supabase.auth.currentUser?.email ?? '';
    final name = meta?['full_name'] as String? ??
        meta?['name'] as String? ??
        email.split('@').first;
    return name.isEmpty ? 'Learner' : name;
  }

  // 14 FM domains with icons and colours
  static const List<Map<String, dynamic>> _domains = [
    {'title': 'Technical Services',  'icon': Icons.build_rounded,            'color': 0xFF1565C0},
    {'title': 'Housekeeping',        'icon': Icons.cleaning_services_rounded, 'color': 0xFF00897B},
    {'title': 'Security Mgmt',       'icon': Icons.security_rounded,          'color': 0xFF6A1B9A},
    {'title': 'Fire & Safety',       'icon': Icons.local_fire_department,     'color': 0xFFD84315},
    {'title': 'Facade Cleaning',     'icon': Icons.window_rounded,            'color': 0xFF0277BD},
    {'title': 'Pest Control',        'icon': Icons.pest_control_rounded,      'color': 0xFF558B2F},
    {'title': 'Helpdesk',            'icon': Icons.support_agent_rounded,     'color': 0xFFE65100},
    {'title': 'Accounts',            'icon': Icons.account_balance_rounded,   'color': 0xFF37474F},
    {'title': 'Budgeting',           'icon': Icons.pie_chart_rounded,         'color': 0xFF4527A0},
    {'title': 'Building Compliance', 'icon': Icons.domain_rounded,            'color': 0xFF00695C},
    {'title': 'Labour Compliance',   'icon': Icons.groups_rounded,            'color': 0xFF1B5E20},
    {'title': 'Vendor Management',   'icon': Icons.handshake_rounded,         'color': 0xFFBF360C},
    {'title': 'Store Management',    'icon': Icons.inventory_2_rounded,       'color': 0xFF4A148C},
    {'title': 'Procurement',         'icon': Icons.shopping_cart_rounded,     'color': 0xFF006064},
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(userName: _userName, domains: _domains),
      const _CoursesTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      body: pages[_navIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        backgroundColor: Colors.white,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final String userName;
  final List<Map<String, dynamic>> domains;

  const _HomeTab({required this.userName, required this.domains});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          expandedHeight: 160,
          floating: false,
          pinned: true,
          backgroundColor: const Color(0xFF1565C0),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Hello, $userName 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'What would you like to learn today?',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Stats row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _StatCard(
                  icon: Icons.menu_book_rounded,
                  label: 'Domains',
                  value: '14',
                  color: const Color(0xFF1565C0),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.emoji_events_rounded,
                  label: 'Progress',
                  value: '0%',
                  color: const Color(0xFFFF6F00),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.star_rounded,
                  label: 'Points',
                  value: '0',
                  color: const Color(0xFF00897B),
                ),
              ],
            ),
          ),
        ),

        // Section header
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              'FM Domains',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ),

        // Domain grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _DomainCard(domain: domains[i]),
              childCount: domains.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Courses Tab (shortcut to CourseListScreen) ────────────────────────────
class _CoursesTab extends StatelessWidget {
  const _CoursesTab();

  @override
  Widget build(BuildContext context) {
    // Immediately delegate to standalone CourseListScreen content
    return const CourseListBody();
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const ProfileBody();
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Domain Card ─────────────────────────────────────────────────────────────
class _DomainCard extends StatelessWidget {
  final Map<String, dynamic> domain;

  const _DomainCard({required this.domain});

  @override
  Widget build(BuildContext context) {
    final color = Color(domain['color'] as int);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/course-detail',
        arguments: domain,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(domain['icon'] as IconData, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              domain['title'] as String,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.play_circle_outline_rounded,
                    size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  '5 lessons',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CourseListBody (reused in Courses tab & standalone screen) ───────────────
class CourseListBody extends StatefulWidget {
  const CourseListBody({super.key});

  @override
  State<CourseListBody> createState() => _CourseListBodyState();
}

class _CourseListBodyState extends State<CourseListBody> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const List<Map<String, dynamic>> _domains = [
    {'title': 'Technical Services',  'icon': Icons.build_rounded,            'color': 0xFF1565C0, 'lessons': 12, 'duration': '4h 30m'},
    {'title': 'Housekeeping',        'icon': Icons.cleaning_services_rounded, 'color': 0xFF00897B, 'lessons': 8,  'duration': '2h 45m'},
    {'title': 'Security Management', 'icon': Icons.security_rounded,          'color': 0xFF6A1B9A, 'lessons': 10, 'duration': '3h 20m'},
    {'title': 'Fire & Safety',       'icon': Icons.local_fire_department,     'color': 0xFFD84315, 'lessons': 9,  'duration': '3h 00m'},
    {'title': 'Facade Cleaning',     'icon': Icons.window_rounded,            'color': 0xFF0277BD, 'lessons': 6,  'duration': '2h 00m'},
    {'title': 'Pest Control',        'icon': Icons.pest_control_rounded,      'color': 0xFF558B2F, 'lessons': 7,  'duration': '2h 15m'},
    {'title': 'Helpdesk Functions',  'icon': Icons.support_agent_rounded,     'color': 0xFFE65100, 'lessons': 8,  'duration': '2h 30m'},
    {'title': 'Accounts Function',   'icon': Icons.account_balance_rounded,   'color': 0xFF37474F, 'lessons': 10, 'duration': '3h 30m'},
    {'title': 'Budgeting',           'icon': Icons.pie_chart_rounded,         'color': 0xFF4527A0, 'lessons': 11, 'duration': '4h 00m'},
    {'title': 'Building Compliance', 'icon': Icons.domain_rounded,            'color': 0xFF00695C, 'lessons': 9,  'duration': '3h 15m'},
    {'title': 'Labour Compliance',   'icon': Icons.groups_rounded,            'color': 0xFF1B5E20, 'lessons': 8,  'duration': '2h 50m'},
    {'title': 'Vendor Management',   'icon': Icons.handshake_rounded,         'color': 0xFFBF360C, 'lessons': 7,  'duration': '2h 20m'},
    {'title': 'Store Management',    'icon': Icons.inventory_2_rounded,       'color': 0xFF4A148C, 'lessons': 6,  'duration': '2h 00m'},
    {'title': 'Procurement',         'icon': Icons.shopping_cart_rounded,     'color': 0xFF006064, 'lessons': 8,  'duration': '2h 40m'},
  ];

  List<Map<String, dynamic>> get _filtered => _query.isEmpty
      ? _domains
      : _domains
          .where((d) =>
              (d['title'] as String)
                  .toLowerCase()
                  .contains(_query.toLowerCase()))
          .toList();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App bar
        Container(
          color: const Color(0xFF1565C0),
          padding: EdgeInsets.fromLTRB(
              16, MediaQuery.of(context).padding.top + 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FM Courses',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search courses...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No courses found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final d = _filtered[i];
                    final color = Color(d['color'] as int);
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        ctx,
                        '/course-detail',
                        arguments: d,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(d['icon'] as IconData,
                                  color: color, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['title'] as String,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.play_lesson_rounded,
                                          size: 13,
                                          color: Colors.grey.shade400),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${d['lessons']} lessons',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.schedule_rounded,
                                          size: 13,
                                          color: Colors.grey.shade400),
                                      const SizedBox(width: 4),
                                      Text(
                                        d['duration'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── ProfileBody (reused in Profile tab & standalone screen) ─────────────────
class ProfileBody extends StatefulWidget {
  const ProfileBody({super.key});

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final admin = await UploadService.isCurrentUserAdmin();
    if (mounted) setState(() => _isAdmin = admin);
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final meta = user?.userMetadata;
    final name = meta?['full_name'] as String? ??
        meta?['name'] as String? ??
        user?.email?.split('@').first ??
        'Learner';
    final email = user?.email ?? '';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF1565C0),
          expandedHeight: 180,
          pinned: true,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 16, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Admin badge on avatar if is_admin
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'L',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ),
                      if (_isAdmin)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                ],
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 16),

            // ── Admin Panel entry (shown only to admins) ─────────────────
            if (_isAdmin) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Material(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () =>
                        Navigator.pushNamed(context, '/admin'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shield_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Panel',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                Text(
                                  'Manage courses, lessons & users',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey),
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
                ),
              ),
              const Divider(indent: 16, endIndent: 16),
            ],

            _ProfileTile(
              icon: Icons.person_outline_rounded,
              title: 'Edit Profile',
              onTap: () {},
            ),
            _ProfileTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {},
            ),
            _ProfileTile(
              icon: Icons.language_rounded,
              title: 'Language',
              subtitle: 'English',
              onTap: () {},
            ),
            _ProfileTile(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              onTap: () {},
            ),
            const Divider(indent: 16, endIndent: 16),
            _ProfileTile(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              titleColor: Colors.red,
              iconColor: Colors.red,
              onTap: () async {
                await supabase.auth.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Learn FM v${AppConfig.appVersion}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF1565C0)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor ?? const Color(0xFF1A1A2E),
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: Icon(Icons.chevron_right_rounded,
          color: Colors.grey.shade400, size: 20),
      onTap: onTap,
    );
  }
}
