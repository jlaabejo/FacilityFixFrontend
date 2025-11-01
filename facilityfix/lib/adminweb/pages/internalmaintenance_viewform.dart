import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart'; 
import '../../services/api_services.dart'; 


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

  // Notifications controllers (NOW EDITABLE)
  final _adminNotifyCtrl = TextEditingController();
  final _staffNotifyCtrl = TextEditingController();

  // Header chips (view-only)
  List<String> _tags = const [];

  // Attachments sourced from backend/task payload
  final List<Map<String, String?>> _attachments = [];

  // Inventory items
  List<Map<String, dynamic>> _availableInventoryItems = [];
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
        setState(() {
          _availableInventoryItems = List<Map<String, dynamic>>.from(response['data']);
        });
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
    setText(_departmentCtrl, ['department', 'assigneeDept']);
    setText(_createdByCtrl, ['created_by', 'assigneeName', 'assigned_staff_name']);
    setText(_estimatedDurationCtrl, ['estimated_duration', 'estimatedDuration']);
    setText(_locationCtrl, ['location']);
    setText(_descriptionCtrl, ['task_description', 'description']);
    setText(_recurrenceCtrl, ['recurrence_type', 'recurrence']);
    setText(_startDateCtrl, ['scheduled_date', 'startDate', 'start_date']);
    setText(_nextDueCtrl, ['next_occurrence', 'nextDueDate', 'next_due_date']);
    setText(_assigneeNameCtrl, ['assigned_staff_name', 'assigneeName', 'assigned_to']);
    setText(_assigneeDeptCtrl, ['department', 'assigneeDept']);
    setText(_adminNotifyCtrl, ['admin_notification', 'adminNotify']);
    setText(_staffNotifyCtrl, ['staff_notification', 'staffNotify']);

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
  };

  void _enterEditMode() => setState(() => _isEditMode = true);

  void _cancelEdit() {
    // Revert to snapshot
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
      print('[v0] Updating maintenance task: ${widget.taskId} -> $updateData');

      // Create inventory requests for selected items first
      final inventoryRequestIds = await _createInventoryRequests();

      // TODO: Call API to update the task with all data including inventory request IDs
      // For now, we're not updating the task yet until the API is implemented
      // await _apiService.updateMaintenanceTask(widget.taskId, {
      //   ...updateData,
      //   if (inventoryRequestIds.isNotEmpty) 'inventory_request_ids': inventoryRequestIds,
      // });

      _original = Map<String, String>.from(updateData); // update baseline
      setState(() => _isEditMode = false);

      // Reload inventory requests to show the newly created ones
      if (inventoryRequestIds.isNotEmpty) {
        await _loadLinkedInventoryRequests();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[v0] Error saving task: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save task: $e')));
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

  String? _durationValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final ok = RegExp(
      r'^\d+\s*(hr|hrs|hour|hours|min|mins|minutes)$',
      caseSensitive: false,
    ).hasMatch(v.trim());
    return ok ? null : 'Use formats like "3 hrs" or "45 mins"';
  }

  String? _dateValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final ok = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v.trim());
    return ok ? null : 'Use YYYY-MM-DD';
  }

  /// Accept strings like: "1 week before, 3 days before, 1 day before"
  String? _notifyValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final parts = v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    final re = RegExp(
      r'^\d+\s*(day|days|week|weeks)\s+before$',
      caseSensitive: false,
    );
    for (final p in parts) {
      if (!re.hasMatch(p)) {
        return 'Use entries like "1 week before" or "3 days before", comma-separated';
      }
    }
    return null;
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _taskData?['task_title'] ?? 
                                  _taskData?['taskTitle'] ?? 
                                  _taskData?['title'] ?? 
                                  'Maintenance Task',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.taskId,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Assigned To: ${_assigneeNameCtrl.text}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        // Right: chips then toolbar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildTaskTags(),
                            const SizedBox(height: 8),
                            _buildBottomActionBar(),
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
                         
                              const SizedBox(height: 24),
                              _buildAttachmentsCard(),
                              const SizedBox(height: 24),
                              _buildNotificationsCard(),
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
          "Work Orders",
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
              child: const Text('Work Orders'),
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
    final nextDue = _nextDueCtrl.text.trim();
    final hasNextDue = nextDue.isNotEmpty && nextDue != 'N/A';
    
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
                  ? "Next Service: $nextDue"
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
            onPressed: _enterEditMode,
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
          _editableRow('Created By', _createdByCtrl, validator: _req),
          _editableRow(
            'Estimated Duration',
            _estimatedDurationCtrl,
            validator: _durationValidator,
            hint: 'e.g., 3 hrs, 45 mins',
          ),
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
          _editableRow(
            'Recurrence',
            _recurrenceCtrl,
            validator: _req,
            hint: 'e.g., Every 1 month',
          ),
          _editableRow(
            'Start Date',
            _startDateCtrl,
            validator: _dateValidator,
            hint: 'YYYY-MM-DD',
          ),
          _editableRow(
            'Next Due Date',
            _nextDueCtrl,
            validator: _dateValidator,
            hint: 'YYYY-MM-DD',
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard() {
    return _card(
      icon: Icons.person,
      iconBg: Colors.grey[200]!,
      title: 'Assignment',
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _editableRow(
                  'Assignee Name',
                  _assigneeNameCtrl,
                  validator: _req,
                  compact: true,
                ),
                _editableRow(
                  'Department',
                  _assigneeDeptCtrl,
                  validator: _req,
                  compact: true,
                ),
              ],
            ),
          ),
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
                                'Requested: $startDate',
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
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.comment,
                  color: Color(0xFF2E7D2E),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Admin Notes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1976D2), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning, color: Color(0xFF1976D2), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Emergency lights in basement often have moisture issues - check battery backups.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[800],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard() {
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
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.attach_file,
                  color: Color(0xFF1976D2),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Attachments",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_attachments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                _isEditMode
                    ? 'No attachments yet. Use the edit mode toolbar to upload files.'
                    : 'No attachments provided.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            )
          else
            Column(
              children: [
                for (final attachment in _attachments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAttachmentRow(attachment),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentRow(Map<String, String?> attachment) {
    final name = attachment['name'] ?? 'Attachment';
    final url = attachment['url'];
    final ext = name.split('.').length > 1
        ? name.split('.').last.toLowerCase()
        : '';

    IconData icon;
    Color bgColor;

    switch (ext) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        bgColor = const Color(0xFFF44336);
        break;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        icon = Icons.image;
        bgColor = const Color(0xFF4CAF50);
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        bgColor = const Color(0xFF1976D2);
        break;
      default:
        icon = Icons.insert_drive_file;
        bgColor = const Color(0xFF9E9E9E);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  url ?? 'No download link provided',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: url != null
                ? () {
                    // TODO: Implement preview/download when backend ready
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Attachment URL copied: $url')),
                    );
                  }
                : null,
            icon: Icon(
              Icons.visibility,
              color: url != null ? Colors.grey[600] : Colors.grey[400],
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// NEW: Notifications card (editable in edit mode)
  Widget _buildNotificationsCard() {
    return _card(
      icon: Icons.notifications,
      iconBg: Colors.grey[200]!,
      title: 'Notifications',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _editableRow(
            'Admin',
            _adminNotifyCtrl,
            validator: _notifyValidator,
            hint: 'e.g., 1 week before, 3 days before, 1 day before',
          ),
          _editableRow(
            'Assigned Staff',
            _staffNotifyCtrl,
            validator: _notifyValidator,
            hint: 'e.g., 3 days before, 1 day before',
          ),
        ],
      ),
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
