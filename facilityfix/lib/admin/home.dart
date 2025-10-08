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

  // Dashboard data from API
  List<Map<String, dynamic>> _recentRepairRequests = [];
  List<Map<String, dynamic>> _recentMaintenance = [];
  int _activeWorkOrders = 0;
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
    _loadUserData(); // 🔌 fetch admin profile on launch
    _loadDashboardData(); // 🔌 fetch dashboard data
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

  // ───────── dashboard data helpers ─────────

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    try {
      final apiService = APIService();
      
      // Fetch all tenant requests (includes Concern Slips, Job Services, Work Orders)
      final allRequests = await apiService.getAllTenantRequests();
      
      // Fetch maintenance tasks
      final maintenanceTasks = await apiService.getAllMaintenance();

      if (mounted) {
        setState(() {
          // Process repair requests (recent 2 items)
          _recentRepairRequests = allRequests
              .where((request) => 
                  request['request_type'] == 'Concern Slip' ||
                  request['request_type'] == 'Job Service' ||
                  request['request_type'] == 'Work Order Permit')
              .take(2)
              .map((request) => _processRequestData(request))
              .toList();

          // Process maintenance tasks (recent 2 items)  
          _recentMaintenance = maintenanceTasks
              .take(2)
              .map((task) => _processMaintenanceData(task))
              .toList();

          // Calculate statistics
          _activeWorkOrders = allRequests
              .where((request) => 
                  request['status'] == 'assigned' || 
                  request['status'] == 'in_progress')
              .length;
          
          _maintenanceDue = maintenanceTasks
              .where((task) => 
                  task['status'] == 'scheduled' || 
                  task['status'] == 'pending')
              .length;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      // Keep existing data or show empty state
    }
  }

  Map<String, dynamic> _processRequestData(Map<String, dynamic> request) {
    return {
      'title': request['title'] ?? 'Untitled Request',
      'id': request['formatted_id'] ?? request['id'] ?? 'N/A',
      'createdAt': _parseDate(request['created_at']),
      'statusTag': _capitalizeStatus(request['status'] ?? 'pending'),
      'departmentTag': _mapCategoryToDepartment(request['category']),
      'priorityTag': _capitalizePriority(request['priority']),
      'unitId': request['unit_id'] ?? 'N/A',
      'requestTypeTag': request['request_type'] ?? 'Concern Slip',
      'assignedStaff': null,
      'staffDepartment': null,
    };
  }

  Map<String, dynamic> _processMaintenanceData(Map<String, dynamic> task) {
    return {
      'title': task['task_title'] ?? task['title'] ?? 'Maintenance Task',
      'id': task['formatted_id'] ?? task['id'] ?? 'N/A',
      'createdAt': _parseDate(task['scheduled_date'] ?? task['created_at']),
      'statusTag': _capitalizeStatus(task['status'] ?? 'scheduled'),
      'departmentTag': _mapCategoryToDepartment(task['category'] ?? task['department']),
      'priority': _capitalizePriority(task['priority']),
      'location': task['location'] ?? 'N/A',
      'requestTypeTag': 'Maintenance',
      'assignedStaff': task['assigned_staff'] ?? task['assigned_to'],
      'staffDepartment': _mapCategoryToDepartment(task['category'] ?? task['department']),
      'staffPhotoUrl': 'assets/images/avatar.png',
    };
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    
    return DateTime.now();
  }

  String _capitalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'assessed':
        return 'Assessed';
      case 'completed':
        return 'Completed';
      case 'scheduled':
        return 'Scheduled';
      case 'done':
        return 'Done';
      default:
        return status;
    }
  }

  String _capitalizePriority(String? priority) {
    if (priority == null) return 'Medium';
    
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return 'Medium';
    }
  }

  String _mapCategoryToDepartment(String? category) {
    if (category == null) return 'General';
    
    switch (category.toLowerCase()) {
      case 'electrical':
        return 'Electrical';
      case 'plumbing':
        return 'Plumbing';
      case 'hvac':
        return 'HVAC';
      case 'carpentry':
        return 'Carpentry';
      case 'maintenance':
        return 'Maintenance';
      case 'masonry':
        return 'Masonry';
      default:
        return 'General';
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
            : RefreshIndicator(
                onRefresh: () async {
                  await _loadUserData();
                  await _loadDashboardData();
                },
                child: SingleChildScrollView(
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

                      // Quick status cards (now with real data)
                      Row(
                        children: [
                          Expanded(
                            child: StatusCard(
                              title: 'Repair\tRequest',
                              count: '$_activeWorkOrders',
                              icon: Icons.settings_outlined,
                              iconColor: Color(0xFF005CE8),
                              backgroundColor: Color(0xFFEFF4FF),
                              borderColor: Color(0xFF005CE8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatusCard(
                              title: 'Maintenance\tDue',
                              count: '$_maintenanceDue',
                              icon: Icons.check_circle_rounded,
                              iconColor: Color(0xFF24D164),
                              backgroundColor: Color(0xFFF0FDF4),
                              borderColor: Color(0xFF24D164),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Recent Repair Tasks (now with real data)
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
                        children: _recentRepairRequests.isNotEmpty
                            ? _recentRepairRequests.map((request) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: RepairCard(
                                    title: request['title'],
                                    id: request['id'],
                                    createdAt: request['createdAt'],
                                    statusTag: request['statusTag'],
                                    departmentTag: request['departmentTag'],
                                    requestTypeTag: request['requestTypeTag'],
                                    unitId: request['unitId'],
                                    priorityTag: request['priorityTag'],
                                    onTap: () {},
                                    onChatTap: () {},
                                  ),
                                );
                              }).toList()
                            : [
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text(
                                      'No recent repair requests',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                      ),
                      const SizedBox(height: 24),

                      // Recent Maintenance Tasks (now with real data)
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
                        children: _recentMaintenance.isNotEmpty
                            ? _recentMaintenance.map((task) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: MaintenanceCard(
                                    title: task['title'],
                                    id: task['id'],
                                    createdAt: task['createdAt'],
                                    statusTag: task['statusTag'],
                                    departmentTag: task['departmentTag'],
                                    priority: task['priority'],
                                    location: task['location'],
                                    requestTypeTag: task['requestTypeTag'],
                                    assignedStaff: task['assignedStaff'],
                                    staffDepartment: task['staffDepartment'],
                                    staffPhotoUrl: task['staffPhotoUrl'],
                                    onTap: () {},
                                    onChatTap: () {},
                                  ),
                                );
                              }).toList()
                            : [
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text(
                                      'No recent maintenance tasks',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
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
      ),

      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}