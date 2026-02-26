import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
  final String userName;
  final String userEmail;
  const ProfileScreen({super.key, required this.userName, required this.userEmail});

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
              ),
              child: Column(children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'L',
                    style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(userName, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(userEmail, style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 8),
            _statsRow(),
            const SizedBox(height: 8),
            _section('Account', [
              _tile(Icons.person_outline, 'Edit Profile', () {}),
              _tile(Icons.notifications_outlined, 'Notifications', () {}),
              _tile(Icons.lock_outline, 'Privacy & Security', () {}),
              _tile(Icons.download_outlined, 'Downloads', () {}),
            ]),
            const SizedBox(height: 8),
            _section('Learning', [
              _tile(Icons.emoji_events_outlined, 'Certificates', () {}),
              _tile(Icons.history, 'Learning History', () {}),
              _tile(Icons.bookmark_outline, 'Saved Courses', () {}),
            ]),
            const SizedBox(height: 8),
            _section('Support', [
              _tile(Icons.help_outline, 'Help & FAQ', () {}),
              _tile(Icons.feedback_outlined, 'Send Feedback', () {}),
              _tile(Icons.info_outline, 'About Learn FM', () {}),
            ]),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Sign Out', style: TextStyle(color: Colors.red, fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _statsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('3', 'Courses'),
          _divider(),
          _statItem('12h', 'Learned'),
          _divider(),
          _statItem('1', 'Certificates'),
          _divider(),
          _statItem('65%', 'Avg Progress'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }

  Widget _divider() => Container(width: 1, height: 30, color: Colors.grey.shade200);

  Widget _section(String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: const Color(0xFF1565C0), size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
      onTap: onTap,
    );
  }
}
