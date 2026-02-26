import 'package:flutter/material.dart';

const List<Map<String, dynamic>> kCourses = [
  {'title': 'Technical Services', 'icon': Icons.build, 'lessons': 12, 'duration': '8h', 'level': 'Beginner', 'desc': 'HVAC, electrical systems, plumbing maintenance and repairs for FM professionals.'},
  {'title': 'Housekeeping Management', 'icon': Icons.cleaning_services, 'lessons': 8, 'duration': '5h', 'level': 'Beginner', 'desc': 'Standards, schedules, quality checks and staff management for housekeeping.'},
  {'title': 'Security Operations', 'icon': Icons.security, 'lessons': 10, 'duration': '6h', 'level': 'Intermediate', 'desc': 'Access control, CCTV, incident response and security protocols.'},
  {'title': 'Fire Safety & Emergency', 'icon': Icons.local_fire_department, 'lessons': 14, 'duration': '10h', 'level': 'Intermediate', 'desc': 'Fire prevention, evacuation planning, extinguisher types, and mock drills.'},
  {'title': 'Facade Cleaning', 'icon': Icons.window, 'lessons': 6, 'duration': '4h', 'level': 'Beginner', 'desc': 'Rope access, cradle systems, chemical cleaning and safety protocols.'},
  {'title': 'Pest Control', 'icon': Icons.bug_report, 'lessons': 7, 'duration': '4h', 'level': 'Beginner', 'desc': 'Identification, prevention, treatment methods and compliance requirements.'},
  {'title': 'Helpdesk & CMMS', 'icon': Icons.support_agent, 'lessons': 9, 'duration': '5h', 'level': 'Beginner', 'desc': 'Ticket management, SLA tracking and CMMS software usage.'},
  {'title': 'Accounts & Finance', 'icon': Icons.account_balance, 'lessons': 11, 'duration': '7h', 'level': 'Intermediate', 'desc': 'P&L statements, cost centers, invoicing and financial reporting for FM.'},
  {'title': 'Budgeting & Cost Control', 'icon': Icons.attach_money, 'lessons': 8, 'duration': '5h', 'level': 'Intermediate', 'desc': 'Annual budgets, variance analysis, cost optimization and forecasting.'},
  {'title': 'Building Compliance', 'icon': Icons.gavel, 'lessons': 13, 'duration': '9h', 'level': 'Advanced', 'desc': 'Local authority regulations, inspections, NOC renewals and statutory compliance.'},
  {'title': 'Labour Compliance', 'icon': Icons.people, 'lessons': 10, 'duration': '7h', 'level': 'Advanced', 'desc': 'Labour laws, PF/ESI, contractor compliance and documentation.'},
  {'title': 'Vendor Management', 'icon': Icons.handshake, 'lessons': 9, 'duration': '6h', 'level': 'Intermediate', 'desc': 'Vendor selection, SLA monitoring, performance review and renewals.'},
  {'title': 'Store Management', 'icon': Icons.store, 'lessons': 7, 'duration': '4h', 'level': 'Beginner', 'desc': 'Inventory control, stock management, GRN and store audits.'},
  {'title': 'Procurement', 'icon': Icons.shopping_cart, 'lessons': 8, 'duration': '5h', 'level': 'Intermediate', 'desc': 'RFQ, comparative analysis, purchase orders and vendor negotiations.'},
];

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _search = '';
  String _filter = 'All';

  List<Map<String, dynamic>> get _filtered {
    return kCourses.where((c) {
      final matchSearch = c['title'].toString().toLowerCase().contains(_search.toLowerCase());
      final matchFilter = _filter == 'All' || c['level'] == _filter;
      return matchSearch && matchFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Courses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search courses...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1565C0))),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Beginner', 'Intermediate', 'Advanced'].map((f) {
                      final selected = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: selected,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: const Color(0xFF1565C0),
                          labelStyle: TextStyle(color: selected ? Colors.white : Colors.grey.shade700, fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final c = _filtered[i];
                return _CourseCard(course: c);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  const _CourseCard({required this.course});

  Color get _levelColor {
    switch (course['level']) {
      case 'Beginner': return Colors.green;
      case 'Intermediate': return Colors.orange;
      case 'Advanced': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(course['icon'] as IconData, color: const Color(0xFF1565C0), size: 24),
        ),
        title: Text(course['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(course['desc'], style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.play_circle_outline, size: 13, color: Colors.grey.shade600),
              const SizedBox(width: 3),
              Text('${course['lessons']} lessons', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(width: 10),
              Icon(Icons.schedule, size: 13, color: Colors.grey.shade600),
              const SizedBox(width: 3),
              Text(course['duration'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _levelColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(course['level'], style: TextStyle(fontSize: 10, color: _levelColor, fontWeight: FontWeight.w600)),
              ),
            ]),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1565C0)),
        onTap: () {
          Navigator.pushNamed(context, '/course-detail', arguments: course);
        },
      ),
    );
  }
}
