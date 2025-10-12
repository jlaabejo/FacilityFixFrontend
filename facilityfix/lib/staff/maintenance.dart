import 'dart:async';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/config/env.dart';
import 'package:facilityfix/staff/maintenance_detail.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/services/chat_helper.dart';
import 'package:facilityfix/staff/notification.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/profile.dart';
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
  // ─────────────── Tabs (by status) ───────────────
  String _selectedTabLabel = "All";

  // ─────────────── Filters ───────────────
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  // ─────────────── Dynamic data from API ───────────────
  List<Map<String, dynamic>> _allMaintenanceTasks = [];
  bool _isLoading = true;

  // ===== Refresh =============================================================
  Future<void> _refresh() async {
    await _loadAllMaintenanceTasks();
  }

  Future<void> _loadAllMaintenanceTasks() async {
    setState(() => _isLoading = true);

    try {
      // Get current user to filter tasks assigned to them
      final profile = await AuthStorage.getProfile();
      
      // Try multiple possible user ID field names
      final userId = profile?['uid'] ?? 
                    profile?['user_id'] ?? 
                    profile?['id'] ?? 
                    profile?['userId'] ?? '';
      
      final userEmail = profile?['email'] ?? '';
      
      print('DEBUG: Current user profile: $profile');
      print('DEBUG: Current user ID: $userId');
      print('DEBUG: Current user email: $userEmail');
      
      if (userId.isEmpty && userEmail.isEmpty) {
        print('Warning: No user ID or email found - showing all maintenance tasks');
        print('User may need to log in again for proper task filtering');
        // Don't return early - show all tasks instead of empty list
      }

      // Use staff role for API service
      final apiService = APIService(roleOverride: AppRole.staff);
      print('DEBUG: Making API call to getAllMaintenance...');
      final allTasks = await apiService.getAllMaintenance();
      print('DEBUG: API response received - task count: ${allTasks.length}');
      print('DEBUG: Sample task data: ${allTasks.isNotEmpty ? allTasks.first : 'No tasks'}');

      if (mounted) {
        // For now, show all tasks to debug the rendering issue
        // TODO: Implement proper user-based filtering later
        List<Map<String, dynamic>> assignedTasks = allTasks;
        
        print('DEBUG: User profile fields available: ${profile?.keys.toList()}');
        print('DEBUG: Sample task assigned_to values:');
        for (int i = 0; i < allTasks.length && i < 3; i++) {
          final task = allTasks[i];
          print('  Task ${i + 1}: assigned_to="${task['assigned_to']}", assigned_staff="${task['assigned_staff']}"');
        }
        print('DEBUG: Showing all ${assignedTasks.length} tasks (filtering temporarily disabled)');

        setState(() {
          _allMaintenanceTasks = assignedTasks.map((task) {
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
            };
            return mappedTask;
          }).toList();
          _isLoading = false;
          
          print('DEBUG: Mapped ${_allMaintenanceTasks.length} tasks for display');
          print('DEBUG: Sample mapped task: ${_allMaintenanceTasks.isNotEmpty ? _allMaintenanceTasks.first : 'None'}');
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
  }

  // ===== Bottom nav ==========================================================
  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.build),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.inventory),
    NavItem(icon: Icons.person),
  ];

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const MaintenancePage(),
      const AnnouncementPage(),
      const InventoryPage(),
      const ProfilePage(),
    ];
    if (index != 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  // ===== Filtering logic =====================================================
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';
  String _norm(String? s) => (s ?? '').toLowerCase().trim();

  bool _tabMatchesByStatus(Map<String, dynamic> task) {
    final status = _norm(task['status']);
    switch (_norm(_selectedTabLabel)) {
      case 'all':
        return true;
      case 'scheduled':
        return status == 'scheduled';
      case 'in progress':
        return status == 'in_progress' || status == 'in progress';
      case 'completed':
        return status == 'completed' || status == 'done';
      case 'overdue':
        if (status == 'completed' || status == 'done') return false;
        try {
          final scheduledDate = DateTime.tryParse(task['scheduled_date'] ?? '');
          if (scheduledDate == null) return false;
          return scheduledDate.isBefore(DateTime.now());
        } catch (e) {
          return false;
        }
      default:
        return true;
    }
  }

  bool _statusMatches(Map<String, dynamic> task) {
    if (_selectedStatus == 'All') return true;
    return _norm(task['status']) == _norm(_selectedStatus);
  }

  bool _categoryMatches(Map<String, dynamic> task) {
    if (_selectedCategory == 'All') return true;
    return _norm(task['category']) == _norm(_selectedCategory);
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
        .where(_tabMatchesByStatus)
        .where(_statusMatches)
        .where(_categoryMatches)
        .where(_searchMatches)
        .toList();
    
    print('DEBUG: Filtering results:');
    print('  Total tasks: ${_allMaintenanceTasks.length}');
    print('  After tab filter: ${_allMaintenanceTasks.where(_tabMatchesByStatus).length}');
    print('  After status filter: ${_allMaintenanceTasks.where(_tabMatchesByStatus).where(_statusMatches).length}');
    print('  After category filter: ${_allMaintenanceTasks.where(_tabMatchesByStatus).where(_statusMatches).where(_categoryMatches).length}');
    print('  After search filter: ${filtered.length}');
    print('  Current filters: tab="$_selectedTabLabel", status="$_selectedStatus", category="$_selectedCategory", search="${_searchController.text}"');
    
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
    final base = _allMaintenanceTasks
        .where(_tabMatchesByStatus)
        .where(_categoryMatches)
        .where(_searchMatches);
    final set = <String>{};
    for (final task in base) {
      final s = (task['status'] ?? '').toString().trim();
      if (s.isNotEmpty) set.add(s);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  List<String> get _categoryOptions {
    // Predefined maintenance categories
    final predefined = {
      'preventive',
      'corrective',
      'emergency',
      'predictive',
      'routine',
    };

    final base = _allMaintenanceTasks
        .where(_tabMatchesByStatus)
        .where(_statusMatches)
        .where(_searchMatches);

    final set = <String>{};
    for (final task in base) {
      final c = (task['category'] ?? '').toString().trim();
      if (c.isNotEmpty) set.add(c);
    }

    // Merge both sets
    final list = {...predefined, ...set}.toList()..sort();
    return ['All', ...list];
  }

  List<TabItem> get _tabs {
    final visible = _allMaintenanceTasks
        .where(_statusMatches)
        .where(_categoryMatches)
        .where(_searchMatches)
        .toList();

    int countFor(String type) {
      switch (type.toLowerCase()) {
        case 'scheduled':
          return visible.where((t) => _norm(t['status']) == 'scheduled').length;
        case 'in progress':
          return visible.where((t) => _norm(t['status']) == 'in_progress' || _norm(t['status']) == 'in progress').length;
        case 'completed':
          return visible.where((t) => _norm(t['status']) == 'completed' || _norm(t['status']) == 'done').length;
        case 'overdue':
          return visible.where((t) {
            if (_norm(t['status']) == 'completed' || _norm(t['status']) == 'done') return false;
            try {
              final scheduledDate = DateTime.tryParse(t['scheduled_date'] ?? '');
              if (scheduledDate == null) return false;
              return scheduledDate.isBefore(DateTime.now());
            } catch (e) {
              return false;
            }
          }).length;
        default:
          return visible.length;
      }
    }

    return [
      TabItem(label: 'All', count: visible.length),
      TabItem(label: 'Scheduled', count: countFor('scheduled')),
      TabItem(label: 'In Progress', count: countFor('in progress')),
      TabItem(label: 'Completed', count: countFor('completed')),
      TabItem(label: 'Overdue', count: countFor('overdue')),
    ];
  }

  // ===== Chat Navigation =====================================================
  Future<void> _handleMaintenanceChatNavigation(Map<String, dynamic> task) async {
    try {
      final taskId = task['id'] ?? '';
      
      if (taskId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Unable to start chat - Invalid task ID'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Navigate to maintenance chat - filtered by maintenance ID
      await ChatHelper.navigateToMaintenanceChat(
        context: context,
        maintenanceId: taskId,
        isStaff: true,
      );
    } catch (e) {
      print('Error navigating to maintenance chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      assignedStaff: task['assigned_staff'],
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
              maintenanceTaskId: maintenanceTaskId,
            ),
          ),
        ).then((_) {
          // Refresh data when returning
          _loadAllMaintenanceTasks();
        });
      },
      onChatTap: () {
        _handleMaintenanceChatNavigation(task);
      },
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
                      selectedClassification: _selectedCategory,
                      classifications: _categoryOptions,
                      onStatusChanged: (status) {
                        setState(() {
                          _selectedStatus = status.trim().isEmpty ? 'All' : status;
                        });
                      },
                      onClassificationChanged: (category) {
                        setState(() {
                          _selectedCategory = category.trim().isEmpty ? 'All' : category;
                        });
                      },
                      onSearchChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),

                    // Mobile-friendly tab selector
                    MobileTabSelector(
                      tabs: _tabs,
                      selectedLabel: _selectedTabLabel,
                      onTabSelected: (label) => setState(() => _selectedTabLabel = label),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Text(
                          'Maintenance $_selectedTabLabel',
                          style: const TextStyle(
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