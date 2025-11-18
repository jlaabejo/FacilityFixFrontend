import 'package:facilityfix/adminweb/widgets/logout_popup.dart';
import 'package:facilityfix/adminweb/widgets/tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import 'pop_up/createmaintenancedialogue_popup.dart';
import 'pop_up/maintenance_firesafety_popup.dart';
import 'pop_up/maintenance_earthquake_popup.dart';
import 'pop_up/maintenance_typhoonflood_popup.dart';
import '../services/api_service.dart';
import 'package:facilityfix/adminweb/widgets/pop_up_dialog.dart';
import 'internalmaintenance_form.dart';
import 'externalmaintenance_form.dart';

class AdminMaintenancePage extends StatefulWidget {
  const AdminMaintenancePage({super.key});

  @override
  State<AdminMaintenancePage> createState() => _AdminMaintenancePageState();
}

class _AdminMaintenancePageState extends State<AdminMaintenancePage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _filteredTasks = [];
  bool _isLoading = true;
  String? _error;
  
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatusFilter;
  
  // Pagination state
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  
  // Sorting state
  bool _sortAscending = false;

  // Special maintenance tasks summary data
  Map<String, dynamic> _specialTasksSummary = {
    'fire_safety': {'exists': false},
    'earthquake': {'exists': false},
    'typhoon_flood': {'exists': false},
  };

  @override
  void initState() {
    super.initState();
    _initializeAndFetchData();
    _searchController.addListener(_applyFilters);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndFetchData() async {
    try {
      await Future.wait([
        _fetchMaintenanceTasks(),
        _fetchSpecialTasksSummary(),
      ]);
    } catch (e) {
      print('[v0] Error initializing: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchSpecialTasksSummary() async {
    try {
      final response = await _apiService.getSpecialMaintenanceTasksSummary();

      if (response['success'] == true) {
        final summaries = response['summaries'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _specialTasksSummary = summaries;
          });
        }
      }
    } catch (e) {
      print('[v0] Error fetching special tasks summary: $e');
      // Non-critical error, tasks may not be initialized yet
      // Try to initialize them
      try {
        await _apiService.initializeSpecialMaintenanceTasks();
        // Retry fetching after initialization
        final response = await _apiService.getSpecialMaintenanceTasksSummary();
        if (response['success'] == true && mounted) {
          setState(() {
            _specialTasksSummary = response['summaries'] as Map<String, dynamic>;
          });
        }
      } catch (initError) {
        print('[v0] Error initializing special tasks: $initError');
      }
    }
  }

  Future<void> _fetchMaintenanceTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _apiService.getMaintenanceTasks();

      if (response['success'] == true) {
        final tasks = response['tasks'] as List<dynamic>;
        setState(() {
          _tasks = tasks.map((task) => task as Map<String, dynamic>).toList();
          _applyFilters();
          _isLoading = false;
        });
      } else {
        throw Exception(response['error'] ?? 'Failed to load tasks');
      }
    } catch (e) {
      print('[v0] Error fetching maintenance tasks: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load maintenance tasks: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Apply search and filter
  void _applyFilters() {
    setState(() {
      _filteredTasks = _tasks.where((task) {
        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          final id = (task['id'] ?? '').toString().toLowerCase();
          final location = _getTaskField(task, ['location', 'area'], '').toLowerCase();
          final title = _getTaskField(task, ['task_title', 'taskTitle', 'title'], '').toLowerCase();
          
          if (!id.contains(searchQuery) && 
              !location.contains(searchQuery) && 
              !title.contains(searchQuery)) {
            return false;
          }
        }
        
        // Status filter
        if (_selectedStatusFilter != null && _selectedStatusFilter != 'All') {
          final status = _getTaskField(task, ['status', 'statusTag'], '').toLowerCase();
          if (!status.contains(_selectedStatusFilter!.toLowerCase())) {
            return false;
          }
        }
        
        return true;
      }).toList();
      
      // Sort by status first (scheduled first), then by date
      _sortTasks();
      
      // Reset to first page when filters change
      _currentPage = 0;
    });
  }
  
  // Sort tasks by status (scheduled first) and then by date
  void _sortTasks() {
    _filteredTasks.sort((a, b) {
      // Get status for both tasks
      final statusA = _getTaskField(a, ['status', 'statusTag'], '').toLowerCase();
      final statusB = _getTaskField(b, ['status', 'statusTag'], '').toLowerCase();
      
      // Priority: scheduled first, then others
      final isScheduledA = statusA.contains('scheduled');
      final isScheduledB = statusB.contains('scheduled');
      
      if (isScheduledA && !isScheduledB) return -1;
      if (!isScheduledA && isScheduledB) return 1;
      
      // Within same status priority, sort by date
      final dateA = _parseDate(a['scheduled_date'] ?? a['created_at'] ?? a['dateCreated']);
      final dateB = _parseDate(b['scheduled_date'] ?? b['created_at'] ?? b['dateCreated']);
      
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      
      return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });
  }
  
  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    try {
      if (date is String) {
        return DateTime.parse(date);
      }
      if (date is DateTime) {
        return date;
      }
    } catch (e) {
      // Invalid date format
    }
    return null;
  }
  
  // Toggle sort order
  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;
      _sortTasks();
    });
  }
  
  // Get paginated tasks
  List<Map<String, dynamic>> get _paginatedTasks {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredTasks.length);
    
    if (startIndex >= _filteredTasks.length) {
      return [];
    }
    
    return _filteredTasks.sublist(startIndex, endIndex);
  }
  
  // Get total pages
  int get _totalPages {
    return (_filteredTasks.length / _itemsPerPage).ceil();
  }
  
  // Convert status to title case
  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Format maintenance ID with MT-2025-XXXXX pattern
  String _formatMaintenanceId(dynamic id) {
    if (id == null) return 'N/A';
    
    final idStr = id.toString();
    
    // If already formatted with MT-2025 prefix, return as is
    if (idStr.startsWith('MT-2025-') || idStr.startsWith('SPECIAL-')) {
      return idStr;
    }
    
    // Extract numeric ID and pad to 5 digits
    final numericId = int.tryParse(idStr);
    if (numericId != null) {
      final paddedId = numericId.toString().padLeft(5, '0');
      return 'MT-2025-$paddedId';
    }
    
    // If can't parse, return original
    return idStr;
  }

  // Helper function to convert routeKey to actual route path
  String? _getRoutePath(String routeKey) {
    final Map<String, String> pathMap = {
      'dashboard': '/dashboard',
      'user_users': '/user/users',
      'user_roles': '/user/roles',
      'work_maintenance': '/work/maintenance',
      'work_repair': '/work/repair',
      'calendar': '/calendar',
      'inventory_items': '/inventory/items',
      'inventory_request': '/inventory/request',
      'analytics': '/analytics',
      'announcement': '/announcement',
      'settings': '/settings',
    };
    return pathMap[routeKey];
  }

// Logout functionality
void _handleLogout(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return const LogoutPopup();
    },
  );

  if (result == true) {
    context.go('/');
  }
}


  final List<double> _colW = <double>[
    160, // MAINTENANCE ID
    200, // TASK TITLE
    170, // LOCATION
    100, // TYPE
    120, // STATUS
    130, // SCHEDULE DATE
    80, // RECURRENCE
    48, // ACTION
  ];

  Widget _fixedCell(
    int i,
    Widget child, {
    Alignment align = Alignment.centerLeft,
  }) {
    return SizedBox(
      width: _colW[i],
      child: Align(alignment: align, child: child),
    );
  }

  Text _ellipsis(String s, {TextStyle? style}) => Text(
    s,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    softWrap: false,
    style: style,
  );

  // Helper to safely extract field values with multiple possible keys
  String _getTaskField(Map<String, dynamic> task, List<String> keys, String defaultValue) {
    for (final key in keys) {
      final value = task[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return defaultValue;
  }

  // Action dropdown menu methods
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> maintenance,
    Offset position,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                color: Colors.green[600],
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'View',
                style: TextStyle(color: Colors.green[600], fontSize: 14),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: Colors.blue[600], size: 18),
              const SizedBox(width: 12),
              Text(
                'Edit',
                style: TextStyle(color: Colors.blue[600], fontSize: 14),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red[600], size: 18),
              const SizedBox(width: 12),
              Text(
                'Delete',
                style: TextStyle(color: Colors.red[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
    ).then((value) {
      if (value != null) {
        _handleActionSelection(value, maintenance);
      }
    });
  }

  // Handle action selection
  void _handleActionSelection(String action, Map<String, dynamic> maintenance) {
    switch (action) {
      case 'view':
        _viewMaintenance(maintenance);
        break;
      case 'edit':
        _editMaintenance(maintenance);
        break;
      case 'delete':
        _deleteMaintenance(maintenance);
        break;
    }
  }

  String _resolveMaintenanceType(Map<String, dynamic> maintenance) {
    final candidates = [
      maintenance['maintenanceType'],
      maintenance['maintenance_type'],
      maintenance['task_type'],
      maintenance['taskType'],
      maintenance['type'],
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      final raw = candidate.toString().toLowerCase().trim();
      if (raw.isEmpty) continue;
      if (raw.contains('external') || raw == 'epm') {
        return 'external';
      }
      if (raw.contains('internal') || raw == 'ipm') {
        return 'internal';
      }
    }

    return '';
  }

  // Helper methods for special tasks
  String _getSpecialTaskValue(String taskKey) {
    final taskData = _specialTasksSummary[taskKey] as Map<String, dynamic>?;
    if (taskData == null || taskData['exists'] != true) {
      return 'N/A';
    }
    final completionPercentage = taskData['completion_percentage'] ?? 0;
    return '${completionPercentage.toStringAsFixed(0)}%';
  }

  String _getSpecialTaskSubtitle(String taskKey) {
    final taskData = _specialTasksSummary[taskKey] as Map<String, dynamic>?;
    if (taskData == null || taskData['exists'] != true) {
      return 'Not initialized';
    }
    final nextDate = taskData['next_scheduled_date'] ?? 'Not scheduled';
    return 'Next: $nextDate';
  }

  Future<void> _viewSpecialTask(String taskKey) async {
    try {
      final response = await _apiService.getSpecialMaintenanceTask(taskKey);
      if (response['success'] == true && mounted) {
        final task = response['task'] as Map<String, dynamic>;

        // Map task_key to dialog
        switch (taskKey) {
          case 'fire_safety':
            FireSafetyDialog.show(
              context,
              task,
              onSaved: () {
                _fetchSpecialTasksSummary();
              },
            );
            break;
          case 'earthquake':
            EarthquakeDialog.show(
              context,
              task,
              onSaved: () {
                _fetchSpecialTasksSummary();
              },
            );
            break;
          case 'typhoon_flood':
            TyphoonFloodDialog.show(
              context,
              task,
              onSaved: () {
                _fetchSpecialTasksSummary();
              },
            );
            break;
        }
      }
    } catch (e) {
      print('[v0] Error viewing special task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load task details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // View method
  void _viewMaintenance(Map<String, dynamic> maintenance) {
    final id = (maintenance['id'] ?? '').toString();
    final typeSlug = _resolveMaintenanceType(maintenance);

    if (typeSlug.contains('internal')) {
      context.push('/work/maintenance/$id/internal', extra: maintenance);
    } else if (typeSlug.contains('external')) {
      context.push('/work/maintenance/$id/external', extra: maintenance);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unknown maintenance type.')),
      );
    }
  }

  // Edit method
  void _editMaintenance(Map<String, dynamic> maintenance) {
    final typeSlug = _resolveMaintenanceType(maintenance);

    if (typeSlug.contains('internal')) {
      // Navigate to internal form with edit mode
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InternalMaintenanceFormPage(
            maintenanceData: maintenance,
            isEditMode: true,
          ),
        ),
      );
    } else if (typeSlug.contains('external')) {
      // Navigate to external form with edit mode
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ExternalMaintenanceFormPage(
            maintenanceData: maintenance,
            isEditMode: true,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unknown maintenance type.')),
      );
    }
  }

  void _deleteMaintenance(Map<String, dynamic> maintenance) async {
    // Extract the actual ID from the maintenance object
    final maintenanceId = maintenance['id'] ?? 
                         maintenance['_doc_id'] ?? 
                         maintenance['task_id'];
    
    if (maintenanceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: Invalid maintenance ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Use the reusable app dialog to confirm destructive action
    final confirmed = await showAppDialog<bool>(
      context,
      config: DialogConfig.destructive(
        title: 'Delete Maintenance',
        description: 'Are you sure you want to delete maintenance task ${_formatMaintenanceId(maintenanceId)}? This action cannot be undone.',
        primaryButtonLabel: 'Delete',
        primaryAction: () {}, // actual deletion happens after confirmation
        secondaryButtonLabel: 'Cancel',
        secondaryAction: () {},
      ),
      barrierDismissible: false,
    );

    if (confirmed == true) {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Deleting maintenance task...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      try {
        final response = await _apiService.deleteMaintenanceTask(maintenanceId.toString());

        if (response['success'] == true || response['message']?.toString().toLowerCase().contains('deleted') == true) {
          await _fetchMaintenanceTasks(); // Refresh the list

          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Maintenance task ${_formatMaintenanceId(maintenanceId)} deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception(response['error'] ?? response['message'] ?? 'Failed to delete maintenance task');
        }
      } catch (e) {
        print('[v0] Error deleting maintenance: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'work_maintenance',
      onNavigate: (routeKey) {
        final routePath = _getRoutePath(routeKey);
        if (routePath != null) {
          context.go(routePath);
        } else if (routeKey == 'logout') {
          _handleLogout(context);
        }
      },
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with title and Create New button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Task Management",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    //breadcrumbs
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => context.go('/dashboard'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Dashboard'),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 16,
                        ),
                        TextButton(
                          onPressed: () => context.go('/work/maintenance'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Task Management'),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 16,
                        ),
                        TextButton(
                          onPressed: null,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Maintenance Tasks'),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed:
                      () => showCreateMaintenanceTaskDialog(
                        context,
                        onInternal:
                            () =>
                                context.go('/work/maintenance/create/internal'),
                        onExternal:
                            () =>
                                context.go('/work/maintenance/create/external'),
                      ),
                  icon: const Icon(Icons.add, size: 22),
                  label: const Text(
                    "Create New",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2, // slight shadow for emphasis
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Summary cards - using dynamic data from special tasks
            Row(
              children: [
                _buildSummaryCard(
                  "FIRE SAFETY",
                  _getSpecialTaskValue('fire_safety'),
                  _getSpecialTaskSubtitle('fire_safety'),
                  Colors.white,
                  onTap: () => _viewSpecialTask('fire_safety'),
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  "EARTHQUAKE",
                  _getSpecialTaskValue('earthquake'),
                  _getSpecialTaskSubtitle('earthquake'),
                  Colors.white,
                  onTap: () => _viewSpecialTask('earthquake'),
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  "TYPHOON/FLOOD",
                  _getSpecialTaskValue('typhoon_flood'),
                  _getSpecialTaskSubtitle('typhoon_flood'),
                  Colors.white,
                  onTap: () => _viewSpecialTask('typhoon_flood'),
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  "PENDING ITEMS",
                  "${_tasks.where((t) => t['status'] == 'pending' || t['status'] == 'scheduled').length}",
                  "Total Pending",
                  Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 32),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table header with search and filter
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Maintenance Tasks",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            // Search field
                            Container(
                              width: 240,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  suffixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey[500],
                                    size: 20,
                                  ),
                                  hintText: "Search",
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Refresh Button (copied from announcements page style)
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: InkWell(
                                onTap: _fetchMaintenanceTasks,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh_rounded, size: 20, color: Colors.blue[600]),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Filter button with dropdown
                            PopupMenuButton<String>(
                              initialValue: _selectedStatusFilter,
                              onSelected: (value) {
                                setState(() {
                                  _selectedStatusFilter = value == 'All' ? null : value;
                                  _applyFilters();
                                });
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'All',
                                  child: Text('All Status'),
                                ),
                                const PopupMenuItem(
                                  value: 'New',
                                  child: Text('New'),
                                ),
                                const PopupMenuItem(
                                  value: 'Scheduled',
                                  child: Text('Scheduled'),
                                ),
                                const PopupMenuItem(
                                  value: 'In Progress',
                                  child: Text('In Progress'),
                                ),
                                const PopupMenuItem(
                                  value: 'Completed',
                                  child: Text('Completed'),
                                ),
                                const PopupMenuItem(
                                  value: 'Assigned',
                                  child: Text('Assigned'),
                                ),
                              ],
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.filter_list,
                                      size: 20,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedStatusFilter ?? 'Filter',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[400]),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'Error: $_error',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchMaintenanceTasks,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_filteredTasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: Text(
                          'No maintenance tasks found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    // Table content
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 13,
                        headingRowHeight: 56,
                        dataRowHeight: 64,
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey[50],
                        ),
                        headingTextStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                        dataTextStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        columns: [
                          DataColumn(label: _fixedCell(0, const Text("MAINTENANCE ID"))),
                          DataColumn(
                            label: _fixedCell(1, const Text("TASK TITLE")),
                          ),
                          DataColumn(
                            label: _fixedCell(2, const Text("LOCATION")),
                          ),
                          DataColumn(
                            label: _fixedCell(3, const Text("TYPE")),
                          ),
                          DataColumn(
                            label: _fixedCell(4, const Text("STATUS")),
                          ),
                          DataColumn(
                            label: _fixedCell(5, InkWell(
                              onTap: _toggleSortOrder,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("SCHEDULE DATE"),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _sortAscending 
                                      ? Icons.arrow_upward 
                                      : Icons.arrow_downward,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            )),
                          ),
                          DataColumn(
                            label: _fixedCell(6, const Text("RECURRENCE")),
                          ),
                          DataColumn(label: _fixedCell(7, const Text(""))),
                        ],
                        rows: _paginatedTasks.map((maintenance) {
                          final rawId = _getTaskField(maintenance, ['id', 'formatted_id'], 'N/A');
                          final id = _formatMaintenanceId(rawId);
                          final title = _getTaskField(maintenance, ['task_title', 'taskTitle', 'title'], 'N/A');
                          final location = _getTaskField(maintenance, ['location', 'area'], 'N/A');
                          final typeSlug = _resolveMaintenanceType(maintenance);
                          final type = typeSlug.contains('internal') ? 'Internal' :
                                typeSlug.contains('external') ? 'External' : 'N/A';
                          final rawStatus = _getTaskField(maintenance, ['status', 'statusTag'], 'N/A');

                          // Simple inline tag widget for the TYPE column (replaces MaintenanceTypeTag usage)
                          final Widget typeTag = Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          );

                          final status = _toTitleCase(rawStatus);
                          final scheduledDate = maintenance['scheduled_date'] ?? 
                                               maintenance['dateCreated'] ?? 
                                               maintenance['created_at'];
                          final date = _formatDate(scheduledDate);
                          final recurrence = _getTaskField(
                            maintenance,
                            ['recurrence', 'recurrence_type', 'recurrenceType'], 
                            'None'
                          );

                          return DataRow(
                            cells: [
                              DataCell(_fixedCell(0, _ellipsis(id))),
                              DataCell(_fixedCell(1, _ellipsis(title))),
                              DataCell(_fixedCell(2, _ellipsis(location))),
                              DataCell(_fixedCell(3, typeTag)),
                              DataCell(
                                _fixedCell(4, _buildStatusChip(status)),
                              ),
                              DataCell(_fixedCell(5, _ellipsis(date))),
                              DataCell(_fixedCell(6, _ellipsis(recurrence))),
                              DataCell(
                                _fixedCell(
                                  7,
                                  Builder(
                                    builder: (context) {
                                      return IconButton(
                                        icon: const Icon(
                                          Icons.more_vert,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          final RenderBox button = context
                                              .findRenderObject() as RenderBox;
                                          final RenderBox overlay = Navigator.of(
                                            context,
                                          ).overlay!.context.findRenderObject()
                                              as RenderBox;
                                          final position = button.localToGlobal(
                                            Offset.zero,
                                            ancestor: overlay,
                                          );

                                          _showActionMenu(
                                            context,
                                            maintenance,
                                            position,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  align: Alignment.center,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[400]),

                  // Pagination
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${_paginatedTasks.isEmpty ? 0 : _currentPage * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage + _paginatedTasks.length)} of ${_filteredTasks.length} entries',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _currentPage > 0
                                  ? () {
                                      setState(() {
                                        _currentPage--;
                                      });
                                    }
                                  : null,
                              color: Colors.grey[700],
                            ),
                            ...List.generate(
                              _totalPages.clamp(0, 5),
                              (index) {
                                // Show first 2, current page ± 1, and last 2
                                int pageNumber;
                                if (_totalPages <= 5) {
                                  pageNumber = index;
                                } else if (_currentPage < 2) {
                                  pageNumber = index;
                                } else if (_currentPage > _totalPages - 3) {
                                  pageNumber = _totalPages - 5 + index;
                                } else {
                                  pageNumber = _currentPage - 2 + index;
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _currentPage = pageNumber;
                                      });
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _currentPage == pageNumber
                                            ? const Color(0xFF1976D2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: _currentPage == pageNumber
                                              ? const Color(0xFF1976D2)
                                              : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${pageNumber + 1}',
                                          style: TextStyle(
                                            color: _currentPage == pageNumber
                                                ? Colors.white
                                                : Colors.grey[700],
                                            fontWeight:
                                                _currentPage == pageNumber
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _currentPage < _totalPages - 1
                                  ? () {
                                      setState(() {
                                        _currentPage++;
                                      });
                                    }
                                  : null,
                              color: Colors.grey[700],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        final dt = DateTime.parse(date);
        return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}-${dt.year}';
      }
      return date.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  // Widget for summary cards
  Widget _buildSummaryCard(
    String title,
    String value,
    String subtitle,
    Color backgroundColor, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for status chips
  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    final statusLower = status.toLowerCase();

    if (statusLower.contains('progress')) {
      bgColor = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFD32F2F);
    } else if (statusLower.contains('new') ||
        statusLower.contains('scheduled')) {
      bgColor = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF1976D2);
    } else if (statusLower.contains('completed')) {
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF388E3C);
    } else {
      bgColor = Colors.grey[100]!;
      textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
