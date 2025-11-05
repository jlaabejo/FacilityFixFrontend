import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart'; 
import '../../services/api_services.dart'; 
import '../../utils/ui_format.dart';
import 'internalmaintenance_form.dart';


class InternalTaskViewPage extends StatefulWidget {
  /// Deep-linkable view with optional edit mode.
  final String taskId;
  final Map<String, dynamic>? initialTask;
  final bool startInEditMode;

  const InternalTaskViewPage({
    super.key,
    required this.taskId,
    this.initialTask,
    this.startInEditMode = false,
  });

  @override
  State<InternalTaskViewPage> createState() => _InternalTaskViewPageState();
}

class _InternalTaskViewPageState extends State<InternalTaskViewPage> {
  // ------------------------ API Service ------------------------
  final APIService _apiService = APIService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _taskData;

  // ------------------------ Navigation helpers ------------------------
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
                context.go('/');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------ Edit mode + form state ------------------------
  final _formKey = GlobalKey<FormState>();
  bool _isEditMode = false;

  // Title controller
  final _titleCtrl = TextEditingController();

  // Basic Information controllers
  final _departmentCtrl = TextEditingController();
  final _createdByCtrl = TextEditingController();
  final _estimatedDurationCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // Schedule controllers
  final _recurrenceCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _nextDueCtrl = TextEditingController();

  // Assignment controllers
  final _assigneeNameCtrl = TextEditingController();
  final _assigneeDeptCtrl = TextEditingController();

  // Staff selection for assignment
  List<Map<String, dynamic>> _staffList = [];
  String? _selectedStaffId;
  String? _selectedStaffName;
  bool _isLoadingStaff = false;

  // Notifications controllers (NOW EDITABLE)
  final _adminNotifyCtrl = TextEditingController();
  final _staffNotifyCtrl = TextEditingController();

  // Header chips (view-only)
  List<String> _tags = const [];

  // Attachments sourced from backend/task payload
  final List<Map<String, String?>> _attachments = [];

  // Inventory items
  List<Map<String, dynamic>> _selectedInventoryItems = [];
  List<Map<String, dynamic>> _linkedInventoryRequests = []; // Existing requests from backend

  // Snapshot used for Cancel
  late Map<String, String> _original;

  // Sample checklist (view-only for now)
  final List<Map<String, dynamic>> _checklistItems = [];

  // ------------------------ Init/Dispose ------------------------
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Fetch task data from backend if not provided
      if (widget.initialTask == null) {
        // Get all maintenance tasks and find the one with matching ID
        final allTasks = await _apiService.getAllMaintenance();
        _taskData = allTasks.firstWhere(
          (task) => (task['formatted_id'] == widget.taskId || task['id'] == widget.taskId),
          orElse: () => throw Exception('Task not found with ID: ${widget.taskId}'),
        );
      } else {
        _taskData = widget.initialTask;
      }

      // Load available inventory items
      await _loadInventoryItems();

      // Load linked inventory requests
      await _loadLinkedInventoryRequests();

      // Load staff members for assignment
      await _loadStaffMembers();

      _populateFields();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('[v0] Error initializing task data: $e');
      setState(() {
        _error = 'Failed to load task data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStaffMembers() async {
    setState(() {
      _isLoadingStaff = true;
    });

    try {
      String? taskCategory = _taskData?['category']?.toString().toLowerCase();
      String? department;

      // Map category to department
      switch (taskCategory) {
        case 'electrical':
          department = 'electrical';
          break;
        case 'plumbing':
          department = 'plumbing';
          break;
        case 'hvac':
          department = 'hvac';
          break;
        case 'carpentry':
          department = 'carpentry';
          break;
        case 'maintenance':
          department = 'maintenance';
          break;
        case 'security':
          department = 'security';
          break;
        case 'fire_safety':
          department = 'fire_safety';
          break;
        default:
          department = null;
      }

      final staffData = await _apiService.getStaffMembers(
        department: department,
        availableOnly: true,
      );

      setState(() {
        _staffList = staffData;
        _isLoadingStaff = false;
      });

      print('[InternalTaskView] Loaded ${_staffList.length} staff members');
    } catch (e) {
      print('[InternalTaskView] Error loading staff: $e');
      setState(() {
        _isLoadingStaff = false;
      });
    }
  }

  Future<void> _loadLinkedInventoryRequests() async {
    try {
      print('[v0] Loading inventory requests for task ${widget.taskId}');
      final response = await _apiService.getInventoryRequestsByMaintenanceTask(widget.taskId);

      print('[v0] Inventory requests response: $response');

      if (response['success'] == true && response['data'] != null) {
        final requests = List<Map<String, dynamic>>.from(response['data']);

        // Enrich inventory requests with item details
        for (var request in requests) {
          if (request['inventory_id'] != null) {
            try {
              final itemData = await _apiService.getInventoryItemById(request['inventory_id']);
              if (itemData != null) {
                request['item_name'] = itemData['item_name'];
                request['item_code'] = itemData['item_code'];
              }
            } catch (e) {
              print('[v0] Error loading inventory item details: $e');
              // Continue without item details
            }
          }
        }

        setState(() {
          _linkedInventoryRequests = requests;
        });
        print('[v0] Loaded ${_linkedInventoryRequests.length} inventory requests for task ${widget.taskId}');
      } else {
        print('[v0] No inventory requests found or invalid response');
      }
    } catch (e) {
      print('[v0] Error loading linked inventory requests: $e');
      // Don't fail the whole form if inventory requests fail to load
    }
  }

  Future<void> _loadInventoryItems() async {
    try {
      final response = await _apiService.getInventoryItems();
      
      if (response['success'] == true && response['data'] != null) {
        // Inventory items loaded successfully but not stored
        // as _availableInventoryItems field was removed
        print('[v0] Loaded ${(response['data'] as List).length} inventory items');
      }
    } catch (e) {
      print('[v0] Error loading inventory items: $e');
      // Don't fail the whole form if inventory loading fails
    }
  }

  void _populateFields() {
    final Map<String, dynamic> seed = _taskData ?? {};

    // Safe setter with multiple possible keys
    void setText(TextEditingController c, List<String> keys) {
      for (final key in keys) {
        final value = seed[key];
        if (value != null && value.toString().isNotEmpty) {
          c.text = value.toString();
          return;
        }
      }
      c.text = '';
    }

    // Assign from incoming data with fallback keys
    setText(_titleCtrl, ['task_title', 'taskTitle', 'title']);
    setText(_departmentCtrl, ['department', 'assigneeDept']);
  setText(_createdByCtrl, ['created_by', 'assigneeName', 'assigned_staff_name', 'createdBy']);
    setText(_estimatedDurationCtrl, ['estimated_duration', 'estimatedDuration']);
    setText(_locationCtrl, ['location']);
    setText(_descriptionCtrl, ['task_description', 'description']);
    setText(_recurrenceCtrl, ['recurrence_type', 'recurrence']);
    setText(_startDateCtrl, ['scheduled_date', 'startDate', 'start_date']);
    setText(_nextDueCtrl, ['next_occurrence', 'nextDueDate', 'next_due_date']);
    // Be generous with fallback keys for assignee name & department
    setText(_assigneeNameCtrl, [
      'assigned_staff_name',
      'assigneeName',
      'assigned_to',
      'assignee',
      'assignee_name',
      'created_by'
    ]);
    setText(_assigneeDeptCtrl, [
      'department',
      'assigneeDept',
      'assignee_department',
      'assigned_staff_department',
      'staff_department'
    ]);
  setText(_adminNotifyCtrl, ['admin_notification', 'adminNotify', 'remarks']);
    setText(_staffNotifyCtrl, ['staff_notification', 'staffNotify']);

    // Set selected staff ID if available
    // Try to find the staff member in the staff list
    final assignedTo = seed['assigned_to'];
    if (assignedTo != null && assignedTo.toString().isNotEmpty) {
      final assignedValue = assignedTo.toString();

      // First, try to find by user_id or id (exact match)
      var matchedStaff = _staffList.firstWhere(
        (staff) => (staff['user_id'] ?? staff['id']) == assignedValue,
        orElse: () => {},
      );

      // If not found by ID, try to find by name
      if (matchedStaff.isEmpty) {
        matchedStaff = _staffList.firstWhere(
          (staff) {
            final firstName = staff['first_name'] ?? '';
            final lastName = staff['last_name'] ?? '';
            final fullName = '$firstName $lastName'.trim();
            return fullName == assignedValue;
          },
          orElse: () => {},
        );
      }

      // Set the selected staff ID if we found a match
      if (matchedStaff.isNotEmpty) {
        _selectedStaffId = (matchedStaff['user_id'] ?? matchedStaff['id'] ?? '').toString();
        _selectedStaffName = _assigneeNameCtrl.text;
      }
    }

    void addAttachment(dynamic entry) {
      if (entry == null) return;
      if (entry is String && entry.isNotEmpty) {
        _attachments.add({
          'name': entry.split('/').isNotEmpty ? entry.split('/').last : entry,
          'url': entry,
        });
      } else if (entry is Map) {
        final name = entry['name'] ?? entry['filename'] ?? entry['title'];
        final url = entry['url'] ?? entry['path'] ?? entry['downloadUrl'];
        if (name != null || url != null) {
          _attachments.add({
            'name': name?.toString() ?? 'Attachment',
            'url': url?.toString(),
          });
        }
      }
    }

    void hydrateAttachments(dynamic raw) {
      if (raw is List) {
        for (final entry in raw) {
          addAttachment(entry);
        }
      } else if (raw is Map && raw['items'] is List) {
        for (final entry in raw['items']) {
          addAttachment(entry);
        }
      } else if (raw is String) {
        addAttachment(raw);
      }
    }

    hydrateAttachments(seed['attachments']);
    hydrateAttachments(seed['photos']);

    final checklistData = seed['checklist_completed'] ?? seed['checklistItems'];
    if (checklistData != null && checklistData is List) {
      _checklistItems.clear();
      for (var item in checklistData) {
        _checklistItems.add({
          'text': item['task'] ?? item['description'] ?? '',
          'completed': item['completed'] ?? false,
        });
      }
    }

    // Tags - try to get from data or use defaults
    final dynamic t = seed['tags'];
    _tags =
        (t is List && t.isNotEmpty)
            ? t.map((e) => e.toString()).toList()
            : <String>['Maintenance', 'Internal'];

    _original = _takeSnapshot();
    _isEditMode = widget.startInEditMode;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _departmentCtrl.dispose();
    _createdByCtrl.dispose();
    _estimatedDurationCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _recurrenceCtrl.dispose();
    _startDateCtrl.dispose();
    _nextDueCtrl.dispose();
    _assigneeNameCtrl.dispose();
    _assigneeDeptCtrl.dispose();
    _adminNotifyCtrl.dispose();
    _staffNotifyCtrl.dispose();
    super.dispose();
  }

  // ------------------------ Snapshot & Handlers ------------------------
  Map<String, String> _takeSnapshot() => {
    'title': _titleCtrl.text,
    'department': _departmentCtrl.text,
    'createdBy': _createdByCtrl.text,
    'estimatedDuration': _estimatedDurationCtrl.text,
    'location': _locationCtrl.text,
    'description': _descriptionCtrl.text,
    'recurrence': _recurrenceCtrl.text,
    'startDate': _startDateCtrl.text,
    'nextDueDate': _nextDueCtrl.text,
    'assigneeName': _assigneeNameCtrl.text,
    'assigneeDept': _assigneeDeptCtrl.text,
    'adminNotify': _adminNotifyCtrl.text,
    'staffNotify': _staffNotifyCtrl.text,
    'selectedStaffId': _selectedStaffId ?? '',
  };

  void _enterEditMode() => setState(() => _isEditMode = true);

  void _cancelEdit() {
    // Revert to snapshot
    _titleCtrl.text = _original['title']!;
    _departmentCtrl.text = _original['department']!;
    _createdByCtrl.text = _original['createdBy']!;
    _estimatedDurationCtrl.text = _original['estimatedDuration']!;
    _locationCtrl.text = _original['location']!;
    _descriptionCtrl.text = _original['description']!;
    _recurrenceCtrl.text = _original['recurrence']!;
    _startDateCtrl.text = _original['startDate']!;
    _nextDueCtrl.text = _original['nextDueDate']!;
    _assigneeNameCtrl.text = _original['assigneeName']!;
    _assigneeDeptCtrl.text = _original['assigneeDept']!;
    _adminNotifyCtrl.text = _original['adminNotify']!;
    _staffNotifyCtrl.text = _original['staffNotify']!;
    _selectedStaffId = _original['selectedStaffId']!.isNotEmpty ? _original['selectedStaffId'] : null;
    setState(() => _isEditMode = false);
  }

  Future<void> _saveEdit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors.')),
      );
      return;
    }

    try {
      final updateData = _takeSnapshot();
      print('[InternalTaskView] Updating maintenance task: ${widget.taskId} -> $updateData');

      // Create inventory requests for selected items first
      final inventoryRequestIds = await _createInventoryRequests();

      // Prepare the update payload for the API
      final Map<String, dynamic> apiUpdateData = {
        'task_title': _titleCtrl.text.trim(),
        'department': _departmentCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'task_description': _descriptionCtrl.text.trim(),
        'recurrence_type': _recurrenceCtrl.text.trim(),
        'scheduled_date': _startDateCtrl.text.trim(),
        'estimated_duration': _estimatedDurationCtrl.text.trim(),
      };

      // Add assigned_to if a staff member is selected
      if (_selectedStaffId != null && _selectedStaffId!.isNotEmpty) {
        apiUpdateData['assigned_to'] = _selectedStaffId;
      }

      // Add inventory request IDs if any
      if (inventoryRequestIds.isNotEmpty) {
        apiUpdateData['inventory_request_ids'] = inventoryRequestIds;
      }

      // Call the API to update the task
      print('[InternalTaskView] Calling API with data: $apiUpdateData');
      final response = await _apiService.updateMaintenanceTask(
        widget.taskId,
        apiUpdateData,
      );

      print('[InternalTaskView] Update response: $response');

      if (response['success'] == true) {
        _original = Map<String, String>.from(updateData); // update baseline
        setState(() => _isEditMode = false);

        // Reload inventory requests to show the newly created ones
        if (inventoryRequestIds.isNotEmpty) {
          await _loadLinkedInventoryRequests();
        }

        // Reload the task data to reflect the changes
        await _initializeData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['detail'] ?? 'Failed to update task');
      }
    } catch (e) {
      print('[InternalTaskView] Error saving task: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text('Failed to save task: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<List<String>> _createInventoryRequests() async {
    if (_selectedInventoryItems.isEmpty) return [];

    final List<String> createdRequestIds = [];

    try {
      for (final item in _selectedInventoryItems) {
        final response = await _apiService.createInventoryRequest(
          inventoryId: item['inventory_id'],
          buildingId: 'default_building_id', // TODO: Use actual building ID
          quantityRequested: item['quantity'],
          purpose: 'Maintenance Task: ${widget.taskId}',
          requestedBy: _createdByCtrl.text.isNotEmpty ? _createdByCtrl.text : 'system',
          maintenanceTaskId: widget.taskId,
        );

        // Extract the request ID from the response
        if (response['success'] == true && response['request_id'] != null) {
          createdRequestIds.add(response['request_id']);
          print('[v0] Created inventory request: ${response['request_id']}');
        }
      }
      print('[v0] Created ${createdRequestIds.length} inventory requests for task ${widget.taskId}');
      return createdRequestIds;
    } catch (e) {
      print('[v0] Error creating inventory requests: $e');
      throw Exception('Failed to create inventory requests: $e');
    }
  }


  // ------------------------ Validators (real-time) ------------------------
  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String _toTitleCase(String s) {
    if (s.trim().isEmpty) return s;
    return s
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _formatDateString(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    DateTime? dt = DateTime.tryParse(value);
    if (dt == null) {
      try {
        dt = UiDateUtils.parse(value);
      } catch (_) {
        dt = null;
      }
    }
    return dt != null ? UiDateUtils.fullDate(dt) : value;
  }

  // ------------------------ UI ------------------------
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _initializeData();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(), // Breadcrumbs/title
              const SizedBox(height: 32),

              // ---------------- Main content container ----------------
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Notification banner (top of container) ---
                    _buildNotificationBanner(),
                    const SizedBox(height: 24),

                    // --- Task header + chips + edit toolbar ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: title + id + assignee
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _isEditMode
                                  ? TextFormField(
                                      controller: _titleCtrl,
                                      validator: _req,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        hintText: 'Enter task title',
                                      ),
                                    )
                                  : Text(
                                      _titleCtrl.text.isNotEmpty
                                          ? _titleCtrl.text
                                          : 'Maintenance Task',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                              const SizedBox(height: 4),
                              // Show formatted maintenance identifier if available, else fall back to the route taskId
                              Text(
                                _taskData?['formatted_id'] ?? _taskData?['maintenance_id'] ?? widget.taskId,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Also show the backend numeric/database id (UID/request id) for clarity
                              Text(
                                'Request ID: ${_taskData?['id'] ?? _taskData?['request_id'] ?? widget.taskId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Assigned To: ${_assigneeNameCtrl.text.isNotEmpty ? _assigneeNameCtrl.text : (_selectedStaffName ?? 'Unassigned')}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right: chips (toolbar moved to bottom-right)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildTaskTags(),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // --- Two-column layout ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildBasicInformationCard(),
                              const SizedBox(height: 24),
                              _buildChecklistCard(),
                              const SizedBox(height: 24),
                              _buildInventoryRequestsCard(),
                              const SizedBox(height: 24),
                              _buildAdminNotesCard(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Right column
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              _buildScheduleCard(),
                              const SizedBox(height: 24),
                              _buildAssignmentCard(),
                              const SizedBox(height: 8),
                              // Place the main Edit/Save action under the Assign Staff card (right column)
                              Align(
                                alignment: Alignment.centerRight,
                                child: _buildBottomActionBar(),
                              ),
                              const SizedBox(height: 24),
                    
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
      ),
    );
  }

  // ------------------------ Header (breadcrumbs only) ------------------------
  Widget _buildHeaderSection() {
    final taskTitle = _taskData?['task_title'] ?? 
                      _taskData?['taskTitle'] ?? 
                      _taskData?['title'] ?? 
                      'Maintenance Task';
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
              onPressed: null,
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(taskTitle),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------ Header Chips ------------------------
  Widget _buildTaskTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _tags.map((t) {
            final isPrimary = t.toLowerCase().contains('high');
            final bg = isPrimary ? const Color(0xFFE8F5E8) : Colors.grey[100]!;
            final fg = isPrimary ? const Color(0xFF2E7D2E) : Colors.grey[700]!;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                t,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
    );
  }

  // ------------------------ Notification Banner (top of container) ------------------------
  Widget _buildNotificationBanner() {
    final rawNextDue = _nextDueCtrl.text.trim();
    String formattedNext = rawNextDue;
    DateTime? parsedNext;
    if (rawNextDue.isNotEmpty) {
      parsedNext = DateTime.tryParse(rawNextDue);
      if (parsedNext == null) {
        try {
          parsedNext = UiDateUtils.parse(rawNextDue);
        } catch (_) {
          parsedNext = null;
        }
      }
      if (parsedNext != null) formattedNext = UiDateUtils.fullDate(parsedNext);
    }
    final hasNextDue = formattedNext.isNotEmpty && formattedNext != 'N/A';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasNextDue ? const Color(0xFFE3F2FD) : Colors.grey[100]!,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            hasNextDue ? Icons.calendar_today : Icons.info_outline,
            color: hasNextDue ? const Color(0xFF1976D2) : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            hasNextDue ? "Tasks Scheduled" : "Schedule Information",
            style: TextStyle(
              color: hasNextDue ? const Color(0xFF1976D2) : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasNextDue
                  ? "Next Service: $formattedNext"
                  : "No next service date scheduled",
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Bottom actions: Edit (view mode) OR Cancel/Save (edit mode)
  Widget _buildBottomActionBar() {
    if (!_isEditMode) {
      // VIEW MODE: single Edit button
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              // Prepare an editable payload for the edit form. Attempt to include checklist and parts
              final Map<String, dynamic> editData = Map<String, dynamic>.from(_taskData ?? {});

              // Ensure remarks/admin notes are present
              if ((editData['remarks'] == null || editData['remarks'].toString().isEmpty) && _adminNotifyCtrl.text.trim().isNotEmpty) {
                editData['remarks'] = _adminNotifyCtrl.text.trim();
              }

              // Normalize checklist: prefer existing server checklist, else synthesize from local checklist items
              if (editData['checklist'] == null) {
                if (_checklistItems.isNotEmpty) {
                  editData['checklist'] = _checklistItems.map((e) => {
                        'task': e['text'] ?? '',
                        'completed': e['completed'] ?? false,
                      }).toList();
                } else if (editData['checklist_completed'] != null) {
                  editData['checklist'] = editData['checklist_completed'];
                }
              }

              // Normalize parts/parts_used from linked inventory requests if not present
              if (editData['parts_used'] == null && _linkedInventoryRequests.isNotEmpty) {
                editData['parts_used'] = _linkedInventoryRequests.map((r) => {
                      'inventory_id': r['inventory_id'],
                      'item_name': r['item_name'] ?? r['name'] ?? r['item_name'],
                      'item_code': r['item_code'],
                      'quantity_requested': r['quantity_requested'] ?? r['quantity'] ?? 1,
                      'status': r['status'],
                    }).toList();
              }

              // Ensure date fields are available for the form
              if ((editData['scheduled_date'] == null || editData['scheduled_date'].toString().isEmpty) && _startDateCtrl.text.isNotEmpty) {
                editData['scheduled_date'] = _startDateCtrl.text;
                editData['start_date'] = _startDateCtrl.text;
              }
              if ((editData['next_due_date'] == null || editData['next_due_date'].toString().isEmpty) && _nextDueCtrl.text.isNotEmpty) {
                editData['next_due_date'] = _nextDueCtrl.text;
                editData['nextDueDate'] = _nextDueCtrl.text;
              }

              // Open the full edit form and pass the prepared payload so it can populate fields
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => InternalMaintenanceFormPage(
                    maintenanceData: editData,
                    isEditMode: true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit, size: 20),
            label: const Text("Edit Task"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      );
    }

    // EDIT MODE: Cancel + Save (right aligned)
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _cancelEdit,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _saveEdit,
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          ),
        ),
      ],
    );
  }

  // ------------------------ Cards (some editable) ------------------------
  Widget _buildBasicInformationCard() {
    return _card(
      icon: Icons.info,
      iconBg: const Color(0xFF1976D2),
      title: 'Basic Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _editableRow('Department', _departmentCtrl, validator: _req),

          _editableRow('Location / Area', _locationCtrl, validator: _req),
          const SizedBox(height: 16),
          Text(
            'Task Description',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _isEditMode
              ? TextFormField(
                controller: _descriptionCtrl,
                minLines: 3,
                maxLines: 6,
                validator: _req,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Describe the work to be done...',
                ),
              )
              : Text(
                _descriptionCtrl.text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return _card(
      icon: Icons.calendar_today,
      iconBg: const Color(0xFFE8F5E8),
      title: 'Schedule',
      child: Column(
        children: [
          // Show editable input in edit mode, otherwise display title-cased recurrence
          _isEditMode
              ? _editableRow(
                  'Recurrence',
                  _recurrenceCtrl,
                  validator: _req,
                  hint: 'e.g., Every 1 month',
                )
              : _readOnlyRow(
                  'Recurrence',
                  _toTitleCase(_recurrenceCtrl.text),
                ),
          _buildStartDateRow(),
          _readOnlyRow(
            'Next Due Date',
            _formatDateString(_nextDueCtrl.text),
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStartDateRow() {
    final labelStyle = TextStyle(
      fontSize: 14,
      color: Colors.grey[600],
      fontWeight: FontWeight.w500,
    );
    final valueStyle = const TextStyle(
      fontSize: 14,
      color: Colors.black87,
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text('Start Date', style: labelStyle)),
          Expanded(
            child: _isEditMode
                ? InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _startDateCtrl.text.isNotEmpty
                            ? DateTime.tryParse(_startDateCtrl.text) ?? DateTime.now()
                            : DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _startDateCtrl.text = picked.toString().split(' ')[0];
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        _startDateCtrl.text.isNotEmpty
                            ? _formatDateString(_startDateCtrl.text)
                            : 'Select date',
                        style: TextStyle(
                          color: _startDateCtrl.text.isEmpty ? Colors.grey : Colors.black87,
                        ),
                      ),
                    ),
                  )
                : Text(_formatDateString(_startDateCtrl.text), style: valueStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard() {
    return _card(
      icon: Icons.person,
      iconBg: Colors.grey[200]!,
      title: 'Assign Staff',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditMode) ...[
            // In edit mode: show staff dropdown
            if (_isLoadingStaff)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_staffList.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No staff members available in this category',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedStaffId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Assigned Staff',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                items: _staffList.map<DropdownMenuItem<String>>((staff) {
                  final staffId = staff['user_id'] ?? staff['id'] ?? '';
                  final firstName = staff['first_name'] ?? '';
                  final lastName = staff['last_name'] ?? '';
                  final department = staff['staff_department'] ?? staff['department'] ?? 'General';

                  String name = '$firstName $lastName'.trim();
                  if (name.isEmpty) name = 'Staff Member';

                  return DropdownMenuItem<String>(
                    value: staffId.toString(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          department,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStaffId = value;
                    if (value != null) {
                      final staff = _staffList.firstWhere(
                        (s) => (s['user_id'] ?? s['id']) == value,
                        orElse: () => {},
                      );
                      final firstName = staff['first_name'] ?? '';
                      final lastName = staff['last_name'] ?? '';
                      _selectedStaffName = '$firstName $lastName'.trim();
                      _assigneeNameCtrl.text = _selectedStaffName!;
                      _assigneeDeptCtrl.text = staff['staff_department'] ?? staff['department'] ?? '';
                    }
                  });
                },
                validator: (value) => value == null || value.isEmpty ? 'Please select a staff member' : null,
              ),
            ] else ...[
            // In view mode: show read-only assignment info (compact, no left padding)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              _readOnlyRow(
                'Assignee Name',
                _assigneeNameCtrl.text,
                compact: true,
              ),
              _readOnlyRow(
                'Department',
                _assigneeDeptCtrl.text,
                compact: true,
              ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF9800)),
                ),
                child: const Icon(
                  Icons.checklist,
                  color: Color(0xFFFF9800),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Checklist / Task Steps",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_checklistItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                'No checklist items available for this task.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...(_checklistItems.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child:
                          entry.value['completed']
                              ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.green,
                              )
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value['text'],
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              entry.value['completed']
                                  ? Colors.grey[500]
                                  : Colors.black87,
                          decoration:
                              entry.value['completed']
                                  ? TextDecoration.lineThrough
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })),
        ],
      ),
    );
  }

  Widget _buildInventoryRequestsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2196F3)),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Color(0xFF2196F3),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Inventory Requests",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_linkedInventoryRequests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                'No inventory requests linked to this task.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            )
          else
            Column(
              children: _linkedInventoryRequests.map((request) {
                final status = request['status'] ?? 'pending';
                final itemName = request['item_name'] ?? 'Unknown Item';
                final quantity = request['quantity_requested'] ?? 0;
                final startDate = request['start_date'] ?? request['requested_date'] ?? '';
                
                Color statusColor;
                IconData statusIcon;
                switch (status) {
                  case 'approved':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    break;
                  case 'fulfilled':
                    statusColor = Colors.blue;
                    statusIcon = Icons.done_all;
                    break;
                  case 'denied':
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                    break;
                  default:
                    statusColor = Colors.orange;
                    statusIcon = Icons.pending;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quantity: $quantity',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (startDate.isNotEmpty)
                              Text(
                                'Requested: ${_formatDateString(startDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              color: statusColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminNotesCard() {
    // Show the admin notes card only when there is text in view mode.
    // In edit mode the card is shown so the user can add/edit notes.
    final hasAdminNotes = _adminNotifyCtrl.text.trim().isNotEmpty;
    if (!hasAdminNotes && !_isEditMode) {
      // Nothing to show in view mode and not editing -> hide entirely
      return const SizedBox.shrink();
    }

    final card = _card(
      icon: Icons.note,
      iconBg: Colors.grey[200]!,
      title: 'Admin Notes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _isEditMode
              ? TextFormField(
                  controller: _adminNotifyCtrl,
                  minLines: 3,
                  maxLines: 8,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: 'Enter admin notes...',
                  ),
                )
              : Text(
                  _adminNotifyCtrl.text.trim().isNotEmpty
                      ? _adminNotifyCtrl.text
                      : 'No admin notes available.',
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
        ],
      ),
    );

    // If in view mode and there are notes, show an Edit button below the card.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        if (!_isEditMode && hasAdminNotes) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _enterEditMode,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Notes'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }


  // ------------------------ Small card wrapper ------------------------
  Widget _card({
    required IconData icon,
    required Color iconBg,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color:
                      iconBg.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // ------------------------ Core editable row ------------------------
  Widget _editableRow(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    String? hint,
    bool highlight = false,
    bool compact = false,
  }) {
    final labelStyle = TextStyle(
      fontSize: 14,
      color: Colors.grey[600],
      fontWeight: FontWeight.w500,
    );
    final valueStyle = TextStyle(
      fontSize: 14,
      color: highlight ? Colors.red[600] : Colors.black87,
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text(label, style: labelStyle)),
          Expanded(
            child:
                _isEditMode
                    ? TextFormField(
                      controller: controller,
                      validator: validator,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: hint,
                        border: const OutlineInputBorder(),
                        errorMaxLines: 2,
                      ),
                    )
                    : Text(controller.text, style: valueStyle),
          ),
        ],
      ),
    );
  }

  // ------------------------ Read-only row (always displays value) ------------------------
  Widget _readOnlyRow(
    String label,
    String value, {
    bool highlight = false,
    bool compact = false,
  }) {
    final labelStyle = TextStyle(
      fontSize: 14,
      color: Colors.grey[600],
      fontWeight: FontWeight.w500,
    );
    final valueStyle = TextStyle(
      fontSize: 14,
      color: highlight ? Colors.red[600] : Colors.black87,
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text(label, style: labelStyle)),
          Expanded(
            child: Text(value.isNotEmpty ? value : 'N/A', style: valueStyle),
          ),
        ],
      ),
    );
  }
}

// Inventory Selection Dialog
class _InventorySelectionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableItems;
  final Function(Map<String, dynamic> item, int quantity) onItemSelected;

  const _InventorySelectionDialog({
    required this.availableItems,
    required this.onItemSelected,
  });

  @override
  State<_InventorySelectionDialog> createState() => _InventorySelectionDialogState();
}

class _InventorySelectionDialogState extends State<_InventorySelectionDialog> {
  Map<String, dynamic>? _selectedItem;
  final _quantityController = TextEditingController(text: '1');
  String _searchQuery = '';

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.availableItems;
    
    final query = _searchQuery.toLowerCase();
    return widget.availableItems.where((item) {
      final name = (item['item_name'] ?? '').toString().toLowerCase();
      final code = (item['item_code'] ?? '').toString().toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Inventory Item',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or code...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Items list
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'No items found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = _selectedItem == item;
                        final currentStock = item['current_stock'] ?? 0;
                        final isLowStock = currentStock <= (item['reorder_level'] ?? 0);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFE8F5E8) : Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              setState(() {
                                _selectedItem = item;
                              });
                            },
                            title: Text(
                              item['item_name'] ?? 'Unknown Item',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Code: ${item['item_code'] ?? 'N/A'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                Text(
                                  'Department: ${item['department'] ?? 'N/A'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLowStock ? Colors.orange[100] : Colors.green[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Stock: $currentStock',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: isLowStock ? Colors.orange[900] : Colors.green[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32))
                                : null,
                          ),
                        );
                      },
                    ),
            ),

            if (_selectedItem != null) ...[
              const Divider(height: 32),
              
              // Quantity input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity Needed',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Available: ${_selectedItem!['current_stock'] ?? 0}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _selectedItem == null
                      ? null
                      : () {
                          final quantity = int.tryParse(_quantityController.text) ?? 1;
                          if (quantity <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Quantity must be greater than 0'),
                              ),
                            );
                            return;
                          }
                          widget.onItemSelected(_selectedItem!, quantity);
                          Navigator.pop(context);
                        },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
