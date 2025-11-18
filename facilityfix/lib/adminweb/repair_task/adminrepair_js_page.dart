import 'package:facilityfix/adminweb/widgets/tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../services/api_service.dart';
import '../widgets/delete_popup.dart';
import 'pop_up/js_viewdetails_popup.dart';
import 'pop_up/edit_popup.dart';

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
  List<Map<String, dynamic>> _filteredTasks = [];

  // Pagination state
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // Sorting state
  bool _sortAscending = false;

  // Get paginated tasks
  List<Map<String, dynamic>> get _paginatedTasks {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(
      0,
      _filteredTasks.length,
    );

    if (startIndex >= _filteredTasks.length) {
      return [];
    }

    return _filteredTasks.sublist(startIndex, endIndex);
  }

  // Get total pages
  int get _totalPages {
    return (_filteredTasks.length / _itemsPerPage).ceil();
  }

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
  }

  // Error handling
  String? _errorMessage;

  // Dropdown values for filtering
  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All Status';
  String _selectedConcernType = 'Job Service';
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

      // Process each job service and fetch concern slip data
      final tasks = <Map<String, dynamic>>[];

      for (var jobService in jobServices) {
        Map<String, dynamic> taskData = _processJobServiceData(jobService);

        // Fetch concern slip data to get assessment and recommendation
        final concernSlipId = jobService['concern_slip_id'];
        if (concernSlipId != null && concernSlipId.toString().isNotEmpty) {
          try {
            final concernSlip = await apiService.getConcernSlip(
              concernSlipId.toString(),
            );

            // Add assessment and recommendation from concern slip
            taskData['assessment'] =
                concernSlip['staff_assessment'] ??
                concernSlip['assessment'] ??
                'No assessment available';
            taskData['recommendation'] =
                concernSlip['staff_recommendation'] ??
                'No recommendation available';
            taskData['concernId'] =
                concernSlip['formatted_id'] ?? concernSlipId.toString();

            print(
              '[Job Services] Fetched concern slip $concernSlipId: assessment=${concernSlip['staff_assessment']}, recommendation=${concernSlip['staff_recommendation']}',
            );
          } catch (e) {
            print(
              '[Job Services] Error fetching concern slip $concernSlipId: $e',
            );
            // Set default values if concern slip fetch fails
            taskData['assessment'] = 'Unable to load assessment';
            taskData['recommendation'] = 'Unable to load recommendation';
          }
        } else {
          // No concern slip ID, use defaults
          taskData['assessment'] = 'No assessment available';
          taskData['recommendation'] = 'No recommendation available';
        }

        // Directly check for assessment on the job service itself
        if (jobService['assessment'] != null) {
          taskData['assessment'] = jobService['assessment'];
        }

        tasks.add(taskData);
      }

      if (mounted) {
        setState(() {
          _repairTasks = tasks;
          _filteredTasks = List.from(tasks);
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading job services: $e');
      if (mounted) {
        setState(() {
          _repairTasks = [];
          _filteredTasks = [];
          _isLoading = false;
          _errorMessage = 'Failed to load job services: $e';
        });
      }
    }
  }

  // Apply filters
  void _applyFilters() {
    setState(() {
      _filteredTasks =
          _repairTasks.where((task) {
            // Category filter
            if (_selectedCategory != 'All Categories') {
              final taskCategory =
                  (task['category']?.toString().toLowerCase() ?? '').trim();
              final selectedCategory = _selectedCategory.trim().toLowerCase();

              if (selectedCategory == 'others') {
                // For "Other", match anything NOT in the main categories
                if ([
                  'carpentry',
                  'electrical',
                  'masonry',
                  'plumbing',
                ].contains(taskCategory)) {
                  return false;
                }
              } else {
                // Match exact category (case-insensitive)
                if (taskCategory != selectedCategory) {
                  return false;
                }
              }
            }

            // Status filter
            if (_selectedStatus != 'All Status') {
              final taskStatus = task['status']?.toString() ?? '';
              if (taskStatus != _selectedStatus) {
                return false;
              }
            }

            return true;
          }).toList();

      // Reset to first page when filters change
      _currentPage = 0;
    });
  }

  // Process job service data from API to match UI format
  Map<String, dynamic> _processJobServiceData(Map<String, dynamic> jobService) {
    // Format Job Service ID with JS- prefix FOR DISPLAY ONLY
    String serviceId = 'N/A';
    if (jobService['formatted_id'] != null) {
      serviceId = jobService['formatted_id'].toString();
    } else if (jobService['id'] != null) {
      final id = jobService['id'].toString();
      // Add JS- prefix if not already present
      serviceId = id.startsWith('JS-') ? id : 'JS-$id';
    }

    return {
      'serviceId': serviceId, // Display ID with "JS-" prefix
      'id': jobService['id'] ?? 'N/A', // Store raw UUID for API calls
      'buildingUnit': jobService['location'] ?? jobService['unit_id'] ?? 'N/A',
      'schedule': _formatDate(
        jobService['scheduled_date'] ?? jobService['created_at'],
      ),
      'priority': _capitalizePriority(jobService['priority']),
      'status': _mapStatus(jobService['status'], jobService['workflow']),

      // Additional task data
      'requestedBy':
          jobService['requested_by_name'] ??
          jobService['requester_name'] ??
          jobService['reported_by'] ??
          'N/A',
      'title': jobService['title'] ?? 'Job Service Request',
      'dateRequested': _formatDate(jobService['created_at']),
      'created_by': jobService['created_by'] ?? 'N/A',
      'department': _mapCategoryToDepartment(jobService['category']),
      'description': jobService['description'] ?? '',
      'concern_slip_id': jobService['concern_slip_id'], // Add concern slip ID
      'additionalNotes':
          jobService['additional_notes'] ??
          jobService['notes'] ??
          jobService['description'] ??
          '',
      'rawData': jobService, // Store raw data for detailed view and checks
      // assessment and recommendation will be fetched from concern slip in _loadJobServices
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

  String _mapStatus(dynamic status, dynamic workflow) {
    // Custom mapping logic for Job Service (JS)
    final s = (status ?? '').toString().toLowerCase();

    if (s == 'completed') return 'Completed';
    if (s == 'cancelled') return 'Cancelled';
    if (s == 'rejected') return 'Rejected';
    if (s == 'returned_to_tenant') return 'Returned to Tenant';
    if (s == 'pending') return 'Pending';
    if (s == 'assigned') return 'To Inspect';
    if (s == 'in_progress') return 'In Progress';
    if (s == 'assessed') return 'Assessed';
    if (s == 'sent' || s == 'sent_to_client') return 'Sent to Client';
    if (s == 'approved') return 'Approved';
    // fallback
    return 'Pending';
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
        return priority
            .split('_')
            .map(
              (word) =>
                  word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
            )
            .join(' ');
    }
  }

  String _mapCategoryToDepartment(String? category) {
    if (category == null) return 'N/A';
    switch (category.toLowerCase()) {
      case 'electrical':
        return 'Electrical';
      case 'plumbing':
        return 'Plumbing';
      case 'hvac':
        return 'HVAC';
      case 'carpentry':
        return 'Carpentry';
      case 'masonry':
        return 'Masonry';
      default:
        return 'Other';
    }
  }

  // Action dropdown menu methods
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> task,
    Offset position,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    List<PopupMenuEntry<String>> menuItems = [
      PopupMenuItem(
        value: 'view',
        child: Row(
          children: [
            Icon(Icons.visibility_outlined, color: Colors.green[600], size: 18),
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
    // Show the Job Service + Concern Slip dialog with stepper (dual-state view)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return JobServiceConcernSlipDialog(
          task: task,
          onAssignmentComplete: () {
            // Reload the job services after assignment
            _loadJobServices();
          },
        );
      },
    );
  }

  // Edit task method
  void _editTask(Map<String, dynamic> task) {
    // Open the EditDialog for job services and refresh on success
    final raw = task['rawData'] ?? task;
    EditDialog.show(
      context,
      type: EditDialogType.jobService,
      task: raw as Map<String, dynamic>,
      onSave: () {},
    ).then((result) {
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Changes saved for: ${task['serviceId'] ?? task['id']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadJobServices();
      }
    });
  }

  // Delete task method
  void _deleteTask(Map<String, dynamic> task) async {
    final confirmed = await showDeleteDialog(
      context,
      itemName: 'Task',
      description:
          'Are you sure you want to delete this task ${task['id']}? This action cannot be undone. All associated data will be permanently removed from the system.',
    );

    if (confirmed) {
      try {
        // Determine backend id (prefer rawData._doc_id or rawData.id if available)
        final raw = task['rawData'] as Map<String, dynamic>?;
        final idToDelete = raw?['_doc_id'] ?? raw?['id'] ?? task['id'];

        if (idToDelete == null) {
          throw Exception('Unable to determine task id to delete');
        }

        final apiService = ApiService();
        await apiService.deleteJobService(idToDelete.toString());

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
        _loadJobServices();
      } catch (e) {
        print('[AdminRepairJobServicePage] Error deleting job service: $e');
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
    110, // JOB SERVICE ID
    150, // TITLE
    130, // DATE REQUESTED
    100, // BUILDING & UNIT
    70, // PRIORITY
    80, // DEPARTMENT
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

            // Table Section - Repair Tasks (Job Service)
            _isLoading
                ? Container(
                  height: 400,
                  child: const Center(child: CircularProgressIndicator()),
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
                        'Others',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value == 'All Categories'
                                ? value
                                : 'Category: $value',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Status Dropdown - width adapts to content
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120, maxWidth: 300),
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
                    isDense: true,
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
                          'To Inspect',
                          'In Progress',
                          'Assessed',
                          'Sent to Client',
                          'Approved',
                          'Rejected',
                          'Completed',
                          'Returned to Tenant',
                          'Cancelled',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              'Status: $value',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                  ),
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
              onTap: _loadJobServices,
              borderRadius: BorderRadius.circular(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: Colors.blue[600],
                  ),
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
                            'Job Service',
                            'Concern Slip',
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
                _repairTasks.isEmpty
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
                    : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
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
                                    label: _fixedCell(
                                      0,
                                      const Text("JOB SERVICE ID"),
                                    ),
                                  ),
                                  DataColumn(
                                    label: _fixedCell(
                                      1,
                                      const Text("TASK TITLE"),
                                    ),
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
                                      const Text("BUILDING / UNIT"),
                                    ),
                                  ),
                                  DataColumn(
                                    label: _fixedCell(
                                      4,
                                      const Text("PRIORITY"),
                                    ),
                                  ),
                                  DataColumn(
                                    label: _fixedCell(
                                      5,
                                      const Text("DEPARTMENT"),
                                    ),
                                  ),
                                  DataColumn(
                                    label: _fixedCell(6, const Text("STATUS")),
                                  ),
                                  DataColumn(
                                    label: _fixedCell(7, const Text("")),
                                  ),
                                ],
                                rows:
                                    _paginatedTasks.map((task) {
                                      return DataRow(
                                        cells: [
                                          // SERVICE ID
                                          DataCell(
                                            _fixedCell(
                                              0,
                                              _ellipsis(
                                                task['serviceId'] ?? 'N/A',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // TASK TITLE
                                          DataCell(
                                            _fixedCell(
                                              1,
                                              _ellipsis(
                                                task['title'] ??
                                                    'Job Service Request',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // DATE REQUESTED
                                          DataCell(
                                            _fixedCell(
                                              2,
                                              _ellipsis(
                                                task['dateRequested'] ?? 'N/A',
                                              ),
                                            ),
                                          ),

                                          // BUILDING / UNIT
                                          DataCell(
                                            _fixedCell(
                                              3,
                                              _ellipsis(
                                                task['buildingUnit'] ?? 'N/A',
                                              ),
                                            ),
                                          ),

                                          // PRIORITY
                                          DataCell(
                                            _fixedCell(
                                              4,
                                              _buildPriorityChip(
                                                task['priority'] ?? 'Medium',
                                              ),
                                            ),
                                          ),

                                          // DEPARTMENT
                                          DataCell(
                                            _fixedCell(
                                              5,
                                              DepartmentTag(
                                                task['department'] ?? 'N/A',
                                              ),
                                            ),
                                          ),

                                          // STATUS
                                          DataCell(
                                            _fixedCell(
                                              6,
                                              _buildStatusChip(
                                                task['status'] ?? 'Pending',
                                              ),
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
                                                          .localToGlobal(
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
                        // Pagination Section
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey[400],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _filteredTasks.isEmpty
                                    ? "No entries"
                                    : "Showing ${_currentPage * _itemsPerPage + 1} to ${((_currentPage + 1) * _itemsPerPage).clamp(0, _filteredTasks.length)} of ${_filteredTasks.length} ${_filteredTasks.length == 1 ? 'entry' : 'entries'}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: [
                                  // Previous button
                                  IconButton(
                                    onPressed:
                                        _currentPage > 0
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
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
                                            color:
                                                _currentPage == index
                                                    ? Colors.blue
                                                    : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color:
                                                  _currentPage == index
                                                      ? Colors.blue
                                                      : Colors.grey[300]!,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color:
                                                  _currentPage == index
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
                                    onPressed:
                                        _currentPage < _totalPages - 1
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
