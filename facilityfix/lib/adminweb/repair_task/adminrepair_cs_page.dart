import 'package:facilityfix/adminweb/widgets/tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import 'pop_up/cs_viewdetails_popup.dart';
import 'pop_up/edit_popup.dart';
import '../widgets/delete_popup.dart';
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
  String _selectedCategory = 'All Categories';
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

  // Helper method to get priority weight for sorting
  int _getPriorityWeight(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
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
                'status': _mapStatus(
                  slip['status'],
                  slip['workflow'],
                  slip['resolution_type'],
                ),
                'location': slip['location'] ?? 'N/A',
                'description': slip['description'] ?? 'No Description',
                'category': slip['category'],
                'reportedBy': slip['reported_by'] ?? 'Unknown',
                'rawData': slip, // Store raw data for detailed view
              };
            }).toList();

        // Sort tasks by priority (high to low)
        _repairTasks.sort((a, b) {
          final priorityA = _getPriorityWeight(a['priority']);
          final priorityB = _getPriorityWeight(b['priority']);
          return priorityB.compareTo(priorityA); // Descending order
        });

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

  String _mapStatus(dynamic status, dynamic workflow, dynamic resolutionType) {
    // Normalize input and reduce statuses to the project's canonical token set.
    // Allowed token outputs (lowercase): 'pending', 'in progress', 'to inspect', 'inspected'.
    final s = (status ?? '').toString().toLowerCase();

    // Pending
    if (s.contains('pending')) return 'pending';

    // To Inspect (assigned / to inspect variants)
    if (s.contains('assigned') || s.contains('to inspect') || s.contains('to_inspect')) {
      return 'to inspect';
    }

    // In Progress
    if (s.contains('in_progress') || s.contains('in progress')) return 'in progress';

    // Inspected / Assessed / Completed and similar => 'inspected'
    if (s.contains('inspected') || s.contains('assessed') || s.contains('completed') || s.contains('assess')) {
      return 'inspected';
    }

    // Fallback: treat unknowns as pending token
    return 'pending';
  }

  // single _mapStatus defined above; duplicate removed
  
  String _getDepartment(String? category) {
    switch (category?.toLowerCase()) {
      case 'electrical':
        return 'Electrical';
      case 'plumbing':
        return 'Plumbing';
      case 'masonry':
        return 'Masonry';
      case 'hvac':
        return 'HVAC';
      case 'carpentry':
        return 'Carpentry';
      case 'pest control':
        return 'Pest Control';
      default:
        return '';
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

            // Category filter
            bool matchesDepartment = true;
            if (_selectedCategory != 'All Categories') {
              final taskDept = task['department']?.toString().toLowerCase() ?? '';
              final selectedDept = _selectedCategory.toLowerCase();
              
              if (selectedDept == 'other') {
                // For "Other", match HVAC and Pest Control categories
                matchesDepartment = taskDept == 'hvac' || taskDept == 'pest control';
              } else {
                matchesDepartment = taskDept == selectedDept;
              }
            }

            // Status filter - normalize both the selected label and the task status
            bool matchesStatus = _selectedStatus == 'All Status';
            if (!matchesStatus) {
                String taskStatus = (task['status']?.toString() ?? '').toLowerCase();
                // If staff has already assessed/filled assessment fields, treat as inspected
                final raw = task['rawData'] ?? {};
                final bool hasAssessment = (raw?['assessed_by'] != null) || (raw?['assessed_at'] != null) || (raw?['staff_assessment'] != null) || (raw?['staff_recommendation'] != null) || (raw?['assessment'] != null);
                if (hasAssessment) taskStatus = 'inspected';
              final selectedStatus = _selectedStatus;
              final normalizedSelected = selectedStatus.toLowerCase();

              // Direct normalized match
              if (taskStatus == normalizedSelected) {
                matchesStatus = true;
              } else {
                // Map common display labels to canonical task status tokens
                final Map<String, List<String>> canonicalMap = {
                  'pending': ['pending'],
                  'in progress': ['in progress', 'in_progress'],
                  'to inspect': ['to inspect', 'to_inspect', 'assigned'],
                  'inspected': ['inspected', 'completed', 'assessed', 'sent', 'sent to client', 'done'],
                  // allow filtering by resolution types shown as Status dropdown options
                  'job service': ['job service', 'pending js', 'pending js'],
                  'work order': ['work order', 'pending wop', 'pending wop'],
                };

                final validStatuses = canonicalMap[normalizedSelected] ?? [normalizedSelected];
                matchesStatus = validStatuses.contains(taskStatus);

                // As a fallback, check resolution_type for Job Service / Work Order selections
                if (!matchesStatus && (normalizedSelected == 'job service' || normalizedSelected == 'work order')) {
                  final resolution = (task['rawData']?['resolution_type'] ?? '').toString().toLowerCase();
                  if (resolution.isNotEmpty) {
                    matchesStatus = resolution.contains(normalizedSelected.replaceAll(' ', '_')) || resolution.contains(normalizedSelected);
                  }
                }
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
    // With normalized statuses, allow setting resolution when task is inspected/assessed
    return status == 'assessed' || status == 'inspected';
  }

  // Check if action buttons should be disabled
  bool _areActionButtonsDisabled(Map<String, dynamic> task) {
    final status = task['status']?.toString().toLowerCase();
    // Mapped 'assigned' -> 'to inspect'
    return (status == 'assigned' || status == 'to inspect' || status == 'to_inspect') && task['rawData']?['assessed_by'] == null;
  }

  // Action dropdown menu methods
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> task,
    Offset position,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final actionsDisabled = _areActionButtonsDisabled(task);

    final List<PopupMenuEntry<String>> menuItems = [];

    // Always available actions
    menuItems.addAll([
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
    ]);

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: menuItems,
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
    // Open the EditDialog for concern slips and refresh on success
    final raw = task['rawData'] ?? task;
    EditDialog.show(
      context,
      type: EditDialogType.concernSlip,
      task: raw as Map<String, dynamic>,
      onSave: () {},
    ).then((result) {
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Changes saved for: ${task['id']}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadConcernSlips();
      }
    });
  }

  // Delete task method
  void _deleteTask(Map<String, dynamic> task) async {
    final confirmed = await showDeleteDialog(
      context,
      itemName: 'Task',
      description: 'Are you sure you want to delete this task ${task['id']}? This action cannot be undone. All associated data will be permanently removed from the system.',
    );

    if (confirmed) {
      try {
        // Determine backend id (prefer rawData._doc_id or rawData.id if available)
        final raw = task['rawData'] as Map<String, dynamic>?;
        final idToDelete = raw?['_doc_id'] ?? raw?['id'] ?? task['id'];

        if (idToDelete == null) {
          throw Exception('Unable to determine task id to delete');
        }

        await _apiService.deleteConcernSlip(idToDelete.toString());

        // Remove locally to update UI immediately
        if (mounted) {
          setState(() {
            _repairTasks.removeWhere((t) => t['id'] == task['id']);
            _filteredTasks.removeWhere((t) => t['id'] == task['id']);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task ${task['id']} deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Background refresh to ensure consistency with server
        _loadConcernSlips();
      } catch (e) {
        print('[AdminRepairPage] Error deleting concern slip: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  final List<double> _colW = <double>[
    85, // CONCERN ID
    130, // TITLE
    130, // DATE REQUESTED
    100, // BUILDING & UNIT
    70, // PRIORITY
    100, // CLASSIFICTAION
    90, // STATUS
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
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Category Dropdown
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
                  value: _selectedCategory,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                      _applyFilters();
                    });
                  },
                  items:
                      <String>[
                        'All Categories',
                        'Carpentry',
                        'Electrical',
                        'Masonry',
                        'Plumbing',
                        'Other',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value == 'All Categories' ? value : 'Category: $value',
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
                                      'In Progress',
                                      'To Inspect',
                                      'Inspected',
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
          const SizedBox(width: 150),

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
                        } else if (newValue == 'Work Order') {
                          context.go('/adminweb/pages/adminrepair_wop_page');
                        }
                      },
                      items:
                          <String>[
                            'Concern Slip',
                            'Job Service',
                            'Work Order',
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
                              label: _fixedCell(5, const Text("CATEGORY")),
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
                                        PriorityTag(task['priority']),
                                      ),
                                    ),
                                    DataCell(
                                      _fixedCell(
                                        5,
                                        DepartmentTag(
                                          task['department'],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      _fixedCell(
                                        6,
                                        StatusTag(task['status']),
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
}
