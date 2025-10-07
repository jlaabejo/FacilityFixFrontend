import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/calendar.dart';
import 'package:facilityfix/admin/inventory.dart';
import 'package:facilityfix/admin/notification.dart';
import 'package:facilityfix/admin/profile.dart';
import 'package:facilityfix/admin/workorder.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/widgets/analytics.dart';
import 'package:facilityfix/widgets/cards.dart';
import 'package:facilityfix/widgets/modals.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:facilityfix/services/auth_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  int _selectedIndex = 0;

  // runtime user fields (defaults)
  String _userName = 'User'; // ← will be replaced by admin first name if available
  static const String _roleLabel = 'Administrator';
  bool _isLoading = false;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData(); // 🔌 fetch admin profile on launch
  }

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

  // ───────── profile helpers ─────────

  // Capitalize first name only (e.g., "juAN carLoS" -> "Juan")
  String _titleCaseFirstOnly(String input) {
    final s = input.trim();
    if (s.isEmpty) return s;
    final firstWord = s.split(RegExp(r'\s+')).first;
    final lower = firstWord.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final apiService = APIService();
      final profileData = await apiService.getUserProfile(); // expect Map or null

      if (profileData != null) {
        await AuthStorage.saveProfile(profileData); // optional caching
        _updateUIFromProfile(profileData);
      } else {
        // fallback to cached profile if API returned null
        final localProfile = await AuthStorage.getProfile();
        if (localProfile != null) {
          _updateUIFromProfile(localProfile);
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // fallback to cached profile on error
      final localProfile = await AuthStorage.getProfile();
      if (localProfile != null) {
        _updateUIFromProfile(localProfile);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateUIFromProfile(Map<String, dynamic> profile) {
    // Try 'first_name'; if missing, pick first token of 'full_name'
    final rawFirst = (profile['first_name'] ?? '').toString().trim();
    String name;
    if (rawFirst.isNotEmpty) {
      name = _titleCaseFirstOnly(rawFirst);
    } else {
      final full = (profile['full_name'] ?? '').toString().trim();
      name = full.isNotEmpty ? _titleCaseFirstOnly(full) : 'User';
    }

    if (mounted) {
      setState(() {
        _userName = name.isNotEmpty ? name : 'User';
      });
    }
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Home',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting (uses admin first name when available)
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
                        const Text(
                          'Administrator',
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick status cards
                    Row(
                      children: const [
                        Expanded(
                          child: StatusCard(
                            title: 'Repair\tRequest',
                            count: '1',
                            icon: Icons.settings_outlined,
                            iconColor: Color(0xFF005CE8),
                            backgroundColor: Color(0xFFEFF4FF),
                            borderColor: Color(0xFF005CE8),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: StatusCard(
                            title: 'Maintenance\tDue',
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

                    // Recent Repair Tasks
                    SectionHeader(
                      title: 'Recent Repair Request',
                      actionLabel: 'View all',
                      onActionTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WorkOrderPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        RepairCard(
                          title: 'Leaking faucet',
                          id: 'CS-2025-005',
                          createdAt: DateFormat('MMMM d, yyyy')
                              .parse('August 22, 2025'),
                          statusTag: 'Pending',
                          departmentTag: 'Plumbing',
                          requestTypeTag: 'Concern Slip',
                          unitId: 'A 1001',
                          priorityTag: null,
                          onTap: () {},
                          onChatTap: () {},
                        ),
                        const SizedBox(height: 12),
                        RepairCard(
                          title: 'Broken sink handle',
                          id: 'CS-2025-006',
                          createdAt: DateFormat('MMMM d, yyyy')
                              .parse('August 23, 2025'),
                          statusTag: 'Pending',
                          departmentTag: 'Plumbing',
                          requestTypeTag: 'Concern Slip',
                          unitId: 'A 1002',
                          priorityTag: 'High',
                          onTap: () {},
                          onChatTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent Maintenance Tasks
                    SectionHeader(
                      title: 'Recent Maintenance',
                      actionLabel: 'View all',
                      onActionTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WorkOrderPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        MaintenanceCard(
                          title: 'Quarterly Pipe Inspection',
                          id: 'MT-P-2025-011',
                          createdAt:
                              DateTime(DateTime.now().year, 8, 28),
                          statusTag: 'In Progress',
                          departmentTag: 'Plumbing',
                          priority: 'High',
                          location: 'Tower A - 5th Floor',
                          requestTypeTag: 'Maintenance',
                          assignedStaff: 'Juan Dela Cruz',
                          staffDepartment: 'Plumbing',
                          staffPhotoUrl: 'assets/images/avatar.png',
                          onTap: () {},
                          onChatTap: () {},
                        ),
                        const SizedBox(height: 12),
                        MaintenanceCard(
                          title: 'Generator Check-up',
                          id: 'MT-E-2025-013',
                          createdAt:
                              DateTime(DateTime.now().year, 8, 27),
                          statusTag: 'Done',
                          departmentTag: 'Electrical',
                          priority: 'Medium',
                          location: 'Basement - Power Room',
                          requestTypeTag: 'Maintenance',
                          assignedStaff: 'Juan Dela Cruz',
                          staffDepartment: 'Electrical',
                          staffPhotoUrl: 'assets/images/avatar.png',
                          onTap: () {},
                          onChatTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Announcements
                    SectionHeader(
                      title: 'Latest Announcement',
                      actionLabel: 'View all',
                      onActionTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AnnouncementPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    AnnouncementCard(
                      title: 'Utility Interruption',
                      createdAt:
                          DateTime.now().subtract(const Duration(days: 3)),
                      announcementType: 'utility interruption',
                      isRead: true,
                      id: '',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),

                    // Analytics
                    const SectionHeader(
                      title: 'Analytics',
                      actionLabel: '',
                    ),
                    const SizedBox(height: 12),
                  ],
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
