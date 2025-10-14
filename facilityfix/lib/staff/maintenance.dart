import 'dart:async';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/config/env.dart';
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
import 'package:facilityfix/widgets/view_details.dart';
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
            builder: (_) => _MaintenanceDetailScreen(task: task),
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

// Maintenance Detail Screen using MaintenanceDetails widget
class _MaintenanceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const _MaintenanceDetailScreen({required this.task});

  @override
  State<_MaintenanceDetailScreen> createState() => _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<_MaintenanceDetailScreen> {
  late List<Map<String, dynamic>> _checklistItems;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    print('DEBUG: MaintenanceDetailScreen initState called');
    print('DEBUG: Task data keys: ${widget.task.keys.toList()}');
    print('DEBUG: Raw checklist_completed value: ${widget.task['checklist_completed']}');
    print('DEBUG: Raw checklist_completed type: ${widget.task['checklist_completed'].runtimeType}');
    _checklistItems = _convertChecklistToMap(widget.task['checklist_completed']);
    print('DEBUG: Converted checklist items: $_checklistItems');
    print('DEBUG: Checklist items count: ${_checklistItems.length}');
  }
  
  // Computed properties for checklist progress
  int get completedCount => _checklistItems.where((item) => item['completed'] == true).length;
  int get totalCount => _checklistItems.length;

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime? date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp);
    } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
      // Handle Firestore Timestamp
      try {
        date = (timestamp as dynamic).toDate();
      } catch (e) {
        print('Error converting Timestamp: $e');
      }
    }
    
    return date?.toIso8601String() ?? '';
  }

  List<Map<String, dynamic>> _convertChecklistToMap(dynamic checklist) {
    print('DEBUG _convertChecklistToMap: Input checklist: $checklist');
    print('DEBUG _convertChecklistToMap: Input type: ${checklist.runtimeType}');
    
    if (checklist == null) {
      print('DEBUG _convertChecklistToMap: checklist is null, returning empty list');
      return [];
    }
    
    if (checklist is! List) {
      print('DEBUG _convertChecklistToMap: checklist is not a List (is ${checklist.runtimeType}), returning empty list');
      return [];
    }
    
    print('DEBUG _convertChecklistToMap: checklist is a List with ${checklist.length} items');
    
    final result = checklist
        .where((item) {
          final isMap = item is Map;
          print('DEBUG _convertChecklistToMap: Item is Map? $isMap, item: $item');
          return isMap;
        })
        .map<Map<String, dynamic>>((item) {
          final converted = {
            'id': item['id']?.toString() ?? '',
            'task': item['task']?.toString() ?? '',
            'completed': item['completed'] == true,
          };
          print('DEBUG _convertChecklistToMap: Converted item: $converted');
          return converted;
        })
        .where((item) {
          final hasId = item['id'].toString().isNotEmpty;
          print('DEBUG _convertChecklistToMap: Item has ID? $hasId');
          return hasId;
        })
        .toList();
    
    print('DEBUG _convertChecklistToMap: Final result count: ${result.length}');
    return result;
  }

  Future<void> _toggleChecklistItem(int index) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      final item = _checklistItems[index];
      final newCompletedStatus = !item['completed'];

      // Optimistically update UI
      setState(() {
        _checklistItems[index]['completed'] = newCompletedStatus;
      });

      // Update via API
      final apiService = APIService(roleOverride: AppRole.staff);
      await apiService.updateChecklistItem(
        taskId: widget.task['id'],
        itemId: item['id'],
        completed: newCompletedStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newCompletedStatus 
                ? 'Task marked as completed' 
                : 'Task marked as incomplete'
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error updating checklist item: $e');
      
      // Revert optimistic update on error
      setState(() {
        _checklistItems[index]['completed'] = !_checklistItems[index]['completed'];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating checklist: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Maintenance Details',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checklist Progress Banner
              if (_checklistItems.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: completedCount == totalCount 
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: completedCount == totalCount
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        completedCount == totalCount
                            ? Icons.check_circle
                            : Icons.pending_actions,
                        size: 20,
                        color: completedCount == totalCount
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        completedCount == totalCount
                            ? 'All tasks completed! 🎉'
                            : 'Checklist Progress: $completedCount of $totalCount completed',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: completedCount == totalCount
                              ? const Color(0xFF047857)
                              : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Basic task information (non-checklist fields)
              MaintenanceDetails(
                // Basic Information
                id: widget.task['id'] ?? '',
                createdAt: _parseDate(widget.task['created_at']) ?? DateTime.now(),
                updatedAt: _parseDate(widget.task['updated_at']),
                departmentTag: widget.task['category'] ?? widget.task['department'],
                requestTypeTag: widget.task['maintenance_type'] ?? widget.task['maintenanceType'] ?? 'internal',
                priority: widget.task['priority'],
                statusTag: widget.task['status'] ?? 'scheduled',
                resolutionType: null,
                
                // Tenant / Requester
                requestedBy: widget.task['created_by'] ?? widget.task['assigned_to'] ?? '',
                scheduleDate: _formatTimestamp(widget.task['scheduled_date']),
                
                // Request Details
                title: widget.task['task_title'] ?? widget.task['title'] ?? 'Maintenance Task',
                startedAt: _parseDate(widget.task['started_at']),
                completedAt: _parseDate(widget.task['completed_at']),
                location: widget.task['location'],
                description: widget.task['task_description'] ?? widget.task['description'],
                checklist_complete: null, // We'll render checklist separately
                attachments: widget.task['photos'] is List 
                    ? (widget.task['photos'] as List).map((e) => e.toString()).toList()
                    : null,
                adminNote: widget.task['completion_notes'],
                
                // Staff
                assignedStaff: widget.task['assigned_staff_name'] ?? widget.task['assigned_to'],
                staffDepartment: widget.task['department'],
                staffPhotoUrl: null,
                assessedAt: _parseDate(widget.task['updated_at']),
                assessment: widget.task['completion_notes'],
                staffAttachments: widget.task['photos'] is List 
                    ? (widget.task['photos'] as List).map((e) => e.toString()).toList()
                    : null,
                
                // Tracking
                materialsUsed: widget.task['parts_used'] is List 
                    ? (widget.task['parts_used'] as List).map((e) => e.toString()).toList()
                    : null,
              ),
              
              // Interactive Checklist Section
              if (_checklistItems.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.checklist,
                              size: 20,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Task Checklist',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$completedCount of $totalCount completed',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Checklist Items
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _checklistItems.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE5E7EB),
                        ),
                        itemBuilder: (context, index) {
                          final item = _checklistItems[index];
                          final isCompleted = item['completed'] == true;
                          
                          return InkWell(
                            onTap: _isUpdating ? null : () => _toggleChecklistItem(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isCompleted
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    size: 24,
                                    color: isCompleted
                                        ? Colors.green
                                        : const Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item['task'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isCompleted
                                            ? const Color(0xFF6B7280)
                                            : const Color(0xFF1F2937),
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        fontWeight: isCompleted
                                            ? FontWeight.w400
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (_isUpdating)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}