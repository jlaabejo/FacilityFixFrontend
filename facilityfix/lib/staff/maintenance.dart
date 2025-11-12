import 'dart:async';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/config/env.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/notification.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/view_details/maintenance_detail.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart';
import 'package:facilityfix/widgets/cards.dart';
import 'package:facilityfix/widgets/helper_models.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:flutter/material.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  // ─────────────── Filters ───────────────
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  // ─────────────── Dynamic data from API ───────────────
  List<Map<String, dynamic>> _allMaintenanceTasks = [];
  bool _isLoading = true;
  String _currentStaffId = '';
  int _unreadNotifCount = 0;

  // ===== Refresh =============================================================
  Future<void> _refresh() async {
    await _loadAllMaintenanceTasks();
  }

  Future<void> _loadAllMaintenanceTasks() async {
    setState(() => _isLoading = true);
    

    try {
      // Get current user profile for logging/debugging
      final profile = await AuthStorage.getProfile();

      final userId = profile?['uid'] ??
                    profile?['user_id'] ??
                    profile?['id'] ??
                    profile?['userId'] ?? '';

      final staffId = profile?['staff_id'] ??
                     profile?['staffId'] ??
                     userId;

      final userEmail = profile?['email'] ?? '';

      // Store staff ID for checklist filtering
      _currentStaffId = staffId;

      print('DEBUG: Current user profile: $profile');
      print('DEBUG: Current user ID: $userId');
      print('DEBUG: Current staff ID: $staffId');
      print('DEBUG: Current user email: $userEmail');

      // Use staff role for API service
      final apiService = APIService(roleOverride: AppRole.staff);

     
      print('DEBUG: Making API call to getMyAssignedMaintenance...');
      final assignedTasks = await apiService.getMyAssignedMaintenance();
      print('DEBUG: API response received - assigned task count: ${assignedTasks.length}');
      print('DEBUG: Sample assigned task data: ${assignedTasks.isNotEmpty ? assignedTasks.first : 'No tasks'}');

      // Also load special maintenance tasks
      print('DEBUG: Making API call to getSpecialMaintenanceTasks...');
      List<Map<String, dynamic>> specialTasks = [];
      try {
        specialTasks = await apiService.getSpecialMaintenanceTasks();
        print('DEBUG: Special tasks loaded - count: ${specialTasks.length}');
      } catch (e) {
        print('DEBUG: Note - Special maintenance tasks not available yet: $e');
        // Not critical if special tasks aren't available
      }

      if (mounted) {
        print('DEBUG: User profile fields available: ${profile?.keys.toList()}');
        print('DEBUG: Sample task assigned_to values:');
        for (int i = 0; i < assignedTasks.length && i < 3; i++) {
          final task = assignedTasks[i];
          print('  Task ${i + 1}: assigned_to="${task['assigned_to']}", assigned_staff="${task['assigned_staff']}"');
          // Check checklist items too
          final checklist = task['checklist_completed'] as List?;
          if (checklist != null && checklist.isNotEmpty) {
            print('    Checklist items:');
            for (var item in checklist.take(2)) {
              print('      - ${item['task']}: assigned_to="${item['assigned_to']}"');
            }
          }
        }
        print('DEBUG: Showing ${assignedTasks.length} regular tasks and ${specialTasks.length} special tasks assigned to user');

        // For special tasks, filter checklist items to only show items assigned to current user
        final filteredSpecialTasks = specialTasks.map((task) {
          final checklist = task['checklist_completed'] as List?;
          if (checklist != null && checklist.isNotEmpty) {
            // Filter checklist to only include items assigned to this user
            final filteredChecklist = checklist.where((item) {
              final assignedTo = item['assigned_to'];
              return assignedTo != null && assignedTo == userId;
            }).toList();

            // Only include the task if there are assigned items
            if (filteredChecklist.isNotEmpty) {
              return {
                ...task,
                'checklist_completed': filteredChecklist,
              };
            }
          }
          return null;
        }).where((task) => task != null).cast<Map<String, dynamic>>().toList();

        print('DEBUG: Filtered special tasks to ${filteredSpecialTasks.length} with assigned items only');

        // Combine regular and filtered special tasks
        final allTasks = [...assignedTasks, ...filteredSpecialTasks];

        setState(() {
          _allMaintenanceTasks = allTasks.map((task) {
            // Ensure consistent data structure
            final mappedTask = {
              'id': task['id'] ?? '',
              'formatted_id': task['formatted_id'] ?? task['id'] ?? '',
              'task_title': task['task_title'] ?? task['title'] ?? 'Maintenance Task',
              'title': task['task_title'] ?? task['title'] ?? 'Maintenance Task',
              'task_description': task['task_description'] ?? task['description'] ?? '',
              'description': task['task_description'] ?? task['description'] ?? '',
              'location': task['location'] ?? '',
              'category': task['category'] ?? 'preventive',
              'priority': task['priority'] ?? 'medium',
              'status': task['status'] ?? 'scheduled',
              'scheduled_date': task['scheduled_date'] ?? task['created_at'] ?? DateTime.now().toIso8601String(),
              'created_at': task['created_at'] ?? DateTime.now().toIso8601String(),
              'assigned_to': task['assigned_to'] ?? task['assigned_staff'] ?? '',
              'assigned_staff': task['assigned_to'] ?? task['assigned_staff'] ?? '',
              'assigned_staff_name': task['assigned_staff_name'] ?? task['assigned_staff'] ?? task['assigned_to'] ?? '',
              'maintenance_type': task['maintenance_type'] ?? task['maintenanceType'] ?? 'internal',
              'maintenanceType': task['maintenanceType'] ?? task['maintenance_type'] ?? 'internal',
              'task_type': task['task_type'] ?? 'internal',
              'building_id': task['building_id'] ?? 'default_building',
              'estimated_duration': task['estimated_duration'],
              'actual_duration': task['actual_duration'],
              'started_at': task['started_at'],
              'completed_at': task['completed_at'],
              'completion_notes': task['completion_notes'],
              'parts_used': task['parts_used'] ?? [],
              'tools_used': task['tools_used'] ?? [],
              'photos': task['photos'] ?? [],
              'recurrence_type': task['recurrence_type'] ?? 'none',
              'checklist_completed': task['checklist_completed'] ?? [],
              'department': task['department'] ?? task['category'] ?? '',
              'updated_at': task['updated_at'] ?? task['created_at'] ?? DateTime.now().toIso8601String(),
              'created_by': task['created_by'] ?? task['assigned_to'] ?? '',
            };
            return mappedTask;
          }).toList();
          _isLoading = false;

          print('DEBUG: Mapped ${_allMaintenanceTasks.length} total tasks for display');
        });
      }
    } catch (e) {
      print('Error loading maintenance tasks: $e');
      print('Error type: ${e.runtimeType}');
      if (e is Exception) {
        print('Exception details: ${e.toString()}');
      }
      if (mounted) {
        setState(() {
          _allMaintenanceTasks = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadAllMaintenanceTasks();
    _loadUnreadNotifCount();
  }

  Future<void> _loadUnreadNotifCount() async {
    try {
      final api = APIService(roleOverride: AppRole.staff);
      final count = await api.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadNotifCount = count);
    } catch (e) {
      print('[MaintenancePage] Failed to load unread notification count: $e');
    }
  }

  // ===== Bottom nav ==========================================================
  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.build),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  void _onTabTapped(int index) {
    if (index == 2) return; // Already on Maintenance page

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WorkOrderPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AnnouncementPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CalendarPage()),
        );
        break;
      case 5:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InventoryPage()),
        );
        break;
    }
  }

  // ===== Filtering logic =====================================================
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';
  String _norm(String? s) => (s ?? '').toLowerCase().trim();

  bool _statusMatches(Map<String, dynamic> task) {
    if (_selectedStatus == 'All') return true;
    return _norm(task['status']) == _norm(_selectedStatus);
  }

  bool _searchMatches(Map<String, dynamic> task) {
    final q = _norm(_searchController.text);
    if (q.isEmpty) return true;

    final scheduledDate = DateTime.tryParse(task['scheduled_date'] ?? '') ?? DateTime.now();
    final dateText = shortDate(scheduledDate);

    return <String>[
      task['title'] ?? '',
      task['task_title'] ?? '',
      task['id'] ?? '',
      task['formatted_id'] ?? '',
      task['location'] ?? '',
      task['category'] ?? '',
      task['status'] ?? '',
      task['maintenance_type'] ?? '',
      dateText,
    ].any((s) => _norm(s).contains(q));
  }

  List<Map<String, dynamic>> get _filtered {
    final filtered = _allMaintenanceTasks
        .where(_statusMatches)
        .where(_searchMatches)
        .toList();
    
    print('DEBUG: Filtering results:');
    print('  Total tasks: ${_allMaintenanceTasks.length}');
    print('  After status filter: ${_allMaintenanceTasks.where(_statusMatches).length}');
    print('  After search filter: ${filtered.length}');
    print('  Current filters: status="$_selectedStatus", search="${_searchController.text}"');
    
    return filtered;
  }

  List<Map<String, dynamic>> get _filteredSorted {
    final list = List<Map<String, dynamic>>.from(_filtered);
    list.sort((a, b) {
      final aDate = DateTime.tryParse(a['scheduled_date'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['scheduled_date'] ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    return list;
  }

  List<String> get _statusOptions {
    // Fixed status list matching the filter design
    return ['All', 'Assessed', 'Assigned', 'Completed', 'Sent'];
  }

  Widget buildMaintenanceCard(Map<String, dynamic> task) {
    final scheduledDate = DateTime.tryParse(task['scheduled_date'] ?? '') ?? DateTime.now();
    final taskId = task['formatted_id'] ?? task['id'] ?? '';
    final title = task['title'] ?? task['task_title'] ?? 'Maintenance Task';
    final location = task['location'] ?? '';
    final status = task['status'] ?? 'scheduled';
    final category = task['category'] ?? 'preventive';
    final priority = task['priority'] ?? 'medium';
    final maintenanceType = task['maintenanceType'] ?? task['maintenance_type'] ?? 'internal';

    return MaintenanceCard(
      id: taskId,
      createdAt: scheduledDate,
      requestTypeTag: maintenanceType.toUpperCase(),
      departmentTag: category,
      priority: priority,
      statusTag: status,
      title: title,
      location: location,
      assignedStaff: task['assigned_staff_name'] ?? task['assigned_staff'],
      staffDepartment: task['category'],
      onTap: () {
        final maintenanceTaskId = task['id'] ?? '';
        
        if (maintenanceTaskId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Invalid maintenance task ID'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MaintenanceDetailPage(
              task: task,
              currentStaffId: _currentStaffId,
            ),
          ),
        ).then((_) {
          // Refresh data when returning
          _loadAllMaintenanceTasks();
        });
      },
      // Chat removed as requested
      onChatTap: null,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredSorted;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Maintenance Tasks',
        notificationCount: _unreadNotifCount,
        onNotificationTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationPage()),
          );
          _loadUnreadNotifCount();
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchAndFilterBar(
                      searchController: _searchController,
                      selectedStatus: _selectedStatus,
                      statuses: _statusOptions,
                      onStatusChanged: (status) {
                        setState(() {
                          _selectedStatus = status.trim().isEmpty ? 'All' : status;
                        });
                      },
                      onSearchChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Text(
                          'Maintenance Tasks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${items.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475467),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: items.isEmpty
                          ? const EmptyState()
                          : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => buildMaintenanceCard(items[i]),
                          ),
                    ),
                  ],
                ),
              ),
        ),
      ),
      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: 2,
        onTap: _onTabTapped,
      ),
    );
  }
}

// Mobile-friendly tab selector
class MobileTabSelector extends StatelessWidget {
  final List<TabItem> tabs;
  final String selectedLabel;
  final ValueChanged<String> onTabSelected;

  const MobileTabSelector({
    super.key,
    required this.tabs,
    required this.selectedLabel,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final bool isSelected = selectedLabel == tab.label;
            
            return GestureDetector(
              onTap: () => onTabSelected(tab.label),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab.label,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1F2937)
                            : const Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tab.count}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
