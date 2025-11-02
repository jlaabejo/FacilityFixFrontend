import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../popupwidgets/wop_viewdetails_popup.dart';
import '../services/api_service.dart';

class RepairWorkOrderPermitPage extends StatefulWidget {
  const RepairWorkOrderPermitPage({super.key});

  @override
  State<RepairWorkOrderPermitPage> createState() =>
      _RepairWorkOrderPermitPageState();
}

class _RepairWorkOrderPermitPageState extends State<RepairWorkOrderPermitPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _repairTasks = [];
  String _errorMessage = '';
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
    _fetchWorkOrderPermits();
  }

  Future<void> _fetchWorkOrderPermits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final permits = await _apiService.getAllWorkOrderPermits();

      // Fetch concern slip data for each permit to get assessment and recommendation
      final tasks = <Map<String, dynamic>>[];

      for (var permit in permits) {
        Map<String, dynamic> taskData = {
          'serviceId': permit['formatted_id'] ?? permit['id'] ?? 'N/A',
          'id': permit['concern_slip_id'] ?? 'N/A',
          'permitId': permit['id'] ?? 'N/A', // Add permit ID for actions
          'title': permit['title'] ?? 'Untitled Work Order',
          'buildingUnit': permit['location'] ?? 'N/A',
          'schedule': _formatDateRange(
            permit['valid_from'],
            permit['valid_to'],
          ),
          'priority': _mapStatusToPriority(permit['status']),
          'status': _mapStatusToDisplay(permit['status']),
          'rawStatus':
              permit['status'] ?? 'pending', // Keep raw status for actions
          'concernId': permit['concern_slip_id'] ?? 'N/A',
          // Additional task data
          'dateRequested': _formatDate(permit['created_at']),
          'requestedBy': permit['requested_by'] ?? 'N/A',
          'department': permit['category'] ?? 'General',
          'description': permit['description'] ?? '',
          'validFrom': permit['valid_from'] ?? 'N/A',
          'validTo': permit['valid_to'] ?? 'N/A',
          'contractors': permit['contractors'] ?? [],
          'attachments': permit['attachments'] ?? [],
        };

        // Fetch concern slip data if concern_slip_id exists
        final concernSlipId = permit['concern_slip_id'];
        if (concernSlipId != null && concernSlipId != 'N/A') {
          try {
            final concernSlip = await _apiService.getConcernSlip(concernSlipId);

            // Add assessment and recommendation from concern slip
            taskData['assessment'] =
                concernSlip['staff_assessment'] ?? 'No assessment available';
            taskData['recommendation'] =
                concernSlip['staff_recommendation'] ??
                'No recommendation available';
            taskData['accountType'] =
                concernSlip['category'] ?? taskData['department'];

            print(
              '[Work Order Permits] Fetched concern slip $concernSlipId: assessment=${concernSlip['staff_assessment']}, recommendation=${concernSlip['staff_recommendation']}',
            );
          } catch (e) {
            print(
              '[Work Order Permits] Error fetching concern slip $concernSlipId: $e',
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

        tasks.add(taskData);
      }

      setState(() {
        _repairTasks = tasks;
        // Sort by priority: High/Critical first, then Medium, then Low
        _repairTasks.sort((a, b) {
          final priorityOrder = {
            'High': 0,
            'Critical': 0,
            'Medium': 1,
            'Low': 2,
          };
          final priorityA = priorityOrder[a['priority']] ?? 3;
          final priorityB = priorityOrder[b['priority']] ?? 3;
          return priorityA.compareTo(priorityB);
        });
        _isLoading = false;
        _currentPage = 1; // Reset to first page when loading new data
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching work order permits: $e';
        _isLoading = false;
      });
      print('[Work Order Permits] Error: $e');
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'N/A';
      }
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDateRange(dynamic startDate, dynamic endDate) {
    if (startDate == null && endDate == null) return 'N/A';

    final start = _formatDateWithTime(startDate);
    final end = _formatDateWithTime(endDate);

    if (start == 'N/A' && end == 'N/A') return 'N/A';
    if (start == 'N/A') return 'Until $end';
    if (end == 'N/A') return 'From $start';

    return '$start - $end';
  }

  String _formatDateWithTime(dynamic date) {
    if (date == null) return 'N/A';

    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'N/A';
      }

      // Format: "Oct 15, 2025 4:10 AM"
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months[dateTime.month - 1];
      final day = dateTime.day;
      final year = dateTime.year;
      final hour =
          dateTime.hour > 12
              ? dateTime.hour - 12
              : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';

      return '$month $day, $year $hour:$minute $ampm';
    } catch (e) {
      return 'N/A';
    }
  }

  String _mapStatusToPriority(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'High';
      case 'denied':
        return 'Low';
      case 'completed':
        return 'Low';
      default:
        return 'Medium';
    }
  }

  String _mapStatusToDisplay(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'In Progress';
      case 'denied':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return 'Pending';
    }
  }

  // Dropdown values for filtering
  String _selectedDepartment = 'All Departments';
  String _selectedStatus = 'All Status';
  String _searchQuery = '';
  String _selectedConcernType = 'Work Order Permit';

  // Map department categories to department names
  String _getDepartment(String category) {
    switch (category.toLowerCase()) {
      case 'electrical':
        return 'Electrical';
      case 'plumbing':
        return 'Plumbing';
      case 'carpentry':
        return 'Carpentry';
      case 'masonry':
        return 'Masonry';
      default:
        return category; // Return the original category
    }
  }

  // Apply current filters by resetting pagination and rebuilding the UI.
  // The actual filtering logic is applied in _getPaginatedTasks() and _totalPages.
  void _applyFilters() {
    setState(() {
      _currentPage = 1;
    });
  }

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;

  // Sorting
  bool _sortAscending = true;

  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;

      // Sort the repair tasks by date requested
      _repairTasks.sort((a, b) {
        final dateA = _parseDateForSort(a['dateRequested']);
        final dateB = _parseDateForSort(b['dateRequested']);

        if (_sortAscending) {
          return dateA.compareTo(dateB);
        } else {
          return dateB.compareTo(dateA);
        }
      });
    });
  }

  DateTime _parseDateForSort(String dateStr) {
    if (dateStr == 'N/A') return DateTime(1970);

    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime(1970);
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

    final isPending = task['rawStatus']?.toLowerCase() == 'pending';
    final isApproved = task['rawStatus']?.toLowerCase() == 'approved';

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
        // Show approve option only for pending permits
        if (isPending)
          PopupMenuItem(
            value: 'approve',
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green[600],
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Approve',
                  style: TextStyle(color: Colors.green[600], fontSize: 14),
                ),
              ],
            ),
          ),
        // Show deny option only for pending permits
        if (isPending)
          PopupMenuItem(
            value: 'deny',
            child: Row(
              children: [
                Icon(
                  Icons.cancel_outlined,
                  color: Colors.orange[700],
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Deny',
                  style: TextStyle(color: Colors.orange[700], fontSize: 14),
                ),
              ],
            ),
          ),
        // Show complete option for approved permits
        if (isApproved)
          PopupMenuItem(
            value: 'complete',
            child: Row(
              children: [
                Icon(Icons.done_all, color: Colors.blue[600], size: 18),
                const SizedBox(width: 12),
                Text(
                  'Mark Complete',
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
      case 'approve':
        _approvePermit(task);
        break;
      case 'deny':
        _denyPermit(task);
        break;
      case 'complete':
        _completePermit(task);
        break;
      case 'delete':
        _deleteTask(task);
        break;
    }
  }

  // View task method
  void _viewTask(Map<String, dynamic> task) {
    WorkOrderConcernSlipDialog.show(context, task);
  }

  // Approve permit method
  Future<void> _approvePermit(Map<String, dynamic> task) async {
    final permitId = task['permitId'];

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Approve Work Order Permit'),
          content: Text(
            'Are you sure you want to approve permit ${task['serviceId']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        // Call API to approve permit
        await _apiService.approveWorkOrderPermit(permitId);

        // Refresh the list
        await _fetchWorkOrderPermits();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Permit ${task['serviceId']} approved successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error approving permit: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Deny permit method
  Future<void> _denyPermit(Map<String, dynamic> task) async {
    final permitId = task['permitId'];
    final reasonController = TextEditingController();

    // Show dialog to get denial reason
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deny Work Order Permit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to deny permit ${task['serviceId']}?',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for denial',
                  border: OutlineInputBorder(),
                  hintText: 'Enter reason...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Deny'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      try {
        setState(() => _isLoading = true);

        // Call API to deny permit
        await _apiService.denyWorkOrderPermit(permitId, reasonController.text);

        // Refresh the list
        await _fetchWorkOrderPermits();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permit ${task['serviceId']} denied'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error denying permit: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Complete permit method
  Future<void> _completePermit(Map<String, dynamic> task) async {
    final permitId = task['permitId'];
    final notesController = TextEditingController();

    // Show dialog to get completion notes
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete Work Order Permit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mark permit ${task['serviceId']} as completed?'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Completion Notes (Optional)',
                  hintText: 'Enter any notes about the completion...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        // Call API to complete permit with notes
        await _apiService.completeWorkOrderPermit(
          permitId,
          completionNotes:
              notesController.text.isNotEmpty ? notesController.text : null,
        );

        // Refresh the list
        await _fetchWorkOrderPermits();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permit ${task['serviceId']} marked as completed'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error completing permit: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
              onPressed: () {
                Navigator.of(context).pop();
                // Remove task from list
                setState(() {
                  _repairTasks.removeWhere((t) => t['id'] == task['id']);
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
    110, // WORK ORDER ID
    190, // TITLE
    110, // BUILDING & UNIT
    120, // DATE REQUESTED
    85, // PRIORITY
    105, // DEPARTMENT
    95, // STATUS
    105, // ACTION
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

  // Pagination helper methods
  List<Map<String, dynamic>> _getPaginatedTasks() {
    // Apply filters first
    List<Map<String, dynamic>> filteredTasks =
        _repairTasks.where((task) {
          // Search filter - search in ID, title, and building & unit
          bool matchesSearch = true;
          if (_searchQuery.isNotEmpty) {
            final searchLower = _searchQuery.toLowerCase();
            final id = task['id']?.toString().toLowerCase() ?? '';
            final title = task['title']?.toString().toLowerCase() ?? '';
            final buildingUnit =
                task['buildingUnit']?.toString().toLowerCase() ?? '';

            matchesSearch =
                id.contains(searchLower) ||
                title.contains(searchLower) ||
                buildingUnit.contains(searchLower);
          }

          // Department filter
          bool matchesDepartment = true;
          if (_selectedDepartment != 'All Departments') {
            final taskDepartment = _getDepartment(
              task['department']?.toString() ?? '',
            );
            final mainDepartments = [
              'Electrical',
              'Plumbing',
              'Carpentry',
              'Masonry',
            ];

            if (_selectedDepartment == 'Other') {
              // If "Other" is selected, match departments not in the main list
              matchesDepartment = !mainDepartments.contains(taskDepartment);
            } else {
              // Match exact department
              matchesDepartment = taskDepartment == _selectedDepartment;
            }
          }

          // Status filter
          bool matchesStatus = true;
          if (_selectedStatus != 'All Status') {
            final taskStatus = task['status']?.toString() ?? '';
            matchesStatus =
                taskStatus.toLowerCase() == _selectedStatus.toLowerCase();
          }

          return matchesSearch && matchesDepartment && matchesStatus;
        }).toList();

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= filteredTasks.length) return [];

    return filteredTasks.sublist(
      startIndex,
      endIndex > filteredTasks.length ? filteredTasks.length : endIndex,
    );
  }

  int get _totalPages {
    // Apply same filters for total page calculation
    List<Map<String, dynamic>> filteredTasks =
        _repairTasks.where((task) {
          bool matchesSearch = true;
          if (_searchQuery.isNotEmpty) {
            final searchLower = _searchQuery.toLowerCase();
            final id = task['id']?.toString().toLowerCase() ?? '';
            final title = task['title']?.toString().toLowerCase() ?? '';
            final buildingUnit =
                task['buildingUnit']?.toString().toLowerCase() ?? '';

            matchesSearch =
                id.contains(searchLower) ||
                title.contains(searchLower) ||
                buildingUnit.contains(searchLower);
          }

          bool matchesDepartment = true;
          if (_selectedDepartment != 'All Departments') {
            final taskDepartment = _getDepartment(
              task['department']?.toString() ?? '',
            );
            final mainDepartments = [
              'Electrical',
              'Plumbing',
              'Carpentry',
              'Masonry',
            ];

            if (_selectedDepartment == 'Other') {
              // If "Other" is selected, match departments not in the main list
              matchesDepartment = !mainDepartments.contains(taskDepartment);
            } else {
              // Match exact department
              matchesDepartment = taskDepartment == _selectedDepartment;
            }
          }

          bool matchesStatus = true;
          if (_selectedStatus != 'All Status') {
            final taskStatus = task['status']?.toString() ?? '';
            matchesStatus =
                taskStatus.toLowerCase() == _selectedStatus.toLowerCase();
          }

          return matchesSearch && matchesDepartment && matchesStatus;
        }).toList();

    return filteredTasks.isEmpty
        ? 1
        : (filteredTasks.length / _itemsPerPage).ceil();
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pageButtons = [];

    // Show max 5 page numbers at a time
    int startPage = _currentPage - 2;
    int endPage = _currentPage + 2;

    if (startPage < 1) {
      startPage = 1;
      endPage = 5;
    }

    if (endPage > _totalPages) {
      endPage = _totalPages;
      startPage = _totalPages - 4;
    }

    if (startPage < 1) startPage = 1;

    for (int i = startPage; i <= endPage; i++) {
      pageButtons.add(
        GestureDetector(
          onTap: () => _goToPage(i),
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color:
                  i == _currentPage
                      ? const Color(0xFF1976D2)
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                i.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: i == _currentPage ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return pageButtons;
  }

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

            // Table Section - Repair Tasks (Work Order Permit)
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
              child: const Text('Work Order Permit'),
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
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 1; // Reset to first page when searching
                  });
                },
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
              onTap: _fetchWorkOrderPermits,
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
                  "Work Order Permits",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
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
                              context.go(
                                '/adminweb/pages/adminrepair_wop_page',
                              );
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
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey[400]),

          // Loading/Error/Data Display
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
                            style: TextStyle(color: Colors.red[700]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchWorkOrderPermits,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : _repairTasks.isEmpty
                    ? const Center(
                      child: Text(
                        'No work order permits found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 40,
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
                              label: _fixedCell(0, const Text("WORK ORDER ID")),
                            ),
                            DataColumn(
                              label: _fixedCell(1, const Text("TITLE")),
                            ),
                            DataColumn(
                              label: _fixedCell(
                                2,
                                const Text("BUILDING & UNIT"),
                              ),
                            ),
                            DataColumn(
                              label: _fixedCell(
                                3,
                                const Text("DATE REQUESTED"),
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
                            DataColumn(
                              label: _fixedCell(7, const Text("")),
                            ),
                          ],
                          rows:
                              _getPaginatedTasks().map((task) {
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
                                      _fixedCell(1, _ellipsis(task['title'])),
                                    ),
                                    DataCell(
                                      _fixedCell(
                                        2,
                                        _ellipsis(task['buildingUnit']),
                                      ),
                                    ),
                                    DataCell(
                                      _fixedCell(
                                        3,
                                        _ellipsis(task['dateRequested']),
                                      ),
                                    ),

                                    // Priority chip
                                    DataCell(
                                      _fixedCell(
                                        4,
                                        _buildPriorityChip(task['priority']),
                                      ),
                                    ),

                                    // Department
                                    DataCell(
                                      _fixedCell(
                                        5,
                                        _ellipsis(task['department']),
                                      ),
                                    ),

                                    // Status chip
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
                      : "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage) > _repairTasks.length ? _repairTasks.length : _currentPage * _itemsPerPage} of ${_repairTasks.length} entries",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 1 ? _previousPage : null,
                      icon: Icon(
                        Icons.chevron_left,
                        color:
                            _currentPage > 1
                                ? Colors.grey[600]
                                : Colors.grey[400],
                      ),
                    ),
                    ..._buildPageNumbers(),
                    IconButton(
                      onPressed: _currentPage < _totalPages ? _nextPage : null,
                      icon: Icon(
                        Icons.chevron_right,
                        color:
                            _currentPage < _totalPages
                                ? Colors.grey[600]
                                : Colors.grey[400],
                      ),
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
      case 'Pending Review':
        bgColor = Colors.grey[100]!;
        textColor = Colors.black;
        break;
      default:
        bgColor = Colors.grey[400]!;
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
