import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../services/api_service.dart';
import '../../services/auth_storage.dart';
import '../../services/api_services.dart' as main_api;

class InternalMaintenanceFormPage extends StatefulWidget {
  const InternalMaintenanceFormPage({super.key});

  @override
  State<InternalMaintenanceFormPage> createState() =>
      _InternalMaintenanceFormPageState();
}

class _InternalMaintenanceFormPageState
    extends State<InternalMaintenanceFormPage> {
  // -------------------- FORM & VALIDATION --------------------
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoMode =
      AutovalidateMode.disabled; // turn on after first submit

  // For consistent field heights
  static const double _kFieldHeight = 56;
  static const List<String> _monthNames = [
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

  // -------------------- CONTROLLERS --------------------
  final _taskTitleController = TextEditingController();
  final _codeIdController =
      TextEditingController(); // Auto-generated, read-only
  final TextEditingController _createdByController = TextEditingController();
  final _assignedStaffController = TextEditingController(); // Now editable
  final _dateCreatedController = TextEditingController(); // read-only display
  final _descriptionController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  final _remarksController = TextEditingController();

  final _startDateController = TextEditingController(); // read-only
  final _nextDueDateController = TextEditingController(); // read-only
  final _checklistItemController =
      TextEditingController(); // For checklist input

  // -------------------- STATE --------------------
  String? _selectedPriority;
  String _selectedStatus = 'New';
  String? _selectedLocation;
  String? _selectedRecurrence;
  String? _selectedDepartment;
  String? _selectedAdminNotification;
  String? _selectedStaffNotification;
  String? _selectedStaffUserId; // Store the actual staff UID

  DateTime? _dateCreated;
  DateTime? _startDate;
  DateTime? _nextDueDate;

  final List<Map<String, dynamic>> _checklistItems = [];

  List<Map<String, dynamic>> _staffMembers = [];
  List<Map<String, dynamic>> _availableInventoryItems = [];
  List<Map<String, dynamic>> _selectedInventoryItems = [];
  final _apiService = ApiService();
  final _mainApiService = main_api.APIService();

  // -------------------- NAV --------------------
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

  // -------------------- HELPERS --------------------
  // TODO: Replace with your auth/current user provider
  // String _getCurrentUserName() => 'Michelle Reyes'; // REMOVED

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPick,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) onPick(picked);
  }

  Future<void> _initAutoFields() async {
    final token = await AuthStorage.getToken();
    if (token != null) {
      _apiService.setAuthToken(token);
    }

    final profile = await AuthStorage.getProfile();
    if (profile != null) {
      final firstName = profile['first_name'] ?? '';
      final lastName = profile['last_name'] ?? '';
      final fullName = '$firstName $lastName'.trim();
      if (fullName.isNotEmpty) {
        _assignedStaffController.text = fullName;
      }
    }

    try {
      final codeId = await _apiService.getNextIPMCode();
      _codeIdController.text = codeId;
      print('[v0] Generated IPM code: $codeId');
      final profile = await AuthStorage.getProfile();
      if (profile != null && profile['full_name'] != null) {
        _createdByController.text = profile['full_name'];
      } else {
        _createdByController.text = 'Admin User';
      }
    } catch (e) {
      print('[v0] Error fetching IPM code: $e');
      // Fallback to timestamp-based code if backend fails
      final year = DateTime.now().year;
      final number = DateTime.now().millisecondsSinceEpoch % 100000;
      _codeIdController.text = 'IPM-$year-${number.toString().padLeft(5, '0')}';
      _createdByController.text = 'Admin User';
    }

    // Date Created (default to now)
    _dateCreated = DateTime.now();
    _dateCreatedController.text = _fmtDate(_dateCreated!);

    _startDate = DateTime.now();
    _startDateController.text = _fmtDate(_startDate!);

    // Load staff members
    await _loadStaffMembers();

    // Load inventory items
    await _loadInventoryItems();
  }

  Future<void> _loadInventoryItems() async {
    try {
      // TODO: Replace with actual building ID from user session or update
      // the parameter name to match the API (e.g., buildingId/building/building_id).

      // Call without named parameter because `buildingId` is not defined on the API method.
      final response = await _mainApiService.getInventoryItems();

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _availableInventoryItems = List<Map<String, dynamic>>.from(
            response['data'],
          );
        });
      }
    } catch (e) {
      print('[v0] Error loading inventory items: $e');
      // Don't fail the whole form if inventory loading fails
    }
  }

  Future<void> _loadStaffMembers() async {
    setState(() => _staffMembers.clear());
    try {
      final staffData = await _apiService.getStaffMembers();
      setState(() {
        _staffMembers = List<Map<String, dynamic>>.from(staffData);
      });
    } catch (e) {
      print('[v0] Error loading staff members: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load staff members: $e')),
        );
      }
    }
  }

  void _addChecklistItem() {
    final itemText = _checklistItemController.text.trim();
    if (itemText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a task item')));
      return;
    }

    setState(() {
      _checklistItems.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'task': itemText,
        'completed': false,
      });
      _checklistItemController.clear(); // Reset input field
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task item added successfully!')),
    );
  }

  void _removeChecklistItem(String id) {
    setState(() {
      _checklistItems.removeWhere((item) => item['id'] == id);
    });
  }

  void _addInventoryItem() {
    if (_availableInventoryItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No inventory items available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => _InventorySelectionDialog(
            availableItems: _availableInventoryItems,
            onItemSelected: (item, quantity) {
              setState(() {
                _selectedInventoryItems.add({
                  'inventory_id': item['id'] ?? item['_doc_id'],
                  'item_name': item['item_name'],
                  'item_code': item['item_code'],
                  'quantity': quantity,
                  'available_stock': item['current_stock'],
                });
              });
            },
          ),
    );
  }

  void _removeInventoryItem(int index) {
    setState(() {
      _selectedInventoryItems.removeAt(index);
    });
  }

  Future<List<String>> _createInventoryRequests(String taskId) async {
    if (_selectedInventoryItems.isEmpty) return [];

    final List<String> createdRequestIds = [];

    try {
      for (final item in _selectedInventoryItems) {
        final response = await _mainApiService.createInventoryRequest(
          inventoryId: item['inventory_id'],
          buildingId: 'default_building_id', // TODO: Use actual building ID
          quantityRequested: item['quantity'],
          purpose: 'Maintenance Task: $taskId',
          requestedBy:
              _assignedStaffController.text.isNotEmpty
                  ? _assignedStaffController.text
                  : 'system',
          maintenanceTaskId: taskId, // Link to maintenance task
        );

        // Extract the request ID from the response
        if (response['success'] == true && response['request_id'] != null) {
          createdRequestIds.add(response['request_id']);
          print('[v0] Created inventory request: ${response['request_id']}');
        }
      }
      print(
        '[v0] Created ${createdRequestIds.length} inventory requests linked to task $taskId',
      );
      return createdRequestIds;
    } catch (e) {
      print('[v0] Error creating inventory requests: $e');
      throw Exception('Failed to create inventory requests: $e');
    }
  }

  DateTime _calculateNextDueDate(DateTime base, String frequency) {
    switch (frequency) {
      case 'Daily':
        return base.add(const Duration(days: 1));
      case 'Weekly':
        return base.add(const Duration(days: 7));
      case 'Monthly':
        return _addMonths(base, 1);
      case 'Quarterly':
        return _addMonths(base, 3);
      case 'Annually':
        return _addMonths(base, 12);
      default:
        return base;
    }
  }

  DateTime _addMonths(DateTime date, int monthsToAdd) {
    final totalMonths = date.month + monthsToAdd;
    final year = date.year + ((totalMonths - 1) ~/ 12);
    final month = ((totalMonths - 1) % 12) + 1;
    final day = math.min(date.day, _daysInMonth(year, month));
    return DateTime(year, month, day);
  }

  int _daysInMonth(int year, int month) {
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextMonthYear = month == 12 ? year + 1 : year;
    return DateTime(
      nextMonthYear,
      nextMonth,
      1,
    ).subtract(const Duration(days: 1)).day;
  }

  void _handleRecurrenceChange(String? value) {
    if (value == null) {
      setState(() {
        _selectedRecurrence = null;
        _nextDueDate = null;
        _nextDueDateController.clear();
      });
      return;
    }

    final baseStart = _startDate ?? DateTime.now();
    final normalized = DateTime(baseStart.year, baseStart.month, baseStart.day);
    final nextDue = _calculateNextDueDate(normalized, value);

    setState(() {
      _selectedRecurrence = value;
      _startDate = normalized;
      _nextDueDate = nextDue;
      _updateDateControllers();
    });
  }

  void _handleStartDateChange(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);

    setState(() {
      _startDate = normalized;
      if (_selectedRecurrence != null) {
        _nextDueDate = _calculateNextDueDate(normalized, _selectedRecurrence!);
      }
      _updateDateControllers();
    });
  }

  void _updateDateControllers() {
    if (_startDate != null) {
      _startDateController.text = _fmtDate(_startDate!);
    }
    if (_nextDueDate != null) {
      _nextDueDateController.text = _fmtDate(_nextDueDate!);
    }
  }

  String _formatFriendlyDate(DateTime date) {
    final month = _monthNames[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  String? _recurrenceSummaryText() {
    if (_selectedRecurrence == null ||
        _startDate == null ||
        _nextDueDate == null) {
      return null;
    }

    final start = _formatFriendlyDate(_startDate!);
    final next = _formatFriendlyDate(_nextDueDate!);
    return 'Repeats $_selectedRecurrence starting $start. Next occurrence $next';
  }

  Widget _buildRecurrenceSummary() {
    final summary = _recurrenceSummaryText();
    if (summary == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_repeat, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(color: Colors.blue, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- VALIDATORS --------------------
  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _reqDropdown<T>(T? v) => (v == null) ? 'Required' : null;

  String? _durationValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final re = RegExp(
      r'^\d+\s*(min|mins|minutes|hr|hrs|hour|hours)$',
      caseSensitive: false,
    );
    return re.hasMatch(v.trim())
        ? null
        : 'Use formats like "45 mins" or "3 hrs"';
  }

  // -------------------- INIT/DISPOSE --------------------
  @override
  void initState() {
    super.initState();
    _initAutoFields();
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _codeIdController.dispose(); // Dispose new controller
    _assignedStaffController.dispose();
    _dateCreatedController.dispose();
    _descriptionController.dispose();
    _estimatedDurationController.dispose();
    _remarksController.dispose();
    _startDateController.dispose();
    _nextDueDateController.dispose();
    _checklistItemController.dispose(); // Dispose new controller
    _createdByController.dispose();
    super.dispose();
  }

  // -------------------- ACTIONS --------------------
  void _saveDraft() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Draft saved successfully!')));
  }

  Future<void> _onNext() async {
    // turn on real-time validation *after* first press
    setState(() => _autoMode = AutovalidateMode.onUserInteraction);

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors.')),
      );
      return;
    }

    final id = _codeIdController.text;
    final scheduledDateIso = _startDate?.toUtc().toIso8601String();
    final maintenance = <String, dynamic>{
      'id': id,
      'maintenanceType': 'Internal',
      'taskTitle': _taskTitleController.text.trim(),
      'taskCode': id,
      'created_by': _createdByController.text.trim(),
      'dateCreated': _dateCreatedController.text,
      'priority': _selectedPriority ?? 'medium',
      'status': _selectedStatus,
      'location': _selectedLocation ?? '',
      'description': _descriptionController.text.trim(),
      'recurrence': _selectedRecurrence,
      'estimatedDuration': _estimatedDurationController.text.trim(),
      'startDate': _startDateController.text,
      'nextDueDate': _nextDueDateController.text,
      'assigneeName': _assignedStaffController.text.trim(),
      'assigneeDept': _selectedDepartment,
      'checklistItems': _checklistItems,
      'adminNotify':
          _selectedAdminNotification ??
          '1 week before, 3 days before, 1 day before',
      'staffNotify':
          _selectedStaffNotification ?? '3 days before, 1 day before',
      'remarks': _remarksController.text.trim(),
      'tags': ['High-Turnover', 'Repair-Prone'],
      // Backend-aligned fields
      'task_title': _taskTitleController.text.trim(),
      'task_description': _descriptionController.text.trim(),
      'building_id': 'default_building',
      'scheduled_date': scheduledDateIso ?? _startDateController.text,
      'category': 'preventive',
      'task_type': 'internal',
      'recurrence_type':
          _selectedRecurrence != null
              ? _selectedRecurrence!.toLowerCase()
              : 'none',
      'assigned_to':
          _selectedStaffUserId ?? _assignedStaffController.text.trim(),
      'assigned_staff_name': _assignedStaffController.text.trim(),
      'department': _selectedDepartment,
      'checklist_completed': _checklistItems,
      'parts_used': <Map<String, dynamic>>[],
      'tools_used': <String>[],
      'photos': <String>[],
    };

    try {
      print('[v0] Saving maintenance task to backend...');
      final result = await _apiService.createMaintenanceTask(maintenance);
      print('[v0] Maintenance task saved successfully');
      print('[v0] Backend response: $result');

      // Extract the actual task ID from the response
      String actualTaskId = id;
      if (result['task'] != null) {
        actualTaskId =
            result['task']['id'] ?? result['task']['formatted_id'] ?? id;
      }
      print('[v0] Using task ID for inventory requests: $actualTaskId');

      // Create inventory requests for selected items with the correct task ID
      final inventoryRequestIds = await _createInventoryRequests(actualTaskId);

      // Update the maintenance task with the inventory request IDs
      if (inventoryRequestIds.isNotEmpty) {
        try {
          await _apiService.updateMaintenanceTask(actualTaskId, {
            'inventory_request_ids': inventoryRequestIds,
          });
          print(
            '[v0] Updated maintenance task with inventory request IDs: $inventoryRequestIds',
          );
        } catch (e) {
          print(
            '[v0] Warning: Failed to update maintenance task with inventory request IDs: $e',
          );
          // Don't fail the whole operation if this update fails
        }
      }

      // Navigate to view page with the data
      if (mounted) {
        context.push('/work/maintenance/', extra: maintenance);
      }
    } catch (e) {
      print('[v0] Error saving maintenance task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save maintenance task: $e')),
        );
      }
    }
  }

  // -------------------- UI --------------------
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- HEADER ----------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Work Management",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  //breadcrumb
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
                        child: const Text('Maintenance Tasks'),
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
                        child: const Text('Internal Maintenance Form'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ---------- FORM ----------
              Container(
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
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== Basic Information =====
                      const Text(
                        "Basic Information",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          // Task Title
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Task Title'),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _taskTitleController,
                                    validator: _req,
                                    decoration: _decoration('Enter Task Title'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Task Code
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Task Code'),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _codeIdController,
                                    enabled: false,
                                    decoration: _decoration(
                                      'Auto-generated',
                                    ).copyWith(
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          // Created By
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Created By'),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _createdByController,
                                    enabled: false,
                                    validator: _req,
                                    decoration: _decoration(
                                      'User Name',
                                    ).copyWith(
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Date Created
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Date Created'),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _dateCreatedController,
                                    readOnly: true,
                                    validator: _req,
                                    onTap:
                                        () => _pickDate(
                                          initial:
                                              _dateCreated ?? DateTime.now(),
                                          onPick: (d) {
                                            setState(() {
                                              _dateCreated = d;
                                              _dateCreatedController
                                                  .text = _fmtDate(d);
                                            });
                                          },
                                        ),
                                    decoration: _decoration(
                                      'YYYY-MM-DD',
                                    ).copyWith(
                                      suffixIcon: const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          // Priority
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Priority'),
                                _fieldBox(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedPriority,
                                    validator: _reqDropdown,
                                    decoration: _decoration(
                                      'Select Priority...',
                                    ),
                                    items:
                                        const ['High', 'Medium', 'Low']
                                            .map(
                                              (v) => DropdownMenuItem(
                                                value: v,
                                                child: Text(v),
                                              ),
                                            )
                                            .toList(),
                                    onChanged:
                                        (v) => setState(
                                          () => _selectedPriority = v,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Status
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Status'),
                                _fieldBox(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedStatus,
                                    validator: _reqDropdown,
                                    decoration: _decoration('Select Status...'),
                                    items:
                                        const [
                                              'New',
                                              'In Progress',
                                              'Completed',
                                              'On Hold',
                                            ]
                                            .map(
                                              (v) => DropdownMenuItem(
                                                value: v,
                                                child: Text(v),
                                              ),
                                            )
                                            .toList(),
                                    onChanged:
                                        (v) => setState(
                                          () => _selectedStatus = v!,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ===== Task Scope & Description =====
                      const Text(
                        "Task Scope & Description",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Location
                      _fieldLabel('Location / Area'),
                      _fieldBox(
                        child: DropdownButtonFormField<String>(
                          value: _selectedLocation,
                          validator: _reqDropdown,
                          decoration: _decoration('Select Location...'),
                          items:
                              const [
                                    'Swimming pool',
                                    'Basketball Court',
                                    'Gym',
                                    'Parking area',
                                    'Lobby',
                                    'Elevators',
                                    'Halls',
                                    'Garden',
                                    'Corridors',
                                  ]
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() {
                                _selectedLocation = v;
                              }),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      _fieldLabel('Description'),
                      TextFormField(
                        controller: _descriptionController,
                        validator: _req,
                        maxLines: 5,
                        decoration: _decoration('Enter Description....'),
                      ),

                      const SizedBox(height: 40),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Checklist / Task Steps",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _addChecklistItem, // Use the new handler
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Add List"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Checklist input field
                      _fieldBox(
                        child: TextFormField(
                          controller:
                              _checklistItemController, // Use new controller
                          decoration: _decoration('Add List'),
                          onFieldSubmitted:
                              (_) => _addChecklistItem(), // Add on submit
                        ),
                      ),

                      // Display added checklist items
                      if (_checklistItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _checklistItems.length,
                            separatorBuilder:
                                (context, index) =>
                                    Divider(height: 1, color: Colors.grey[300]),
                            itemBuilder: (context, index) {
                              final item = _checklistItems[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons
                                      .check_circle_outline, // Use a consistent icon
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                title: Text(
                                  item['task'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  color: Colors.red[400],
                                  onPressed:
                                      () => _removeChecklistItem(
                                        item['id'],
                                      ), // Use handler
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),

                      // ===== Recurrence & Schedule =====
                      const Text(
                        "Recurrence & Schedule",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Row 1: Recurrence and Estimated Duration
                      Row(
                        children: [
                          // Recurrence
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Recurrence Frequency'),
                                _fieldBox(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedRecurrence,
                                    validator: _reqDropdown,
                                    decoration: _decoration(
                                      'Select frequency...',
                                    ),
                                    items:
                                        const [
                                              'Daily',
                                              'Weekly',
                                              'Monthly',
                                              'Quarterly',
                                              'Annually',
                                            ]
                                            .map(
                                              (v) => DropdownMenuItem(
                                                value: v,
                                                child: Text(v),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: _handleRecurrenceChange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Estimated Duration
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Estimated Duration'),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _estimatedDurationController,
                                    validator: _durationValidator,
                                    decoration: _decoration(
                                      'e.g., 3 hrs / 45 mins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Row 2: Start Date and Next Due Date
                      Row(
                        children: [
                          // Start Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Start Date'),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _startDateController,
                                    validator: _req,
                                    readOnly: true,
                                    onTap:
                                        () => _pickDate(
                                          initial: _startDate ?? DateTime.now(),
                                          onPick: _handleStartDateChange,
                                        ),
                                    decoration: _decoration(
                                      'YYYY-MM-DD',
                                    ).copyWith(
                                      suffixIcon: const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Next Due Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Next Due Date'),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _nextDueDateController,
                                    validator: _req,
                                    readOnly: true,
                                    decoration: _decoration(
                                      'YYYY-MM-DD',
                                    ).copyWith(
                                      suffixIcon: const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      _buildRecurrenceSummary(),
                      const SizedBox(height: 40),

                      const Text(
                        "Assign Staff",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          // Department dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Department'),
                                _fieldBox(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedDepartment,
                                    validator: _reqDropdown,
                                    decoration: _decoration(
                                      'Select department...',
                                    ),
                                    items: ['Carpentry', 'Electrical', 'Masonry', 'Plumbing']
                                        .map((v) => DropdownMenuItem<String>(
                                              value: v,
                                              child: Text(v),
                                            ))
                                        .toList(),
                                    onChanged: (v) => setState(
                                          () => _selectedDepartment = v,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Assigned Staff
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Assign Staff'),
                                _fieldBox(
                                  child: Autocomplete<Map<String, dynamic>>(
                                    optionsBuilder: (textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return _staffMembers;
                                      }
                                      return _staffMembers.where((staff) {
                                        final name =
                                            '${staff['first_name'] ?? ''} ${staff['last_name'] ?? ''}'
                                                .toLowerCase();
                                        return name.contains(
                                          textEditingValue.text.toLowerCase(),
                                        );
                                      });
                                    },
                                    displayStringForOption:
                                        (staff) =>
                                            '${staff['first_name'] ?? ''} ${staff['last_name'] ?? ''}'
                                                .trim(),
                                    onSelected: (staff) {
                                      setState(() {
                                        _selectedStaffUserId =
                                            staff['uid'] ?? staff['id'];
                                        _assignedStaffController.text =
                                            '${staff['first_name'] ?? ''} ${staff['last_name'] ?? ''}'
                                                .trim();
                                      });
                                    },
                                    fieldViewBuilder: (
                                      context,
                                      controller,
                                      focusNode,
                                      onFieldSubmitted,
                                    ) {
                                      // Sync the autocomplete controller with our main controller
                                      if (_assignedStaffController
                                              .text
                                              .isNotEmpty &&
                                          controller.text !=
                                              _assignedStaffController.text) {
                                        controller.text =
                                            _assignedStaffController.text;
                                      }

                                      return TextFormField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        validator: _req,
                                        decoration: _decoration(
                                          'Start typing staff name...',
                                        ),
                                        onChanged: (value) {
                                          // Clear selected staff ID if user manually edits
                                          if (value !=
                                              _assignedStaffController.text) {
                                            setState(() {
                                              _selectedStaffUserId = null;
                                            });
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // ===== Inventory Items =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Inventory Items",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addInventoryItem,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("Add Item"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (_selectedInventoryItems.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Text(
                            'No inventory items added yet. Click "Add Item" to request inventory.',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedInventoryItems.length,
                            separatorBuilder:
                                (context, index) =>
                                    Divider(height: 1, color: Colors.grey[300]),
                            itemBuilder: (context, index) {
                              final item = _selectedInventoryItems[index];
                              return ListTile(
                                dense: true,
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2,
                                    color: Color(0xFF2E7D32),
                                    size: 20,
                                  ),
                                ),
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
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E8),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            'Qty: ${item['quantity']}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Available: ${item['available_stock']}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  color: Colors.red[400],
                                  onPressed: () => _removeInventoryItem(index),
                                  tooltip: 'Remove',
                                ),
                              );
                            },
                          ),
                        ),

                      //const SizedBox(height: 40),
                      // const Text(
                      //   "Attachments",
                      //   style: TextStyle(
                      //     fontSize: 20,
                      //     fontWeight: FontWeight.w600,
                      //     color: Colors.black87,
                      //   ),
                      // ),
                      // const SizedBox(height: 24),
                      // Container(
                      //   height: 140,
                      //   width: double.infinity,
                      //   decoration: BoxDecoration(
                      //     border: Border.all(
                      //       color: Colors.grey[300]!,
                      //       width: 2,
                      //     ),
                      //     borderRadius: BorderRadius.circular(8),
                      //   ),
                      //   child: InkWell(
                      //     onTap: () {
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         const SnackBar(
                      //           content: Text(
                      //             'File upload - Feature coming soon!',
                      //           ),
                      //         ),
                      //       );
                      //     },
                      //     child: Column(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: [
                      //         Icon(
                      //           Icons.upload_outlined,
                      //           size: 32,
                      //           color: Colors.grey[400],
                      //         ),
                      //         const SizedBox(height: 8),
                      //         const Text(
                      //           "Drop files here or click to upload",
                      //           style: TextStyle(
                      //             fontSize: 14,
                      //             fontWeight: FontWeight.w500,
                      //           ),
                      //         ),
                      //         const SizedBox(height: 4),
                      //         Text(
                      //           "PDF, PNG, JPG up to 10MB",
                      //           style: TextStyle(
                      //             fontSize: 12,
                      //             color: Colors.grey[600],
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(height: 40),
                      const Text(
                        "Remarks / Admin Notes",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _remarksController,
                        maxLines: 5,
                        decoration: _decoration('Enter Description....'),
                      ),

                      const SizedBox(height: 40),
                      const Text(
                        "Notifications",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: _fieldBox(
                              child: DropdownButtonFormField<String>(
                                value: _selectedAdminNotification,
                                decoration: _decoration('Before due date'),
                                items:
                                    const [
                                          'Before due date',
                                          '1 day before',
                                          '3 days before',
                                          '1 week before',
                                        ]
                                        .map(
                                          (v) => DropdownMenuItem(
                                            value: v,
                                            child: Text(v),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (v) => setState(() {
                                      _selectedAdminNotification = v;
                                      _selectedStaffNotification = v;
                                    }),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Applies to both admin and assigned staff reminders.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),

                      const SizedBox(height: 40),

                      // ===== Actions =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: _saveDraft,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.save_outlined,
                                  size: 18,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Save Draft",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _onNext, // VALIDATE then NAVIGATE
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Submit Internal Task",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- SMALL UI HELPERS --------------------
  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400]),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      borderSide: const BorderSide(color: Colors.blue),
    ),
  );

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    ),
  );

  // Wrap inputs to enforce consistent heights
  Widget _fieldBox({required Widget child}) =>
      SizedBox(height: _kFieldHeight, child: child);
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
  State<_InventorySelectionDialog> createState() =>
      _InventorySelectionDialogState();
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
              child:
                  _filteredItems.isEmpty
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
                          final isLowStock =
                              currentStock <= (item['reorder_level'] ?? 0);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(0xFFE8F5E8)
                                      : Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey[200]!,
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
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Department: ${item['department'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
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
                                          color:
                                              isLowStock
                                                  ? Colors.orange[100]
                                                  : Colors.green[100],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'Stock: $currentStock',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                isLowStock
                                                    ? Colors.orange[900]
                                                    : Colors.green[900],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing:
                                  isSelected
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF2E7D32),
                                      )
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
                  onPressed:
                      _selectedItem == null
                          ? null
                          : () {
                            final quantity =
                                int.tryParse(_quantityController.text) ?? 1;
                            if (quantity <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Quantity must be greater than 0',
                                  ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
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
