import 'dart:math' as math;
import 'package:facilityfix/adminweb/widgets/logout_popup.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../services/api_service.dart';
import '../services/round_robin_assignment_service.dart';
import '../../services/auth_storage.dart';
import '../../services/api_services.dart' as main_api;
import 'package:file_picker/file_picker.dart';
import 'package:facilityfix/services/api_services.dart' as SecondaryAPI;
class InternalMaintenanceFormPage extends StatefulWidget {
  final Map<String, dynamic>? maintenanceData;
  final bool isEditMode;

  const InternalMaintenanceFormPage({
    super.key,
    this.maintenanceData,
    this.isEditMode = false,
    
  });

  

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
  final SecondaryAPI.APIService api = SecondaryAPI.APIService();

  String? _createdByName;

  // For consistent field heights (match external design)
  static const double _kFieldHeight = 48;
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




  List<PlatformFile>? attachments = const [];
  bool _isAutoAssigning = false;
  // -------------------- CONTROLLERS --------------------
  final _taskTitleController = TextEditingController();
  final _codeIdController =
      TextEditingController(); // Auto-generated, read-only
  final _assignedStaffController = TextEditingController(
    text: 'Staff Name',
  ); // Now editable, default placeholder
  final _dateCreatedController = TextEditingController(); // read-only display
  final _descriptionController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  final _remarksController = TextEditingController();
  final _adminNotesController = TextEditingController();
  final _startDateController = TextEditingController(); // read-only
  final _nextDueDateController = TextEditingController(); // read-only
  final _checklistItemController = TextEditingController(); // For checklist input

  // -------------------- STATE --------------------
  String? _selectedPriority;
  String? _selectedStatus;
  String? _selectedLocation;
  String? _selectedRecurrence;
  String? _selectedDepartment;
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
  final _roundRobinService = RoundRobinAssignmentService();

  // Local editing toggle used when the parent did not supply edit mode
  bool _isLocalEdit = false;

  bool get _isEditing => widget.isEditMode || _isLocalEdit;

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

      // Set the Created By name
      setState(() {
        _createdByName = fullName.isNotEmpty ? fullName : 'Admin User';
      });

      // Also set assigned staff controller
      if (fullName.isNotEmpty) {
        _assignedStaffController.text = fullName;
      }
    }

    try {
      final codeId = await _apiService.getNextIPMCode();
      _codeIdController.text = codeId;
      print('[v0] Generated IPM code: $codeId');
    } catch (e) {
      print('[v0] Error fetching IPM code: $e');
      // Fallback to timestamp-based code if backend fails
      final year = DateTime.now().year;
      final number = DateTime.now().millisecondsSinceEpoch % 100000;
      _codeIdController.text = 'IPM-$year-${number.toString().padLeft(5, '0')}';
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
      // TODO: Replace with actual building ID from user session
      final response = await _mainApiService.getBuildingInventory('default_building_id');

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

    // Filter items based on selected location
    List<Map<String, dynamic>> filteredItems = _availableInventoryItems;
    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
      filteredItems =
          _availableInventoryItems.where((item) {
            final recommendedOn = item['recommended_on'];
            if (recommendedOn == null)
              return true; // Show items without recommendations
            if (recommendedOn is List) {
              return recommendedOn.contains(_selectedLocation);
            }
            return true;
          }).toList();
    }

    showDialog(
      context: context,
      builder:
          (context) => _InventorySelectionDialog(
            availableItems: filteredItems,
            selectedLocation: _selectedLocation,
            onItemSelected: (item, quantity) {
              setState(() {
                _selectedInventoryItems.add({
                  'inventory_id': item['item_code'] ?? item['itemCode'] ?? item['id'] ?? item['_doc_id'],
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

  // Auto-assign staff based on selected department using round-robin
  Future<void> _handleAutoAssignStaff() async {
    if (_selectedDepartment == null || _selectedDepartment!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a department first'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Set loading state
    setState(() {
      _isAutoAssigning = true;
    });

    try {
      // Map UI department names to backend department values
      String departmentKey;
      switch (_selectedDepartment!.toLowerCase()) {
        case 'carpentry':
          departmentKey = 'carpentry';
          break;
        case 'electrical':
          departmentKey = 'electrical';
          break;
        case 'masonry':
          departmentKey = 'masonry';
          break;
        case 'plumbing':
          departmentKey = 'plumbing';
          break;
        default:
          departmentKey = 'general_maintenance';
      }

      final nextStaff = await _roundRobinService.getNextStaffForDepartment(
        departmentKey,
      );

      if (nextStaff != null) {
        final firstName = nextStaff['first_name'] ?? '';
        final lastName = nextStaff['last_name'] ?? '';
        final staffName = '$firstName $lastName'.trim();
        final staffId = nextStaff['user_id'] ?? nextStaff['id'];

        // Update the text field and selected staff ID
        if (mounted) {
          setState(() {
            _assignedStaffController.text = staffName;
            _selectedStaffUserId = staffId;
            // _isAutoAssigning = false;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Auto-assigned to $staffName')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          // setState(() {
          //   _isAutoAssigning = false;
          // });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No available staff found in $_selectedDepartment department',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('[AutoAssign] Error auto-assigning staff: $e');
      if (mounted) {
        // setState(() {
        //   _isAutoAssigning = false;
        // });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to auto-assign staff: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Auto-populate recommended inventory items for selected location
  void _autoPopulateInventoryForLocation(String? location) {
    if (location == null || location.isEmpty) return;
    if (_availableInventoryItems.isEmpty) return;

    // Find items recommended for this location
    final recommendedItems =
        _availableInventoryItems.where((item) {
          final recommendedOn = item['recommended_on'];
          if (recommendedOn == null) return false;
          if (recommendedOn is List) {
            return recommendedOn.contains(location);
          }
          return false;
        }).toList();

    // Add recommended items that aren't already selected
    for (final item in recommendedItems) {
      final itemCode = item['item_code'] ?? item['itemCode'];
      final alreadyAdded = _selectedInventoryItems.any(
        (selected) => selected['inventory_id'] == itemCode,
      );

      if (!alreadyAdded) {
        setState(() {
          _selectedInventoryItems.add({
            'inventory_id': itemCode,
            'item_name': item['item_name'],
            'item_code': item['item_code'],
            'quantity': '', // Default quantity
            'available_stock': item['current_stock'],
          });
        });
      }
    }

    // Show feedback to user
    if (recommendedItems.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${recommendedItems.length} recommended item(s) for $location',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<List<String>> _createInventoryReservations(String taskId) async {
    if (_selectedInventoryItems.isEmpty) return [];

    final List<String> createdReservationIds = [];

    try {
      for (final item in _selectedInventoryItems) {
        final qty = item['quantity'];
        if (qty == null || qty <= 0) {
          print('[v0] Skipping reservation for ${item['item_name']} due to invalid quantity: $qty');
          continue;
        }
        final response = await _apiService.createInventoryReservation(
          inventoryId: item['inventory_id'],
          quantity: qty,
          maintenanceTaskId: taskId,
        );

        // Extract the reservation ID from the response
        if (response['success'] == true && response['reservation_id'] != null) {
          createdReservationIds.add(response['reservation_id']);
          print('[v0] Created inventory reservation: ${response['reservation_id']}');
        }
      }
      print(
        '[v0] Created ${createdReservationIds.length} inventory reservations linked to task $taskId',
      );
      return createdReservationIds;
    } catch (e) {
      print('[v0] Error creating inventory reservations: $e');
      throw Exception('Failed to create inventory reservations: $e');
    }
  }

  DateTime _calculateNextDueDate(DateTime base, String frequency) {
    switch (frequency) {
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

  // Parse duration string to minutes (e.g., "3 hrs" -> 180, "45 mins" -> 45)
  int _parseDurationToMinutes(String durationStr) {
    final trimmed = durationStr.trim().toLowerCase();
    final re = RegExp(r'(\d+)\s*(min|mins|minutes|hr|hrs|hour|hours)');
    final match = re.firstMatch(trimmed);

    if (match == null) return 0;

    final value = int.tryParse(match.group(1) ?? '0') ?? 0;
    final unit = match.group(2) ?? '';

    if (unit.startsWith('hr') || unit.startsWith('hour')) {
      return value * 60; // Convert hours to minutes
    } else {
      return value; // Already in minutes
    }
  }

  // -------------------- INIT/DISPOSE --------------------
  @override
  void initState() {
    super.initState();
    _initAutoFields();

    // If in edit mode, populate fields with existing data
    if (widget.isEditMode && widget.maintenanceData != null) {
      _populateFormFields(widget.maintenanceData!);
    }
  }

  void _populateFormFields(Map<String, dynamic> data) {
    // Debug: print the data received for population
    print('[Form] Populating form fields from data: $data');
    setState(() {
      // Basic fields
      _taskTitleController.text = data['task_title'] ?? data['taskTitle'] ?? '';
      _codeIdController.text =
          data['task_code'] ?? data['id']?.toString() ?? '';
      _descriptionController.text =
          data['task_description'] ?? data['description'] ?? '';

      // Handle estimated_duration - convert from minutes (int) back to readable format
      final durationMinutes = data['estimated_duration'];
      if (durationMinutes != null &&
          durationMinutes is int &&
          durationMinutes > 0) {
        if (durationMinutes >= 60) {
          final hours = durationMinutes ~/ 60;
          final remainingMins = durationMinutes % 60;
          if (remainingMins > 0) {
            _estimatedDurationController.text =
                '$hours hrs $remainingMins mins';
          } else {
            _estimatedDurationController.text = '$hours hrs';
          }
        } else {
          _estimatedDurationController.text = '$durationMinutes mins';
        }
      } else if (durationMinutes is String) {
        _estimatedDurationController.text = durationMinutes;
      } else {
        _estimatedDurationController.text = '';
      }

      // Remarks / Additional notes - accept several possible backend keys
      String? remarksVal;
      for (final k in ['remarks', 'additional_notes', 'additional_note', 'additional_comments', 'notes', 'admin_notification']) {
        final v = data[k];
        if (v != null) {
          remarksVal = v.toString();
          break;
        }
      }
      _remarksController.text = remarksVal ?? '';

      // Admin notes - accept several possible backend keys
      String? adminNotesVal;
      for (final k in ['admin_notes', 'admin_notification', 'notes', 'adminNote']) {
        final v = data[k];
        if (v != null) {
          adminNotesVal = v.toString();
          break;
        }
      }
      _adminNotesController.text = adminNotesVal ?? '';
      print('[Form] Populated admin notes: "${_adminNotesController.text}"');

      // Dropdowns - validate values are in options list
      // Priority: Low, Medium, High
      final priority = data['priority']?.toString();
      final validPriorities = ['Low', 'Medium', 'High'];
      _selectedPriority = validPriorities.contains(priority) ? priority : null;

  // Status: coerce to string if present
  _selectedStatus = data['status']?.toString();

      // Location: validate against location options
      final location = data['location'] ?? data['area'];
      final validLocations = [
        'Swimming pool',
        'Basketball Court',
        'Gym',
        'Parking area',
        'Lobby',
        'Elevators',
        'Halls',
        'Garden',
        'Corridors',
        'Other',
      ];
      _selectedLocation =
          (location != null && validLocations.contains(location.toString()))
              ? location.toString()
              : null;

      // Recurrence - capitalize first letter to match dropdown options
      final recurrence = data['recurrence_type'] ?? data['recurrence'];
      if (recurrence != null) {
        final recurrenceCapitalized = recurrence
            .toString()
            .split('_')
            .map((word) {
              if (word.isEmpty) return word;
              return word[0].toUpperCase() + word.substring(1).toLowerCase();
            })
            .join(' ');
        // Valid recurrence options: Weekly, Monthly, Quarterly, Annually
        final validRecurrences = [
          'Weekly',
          'Monthly',
          'Quarterly',
          'Annually',
        ];
        _selectedRecurrence =
            validRecurrences.contains(recurrenceCapitalized)
                ? recurrenceCapitalized
                : null;
      }

      // Department: validate against department options
      final department = data['department'];
      final validDepartments = [
        'Maintenance',
        'Housekeeping',
        'Security',
        'Engineering',
      ];
      _selectedDepartment =
          (department != null &&
                  validDepartments.contains(department.toString()))
              ? department.toString()
              : null;

      // Staff assignment (coerce id to String, name to String)
      if (data['assigned_to'] != null) {
        try {
          _selectedStaffUserId = data['assigned_to']?.toString();
        } catch (_) {
          _selectedStaffUserId = null;
        }
        _assignedStaffController.text =
            (data['assigned_staff_name'] ?? 'Staff Name').toString();
      }

      // Dates - parse flexibly (accept ISO strings or integer timestamps)
      DateTime? parseFlexibleDate(dynamic raw) {
        if (raw == null) return null;
        try {
          if (raw is DateTime) return raw;
          if (raw is int) {
            // Heuristic: if it's in seconds (10 digits), convert to ms
            if (raw.abs() < 100000000000) {
              // likely seconds
              return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
            }
            return DateTime.fromMillisecondsSinceEpoch(raw);
          }
          if (raw is String) {
            // Try ISO parse
            return DateTime.tryParse(raw);
          }
          if (raw is double) {
            final asInt = raw.toInt();
            if (asInt.abs() < 100000000000) {
              return DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
            }
            return DateTime.fromMillisecondsSinceEpoch(asInt);
          }
        } catch (e) {
          print('parseFlexibleDate error: $e');
        }
        return null;
      }

      final createdAt = parseFlexibleDate(data['created_at']);
      if (createdAt != null) {
        _dateCreated = createdAt;
        _dateCreatedController.text = _fmtDate(_dateCreated!);
      }

      final startAt = parseFlexibleDate(data['start_date'] ?? data['scheduled_date']);
      if (startAt != null) {
        _startDate = startAt;
        _startDateController.text = _fmtDate(_startDate!);
      }

      final nextAt = parseFlexibleDate(data['next_due_date'] ?? data['next_due'] ?? data['next_occurrence']);
      if (nextAt != null) {
        _nextDueDate = nextAt;
        _nextDueDateController.text = _fmtDate(_nextDueDate!);
      }

      // Checklist items
      if (data['checklist'] != null && data['checklist'] is List) {
        print('[Form] Populating checklist from data: ${data['checklist']}');
        _checklistItems.clear();
        for (var item in data['checklist']) {
          _checklistItems.add({
            'id':
                item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'task': item['task'] ?? item['description'] ?? '',
            'completed': item['completed'] ?? false,
          });
        }
        print('[Form] Populated ${_checklistItems.length} checklist items');
      }

      // Inventory items
      if (data['parts_used'] != null && data['parts_used'] is List) {
        print('[Form] Populating inventory from data: ${data['parts_used']}');
        _selectedInventoryItems.clear();
        for (var item in data['parts_used']) {
          _selectedInventoryItems.add({
            'inventory_id': item['inventory_id'] ?? item['item_code'] ?? '', 
            'item_name': item['item_name'] ?? item['name'] ?? '',
            'item_code': item['item_code'] ?? item['code'] ?? '',
            'quantity': item['quantity'] ?? '',
            'available_stock': item['available_stock'] ?? item['stock'] ?? '',
          });
        }
      }

      // Created by - keep as current user, don't override from data
      // _createdByName = data['created_by'] ?? 'Admin User';
    });
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
    _adminNotesController.dispose();
    _startDateController.dispose();
    _nextDueDateController.dispose();
    _checklistItemController.dispose(); // Dispose new controller
    super.dispose();
  }

  // -------------------- ACTIONS --------------------
  void _cancelEdit() {
    // If we're in a local edit session, revert changes and exit edit mode.
    if (_isLocalEdit) {
      setState(() {
        _autoMode = AutovalidateMode.disabled;
        _isLocalEdit = false;
        if (widget.maintenanceData != null) {
          _populateFormFields(widget.maintenanceData!);
        }
      });
      return;
    }

    // Otherwise, close the form / dialog
    Navigator.of(context).pop();
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

    // Parse duration to minutes for backend
    final durationInMinutes = _parseDurationToMinutes(
      _estimatedDurationController.text.trim(),
    );

    // Ensure we have a valid duration (greater than 0)
    // If parsing failed or returned 0, this should not happen due to validation
    // But we add this check for safety
    if (durationInMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid estimated duration. Please check the format.'),
        ),
      );
      return;
    }

    final maintenance = <String, dynamic>{
      'id': id,
      'maintenanceType': 'Internal',
      'taskTitle': _taskTitleController.text.trim(),
      'taskCode': id,
      'dateCreated': _dateCreatedController.text,
      'priority': _selectedPriority ?? 'medium',
      'status': _selectedStatus ?? 'scheduled',
      'location': _selectedLocation ?? '',
      'description': _descriptionController.text.trim(),
      'recurrence': _selectedRecurrence,
      'startDate': _startDateController.text,
      'nextDueDate': _nextDueDateController.text,
      'assigneeName': _assignedStaffController.text.trim(),
      'assigneeDept': _selectedDepartment,
      'checklistItems': _checklistItems,
      'adminNotify':
          '3 months before, 1 month before, 1 week before, 5 days before, 3 days before, 1 day before',
      'staffNotify':
          '3 months before, 1 month before, 1 week before, 5 days before, 3 days before, 1 day before',
      'remarks': _remarksController.text.trim(),
      'admin_notes': _adminNotesController.text.trim(),
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
      'estimated_duration':
          durationInMinutes, // Backend expects integer in minutes
      'checklist_completed': _checklistItems,
      'parts_used': <Map<String, dynamic>>[],
      'tools_used': <String>[],
      'photos': <String>[],
    };

    // Debug: print the maintenance data being sent
    print('[Form] Maintenance data to send: $maintenance');

    try {
      if (widget.isEditMode && widget.maintenanceData != null) {
        // UPDATE existing task
        final taskId = widget.maintenanceData!['id']?.toString() ?? id;
        print('[v0] Updating maintenance task: $taskId');

        final result = await _apiService.updateMaintenanceTask(
          taskId,
          maintenance,
        );
        print('[v0] Maintenance task updated successfully');
        print('[v0] Backend response: $result');


  


      // upload files to firebase storage 

      for (final file in attachments!) {
          await api.uploadMultipartFile(
            path: '/files/upload',
            file: file,
            fields: {
              'entity_type': 'Internal Maintenance Attachments',
              'entity_id': result['task']['id'],
              'file_type': 'any',
              'description': 'Attachment for maintenance task ${result['id']}',
            },
          );

      }




        // Navigate back to maintenance list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maintenance task updated successfully!'),
            ),
          );
          context.go('/work/maintenance');
        }
      } else {
        // CREATE new task
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

        // Create inventory reservations for selected items with the correct task ID
        final inventoryReservationIds = await _createInventoryReservations(
          actualTaskId,
        );

        // Update the maintenance task with the inventory reservation IDs
        if (inventoryReservationIds.isNotEmpty) {
          try {
            final response = await _apiService.updateMaintenanceTask(actualTaskId, {
              'inventory_reservation_ids': inventoryReservationIds,
            });

            final result = response;

            // upload files to firebase storage

      for (final file in attachments!) {
          await api.uploadMultipartFile(
            path: '/files/upload',
            file: file,
            fields: {
              'entity_type': 'Internal Maintenance Attachments',
              'entity_id': actualTaskId,
              'file_type': 'any',
              'description': 'Attachment for maintenance task ${result['id']}',
            },
          );

      }

            print(

              '[v0] Updated maintenance task with inventory reservation IDs: $inventoryReservationIds',
            );
          } catch (e) {
            print(
              '[v0] Warning: Failed to update maintenance task with inventory reservation IDs: $e',
            );
            // Don't fail the whole operation if this update fails
          }
        }

        // Navigate to view page with the data
        if (mounted) {
          context.push('/work/maintenance/', extra: maintenance);
        }
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
                    "Task Management",
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
                        child: const Text('Task Management'),
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
                        child: const Text('Maintenance Tasks'),
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
                      _buildSectionHeader(
                        "Basic Information",
                        "General details about the maintenance task",
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

                          // Task ID
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Task ID'),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _codeIdController,
                                    enabled: false,
                                    decoration: _decoration(
                                      'Auto-generated',
                                    ).copyWith(
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
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
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          // Created By - Fetch from admin profile
                            Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              _fieldLabel('Created By'),
                              _fieldBox(
                                child: TextFormField(
                                initialValue: _createdByName ?? 'Admin User',
                                enabled: false,
                                decoration: _decoration(
                                  _createdByName ?? 'Admin User',
                                ).copyWith(
                                  disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                  ),
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

                      const SizedBox(height: 40),

                      // ===== Task Scope & Description =====
                      _buildSectionHeader(
                        "Task Scope & Description",
                        "Detailed description of what needs to be done",
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          // Priority - left
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
                                        const [
                                              'Low',
                                              'Medium',
                                              'High',
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
                                          () => _selectedPriority = v,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Location/Area - right
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Location / Area'),
                                _fieldBox(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedLocation,
                                    validator: _reqDropdown,
                                    decoration: _decoration(
                                      'Select Location...',
                                    ),
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
                                              'Others',
                                            ]
                                            .map(
                                              (v) => DropdownMenuItem(
                                                value: v,
                                                child: Text(v),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        _selectedLocation = v;
                                      });
                                      _autoPopulateInventoryForLocation(v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Specify Location (only shown when "Others" is selected, on the right)
                      if (_selectedLocation == 'Others')
                        Row(
                          children: [
                            const Expanded(child: SizedBox()), // Left spacer
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel('Specify Location'),
                                  _fieldBox(
                                    child: TextFormField(
                                      validator: _req,
                                      decoration: _decoration(
                                        'Enter custom location...',
                                      ),
                                      onChanged: (value) {
                                        // Store custom location value
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      if (_selectedLocation == 'Others')
                        const SizedBox(height: 24),

                      // Description
                      _fieldLabel('Description'),
                      TextFormField(
                        controller: _descriptionController,
                        validator: _req,
                        maxLines: 5,
                        decoration: _decoration('Enter Description....'),
                      ),

                      const SizedBox(height: 24),

                      // ===== Schedule and Checklist =====
                      _buildSectionHeader(
                        "Schedule and Checklist",
                        "Define task steps and scheduling",
                      ),
                      const SizedBox(height: 24),

                      // ===== Recurrence & Schedule =====
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
                                ).copyWith(
                                  suffixIcon: IconButton(
                                  icon: const Icon(Icons.access_time),
                                  tooltip: 'Pick hours & minutes',
                                  onPressed: () async {
                                    final picked = await showTimePicker(
                                    context: context,
                                    // Use a neutral initial time for duration selection
                                    initialTime: TimeOfDay(hour: 0, minute: 30),
                                    );
                                    if (picked != null) {
                                    final h = picked.hour;
                                    final m = picked.minute;
                                    String formatted;
                                    if (h > 0 && m > 0) {
                                      formatted = '$h hrs $m mins';
                                    } else if (h > 0) {
                                      formatted = '$h hrs';
                                    } else {
                                      formatted = '$m mins';
                                    }
                                    setState(() {
                                      _estimatedDurationController.text = formatted;
                                    });
                                    }
                                  },
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
                      const SizedBox(height: 16),
                      // Recurrence summary (placed below Start Date / Next Due Date)
                      _buildRecurrenceSummary(),
                      const SizedBox(height: 24),
                      // Checklist input field with Add Task button beside it - Left side only
                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Checklist/Task Step'),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _fieldBox(
                                        child: TextFormField(
                                          controller: _checklistItemController,
                                          decoration: _decoration(
                                            'Add a task step...',
                                          ),
                                          onFieldSubmitted:
                                              (_) => _addChecklistItem(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _fieldBox(
                                      child: ElevatedButton(
                                        onPressed: _addChecklistItem,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          minimumSize: const Size(
                                            0,
                                            _kFieldHeight,
                                          ),
                                        ),
                                        child: const Text("Add Task"),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Expanded(flex: 4, child: SizedBox()),
                        ],
                      ),

                      // Display added checklist items - Left side only (match Add Task field width)
                      if (_checklistItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 6, // same flex as the Add Task input column
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _checklistItems.length,
                                  separatorBuilder:
                                      (context, index) => Divider(
                                        height: 1,
                                        color: Colors.grey[300],
                                      ),
                                  itemBuilder: (context, index) {
                                    final item = _checklistItems[index];
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(
                                        Icons.check_circle_outline,
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
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const Expanded(flex: 4, child: SizedBox()),
                          ],
                        ),
                      ],

                      const SizedBox(height: 40),

                      // ===== Assign Staff =====
                      _buildSectionHeader(
                        "Assign Staff",
                        "Select department and assign staff member",
                      ),
                      const SizedBox(height: 24),

                      // Department (left) and Assign Staff (right) - auto fill on change
                      Row(
                        children: [
                          // Department - left
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
                                      'Select Department...',
                                    ),
                                    items:
                                        [
                                              'Carpentry',
                                              'Electrical',
                                              'Masonry',
                                              'Plumbing',
                                            ]
                                            .map(
                                              (d) => DropdownMenuItem(
                                                value: d,
                                                child: Text(d),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) {
                                      setState(() => _selectedDepartment = v);
                                      // Automatically attempt to assign staff for the selected department
                                      _handleAutoAssignStaff();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 24),

                          // Assign Staff - right (read-only, auto-filled)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Assign Staff'),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _assignedStaffController,
                                    enabled: false,
                                    decoration: _decoration(
                                      'Staff Name',
                                    ).copyWith(
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
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

                      const SizedBox(height: 8),

                      // Helper/info note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select a department to automatically assign the next available staff member using round-robin. The assigned staff will appear on the right.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Place inventory UI on the right side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column containing the Inventory section
                          SizedBox(
                            width: 520,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: _buildSectionHeader(
                                        "Inventory Items",
                                        "Reserve parts or supplies for the task",
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _addInventoryItem,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text("Add Item"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2E7D32,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Text(
                                      'No inventory items reserved yet. Click "Add Item" to reserve inventory.',
                                      style: TextStyle(color: Colors.grey[600]),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                else
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _selectedInventoryItems.length,
                                      separatorBuilder:
                                          (context, index) => Divider(
                                            height: 1,
                                            color: Colors.grey[300],
                                          ),
                                      itemBuilder: (context, index) {
                                        final item =
                                            _selectedInventoryItems[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              // Icon
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFE8F5E8,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.inventory_2,
                                                  color: Color(0xFF2E7D32),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),

                                              // Item details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['item_name'] ??
                                                          'Unknown Item',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Code: ${item['item_code'] ?? 'N/A'}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Available: ${item['available_stock']}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                                // Quantity controls (fixed increment/decrement)
                                                Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                  color: Colors.grey[300]!,
                                                  ),
                                                  borderRadius:
                                                    BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                    MainAxisSize.min,
                                                  children: [
                                                  // Decrement button
                                                  IconButton(
                                                    icon: const Icon(
                                                    Icons.remove,
                                                    size: 16,
                                                    ),
                                                    padding:
                                                      const EdgeInsets.all(4),
                                                    constraints:
                                                      const BoxConstraints(
                                                    minWidth: 32,
                                                    minHeight: 32,
                                                    ),
                                                    onPressed: () {
                                                    setState(() {
                                                      final currentQty =
                                                        int.tryParse(
                                                          item['quantity']
                                                            ?.toString() ??
                                                          '0',
                                                          ) ??
                                                          0;
                                                      final availableStock =
                                                        int.tryParse(
                                                          item['available_stock']
                                                            ?.toString() ??
                                                          '0',
                                                          ) ??
                                                          0;

                                                      if (currentQty > 1) {
                                                      _selectedInventoryItems[index]
                                                        ['quantity'] =
                                                        currentQty - 1;
                                                      } else {
                                                      // Optionally notify user they can't go below 1
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                        content: Text(
                                                          'Quantity cannot be less than 1',
                                                        ),
                                                        duration:
                                                          Duration(
                                                          seconds: 1,
                                                        ),
                                                        ),
                                                      );
                                                      }

                                                      // Ensure consistency if available stock dropped to 0
                                                      if (availableStock <= 0) {
                                                      _selectedInventoryItems[index]
                                                        ['quantity'] = 0;
                                                      }
                                                    });
                                                    },
                                                    color: Colors.grey[700],
                                                  ),

                                                  // Quantity display (non-editable to ensure consistent updates)
                                                  SizedBox(
                                                    width: 50,
                                                    child: Center(
                                                    child: Text(
                                                      '${item['quantity']}',
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                        FontWeight.w600,
                                                      ),
                                                    ),
                                                    ),
                                                  ),

                                                  // Increment button (robust parsing & clamping)
                                                  IconButton(
                                                    icon: const Icon(
                                                    Icons.add,
                                                    size: 16,
                                                    ),
                                                    padding:
                                                      const EdgeInsets.all(4),
                                                    constraints:
                                                      const BoxConstraints(
                                                    minWidth: 32,
                                                    minHeight: 32,
                                                    ),
                                                    onPressed: () {
                                                    setState(() {
                                                      final currentQty =
                                                        int.tryParse(
                                                          item['quantity']
                                                            ?.toString() ??
                                                          '0',
                                                          ) ??
                                                          0;
                                                      final availableStock =
                                                        int.tryParse(
                                                          item['available_stock']
                                                            ?.toString() ??
                                                          '0',
                                                          ) ??
                                                          0;

                                                      if (availableStock <= 0) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                        content:
                                                          Text('No stock available'),
                                                        duration:
                                                          Duration(
                                                          seconds: 2,
                                                        ),
                                                        ),
                                                      );
                                                      return;
                                                      }

                                                      final newQty = (currentQty + 1)
                                                        .clamp(1, availableStock);

                                                      _selectedInventoryItems[index]
                                                        ['quantity'] = newQty;
                                                    });
                                                    },
                                                    color: const Color(
                                                    0xFF2E7D32,
                                                    ),
                                                  ),
                                                    ],
                                                  ),
                                                  ),
                                                  const SizedBox(width: 8),

                                              // Delete button
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 20,
                                                ),
                                                color: Colors.red[400],
                                                onPressed:
                                                    () => _removeInventoryItem(
                                                      index,
                                                    ),
                                                tooltip: 'Remove',
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Left spacer to push inventory to the right
                          const Expanded(child: SizedBox()),
                        ],
                      ),

                      const SizedBox(height: 40),
                    _buildSectionHeader(
                      "Admin Note",
                      "Notes for admins and post-task remarks",
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _adminNotesController,
                      maxLines: 5,
                      decoration: _decoration('Enter Description....'),
                    ),
                      const SizedBox(height: 24),

                      // ===== Actions =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cancel / Close
                          TextButton(
                            onPressed: _cancelEdit,
                            child: Text(
                              _isEditing ? 'Cancel' : 'Cancel',
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Primary action (Submit / Save)
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
                            child: Text(
                              _isEditing ? "Save Changes" : "Submit Internal Task",
                              style: const TextStyle(
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
  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

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
  final String? selectedLocation;
  final Function(Map<String, dynamic> item, int quantity) onItemSelected;

  const _InventorySelectionDialog({
    required this.availableItems,
    this.selectedLocation,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Inventory Item',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.selectedLocation != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Filtered for: ${widget.selectedLocation}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
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
                        labelText: 'Reserved Quantity',
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

// Add Location Dialog
class _AddLocationDialog extends StatefulWidget {
  final Function(String location) onLocationAdded;

  const _AddLocationDialog({required this.onLocationAdded});

  @override
  State<_AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<_AddLocationDialog> {
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
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
                  'Add Custom Location',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location input
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location Name',
                hintText: 'Enter custom location...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              autofocus: true,
            ),

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
                ElevatedButton(
                  onPressed: () {
                    final location = _locationController.text.trim();
                    if (location.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a location name'),
                        ),
                      );
                      return;
                    }
                    widget.onLocationAdded(location);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
