import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import 'pop_up/tasktype_popup.dart';
import '../widgets/logout_popup.dart';

class AdminTaskTypePage extends StatefulWidget {
  const AdminTaskTypePage({super.key});

  @override
  State<AdminTaskTypePage> createState() => _AdminTaskTypePageState();
}

class _AdminTaskTypePageState extends State<AdminTaskTypePage> {
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All Categories';

  // Sorting state
  int? _sortColumnIndex;
  bool _sortAscending = true;

  // Sample data
  final List<Map<String, dynamic>> _taskTypes = [
    {'id': 'TT001', 'name': 'Aircon Cleaning', 'category': 'Maintenance', 'dateCreated': '2025-01-01'},
    {'id': 'TT002', 'name': 'Basic Cleaning', 'category': 'Maintenance', 'dateCreated': '2025-01-02'},
  ];

  late TaskTypeDataSource _dataSource;
  // Pagination state
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  // Computed getters for filtering and pagination
  List<Map<String, dynamic>> get _filteredTaskTypes {
    List<Map<String, dynamic>> filtered = _taskTypes.where((task) {
      final matchesSearch = _searchController.text.isEmpty ||
          task['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
          task['id'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesCategory = _selectedCategory == 'All Categories' || task['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    if (_sortColumnIndex != null) {
      filtered.sort((a, b) {
        int result;
        if (_sortColumnIndex == 3) { // Date Created
          DateTime dateA = DateTime.tryParse(a['dateCreated'] ?? a['date_created'] ?? '') ?? DateTime(1970);
          DateTime dateB = DateTime.tryParse(b['dateCreated'] ?? b['date_created'] ?? '') ?? DateTime(1970);
          result = dateA.compareTo(dateB);
        } else {
          result = a.values.elementAt(_sortColumnIndex!).toString().compareTo(
                b.values.elementAt(_sortColumnIndex!).toString(),
              );
        }
        return _sortAscending ? result : -result;
      });
    }

    return filtered;
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
      selectedCategory: _selectedCategory,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      onActionSelected: _handleActionSelection,
    );
    _searchController.addListener(_updateDataSource);
  }

  void _updateDataSource() {
    _dataSource.update(
      searchQuery: _searchController.text,
      selectedCategory: _selectedCategory,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
    );
    // Reset paging when filters change
    setState(() {
      _currentPage = 0;
    });
  }

  // Navigation helper
  static String? _getRoutePath(String routeKey) {
    final Map<String, String> pathMap = {
      'dashboard': '/dashboard',
      'user_users': '/user/users',
      'user_scheduling': '/user/scheduling',
      'work_maintenance': '/work/maintenance',
      'work_task_types': '/work/tasktypes',
      'work_repair': '/work/repair',
      'calendar': '/calendar',
      'inventory_equipment': '/inventory/equipment',
      'inventory_items': '/inventory/items',
      'inventory_request': '/inventory/request',
      'analytics': '/analytics',
      'announcement': '/announcement',
      'settings': '/settings',
      'logout': '/logout',
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

  // Column widths for table
  final List<double> _colW = <double>[
    80, // ID
    200, // NAME
    150, // CATEGORY
    130, // DATE CREATED
    120, // ACTIONS
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Action dropdown menu methods
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> taskType,
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
        _handleActionSelection(value, taskType);
      }
    });
  }

  // Handle action selection
  void _handleActionSelection(String action, Map<String, dynamic> taskType) {
    switch (action) {
      case 'view':
        TaskTypeViewDialog.show(context, taskType);
        break;
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit task type ${taskType['id']}')),
        );
        break;
      case 'delete':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete task type ${taskType['id']}')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'work_task_types',
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
                    context.goNamed('work_task_types_create');
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                        value: _selectedCategory,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: [
                          'All Categories',
                          'Preventive',
                          'Corrective',
                          'Predictive',
                          'Emergency',
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
                              _selectedCategory = newValue;
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
                    onTap: () {},
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
            Expanded(
              child: Container(
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
                    Expanded(
                      child: Column(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _sortAscending,
                              columnSpacing: 50,
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
                                DataColumn(label: _fixedCell(0, const Text('ID'))),
                                DataColumn(label: _fixedCell(1, const Text('NAME'))),
                                DataColumn(label: _fixedCell(2, const Text('CATEGORY'))),
                                DataColumn(label: _fixedCell(3, const Text('DATE CREATED')), onSort: _onSort),
                                DataColumn(label: _fixedCell(4, const Text('ACTIONS'))),
                              ],
                              rows: _paginatedTaskTypes.map((task) {
                                return DataRow(cells: [
                                  DataCell(_fixedCell(0, Text(task['id']))),
                                  DataCell(_fixedCell(1, Text(task['name']))),
                                  DataCell(_fixedCell(2, Text(task['category']))),
                                  DataCell(_fixedCell(3, Text(task['dateCreated']))),
                                  DataCell(_fixedCell(4, Builder(builder: (context) {
                                    return IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () {
                                        final RenderBox button = context.findRenderObject() as RenderBox;
                                        final Offset position = button.localToGlobal(Offset.zero);
                                        _showActionMenu(context, task, position);
                                      },
                                    );
                                  })) ),
                                ]);
                              }).toList(),
                            ),
                          ),
                          const Divider(height: 1, thickness: 1, color: Colors.grey),
                          // Pagination
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing ${_paginatedTaskTypes.isEmpty ? 0 : _currentPage * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage + _paginatedTaskTypes.length)} of ${_filteredTaskTypes.length} entries',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: _currentPage > 0 ? () { setState(() { _currentPage--; }); } : null,
                                      color: Colors.grey[700],
                                    ),
                                    ...List.generate(_totalPages.clamp(0, 5), (index) {
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
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: InkWell(
                                          onTap: () { setState(() { _currentPage = pageNumber; }); },
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: pageNumber == _currentPage ? const Color(0xFF1976D2) : Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${pageNumber + 1}',
                                                style: TextStyle(color: pageNumber == _currentPage ? Colors.white : Colors.grey[700]),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: _currentPage < (_totalPages - 1) ? () { setState((){ _currentPage++; }); } : null,
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
                    Divider(height: 1, thickness: 1, color: Colors.grey[400]),
                  ],
                ),
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
  String selectedCategory;
  int? sortColumnIndex;
  bool sortAscending;
  final Function(String, Map<String, dynamic>) onActionSelected;

  TaskTypeDataSource({
    required this.taskTypes,
    required this.searchQuery,
    required this.selectedCategory,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onActionSelected,
  });

  List<Map<String, dynamic>> get _filteredTaskTypes {
    List<Map<String, dynamic>> filtered = taskTypes.where((task) {
      final matchesSearch = searchQuery.isEmpty ||
          task['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          task['id'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == 'All Categories' ||
          task['category'] == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    if (sortColumnIndex != null) {
      filtered.sort((a, b) {
        int result;
        if (sortColumnIndex == 3) { // Date Created
          DateTime dateA = DateTime.parse(a['dateCreated']);
          DateTime dateB = DateTime.parse(b['dateCreated']);
          result = dateA.compareTo(dateB);
        } else {
          result = a.values.elementAt(sortColumnIndex!).toString().compareTo(
                b.values.elementAt(sortColumnIndex!).toString(),
              );
        }
        return sortAscending ? result : -result;
      });
    }

    return filtered;
  }

  void update({
    required String searchQuery,
    required String selectedCategory,
    required int? sortColumnIndex,
    required bool sortAscending,
  }) {
    this.searchQuery = searchQuery;
    this.selectedCategory = selectedCategory;
    this.sortColumnIndex = sortColumnIndex;
    this.sortAscending = sortAscending;
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= _filteredTaskTypes.length) return null;
    final task = _filteredTaskTypes[index];
    return DataRow(cells: [
      DataCell(SizedBox(width: 80, child: Text(task['id']))),
      DataCell(SizedBox(width: 200, child: Text(task['name']))),
      DataCell(SizedBox(width: 150, child: Text(task['category']))),
      DataCell(SizedBox(width: 130, child: Text(task['dateCreated']))),
      DataCell(SizedBox(width: 120, child: Builder(builder: (context) {
        return IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            final RenderBox button = context.findRenderObject() as RenderBox;
            final Offset position = button.localToGlobal(Offset.zero);
            _showActionMenu(context, task, position);
          },
        );
      }))),
    ]);
  }

  void _showActionMenu(BuildContext context, Map<String, dynamic> taskType, Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
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
              Icon(Icons.visibility_outlined, color: Colors.green[600], size: 18),
              const SizedBox(width: 12),
              Text('View', style: TextStyle(color: Colors.green[600], fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: Colors.blue[600], size: 18),
              const SizedBox(width: 12),
              Text('Edit', style: TextStyle(color: Colors.blue[600], fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red[600], size: 18),
              const SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.red[600], fontSize: 14)),
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
