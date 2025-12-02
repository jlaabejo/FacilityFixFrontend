import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../services/api_service_web.dart';
import 'pop_up/tasktype_popup.dart';
import '../widgets/logout_popup.dart';

Offset getSafeOffsetForContext(BuildContext ctx) {
  try {
    final renderObj = ctx.findRenderObject();
    if (renderObj is RenderBox && renderObj.hasSize) {
      return renderObj.localToGlobal(Offset.zero);
    }
  } catch (_) {}

  final overlayState = Overlay.of(ctx);
  final overlayObj = overlayState.context.findRenderObject();
  if (overlayObj is RenderBox && overlayObj.hasSize) {
    return overlayObj.size.center(Offset.zero);
  }

  try {
    final size = MediaQuery.of(ctx).size;
    return size.center(Offset.zero);
  } catch (_) {}

  return Offset.zero;
}

RelativeRect getRelativeRectFromOffset(BuildContext ctx, Offset offset) {
  final overlayState = Overlay.of(ctx);
  final overlayObj = overlayState.context.findRenderObject();
  if (overlayObj is RenderBox && overlayObj.hasSize) {
    return RelativeRect.fromRect(
      Rect.fromLTWH(offset.dx, offset.dy, 0, 0),
      Offset.zero & overlayObj.size,
    );
  }
  try {
    final size = MediaQuery.of(ctx).size;
    return RelativeRect.fromRect(
      Rect.fromLTWH(offset.dx, offset.dy, 0, 0),
      Offset.zero & size,
    );
  } catch (_) {}
  return const RelativeRect.fromLTRB(0, 0, 0, 0);
}

class AdminTaskTypePage extends StatefulWidget {
  const AdminTaskTypePage({super.key});

  @override
  State<AdminTaskTypePage> createState() => _AdminTaskTypePageState();
}

class _AdminTaskTypePageState extends State<AdminTaskTypePage> {
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _selectedMaintenanceTypes = 'All Maintenance Types';

  // Sorting state
  int? _sortColumnIndex;
  bool _sortAscending = true;

  final ApiService _apiService = ApiService();
  final List<Map<String, dynamic>> _taskTypes = [];
  bool _isLoading = true;

  late TaskTypeDataSource _dataSource;
  // Pagination state
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  // Computed getters for filtering and pagination
  List<Map<String, dynamic>> get _filteredTaskTypes {
    final query = _searchController.text.toLowerCase();
    final selectedCategoryLower = _selectedMaintenanceTypes.toLowerCase();
    final showAllCategories = selectedCategoryLower == 'all maintenance types';

    final filtered = _taskTypes.where((task) {
      final name = _getFieldValue(task, ['name', 'task_title', 'taskTypeName']);
      final id = _getFieldValue(task, ['id', 'formatted_id', 'task_type_id']);
      final matchesSearch = query.isEmpty ||
          name.toLowerCase().contains(query) ||
          id.toLowerCase().contains(query);
      final category = _getFieldValue(task, ['category', 'maintenance_type']);
      final matchesCategory = showAllCategories ||
          category.toLowerCase() == selectedCategoryLower;
      return matchesSearch && matchesCategory;
    }).toList();

    if (_sortColumnIndex != null) {
      filtered.sort((a, b) {
        int result;
        switch (_sortColumnIndex) {
          case 0:
            result = _getFieldValue(a, ['id', 'formatted_id', 'task_type_id'])
                .compareTo(_getFieldValue(b, ['id', 'formatted_id', 'task_type_id']));
            break;
          case 1:
            result = _getFieldValue(a, ['name', 'task_title', 'taskTypeName'])
                .compareTo(_getFieldValue(b, ['name', 'task_title', 'taskTypeName']));
            break;
          case 2:
            result = _getFieldValue(a, ['category', 'maintenance_type'])
                .compareTo(_getFieldValue(b, ['category', 'maintenance_type']));
            break;
          case 3:
            final dateA = _parseCreatedAt(a) ?? DateTime(1970);
            final dateB = _parseCreatedAt(b) ?? DateTime(1970);
            result = dateA.compareTo(dateB);
            break;
          default:
            result = 0;
        }
        return _sortAscending ? result : -result;
      });
    }

    return filtered;
  }

  String _getFieldValue(Map<String, dynamic> task, List<String> keys) {
    for (final key in keys) {
      final value = task[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  DateTime? _parseCreatedAt(Map<String, dynamic> task) {
    final raw = task['created_at'] ?? task['date_created'] ?? task['createdAt'] ?? task['formatted_created_at'];
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is double) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    return null;
  }

  String _formatDateLabel(Map<String, dynamic> task) {
    final parsed = _parseCreatedAt(task);
    if (parsed == null) return '-';
    return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> get _paginatedTaskTypes {
    final start = _currentPage * _itemsPerPage;
    if (start >= _filteredTaskTypes.length) return [];
    return _filteredTaskTypes.skip(start).take(_itemsPerPage).toList();
  }

  int get _totalPages {
    if (_filteredTaskTypes.isEmpty) return 0;
    return (_filteredTaskTypes.length / _itemsPerPage).ceil();
  }

  @override
  void initState() {
    super.initState();
    _dataSource = TaskTypeDataSource(
      taskTypes: _taskTypes,
      searchQuery: _searchController.text,
      selectedMaintenanceTypes: _selectedMaintenanceTypes,
      colW: _colW,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      onActionSelected: _handleActionSelection,
    );
    _searchController.addListener(_updateDataSource);
    _loadTaskTypes();
  }

  void _updateDataSource() {
    _dataSource.update(
      searchQuery: _searchController.text,
      selectedMaintenanceTypes: _selectedMaintenanceTypes,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
    );
    // Reset paging when filters change
    setState(() {
      _currentPage = 0;
    });
  }

  Future<void> _loadTaskTypes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final items = await _apiService.listTaskTypes();
      print('[DEBUG] Loaded ${items.length} task types');
      for (int i = 0; i < items.length && i < 3; i++) {
        print('[DEBUG] Task type $i: ${items[i]}');
        print('[DEBUG] Created by field: ${items[i]['created_by']}');
        print('[DEBUG] Created by name field: ${items[i]['created_by_name']}');
        print('[DEBUG] Creator field: ${items[i]['creator']}');
      }
      setState(() {
        _taskTypes
          ..clear()
          ..addAll(items);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load task types: $e')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _updateDataSource();
    }
  }

  // Navigation helper
  static String? _getRoutePath(String routeKey) {
    final Map<String, String> pathMap = {
      'dashboard': '/dashboard',
      'user_users': '/user/users',
      'user_scheduling': '/user/scheduling',
      'work_maintenance': '/work/maintenance',
      'work_task_type': '/work/task_type',
      'work_repair': '/work/repair',
      'calendar': '/calendar',
      'inventory_equipment': '/inventory/equipment',
      'inventory_items': '/inventory/items',
      'inventory_request': '/inventory/request',
      'analytics': '/analytics',
      'announcement': '/announcement',
      'settings': '/settings',
      //'logout': '/logout',
    };
    return pathMap[routeKey];
  }

  // Logout functionality
  void _handleLogout(BuildContext context) async {
    print('[DEBUG] _handleLogout called');
    // Ensure we're not already navigating
    if (!mounted) return;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (dialogContext) {
        print('[DEBUG] Dialog builder called');
        return const LogoutPopup();
      },
    );
    print('[DEBUG] Dialog result: $result');
    
    if (result == true && mounted) {
      // Perform logout
      print('[DEBUG] Logging out...');
      context.go('/');
    } else {
      print('[DEBUG] Logout cancelled or dialog dismissed');
    }
  }

  // Column widths for table
  final List<double> _colW = <double>[
    100, // TASK ID
    200, // NAME
    150, // CATEGORY
    130, // DATE CREATED
    48,
  ];

  // Fixed width cell helper
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

  // Text with ellipsis helper
  Text _ellipsis(String s, {TextStyle? style}) => Text(
    s,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    softWrap: false,
    style: style,
  );

  // Sorting function
  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _updateDataSource();
    });
  }

  // Toggle sort order for SCHEDULE DATE column
  void _toggleSortOrder() {
    setState(() {
      if (_sortColumnIndex == 3) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = 3;
        _sortAscending = true;
      }
      _updateDataSource();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Local helper: compute a safe Offset to use as the anchor for showMenu.
  // (local helper implementations moved to top-level functions so they can be used by DataTable data source)

  // Action dropdown menu methods
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> taskType,
    Offset position,
  ) {
    final relativeRect = getRelativeRectFromOffset(context, position);

    showMenu(
      context: context,
      position: relativeRect,
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
        _handleActionSelection(value, taskType);
      }
    });
  }

  // Handle action selection
  void _handleActionSelection(String action, Map<String, dynamic> taskType) {
    print('[DEBUG] Action: $action on task type: $taskType');
    switch (action) {
      case 'view':
        TaskTypeViewDialog.show(context, taskType);
        break;
      case 'edit':
        context.go(
          '/work/task_type/create?edit=1',
          extra: taskType,
        );
        break;
      case 'delete':
        _deleteTaskType(taskType);
        break;
    }
  }

  Future<void> _deleteTaskType(Map<String, dynamic> taskType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final taskName = _getFieldValue(taskType, ['name', 'task_title']);
        return AlertDialog(
          title: const Text('Delete Task Type'),
          content: Text('Are you sure you want to delete "$taskName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    final taskTypeId = _getFieldValue(taskType, ['id', 'formatted_id', 'task_type_id']);
    if (taskTypeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to resolve task type ID for deletion')), 
      );
      return;
    }

    try {
      await _apiService.deleteTaskType(taskTypeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task type deleted')),
        );
      }
      await _loadTaskTypes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task type: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'work_task_type',
      onNavigate: (routeKey) {
        print('[DEBUG] onNavigate called with routeKey: $routeKey');
        final routePath = _getRoutePath(routeKey);
        if (routePath != null) {
          print('[DEBUG] Navigating to route: $routePath');
          context.go(routePath);
        } else if (routeKey == 'logout') {
          print('[DEBUG] Logout route detected, calling _handleLogout');
          _handleLogout(context);
        } else {
          print('[DEBUG] Unknown routeKey: $routeKey');
        }
      },
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with breadcrumbs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Task Types",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Breadcrumb navigation
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
                          child: const Text('Maintenance'),
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
                          child: const Text('Task Types'),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.goNamed('work_task_type_create');
                  },
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

            // Search, Filter, and Refresh Row
            Row(
              children: [
                // Search Field with white background
                SizedBox(
                  width: 400,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => _updateDataSource(),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        hintText: "Search task types",
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Category Dropdown
                IntrinsicWidth(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMaintenanceTypes,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items:
                            [
                              'All Maintenance Types',
                              'Preventive',
                              'Corrective',
                              'Proactive',
                              'Emergency',
                              'Inspection',
                              'Repair',
                              'Other',
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedMaintenanceTypes = newValue;
                              _updateDataSource();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Refresh Button
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: _loadTaskTypes,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: Colors.blue[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Content Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table header
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Task Type Management",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[400]),

                  // Use DataTable + manual pagination for consistency
                  Column(
                      children: [
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_filteredTaskTypes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 48,
                              horizontal: 24,
                            ),
                            child: Text(
                              'No task types found',
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _sortAscending,
                              columnSpacing: 116,
                              headingRowHeight: 56,
                              dataRowHeight: 64,
                              headingRowColor: WidgetStateProperty.all(
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
                                DataColumn(
                                  label: _fixedCell(0, const Text('TASK ID')),
                                ),
                                DataColumn(
                                  label: _fixedCell(1, const Text('NAME')),
                                ),
                                DataColumn(
                                  label: _fixedCell(
                                    2,
                                    const Text('MAINTENANCE TYPE'),
                                  ),
                                ),
                                DataColumn(
                                  label: _fixedCell(
                                    3,
                                    InkWell(
                                      onTap: _toggleSortOrder,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text("DATE CREATED"),
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
                                    ),
                                  ),
                                ),
                                DataColumn(label: _fixedCell(4, const Text(''))),
                              ],
                              rows: _paginatedTaskTypes.map((task) {
                                final taskId = _getFieldValue(task, ['id', 'formatted_id', 'task_type_id']);
                                final name = _getFieldValue(task, ['name', 'task_title', 'taskTypeName']);
                                final category = _getFieldValue(task, ['category', 'maintenance_type']);
                                final dateLabel = _formatDateLabel(task);
                                return DataRow(
                                  cells: [
                                    DataCell(_fixedCell(0, Text(taskId))),
                                    DataCell(_fixedCell(1, Text(name))),
                                    DataCell(_fixedCell(2, Text(category))),
                                    DataCell(_fixedCell(3, Text(dateLabel))),
                                    DataCell(
                                      _fixedCell(
                                        4,
                                        Builder(
                                          builder: (context) {
                                            return IconButton(
                                              icon: const Icon(Icons.more_vert),
                                              onPressed: () {
                                                final position =
                                                    getSafeOffsetForContext(
                                                      context,
                                                    );
                                                _showActionMenu(
                                                  context,
                                                  task,
                                                  position,
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey,
                        ),
                      // Pagination
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${_paginatedTaskTypes.isEmpty ? 0 : _currentPage * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage + _paginatedTaskTypes.length)} of ${_filteredTaskTypes.length} entries',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed:
                                      _currentPage > 0
                                          ? () {
                                            setState(() {
                                              _currentPage--;
                                            });
                                          }
                                          : null,
                                  color: Colors.grey[700],
                                ),
                                ...List.generate(_totalPages.clamp(0, 5), (
                                  index,
                                ) {
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
                                          color:
                                              pageNumber == _currentPage
                                                  ? const Color(0xFF1976D2)
                                                  : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${pageNumber + 1}',
                                            style: TextStyle(
                                              color:
                                                  pageNumber == _currentPage
                                                      ? Colors.white
                                                      : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed:
                                      _currentPage < (_totalPages - 1)
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskTypeDataSource extends DataTableSource {
  final List<Map<String, dynamic>> taskTypes;
  String searchQuery;
  String selectedMaintenanceTypes;
  int? sortColumnIndex;
  bool sortAscending;
  final List<double> colW;
  final Function(String, Map<String, dynamic>) onActionSelected;

  TaskTypeDataSource({
    required this.taskTypes,
    required this.searchQuery,
    required this.selectedMaintenanceTypes,
    required this.colW,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onActionSelected,
  });

  List<Map<String, dynamic>> get _filteredTaskTypes {
    List<Map<String, dynamic>> filtered =
        taskTypes.where((task) {
          final matchesSearch =
              searchQuery.isEmpty ||
              task['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
              task['id'].toLowerCase().contains(searchQuery.toLowerCase());
          final matchesCategory =
              selectedMaintenanceTypes == 'All Maintenance Types' ||
              task['category'] == selectedMaintenanceTypes;
          return matchesSearch && matchesCategory;
        }).toList();

    if (sortColumnIndex != null) {
      filtered.sort((a, b) {
        int result;
        if (sortColumnIndex == 3) {
          // Date Created
          DateTime dateA = DateTime.parse(a['dateCreated']);
          DateTime dateB = DateTime.parse(b['dateCreated']);
          result = dateA.compareTo(dateB);
        } else {
          result = a.values
              .elementAt(sortColumnIndex!)
              .toString()
              .compareTo(b.values.elementAt(sortColumnIndex!).toString());
        }
        return sortAscending ? result : -result;
      });
    }

    return filtered;
  }

  void update({
    required String searchQuery,
    required String selectedMaintenanceTypes,
    required int? sortColumnIndex,
    required bool sortAscending,
  }) {
    this.searchQuery = searchQuery;
    this.selectedMaintenanceTypes = selectedMaintenanceTypes;
    this.sortColumnIndex = sortColumnIndex;
    this.sortAscending = sortAscending;
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= _filteredTaskTypes.length) return null;
    final task = _filteredTaskTypes[index];
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: colW[0],
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(task['id']),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: colW[1],
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(task['name']),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: colW[2],
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(task['category']),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: colW[3],
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(task['dateCreated']),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: colW[4],
            child: Builder(
              builder: (context) {
                return Center(
                  child: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    final position = getSafeOffsetForContext(context);
                    _showActionMenu(context, task, position);
                  },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> taskType,
    Offset position,
  ) {
    final relativeRect = getRelativeRectFromOffset(context, position);
    showMenu(
      context: context,
      position: relativeRect,
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
        onActionSelected(value, taskType);
      }
    });
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _filteredTaskTypes.length;

  @override
  int get selectedRowCount => 0;
}
