import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/calendar.dart';
import 'package:facilityfix/admin/inventory.dart';
import 'package:facilityfix/admin/notification.dart';
import 'package:facilityfix/admin/profile.dart';
import 'package:facilityfix/admin/workorder.dart';
import 'package:facilityfix/admin/view_details/workorder_details.dart';
import 'package:facilityfix/widgets/analytics.dart';
import 'package:facilityfix/widgets/cards.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/services/auth_service.dart';
import 'package:facilityfix/services/api_services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  int _selectedIndex = 0;

  String _userName = 'Admin';
  static const String _roleLabel = 'Property Management';

  List<Map<String, dynamic>> _recentConcernSlips = [];
  int _totalRepairRequests = 0;
  int _maintenanceDue = 0;
  bool _isLoading = true;

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
    _loadUserData();
    _loadDashboardData();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      if (user != null && user['firstName'] != null) {
        setState(() {
          _userName = user['firstName'];
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final apiService = APIService();

      final concernSlips = await apiService.getAllConcernSlips();

      final pendingRequests =
          concernSlips
              .where(
                (slip) =>
                    slip['status'] == 'pending' ||
                    slip['status'] == 'in_progress',
              )
              .length;

      final sortedSlips = List<Map<String, dynamic>>.from(concernSlips);
      sortedSlips.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['created_at'] ?? '');
          final dateB = DateTime.parse(b['created_at'] ?? '');
          return dateB.compareTo(dateA); // Most recent first
        } catch (e) {
          return 0;
        }
      });
      final recentSlips = sortedSlips.take(5).toList();

      setState(() {
        _recentConcernSlips = recentSlips;
        _totalRepairRequests = pendingRequests;
        _maintenanceDue = 0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    _roleLabel,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: StatusCard(
                      title: 'Repair\tRequest',
                      count: _totalRepairRequests.toString(),
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
                      count: _maintenanceDue.toString(),
                      icon: Icons.check_circle_rounded,
                      iconColor: Color(0xFF24D164),
                      backgroundColor: Color(0xFFF0FDF4),
                      borderColor: Color(0xFF24D164),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SectionHeader(
                title: 'Recent Repair Request',
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

              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _recentConcernSlips.isEmpty
                  ? Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No recent repair requests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'New concern slips will appear here',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                  : Column(
                    children:
                        _recentConcernSlips.map((slip) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RepairCard(
                              title: slip['title'] ?? 'Untitled Request',
                              requestId: slip['id'] ?? 'N/A',
                              reqDate: _formatDate(slip['created_at']),
                              statusTag: _formatStatus(slip['status']),
                              departmentTag: _formatCategory(slip['category']),
                              requestType: 'Concern Slip',
                              unit: slip['unit_id'] ?? 'N/A',
                              priority: _formatPriority(slip['priority']),
                              hasCompletionAssessment:
                                  slip['status'] == 'completed',
                              completionAssigneeName: 'Admin Staff',
                              completionAssigneeDepartment: _formatCategory(
                                slip['category'],
                              ),
                              onTap: () async {
                                try {
                                  final apiService = APIService();
                                  final concernSlipData = await apiService
                                      .getConcernSlipById(slip['id']);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => WorkOrderDetailsPage(
                                            selectedTabLabel: 'concern slip',
                                            concernSlipData: concernSlipData,
                                          ),
                                    ),
                                  );
                                } catch (e) {
                                  print('Error fetching concern slip data: $e');
                                  // Fallback navigation without data
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => WorkOrderDetailsPage(
                                            selectedTabLabel: 'concern slip',
                                          ),
                                    ),
                                  );
                                }
                              },
                              onChatTap: () {},
                            ),
                          );
                        }).toList(),
                  ),

              const SizedBox(height: 24),

              const SectionHeader(title: 'Analytics'),
              const SizedBox(height: 12),
              WeeklyAnalyticsChartCard(
                xLabels: const [
                  'Sun',
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                ],
                repairCounts: const [4, 6, 3, 10, 2, 5, 1],
                maintenanceCounts: const [2, 1, 6, 7, 3, 2, 8],
                highlightIndex: DateTime.now().weekday % 7,
              ),
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

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.month}/${date.day}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Done';
      default:
        return 'Pending';
    }
  }

  String _formatCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'plumbing':
        return 'Plumbing';
      case 'electrical':
        return 'Electrical';
      case 'hvac':
        return 'HVAC';
      case 'general':
        return 'General';
      default:
        return 'General';
    }
  }

  String _formatPriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return 'Medium';
    }
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.onActionTap});
  final String title;
  final VoidCallback? onActionTap;

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
        TextButton(
          onPressed: onActionTap,
          child: Text(
            'View all',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
