import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../popupwidgets/js_viewdetails_popup.dart';
import '../services/api_service.dart';
import '../../widgets/modals.dart';

class RepairJobServicePage extends StatefulWidget {
  const RepairJobServicePage({super.key});

  @override
  State<RepairJobServicePage> createState() => _RepairJobServicePageState();
}

class _RepairJobServicePageState extends State<RepairJobServicePage> {
  // Loading state
  bool _isLoading = true;
  
  // Dynamic data from API
  List<Map<String, dynamic>> _repairTasks = [];
  
  // Staff data for assignment
  List<Map<String, dynamic>> _staffMembers = [];
  bool _isLoadingStaff = false;
  
  // Error handling
  String? _errorMessage;
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

  @override
  void initState() {
    super.initState();
    _loadJobServices();
  }

  // Load job services from API
  Future<void> _loadJobServices() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final jobServices = await apiService.getAllJobServices();

      if (mounted) {
        setState(() {
          _repairTasks = jobServices.map((jobService) => _processJobServiceData(jobService)).toList();
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading job services: $e');
      if (mounted) {
        setState(() {
          _repairTasks = [];
          _isLoading = false;
          _errorMessage = 'Failed to load job services: $e';
        });
      }
    }
  }

  // Process job service data from API to match UI format
  Map<String, dynamic> _processJobServiceData(Map<String, dynamic> jobService) {
    return {
      'serviceId': jobService['formatted_id'] ?? jobService['id'] ?? 'N/A',
      'id': jobService['concern_slip_id'] ?? jobService['id'] ?? 'N/A',
      'buildingUnit': jobService['location'] ?? jobService['unit_id'] ?? 'N/A',
      'schedule': _formatDate(jobService['scheduled_date'] ?? jobService['created_at']),
      'priority': _capitalizePriority(jobService['priority']),
      'status': _capitalizeStatus(jobService['status']),
      
      // Additional task data
      'title': jobService['title'] ?? 'Job Service Request',
      'dateRequested': _formatDate(jobService['created_at']),
      'requestedBy': jobService['reported_by'] ?? 'N/A',
      'department': _mapCategoryToDepartment(jobService['category']),
      'description': jobService['description'] ?? '',
      'assessment': jobService['work_notes']?.join(' ') ?? '',
      'recommendation': '',
    };
  }

  // Helper methods for data formatting
  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _capitalizeStatus(String? status) {
    if (status == null) return 'Pending';
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.split('_').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
        ).join(' ');
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
        return priority.split('_').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
        ).join(' ');
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

  // Dropdown values for filtering
  String _selectedRole = 'All Roles';
  String _selectedStatus = 'All Status';
  String _selectedConcernType = 'Job Service';

  // Action dropdown menu methods
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> task,
    Offset position,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // Check if task is pending to show assign option
    final taskStatus = task['status']?.toString().toLowerCase() ?? '';
    final isPending = taskStatus == 'pending';

    List<PopupMenuEntry<String>> menuItems = [
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
      // Only show assign action for pending tasks
      if (isPending)
        PopupMenuItem(
          value: 'assign',
          child: Row(
            children: [
              Icon(
                Icons.person_add_alt,
                color: Colors.orange[600],
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'Assign',
                style: TextStyle(color: Colors.orange[600], fontSize: 14),
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
    ];

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
      case 'assign':
        _assignTask(task);
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
    JobServiceConcernSlipDialog.show(context, task);
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

  // Assign task method
  void _assignTask(Map<String, dynamic> task) async {
    await _loadStaffMembers();
    
    if (!mounted) return;

    // Prepare staff names for the modal
    final staffNames = _staffMembers.map((staff) {
      final firstName = staff['first_name'] ?? '';
      final lastName = staff['last_name'] ?? '';
      final department = staff['department'] ?? '';
      
      String displayName = '$firstName $lastName';
      if (department.isNotEmpty) {
        displayName += ' ($department)';
      }
      return displayName;
    }).toList();

    // Show assign staff modal
    final result = await showModalBottomSheet<AssignResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignStaffBottomSheet(
        staff: staffNames,
        busyByStaff: {}, // You can implement availability checking here
      ),
    );

    if (result != null && mounted) {
      // Find the selected staff member's user ID
      final selectedStaffIndex = staffNames.indexOf(result.staffName);
      if (selectedStaffIndex >= 0 && selectedStaffIndex < _staffMembers.length) {
        final staffUserId = _staffMembers[selectedStaffIndex]['user_id'] ?? _staffMembers[selectedStaffIndex]['id'];
        
        if (staffUserId != null) {
          await _assignStaffToJobService(task, staffUserId, result.note);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Could not find staff member ID'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Load staff members from API
  Future<void> _loadStaffMembers() async {
    if (_isLoadingStaff) return;
    
    setState(() => _isLoadingStaff = true);
    
    try {
      final apiService = ApiService();
      final staffData = await apiService.getStaffMembers();
      
      if (mounted) {
        setState(() {
          _staffMembers = List<Map<String, dynamic>>.from(staffData);
          _isLoadingStaff = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading staff members: $e');
      if (mounted) {
        setState(() => _isLoadingStaff = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load staff members: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Assign staff to job service
  Future<void> _assignStaffToJobService(
    Map<String, dynamic> task,
    String staffUserId,
    String? note,
  ) async {
    try {
      final apiService = ApiService();
      
      // Use the serviceId (which should be the actual job service ID)
      final jobServiceId = task['serviceId'] ?? task['id'];
      
      await apiService.assignStaffToJobService(jobServiceId, staffUserId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff assigned successfully to ${task['serviceId']}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload the job services to reflect the changes
        await _loadJobServices();
      }
    } catch (e) {
      debugPrint('Error assigning staff to job service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign staff: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              onPressed: () async {
                Navigator.of(context).pop();
                // TODO: Implement actual deletion via API
                // For now, just remove from local list and reload
                setState(() {
                  _repairTasks.removeWhere((t) => t['id'] == task['id']);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task ${task['id']} deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
                // Reload data to reflect changes
                await _loadJobServices();
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
    140, // SERVICE ID
    140, // CONCERN ID
    140, // BUILDING & UNIT
    130, // SCHEDULE
    110, // STATUS
    100, // PRIORITY
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

            // Table Section - Repair Tasks (Job Service)
            _isLoading
                ? Container(
                    height: 400,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _errorMessage != null
                    ? Container(
                        height: 400,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading job services',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadJobServices,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildTableSection(),
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
          "Work Orders",
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
              child: const Text('Work Orders'),
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
              child: const Text('Job Service'),
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

          // Role Dropdown
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
                  value: _selectedRole,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue!;
                    });
                  },
                  items:
                      <String>[
                        'All Roles',
                        'Admin',
                        'Technician',
                        'Manager',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            'Role: $value',
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
                    });
                  },
                  items:
                      <String>[
                        'All Status',
                        'Pending',
                        'In Progress',
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
              onTap: _loadJobServices,
              borderRadius: BorderRadius.circular(20),
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
                            'Job Service',
                            'Concern Slip',
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
            child: _repairTasks.isEmpty
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
                          'No Job Services Found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'There are currently no job service requests to display.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                  columnSpacing: 50,
                  headingRowHeight: 56,
                  dataRowHeight: 64,
                  headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
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
                    DataColumn(label: _fixedCell(0, const Text("SERVICE ID"))),
                    DataColumn(label: _fixedCell(1, const Text("CONCERN ID"))),
                    DataColumn(
                      label: _fixedCell(2, const Text("BUILDING & UNIT")),
                    ),
                    DataColumn(label: _fixedCell(3, const Text("SCHEDULE"))),
                    DataColumn(label: _fixedCell(4, const Text("STATUS"))),
                    DataColumn(label: _fixedCell(5, const Text("PRIORITY"))),
                    DataColumn(label: _fixedCell(6, const Text(""))),
                  ],
                  rows:
                      _repairTasks.map((task) {
                        return DataRow(
                          cells: [
                            DataCell(
                              _fixedCell(
                                0,
                                _ellipsis(
                                  task['serviceId'],
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              _fixedCell(
                                1,
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
                              _fixedCell(2, _ellipsis(task['buildingUnit'])),
                            ),
                            DataCell(
                              _fixedCell(3, _ellipsis(task['schedule'])),
                            ),

                            // Chips get a fixed box too (and aligned left)
                            DataCell(
                              _fixedCell(4, _buildStatusChip(task['status'])),
                            ),
                            DataCell(
                              _fixedCell(
                                5,
                                _buildPriorityChip(task['priority']),
                              ),
                            ),

                            // Action menu cell (narrow, centered)
                            DataCell(
                              _fixedCell(
                                6,
                                Builder(
                                  builder: (context) {
                                    return IconButton(
                                      onPressed: () {
                                        final rbx =
                                            context.findRenderObject()
                                                as RenderBox;
                                        final position = rbx.localToGlobal(
                                          Offset.zero,
                                        );
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
          Divider(height: 1, thickness: 1, color: Colors.grey[400]),

          // Pagination Section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _repairTasks.isEmpty 
                    ? "No entries found"
                    : "Showing 1 to ${_repairTasks.length} of ${_repairTasks.length} entries",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: null,
                      icon: Icon(Icons.chevron_left, color: Colors.grey[400]),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text(
                          "01",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          "02",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.chevron_right, color: Colors.grey[600]),
                    ),
                  ],
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

  // Status Chip Widget
  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'In Progress':
        bgColor = const Color.fromARGB(49, 82, 131, 205);
        textColor = const Color.fromARGB(255, 0, 93, 232);
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
