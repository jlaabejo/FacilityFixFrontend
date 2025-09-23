import 'package:flutter/material.dart';

import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/calendar.dart';
import 'package:facilityfix/admin/inventory.dart';
import 'package:facilityfix/admin/notification.dart';
import 'package:facilityfix/admin/profile.dart';
import 'package:facilityfix/admin/workorder.dart';
import 'package:facilityfix/admin/view_details/workorder_details.dart';

import 'package:facilityfix/widgets/analytics.dart';
import 'package:facilityfix/widgets/cards.dart';
import 'package:facilityfix/widgets/helper_models.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';

import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/services/auth_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  // nav
  int _selectedIndex = 0;

  // loading
  bool _isLoading = true;

  // greeting
  String _userName = 'Admin';

  // lists
  List<Map<String, dynamic>> _recentConcernSlips = [];
  List<Map<String, dynamic>> _recentMaintenance = [];
  List<Map<String, dynamic>> _recentAnnouncements = [];

  // KPIs
  int _totalRepairRequests = 0;
  int _maintenanceDue = 0;

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
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadUserData();        // ensures we greet with local profile (first_name)
    await _loadDashboardData();   // only then hit protected APIs
  }

  // ===== DATA LOADERS =====

  Future<void> _loadUserData() async {
    try {
      final profile = await AuthStorage.getProfile();
      final firstName = (profile?['first_name'] as String?)?.trim();
      if (!mounted) return;
      setState(() {
        _userName = (firstName != null && firstName.isNotEmpty) ? firstName : 'Admin';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _userName = 'Admin');
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final api = APIService(); // role and baseUrl are resolved inside

      // Concern slips (repair requests)
      final concernSlips =
          List<Map<String, dynamic>>.from(await api.getAllConcernSlips());

      final pendingRequests = concernSlips.where((slip) {
        final s = slip['status']?.toString().toLowerCase();
        return s == 'pending' || s == 'in_progress';
      }).length;

      final recentSlips = _sortedRecent(concernSlips, key: 'created_at', take: 5);

      // Maintenance
      final maintenance =
          List<Map<String, dynamic>>.from(await api.getAllMaintenance());
      final recentMaintenance = _sortedRecent(maintenance, key: 'created_at', take: 5);
      final maintenanceDue = maintenance.where((m) {
        final s = m['status']?.toString().toLowerCase();
        return s == 'due';
      }).length;

      // Announcements
      final announcements =
          List<Map<String, dynamic>>.from(await api.getAllAnnouncements());
      final recentAnnouncements =
          _sortedRecent(announcements, key: 'created_at', take: 5);

      if (!mounted) return;
      setState(() {
        _recentConcernSlips = recentSlips;
        _recentMaintenance = recentMaintenance;
        _recentAnnouncements = recentAnnouncements;
        _totalRepairRequests = pendingRequests;
        _maintenanceDue = maintenanceDue;
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error loading dashboard data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _sortedRecent(
    List<Map<String, dynamic>> items, {
    required String key,
    int take = 5,
  }) {
    final sorted = List<Map<String, dynamic>>.from(items);
    sorted.sort((a, b) {
      final dateA = DateTime.tryParse((a[key] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse((b[key] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA); // most recent first
    });
    return sorted.take(take).toList();
  }

  // ===== NAV =====

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const CalendarPage(),
      const InventoryPage(),
    ];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destinations[index]),
    );
    setState(() => _selectedIndex = index);
  }

  // ===== UI =====

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
              // Greeting
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

              const SizedBox(height: 16),

              // Status cards
              Row(
                children: [
                  Expanded(
                    child: StatusCard(
                      title: 'Repair\tRequest',
                      count: _totalRepairRequests.toString(),
                      icon: Icons.settings_outlined,
                      iconColor: const Color(0xFF005CE8),
                      backgroundColor: const Color(0xFFEFF4FF),
                      borderColor: const Color(0xFF005CE8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatusCard(
                      title: 'Maintenance\tDue',
                      count: _maintenanceDue.toString(),
                      icon: Icons.check_circle_rounded,
                      iconColor: const Color(0xFF24D164),
                      backgroundColor: const Color(0xFFF0FDF4),
                      borderColor: const Color(0xFF24D164),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Repair Request
              SectionHeader(
                title: 'Recent Repair Request',
                actionLabel: 'See all',
                onActionTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WorkOrderPage()),
                  );
                },
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_recentConcernSlips.isEmpty)
                _emptyBox(
                  icon: Icons.inbox_outlined,
                  title: 'No recent repair requests',
                  subtitle: 'New concern slips will appear here',
                )
              else
                Column(
                  children: _recentConcernSlips.map((slip) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RepairCard(
                        title: (slip['title'] ?? 'Untitled Request').toString(),
                        requestId: (slip['id'] ?? 'N/A').toString(),
                        reqDate: _formatDate(slip['created_at']),
                        statusTag: _formatStatus(slip['status']?.toString()),
                        departmentTag:
                            _formatCategory(slip['category']?.toString()),
                        requestType: 'Concern Slip',
                        unit: (slip['unit_id'] ?? 'N/A').toString(),
                        priority: _formatPriority(slip['priority']?.toString()),
                        hasCompletionAssessment:
                            (slip['status']?.toString().toLowerCase() ==
                                'completed'),
                        completionAssigneeName: 'Admin Staff',
                        completionAssigneeDepartment:
                            _formatCategory(slip['category']?.toString()),
                        onTap: () async {
                          try {
                            final api = APIService();
                            final concernSlipData =
                                await api.getConcernSlipById(slip['id'].toString());
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkOrderDetailsPage(
                                  selectedTabLabel: 'concern slip',
                                  concernSlipData: concernSlipData,
                                ),
                              ),
                            );
                          } catch (e) {
                            // ignore: avoid_print
                            print('Error fetching concern slip data: $e');
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WorkOrderDetailsPage(
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

              // Recent Maintenance
              SectionHeader(
                title: 'Recent Maintenance',
                actionLabel: 'See all',
                onActionTap: () {
                  // Replace with your maintenance list page if any
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WorkOrderPage()),
                  );
                },
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_recentMaintenance.isEmpty)
                _emptyBox(
                  icon: Icons.build_outlined,
                  title: 'No recent maintenance tasks',
                  subtitle: 'Scheduled or completed items will appear here',
                )
              else
                Column(
                  children: _recentMaintenance.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RepairCard(
                        title: (m['title'] ?? 'Maintenance Task').toString(),
                        requestId: (m['id'] ?? 'N/A').toString(),
                        reqDate: _formatDate(m['created_at']),
                        statusTag: _formatStatus(m['status']?.toString()),
                        departmentTag:
                            _formatCategory(m['category']?.toString()),
                        requestType: 'Maintenance',
                        unit: (m['unit_id'] ?? 'N/A').toString(),
                        priority: _formatPriority(m['priority']?.toString()),
                        hasCompletionAssessment:
                            (m['status']?.toString().toLowerCase() ==
                                'completed'),
                        completionAssigneeName: 'Admin Staff',
                        completionAssigneeDepartment:
                            _formatCategory(m['category']?.toString()),
                        onTap: () {
                          // TODO: navigate to maintenance details if available
                        },
                        onChatTap: () {},
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // Recent Announcements
              SectionHeader(
                title: 'Recent Announcements',
                actionLabel: 'See all',
                onActionTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnnouncementPage()),
                  );
                },
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_recentAnnouncements.isEmpty)
                _emptyBox(
                  icon: Icons.campaign_outlined,
                  title: 'No announcements yet',
                  subtitle: 'New announcements will appear here',
                )
              else
                Column(
                  children: _recentAnnouncements.map((a) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.announcement_outlined),
                        title: Text(
                          (a['title'] ?? 'Announcement').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_formatDate(a['created_at'])),
                        onTap: () {
                          // TODO: Navigate to announcement detail if available
                        },
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // Analytics
              const SectionHeader(
                title: 'Analytics',
                actionLabel: '',
              ),
              const SizedBox(height: 12),

              WeeklyAnalyticsChartCard(
                xLabels: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
                repairCounts: const [4, 6, 3, 10, 2, 5, 1],
                maintenanceCounts: const [2, 1, 6, 7, 3, 2, 8],
                // DateTime.weekday: Mon=1..Sun=7; %7 maps Sun->0, Mon->1 ... Sat->6
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

  // ===== HELPERS =====

  Widget _emptyBox({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.month}/${date.day}';
    } catch (_) {
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
      case 'due':
        return 'Due';
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
      case 'critical':
        return 'Critical';
      default:
        return 'Medium';
    }
  }
}
