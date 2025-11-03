import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../popupwidgets/cs_viewdetails_popup.dart';
import '../popupwidgets/assignstaff_popup.dart';
import '../popupwidgets/set_resolution_type_popup.dart';
import '../services/api_service.dart';

class AdminRepairPage extends StatefulWidget {
  const AdminRepairPage({super.key});

  @override
  State<AdminRepairPage> createState() => _AdminRepairPageState();
}

class _AdminRepairPageState extends State<AdminRepairPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _repairTasks = [];
  List<Map<String, dynamic>> _filteredTasks = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Pagination state
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  
  // Sorting state
  bool _sortAscending = false;
  
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
  
  // Dropdown values for filtering
  String _selectedDepartment = 'All Departments';
  String _selectedStatus = 'All Status';
  String _selectedConcernType = 'Concern Slip';
  String _searchQuery = '';
  
  // Sort by date
  void _sortByDate() {
    setState(() {
      _filteredTasks.sort((a, b) {
        final dateA = _parseDate(a['dateRequested']);
        final dateB = _parseDate(b['dateRequested']);
        
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        
        return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      });
    });
  }
  
  // Parse date helper
  DateTime? _parseDate(dynamic dateStr) {
    if (dateStr == null) return null;
    try {
      if (dateStr is DateTime) return dateStr;
      if (dateStr is String) return DateTime.parse(dateStr);
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Toggle sort order
  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;
      _sortByDate();
    });
  }  @override
  void initState() {
    super.initState();
    _loadConcernSlips();
  }

  Future<void> _loadConcernSlips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final concernSlips = await _apiService.getAllConcernSlips();

      setState(() {
        _repairTasks =
            concernSlips.map((slip) {
              return {
                'id': slip['formatted_id'] ?? slip['_doc_id'] ?? 'N/A',
                'title': slip['title'] ?? 'No Title',
                'dateRequested': _formatDate(slip['created_at']),
                'buildingUnit': _getBuildingUnit(slip),
                'priority': _capitalizePriority(slip['priority'] ?? 'medium'),
                'department': _getDepartment(slip['category']),
                'status': _capitalizeStatus(slip['status'] ?? 'pending'),
                'location': slip['location'] ?? 'N/A',
                'description': slip['description'] ?? 'No Description',
                'category': slip['category'] ?? 'general',
                'reportedBy': slip['reported_by'] ?? 'Unknown',
                'rawData': slip, // Store raw data for detailed view
              };
            }).toList();
        _filteredTasks = List.from(_repairTasks);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load concern slips: $e';
        _isLoading = false;
      });
      print('[AdminRepairPage] Error loading concern slips: $e');
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';

    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'N/A';
      }

      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getBuildingUnit(Map<String, dynamic> slip) {
    // Try to get building and unit info
    final unitId = slip['unit_id'];
    if (unitId != null && unitId.toString().isNotEmpty) {
      return 'Unit $unitId';
    }
    return 'N/A';
  }

  String _capitalizePriority(String priority) {
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

  String _capitalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'To Inspect';
      case 'in_progress':
        return 'In Progress';
      case 'assessed':
        return 'Assessed';
      case 'sent':
        return 'Sent to Client';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      case 'returned_to_tenant':
        return 'Returned to Tenant';
      default:
        return 'Pending';
    }
  }

  String _getDepartment(String? category) {
    switch (category?.toLowerCase()) {
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
      case 'security':
        return 'Security';
      case 'fire_safety':
        return 'Fire Safety';
      case 'pest control':
        return 'Pest Control';

      default:
        return 'General';
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTasks =
          _repairTasks.where((task) {
            // Search filter
            bool matchesSearch =
                _searchQuery.isEmpty ||
                task['title'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                task['id'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                task['location'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );

            // Department filter
            bool matchesDepartment = true;
            if (_selectedDepartment != 'All Departments') {
              final taskDept = task['department']?.toString().toLowerCase() ?? '';
              final selectedDept = _selectedDepartment.toLowerCase();
              
              if (selectedDept == 'others') {
                // For "Others", match pest control, hvac, security, fire safety, maintenance, general
                matchesDepartment = !['carpentry', 'electrical', 'masonry', 'plumbing'].contains(taskDept);
              } else {
                matchesDepartment = taskDept.contains(selectedDept);
              }
            }

            // Status filter - handle both display values and variations
            bool matchesStatus = _selectedStatus == 'All Status';
            if (!matchesStatus) {
              final taskStatus = task['status']?.toString() ?? '';
              final selectedStatus = _selectedStatus;
              
              // Direct match
              if (taskStatus == selectedStatus) {
                matchesStatus = true;
              } else {
                // Handle status variations
                final statusMap = {
                  'Assigned': ['Assigned', 'To Inspect'],
                  'To Inspect': ['Assigned', 'To Inspect'],
                  'In Progress': ['In Progress'],
                  'Assessed': ['Assessed'],
                  'Completed': ['Completed'],
                  'Cancelled': ['Cancelled'],
                  'Pending': ['Pending'],
                };
                
                final validStatuses = statusMap[selectedStatus] ?? [selectedStatus];
                matchesStatus = validStatuses.contains(taskStatus);
              }
            }

            return matchesSearch && matchesDepartment && matchesStatus;
          }).toList();
      
      // Reset to first page when filters change
      _currentPage = 0;
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
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

  // Handle logout functionality
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/'); // Go back to login page
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Check if task can be assigned to staff
  bool _canAssignStaff(Map<String, dynamic> task) {
    final status = task['status']?.toString().toLowerCase();
    return status == 'pending' || status == 'evaluated';
  }

  // Check if resolution type can be set (status is assessed)
  bool _canSetResolutionType(Map<String, dynamic> task) {
    final status = task['status']?.toString().toLowerCase();
    return status == 'assessed';
  }

  // Check if action buttons should be disabled
  bool _areActionButtonsDisabled(Map<String, dynamic> task) {
    final status = task['status']?.toString().toLowerCase();
    return status == 'assigned' && task['rawData']?['assessed_by'] == null;
  }

  // Action dropdown menu methods
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> task,
    Offset position,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final canAssign = _canAssignStaff(task);
    final canSetResolution = _canSetResolutionType(task);
    final actionsDisabled = _areActionButtonsDisabled(task);

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
        if (canAssign)
          PopupMenuItem(
            value: 'assign',
            child: Row(
              children: [
                Icon(
                  Icons.person_add_outlined,
                  color: Colors.blue[600],
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Assign Staff',
                  style: TextStyle(color: Colors.blue[600], fontSize: 14),
                ),
              ],
            ),
          ),
        if (canSetResolution)
          PopupMenuItem(
            value: 'set_resolution',
            child: Row(
              children: [
                Icon(
                  Icons.task_alt,
                  color: Colors.purple[600],
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Set Resolution Type',
                  style: TextStyle(color: Colors.purple[600], fontSize: 14),
                ),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'edit',
          enabled: !actionsDisabled,
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: actionsDisabled ? Colors.grey[400] : Colors.blue[600],
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'Edit',
                style: TextStyle(
                  color: actionsDisabled ? Colors.grey[400] : Colors.blue[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          enabled: !actionsDisabled,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: actionsDisabled ? Colors.grey[400] : Colors.red[600],
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete',
                style: TextStyle(
                  color: actionsDisabled ? Colors.grey[400] : Colors.red[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
    ).then((value) {
      if (value != null) {
        _handleActionSelection(value, task);
      }
    });
  }

  // Handle action selection
  void _handleActionSelection(String action, Map<String, dynamic> task) {
    switch (action) {
      case 'view':
        _viewTask(task);
        break;
      case 'assign':
        _assignStaff(task);
        break;
      case 'set_resolution':
        _setResolutionType(task);
        break;
      case 'edit':
        _editTask(task);
        break;
      case 'delete':
        _deleteTask(task);
        break;
    }
  }

  // View task method
  void _viewTask(Map<String, dynamic> task) {
    ConcernSlipDetailDialog.show(context, task);
  }

  // Assign staff method
  void _assignStaff(Map<String, dynamic> task) {
    AssignScheduleWorkDialog.show(
      context,
      task,
      onAssignmentComplete: () {
        // Refresh the concern slips list after assignment
        _loadConcernSlips();
      },
    );
  }

  // Set resolution type method
  void _setResolutionType(Map<String, dynamic> task) {
    SetResolutionTypeDialog.show(
      context,
      task,
      onSuccess: () {
        // Refresh the concern slips list after setting resolution type
        _loadConcernSlips();
      },
    );
  }

  // Edit task method
  void _editTask(Map<String, dynamic> task) {
    // Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit task: ${task['id']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Delete task method
  void _deleteTask(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Are you sure you want to delete task ${task['id']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Remove task from list
                setState(() {
                  _repairTasks.removeWhere((t) => t['id'] == task['id']);
                  _applyFilters();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task ${task['id']} deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  final List<double> _colW = <double>[
    100, // CONCERN ID
    140, // TITLE
    130, // DATE REQUESTED
    100, // BUILDING & UNIT
    80, // PRIORITY
    90, // DEPARTMENT
    70, // STATUS
    38, // ACTION
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

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'work_repair',
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section - Page Title and Breadcrumb
            _buildHeaderSection(),
            const SizedBox(height: 32),

            // Filter Section - Search, Role, Status, and Filter Button
            _buildFilterSection(),
            const SizedBox(height: 32),

            // Table Section - Repair Tasks (Concern Slip)
            _buildTableSection(),
          ],
        ),
      ),
    );
  }

  // Header Section Widget
  Widget _buildHeaderSection() {
    return Column(
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
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            TextButton(
              onPressed: () => context.go('/work/maintenance'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Task Management'),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            TextButton(
              onPressed: () => context.go('/work/repair'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Repair Tasks'),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            TextButton(
              onPressed: null,
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Concern Slips'),
            ),
          ],
        ),
      ],
    );
  }

  // Filter Section Widget
  Widget _buildFilterSection() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // Search Field
          Expanded(
            flex: 2,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  hintText: "Search",
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Department Dropdown
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDepartment,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDepartment = newValue!;
                      _applyFilters();
                    });
                  },
                  items:
                      <String>[
                        'All Departments',
                        'Carpentry',
                        'Electrical',
                        'Masonry',
                        'Plumbing',
                        'Other',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value == 'All Departments' ? value : 'Dept: $value',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Status Dropdown
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStatus = newValue!;
                      _applyFilters();
                    });
                  },
                  items:
                      <String>[
                        'All Status',
                        'Pending',
                        'Assigned',
                        'In Progress',
                        'Assessed',
                        'Completed',
                        'Cancelled',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            'Status: $value',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 300),

          // Refresh Button
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: _loadConcernSlips,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 20, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Table Section Widget
  Widget _buildTableSection() {
    return Container(
      height: 650, // Fixed height to avoid unbounded constraints
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
          // Table Header with Title and Dropdown
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Repair Tasks",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                // Repair Type Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedConcernType,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedConcernType = newValue!;
                        });

                        // Navigate based on selection
                        if (newValue == 'Concern Slip') {
                          context.go('/work/repair');
                        } else if (newValue == 'Job Service') {
                          context.go('/adminweb/pages/adminrepair_js_page');
                        } else if (newValue == 'Work Order Permit') {
                          context.go('/adminweb/pages/adminrepair_wop_page');
                        }
                      },
                      items:
                          <String>[
                            'Concern Slip',
                            'Job Service',
                            'Work Order Permit',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey[400]),

          // Data Table
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadConcernSlips,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : _filteredTasks.isEmpty
                    ? Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Concern Slip Found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'There are currently no concern slip requests to display.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        
                      ],
                    ),
                    )
                    : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
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
                            DataColumn(
                              label: _fixedCell(0, const Text("CONCERN ID")),
                            ),
                            DataColumn(
                              label: _fixedCell(1, const Text("CONCERN TITLE")),
                            ),
                            DataColumn(
                              label: _fixedCell(
                                2,
                                InkWell(
                                  onTap: _toggleSortOrder,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text("DATE REQUESTED"),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _sortAscending 
                                          ? Icons.arrow_upward 
                                          : Icons.arrow_downward,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: _fixedCell(
                                3,
                                const Text("BUILDING & UNIT"),
                              ),
                            ),
                            DataColumn(
                              label: _fixedCell(4, const Text("PRIORITY")),
                            ),
                            DataColumn(
                              label: _fixedCell(5, const Text("DEPARTMENT")),
                            ),
                            DataColumn(
                              label: _fixedCell(6, const Text("STATUS")),
                            ),
                            DataColumn(label: _fixedCell(7, const Text(""))),
                          ],
                          rows:
                              _paginatedTasks.map((task) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      _fixedCell(
                                        0,
                                        _ellipsis(
                                          task['id'],
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      _fixedCell(1, _ellipsis(task['title'])),
                                    ),
                                    DataCell(
                                      _fixedCell(
                                        2,
                                        _ellipsis(task['dateRequested']),
                                      ),
                                    ),
                                    DataCell(
                                      _fixedCell(
                                        3,
                                        _ellipsis(task['buildingUnit']),
                                      ),
                                    ),

                                    // Chips get a fixed box too (and aligned left)
                                    DataCell(
                                      _fixedCell(
                                        4,
                                        _buildPriorityChip(task['priority']),
                                      ),
                                    ),
                                    DataCell(
                                      _fixedCell(
                                        5,
                                        _buildDepartmentChip(
                                          task['department'],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      _fixedCell(
                                        6,
                                        _buildStatusChip(task['status']),
                                      ),
                                    ),

                                    // Action menu cell (narrow, centered)
                                    DataCell(
                                      _fixedCell(
                                        7,
                                        Builder(
                                          builder: (context) {
                                            return IconButton(
                                              onPressed: () {
                                                final rbx =
                                                    context.findRenderObject()
                                                        as RenderBox;
                                                final position = rbx
                                                    .localToGlobal(Offset.zero);
                                                _showActionMenu(
                                                  context,
                                                  task,
                                                  position,
                                                );
                                              },
                                              icon: Icon(
                                                Icons.more_vert,
                                                color: Colors.grey[400],
                                                size: 20,
                                              ),
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
                    ),
                        ),
                          // Pagination Section
                          Divider(height: 1, thickness: 1, color: Colors.grey[400]),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _filteredTasks.isEmpty
                                      ? "No entries"
                                      : "Showing ${_currentPage * _itemsPerPage + 1} to ${((_currentPage + 1) * _itemsPerPage).clamp(0, _filteredTasks.length)} of ${_filteredTasks.length} ${_filteredTasks.length == 1 ? 'entry' : 'entries'}",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                                Row(
                                  children: [
                                    // Previous button
                                    IconButton(
                                      onPressed: _currentPage > 0
                                          ? () {
                                              setState(() {
                                                _currentPage--;
                                              });
                                            }
                                          : null,
                                      icon: const Icon(Icons.chevron_left),
                                      color: Colors.blue,
                                      disabledColor: Colors.grey[300],
                                    ),
                                    // Page numbers
                                    ...List.generate(
                                      _totalPages,
                                      (index) => Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _currentPage = index;
                                            });
                                          },
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: _currentPage == index
                                                  ? Colors.blue
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: _currentPage == index
                                                    ? Colors.blue
                                                    : Colors.grey[300]!,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                color: _currentPage == index
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Next button
                                    IconButton(
                                      onPressed: _currentPage < _totalPages - 1
                                          ? () {
                                              setState(() {
                                                _currentPage++;
                                              });
                                            }
                                          : null,
                                      icon: const Icon(Icons.chevron_right),
                                      color: Colors.blue,
                                      disabledColor: Colors.grey[300],
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
    );
  }

  // Priority Chip Widget
  Widget _buildPriorityChip(String priority) {
    Color bgColor;
    Color textColor;
    switch (priority) {
      case 'High':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        break;
      case 'Medium':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFFF8F00);
        break;
      case 'Low':
        bgColor = const Color(0xFFE8F5E8);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'Critical':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        break;
      default:
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
        priority,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Department Chip Widget
  Widget _buildDepartmentChip(String department) {
    final departmentLower = department.toLowerCase();
    Color bg = Colors.grey[200]!;
    Color fg = Colors.grey[800]!;

    switch (departmentLower) {
      case 'maintenance':
        bg = const Color(0xFF19B36E);
        fg = Colors.white;
        break;
      case 'carpentry':
        bg = const Color(0xFFF79009);
        fg = Colors.white;
        break;
      case 'plumbing':
        bg = const Color(0xFF005CE7);
        fg = Colors.white;
        break;
      case 'electrical':
        bg = const Color(0xFFF95555);
        fg = Colors.white;
        break;
      case 'masonry':
        bg = const Color(0xFF666666);
        fg = Colors.white;
        break;
      default:
        bg = Colors.grey[200]!;
        fg = Colors.grey[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        department,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Status Chip Widget
  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'In Progress':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFFF8F00);
        break;
      case 'Pending':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        break;
      case 'Completed':
        bgColor = const Color(0xFFE8F5E8);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'Cancelled':
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        break;
      case 'To Inspect':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        break;
      case 'Assessed':
        bgColor = const Color(0xFFF3E5F5);
        textColor = const Color(0xFF7B1FA2);
        break;
      case 'Sent to Client':
        bgColor = const Color(0xFFE0F2F1);
        textColor = const Color(0xFF00695C);
        break;
      case 'Approved':
        bgColor = const Color(0xFFE8F5E8);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'Rejected':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        break;
      case 'Returned to Tenant':
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFFF8F00);
        break;
      default:
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
