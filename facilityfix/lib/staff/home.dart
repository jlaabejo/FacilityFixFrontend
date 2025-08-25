import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/notification.dart' show NotificationPage;
import 'package:facilityfix/staff/profile.dart'; // make sure this exists
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/widgets/cards.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  int _selectedIndex = 0;

  static const String _userName = 'Juan';
  static const String _department = 'Maintenance';

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const CalendarPage(),
      const InventoryPage(),
    ];
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
      setState(() => _selectedIndex = index);
    }
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: CustomAppBar(
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundImage: AssetImage('assets/images/profile.png'),
            radius: 16,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
        ),
        title: 'Home',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'Hello, ',
                        style: const TextStyle(
                          color: Color(0xFF1B1D21),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: _userName,
                            style: const TextStyle(
                              color: Color(0xFF101828),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _department,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status Cards
                Row(
                  children: const [
                    Expanded(
                      child: StatusCard(
                        title: 'Active Request',
                        count: '1',
                        icon: Icons.settings_outlined,
                        iconColor: Color(0xFFF79009),
                        backgroundColor: Color(0xFFFFFAEB),
                        borderColor: Color(0xFFF79009),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: StatusCard(
                        title: 'Done',
                        count: '0',
                        icon: Icons.check_circle_rounded,
                        iconColor: Color(0xFF24D164),
                        backgroundColor: Color(0xFFF0FDF4),
                        borderColor: Color(0xFF24D164),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Requests (Repair – tenant-created)
                const _SectionHeader(title: 'Recent Requests', actionLabel: 'View all'),
                const SizedBox(height: 12),
                Column(
                  children: [
                    RepairCard(
                      title: "Leaking Faucet",
                      requestId: "REQ-2025-009",
                      date: "27 Sept",
                      status: "In Progress",
                      unit: 'A 123',                
                      priority: 'medium',             
                      department: 'maintenance',            
                      showAvatar: false,        
                      avatarUrl: null,         
                      onTap: () {},
                      onChatTap: () {},
                    ),
                    const SizedBox(height: 12),
                    RepairCard(
                      title: "Clogged Drainage",
                      requestId: "CS-2025-00321",
                      date: "12 Jul",
                      status: "Pending",
                      unit: 'C 124',
                      priority: 'low',
                      department: 'maintenance',
                      showAvatar: false,
                      avatarUrl: null,
                      onTap: () {},
                      onChatTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Maintenance (admin-created)
                const _SectionHeader(title: 'Recent Maintenance', actionLabel: 'View all'),
                const SizedBox(height: 12),
                Column(
                  children: [
                    MaintenanceCard(
                      title: "Leaking Faucet",
                      requestId: "REQ-2025-009",
                      date: "27 Sept",
                      status: "In Progress",
                      unit: 'A 1001',
                      priority: 'High',
                      department: 'Maintenance',
                      onTap: () {},
                      onChatTap: () {},
                    ),
                    const SizedBox(height: 12),
                    MaintenanceCard(
                      title: "Clogged Drainage",
                      requestId: "CS-2025-00321",
                      date: "12 Jul",
                      status: "Pending",
                      unit: 'B 102',
                      priority: 'Medium',
                      department: 'Maintenance',
                      onTap: () {},
                      onChatTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Latest Announcement
                const _SectionHeader(title: 'Latest Announcement', actionLabel: 'View all'),
                const SizedBox(height: 12),
                AnnouncementCard(
                  title: 'Utility Interruption',
                  datePosted: '3 hours ago',
                  details: 'Temporary shutdown in pipelines for maintenance cleaning.',
                  classification: 'utility interruption',
                  onTap: () {},
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel});
  final String title;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: () {},
            child: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
