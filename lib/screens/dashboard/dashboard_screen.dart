import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../courses/courses_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _userName = 'Learner';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && mounted) {
      setState(() {
        _userName = (user.userMetadata?['full_name'] as String?) ?? user.email?.split('@')[0] ?? 'Learner';
        _userEmail = user.email ?? '';
      });
    }
  }

  late final List<Widget> _screens = [
    _HomeTab(userName: _userName),
    const CoursesScreen(),
    const AiChatScreen(),
    ProfileScreen(userName: _userName, userEmail: _userEmail),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(userName: _userName),
          const CoursesScreen(),
          const AiChatScreen(),
          ProfileScreen(userName: _userName, userEmail: _userEmail),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), activeIcon: Icon(Icons.smart_toy), label: 'AI Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String userName;
  const _HomeTab({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Learn FM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15)),
                  Text(userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    _statChip(Icons.check_circle_outline, '3 Courses'),
                    const SizedBox(width: 12),
                    _statChip(Icons.schedule, '12h Learned'),
                    const SizedBox(width: 12),
                    _statChip(Icons.emoji_events_outlined, '1 Cert'),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Continue Learning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
            const SizedBox(height: 12),
            _progressCard(context, 'Building Systems', 'HVAC, Electrical, Plumbing basics', 0.65, Icons.apartment),
            _progressCard(context, 'Safety & Compliance', 'Fire safety, regulations, codes', 0.30, Icons.health_and_safety),
            const SizedBox(height: 20),
            const Text('FM Domains', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _domainChip('Technical Services', Icons.build),
                _domainChip('Housekeeping', Icons.cleaning_services),
                _domainChip('Security', Icons.security),
                _domainChip('Fire Safety', Icons.local_fire_department),
                _domainChip('Facade Cleaning', Icons.window),
                _domainChip('Pest Control', Icons.bug_report),
                _domainChip('Helpdesk', Icons.support_agent),
                _domainChip('Accounts', Icons.account_balance),
                _domainChip('Budgeting', Icons.attach_money),
                _domainChip('Building Compliance', Icons.gavel),
                _domainChip('Labour Compliance', Icons.people),
                _domainChip('Vendor Management', Icons.handshake),
                _domainChip('Store Management', Icons.store),
                _domainChip('Procurement', Icons.shopping_cart),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white70, size: 14),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }

  Widget _progressCard(BuildContext context, String title, String subtitle, double progress, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: const Color(0xFF1565C0), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )),
            Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: const Color(0xFF1565C0),
            minHeight: 5,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _domainChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: const Color(0xFF1565C0)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0), fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
