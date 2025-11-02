import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../popupwidgets/cs_viewdetails_popup.dart';
import '../popupwidgets/set_resolution_type_popup.dart';
import '../services/api_service.dart';
import '../widgets/tags.dart';

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

  // Dropdown values for filtering
  String _selectedDepartment = 'All Departments';
  String _selectedStatus = 'All Status';
  String _selectedConcernType = 'Concern Slip';
  String _searchQuery = '';

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;

  // Sorting
  bool _sortAscending = true;

  @override
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
        
        // Sort by priority: High > Medium > Low
        _repairTasks.sort((a, b) {
          final priorityOrder = {'High': 0, 'Critical': 0, 'Medium': 1, 'Low': 2};
          final priorityA = priorityOrder[a['priority']] ?? 3;
          final priorityB = priorityOrder[b['priority']] ?? 3;
          return priorityA.compareTo(priorityB);
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

  String _capitalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'assessed':
        return 'Assessed';
      case 'sent':
        return 'Sent';
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
      case 'carpentry':
        return 'Carpentry';
      case 'masonry':
        return 'Masonry';
      case 'pest control':
      case 'pest_control':
        return 'Pest Control';
      default:
        return category ?? 'Other'; // Return the original category or 'Other'
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTasks =
          _repairTasks.where((task) {
            // Search filter - search in ID, title, building & unit
            bool matchesSearch =
                _searchQuery.isEmpty ||
                task['title'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                task['id'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                task['buildingUnit'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                task['location'].toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );

            // Status filter
            bool matchesStatus =
                _selectedStatus == 'All Status' ||
                task['status'] == _selectedStatus;

            // Department filter
            bool matchesDepartment = _selectedDepartment == 'All Departments';
            if (!matchesDepartment) {
              final taskDepartment = task['department'] ?? '';
              final mainDepartments = ['Electrical', 'Plumbing', 'Carpentry', 'Masonry'];
              
              if (_selectedDepartment == 'Other') {
                // If "Other" is selected, match departments not in the main list
                matchesDepartment = !mainDepartments.contains(taskDepartment);
              } else {
                // Match exact department
                matchesDepartment = taskDepartment == _selectedDepartment;
              }
            }

            return matchesSearch && matchesStatus && matchesDepartment;
          }).toList();

      // Reset to first page when filters change
      _currentPage = 1;
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;
      
      // Sort the filtered tasks by date requested
      _filteredTasks.sort((a, b) {
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

  // Check if resolution type can be set (status is assessed)
  bool _canSetResolutionType(Map<String, dynamic> task) {
    final status = task['status']?.toString().toLowerCase();
    return status == 'assessed';
  }

  // Action dropdown menu methods
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> task,
    Offset position,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final canSetResolution = _canSetResolutionType(task);

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
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: Colors.blue[600],
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'Edit',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.red[600],
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red[600],
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
    ConcernSlipDetailDialog.show(
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
    // Navigate to edit page or show edit dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final TextEditingController titleController = 
            TextEditingController(text: task['title']);
        final TextEditingController descController = 
            TextEditingController(text: task['description']);
        
        // Schedule availability controller
        DateTime? selectedSchedule;
        final scheduleAvailability = task['rawData']?['schedule_availability'] ?? task['dateRequested'];
        if (scheduleAvailability != null && scheduleAvailability.isNotEmpty) {
          try {
            if (scheduleAvailability.toString().contains('T')) {
              selectedSchedule = DateTime.parse(scheduleAvailability.toString());
            } else {
              final parts = scheduleAvailability.toString().split('-');
              if (parts.length == 3) {
                selectedSchedule = DateTime(
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                  int.parse(parts[2]),
                );
              }
            }
          } catch (e) {
            print('[Edit] Error parsing schedule: $e');
          }
        }
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Container(
            width: 700,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with blue background
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_document,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Concern Slip',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task['id'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          titleController.dispose();
                          descController.dispose();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Requester Details Section (Non-editable)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'REQUESTER DETAILS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[900],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildReadOnlyField(
                                      'Requested By',
                                      task['rawData']?['requester_name'] ?? 'N/A',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildReadOnlyField(
                                      'Date Requested',
                                      task['dateRequested'] ?? 'N/A',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildReadOnlyField(
                                      'Building & Unit',
                                      task['buildingUnit'] ?? 'N/A',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildReadOnlyField(
                                      'Department',
                                      task['department'] ?? 'N/A',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Title Field
                        Text(
                          'TITLE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'Enter concern slip title',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        
                        // Description Field
                        Text(
                          'DESCRIPTION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descController,
                          decoration: InputDecoration(
                            hintText: 'Enter concern slip description',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 5,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Provide a detailed description of the concern',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Schedule Availability Field (Editable)
                        Text(
                          'SCHEDULE AVAILABILITY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StatefulBuilder(
                          builder: (context, setDialogState) {
                            return InkWell(
                              onTap: () async {
                                final DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: selectedSchedule ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2030, 12),
                                );
                                
                                if (pickedDate != null) {
                                  setDialogState(() {
                                    selectedSchedule = pickedDate;
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[50],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        selectedSchedule != null 
                                            ? '${selectedSchedule!.day.toString().padLeft(2, '0')}/${selectedSchedule!.month.toString().padLeft(2, '0')}/${selectedSchedule!.year}'
                                            : 'Select schedule date',
                                        style: TextStyle(
                                          color: selectedSchedule != null
                                              ? Colors.black87
                                              : Colors.grey[500],
                                          fontSize: 14,
                                        ),
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
                ),
                
                // Footer with Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          titleController.dispose();
                          descController.dispose();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Validate inputs
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a title'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          
                          try {
                            // Update the task via API
                            final concernSlipId = task['rawData']?['id'] ?? 
                                                 task['rawData']?['_doc_id'];
                            
                            if (concernSlipId != null) {
                              // TODO: Implement API call when backend is ready
                              // await _apiService.updateConcernSlip(
                              //   concernSlipId,
                              //   {
                              //     'title': titleController.text,
                              //     'description': descController.text,
                              //     'schedule_availability': selectedSchedule?.toIso8601String(),
                              //   },
                              // );
                              
                              // For now, update locally
                              setState(() {
                                task['title'] = titleController.text;
                                task['description'] = descController.text;
                                if (selectedSchedule != null) {
                                  final formattedDate = '${selectedSchedule!.day.toString().padLeft(2, '0')}/${selectedSchedule!.month.toString().padLeft(2, '0')}/${selectedSchedule!.year}';
                                  task['dateRequested'] = formattedDate;
                                  if (task['rawData'] != null) {
                                    task['rawData']['schedule_availability'] = selectedSchedule!.toIso8601String();
                                  }
                                }
                                if (task['rawData'] != null) {
                                  task['rawData']['title'] = titleController.text;
                                  task['rawData']['description'] = descController.text;
                                }
                              });
                              
                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Text('${task['id']} updated successfully'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text('Failed to update: $e')),
                                    ],
                                  ),
                                  backgroundColor: Colors.red[600],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          } finally {
                            titleController.dispose();
                            descController.dispose();
                          }
                        },
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Delete task method
  void _deleteTask(Map<String, dynamic> task) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Container(
            width: 500,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with red background
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Concern Slip',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'This action cannot be undone',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Concern slip details
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.description, 
                                     color: Colors.grey[600], size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'CONCERN SLIP DETAILS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDeleteDetailRow('ID', task['id'] ?? 'N/A'),
                            const SizedBox(height: 8),
                            _buildDeleteDetailRow('Title', task['title'] ?? 'No Title'),
                            const SizedBox(height: 8),
                            _buildDeleteDetailRow('Department', task['department'] ?? 'N/A'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Footer with Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          
                          try {
                            // Delete via API
                            final concernSlipId = task['rawData']?['id'] ?? 
                                                 task['rawData']?['_doc_id'];
                            
                            if (concernSlipId != null) {
                              // TODO: Implement API call when backend is ready
                              // await _apiService.deleteConcernSlip(concernSlipId);
                              
                              // For now, remove locally
                              setState(() {
                                _repairTasks.removeWhere((t) => t['id'] == task['id']);
                                _applyFilters();
                              });
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text('${task['id']} deleted successfully'),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text('Failed to delete: $e')),
                                    ],
                                  ),
                                  backgroundColor: Colors.red[600],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_forever, size: 18),
                        label: const Text(
                          'Delete Permanently',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDeleteDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 12)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  final List<double> _colW = <double>[
    110, // CONCERN SLIP ID
    130, // TITLE
    110, // BUILDING & UNIT
    130, // DATE REQUESTED
    70, // PRIORITY
    100, // DEPARTMENT
    90, // STATUS
    90, // ACTION
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
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    
    if (startIndex >= _filteredTasks.length) return [];
    
    return _filteredTasks.sublist(
      startIndex,
      endIndex > _filteredTasks.length ? _filteredTasks.length : endIndex,
    );
  }

  int get _totalPages => _filteredTasks.isEmpty ? 1 : (_filteredTasks.length / _itemsPerPage).ceil();

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
              color: i == _currentPage ? const Color(0xFF1976D2) : Colors.grey[100],
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
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
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
                              label: _fixedCell(0, const Text("CONCERN SLIP ID")),
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
                                Row(
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
                              onSort: (columnIndex, ascending) {
                                _toggleSortOrder();
                              },
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
                              _getPaginatedTasks().map((task) {
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
                                        _ellipsis(task['buildingUnit']),
                                      ),
                                    ),
                                    DataCell(
                                      _fixedCell(
                                        3,
                                        _ellipsis(task['dateRequested']),
                                      ),
                                    ),

                                    // Chips get a fixed box too (and aligned left)
                                    DataCell(
                                      _fixedCell(
                                        4,
                                        PriorityTag(priority: task['priority']),
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
                                        StatusTag(status: task['status']),
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
                                        align: Alignment.centerLeft,
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
                  _filteredTasks.isEmpty 
                    ? "No entries found"
                    : "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage) > _filteredTasks.length ? _filteredTasks.length : _currentPage * _itemsPerPage} of ${_filteredTasks.length} entries",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 1 ? _previousPage : null,
                      icon: Icon(
                        Icons.chevron_left,
                        color: _currentPage > 1 ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                    ..._buildPageNumbers(),
                    IconButton(
                      onPressed: _currentPage < _totalPages ? _nextPage : null,
                      icon: Icon(
                        Icons.chevron_right,
                        color: _currentPage < _totalPages ? Colors.grey[600] : Colors.grey[400],
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
  // Helper method for read-only fields in edit dialog
  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
