import 'dart:math' as math;

import 'package:facilityfix/adminweb/widgets/logout_popup.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/utils/inventory_notifier.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../services/api_service_web.dart';
import '../../services/auth_storage.dart';
import '../../services/api_services_mobile.dart' as main_api;

class ExternalMaintenanceFormPage extends StatefulWidget {
  final Map<String, dynamic>? maintenanceData;
  final bool isEditMode;

  const ExternalMaintenanceFormPage({
    super.key,
    this.maintenanceData,
    this.isEditMode = false,
  });

  @override
  State<ExternalMaintenanceFormPage> createState() =>
      _ExternalMaintenanceFormPageState();
}

class _ExternalMaintenanceFormPageState
    extends State<ExternalMaintenanceFormPage> {
  // ---------- Form + autovalidate gating ----------
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  // For consistent field heights
  static const double _kFieldHeight = 48;

  // ---------- Controllers ----------
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskCodeController = TextEditingController();
  final TextEditingController _createdByController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contractorNameController =
      TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _assessmentController = TextEditingController();
  final TextEditingController _recommendationController =
      TextEditingController();
  final TextEditingController _loggedByController = TextEditingController();
  final TextEditingController _otherLocationController =
      TextEditingController();
  final TextEditingController _otherServiceCategoryController =
      TextEditingController();
  final TextEditingController _estimatedDurationController =
      TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _nextDueDateController = TextEditingController();

  // ---------- State (dropdowns/dates) ----------
  String? _selectedServiceCategory;
  DateTime? _dateCreated;
  String? _selectedPriority;
  String? _selectedLocation;
  String? _selectedRecurrence;
  DateTime? _startDate;
  DateTime? _nextDueDate;
  DateTime? _serviceWindowStart;
  DateTime? _serviceWindowEnd;
  DateTime? _serviceDateActual;
  DateTime? _loggedDate;
  String? _selectedAssessmentReceived;
  String? _selectedAdminNotifications;
  String? _selectedTaskType;
  bool _isOtherLocation = false;
  bool _isOtherServiceCategory = false;
  // Inventory selections (basic local state for UI)
  List<Map<String, dynamic>> _selectedInventoryItems = [];
  // Task type related state
  String? _selectedTaskTypeId;
  // Estimated time for service (used by estimated duration field)
  TimeOfDay? _estimatedTime;

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

  // ---------- Options ----------
  final List<String> _serviceCategoryOptions = [
    'HVAC Systems',
    'Electrical Systems',
    'Plumbing',
    'Fire Safety',
    'Security Systems',
    'Elevators',
    'Cleaning Services',
    'Pest Control',
    'Other',
  ];

  // Task types loaded dynamically from AdminTaskTypePage
  List<Map<String, String>> _taskTypeOptions = [];

  void _handleServiceCategoryChange(String? category) {
    setState(() {
      _selectedServiceCategory = category;
      _isOtherServiceCategory = (category == 'Other');
      if (!_isOtherServiceCategory) {
        _otherServiceCategoryController.clear();
      }
    });
  }

  final List<String> _priorityOptions = ['Low', 'Medium', 'High'];
  final List<String> _locationOptions = [
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
  final List<String> _assessmentOptions = ['Yes', 'No', 'Pending'];

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

  // Auto-generate notifications based on task duration
  void _updateNotifications() {
    if (_startDate == null) return;

    final now = DateTime.now();
    final daysUntilStart = _startDate!.difference(now).inDays;

    // Auto-generate notification schedule based on time until task
    List<String> notifications = [];

    if (daysUntilStart >= 30) {
      notifications.add('1 month before');
    }
    if (daysUntilStart >= 7) {
      notifications.add('1 week before');
    }
    if (daysUntilStart >= 5) {
      notifications.add('5 days before');
    }
    if (daysUntilStart >= 3) {
      notifications.add('3 days before');
    }
    if (daysUntilStart >= 1) {
      notifications.add('1 day before');
    }

    setState(() {
      if (notifications.isNotEmpty) {
        _selectedAdminNotifications = notifications.join(', ');
      } else {
        _selectedAdminNotifications = 'On due date';
      }
    });
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
    final windowStart =
        _serviceWindowStart != null
            ? _formatFriendlyDate(_serviceWindowStart!)
            : null;
    final windowEnd =
        _serviceWindowEnd != null
            ? _formatFriendlyDate(_serviceWindowEnd!)
            : null;

    final buffer = StringBuffer(
      'Repeats $_selectedRecurrence starting $start. Next occurrence $next',
    );
    if (windowStart != null && windowEnd != null) {
      buffer.write(' - Service window $windowStart to $windowEnd');
    }
    return buffer.toString();
  }

  void _handleRecurrenceChange(String? value) {
    if (value == null) {
      setState(() => _selectedRecurrence = null);
      return;
    }

    final rawStart = _startDate ?? DateTime.now();
    final baseStart = DateTime(rawStart.year, rawStart.month, rawStart.day);
    final nextDue = _calculateNextDueDate(baseStart, value);

    setState(() {
      _selectedRecurrence = value;
      _startDate = baseStart;
      _nextDueDate = nextDue;
      _startDateController.text = _formatDateYYYYMMDD(baseStart);
      _nextDueDateController.text = _formatDateYYYYMMDD(nextDue);
      _updateNotifications(); // Auto-update notifications
    });
  }

  void _handleStartDateChange(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);

    setState(() {
      _startDate = normalized;
      _startDateController.text = _formatDateYYYYMMDD(normalized);

      if (_selectedRecurrence != null) {
        final nextDue = _calculateNextDueDate(normalized, _selectedRecurrence!);
        _nextDueDate = nextDue;
        _nextDueDateController.text = _formatDateYYYYMMDD(nextDue);
      }
      _updateNotifications(); // Auto-update notifications
    });
  }

  String _formatDateYYYYMMDD(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate({
    required DateTime initial,
    required Function(DateTime) onPick,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) onPick(picked);
  }

  Future<void> _pickEstimatedTime() async {
    final initial = _estimatedTime ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;

    // Accept only times between 09:00 and 19:00 inclusive
    if (picked.hour < 9 || picked.hour > 19) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a time between 09:00 and 19:00'),
        ),
      );
      return;
    }

    setState(() {
      _estimatedTime = picked;
      // Format using MaterialLocalizations for consistency
      final formatted = MaterialLocalizations.of(
        context,
      ).formatTimeOfDay(picked);
      _estimatedDurationController.text = formatted;
    });
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

  // ---------- Routing helpers ----------
  static String? _getRoutePath(String routeKey) {
    final Map<String, String> pathMap = {
      'dashboard': '/dashboard',
      'user_users': '/user/users',
      'user_scheduling': '/user/scheduling',
      'work_maintenance': '/work/maintenance',
      'work_task_type': '/work/task_type',
      'work_repair': '/work/repair',
      'calendar': '/calendar',
      'inventory_equipment': '/inventory/equipment',
      'inventory_items': '/inventory/items',
      'inventory_request': '/inventory/request',
      'analytics': '/analytics',
      'announcement': '/announcement',
      'settings': '/settings',
      //'logout': '/logout',
    };
    return pathMap[routeKey];
  }

  // Logout functionality
  void _handleLogout(BuildContext context) async {
    print('[DEBUG] _handleLogout called');
    // Ensure we're not already navigating
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (dialogContext) {
        print('[DEBUG] Dialog builder called');
        return const LogoutPopup();
      },
    );
    print('[DEBUG] Dialog result: $result');

    if (result == true && mounted) {
      // Perform logout
      print('[DEBUG] Logging out...');
      context.go('/');
    } else {
      print('[DEBUG] Logout cancelled or dialog dismissed');
    }
  }

  // ---------- Init: auto-fill automated fields ----------
  final ApiService _apiService = ApiService();
  bool _isLoadingCode = false;
  bool _isLoadingData = false;
  // main API service for inventory
  final _mainApiService = main_api.APIService();
  List<Map<String, dynamic>> _availableInventoryItems = [];

  @override
  void initState() {
    super.initState();
    _dateCreated = DateTime.now(); // prefill but user can change
    _selectedAssessmentReceived = 'No'; // Auto-set to "No" when task is created

    _initAutoFields();
    // load task types and inventory items in background
    _loadTaskTypes();
    _loadInventoryItems();

    // If in edit mode, fetch the full task data
    if (widget.isEditMode) {
      _fetchTaskData();
    }
  }

  /// Returns the total reserved quantity for the given inventory id across reservations
  Future<int> _getReservedQty(String inventoryId) async {
    try {
      final resp = await _apiService.getInventoryReservations();
      if (resp['success'] == true && resp['data'] != null) {
        final reservations = List<Map<String, dynamic>>.from(resp['data']);
        int reservedTotal = 0;
        for (var r in reservations) {
          if ((r['inventory_id']?.toString() ?? '') == inventoryId) {
            final status =
                (r['status'] ?? r['request_status'] ?? 'reserved')
                    .toString()
                    .toLowerCase();
            if (status == 'reserved' ||
                status == 'approved' ||
                status == 'pending') {
              reservedTotal += (r['quantity'] ?? 0) as int;
            }
          }
        }
        return reservedTotal;
      }
    } catch (e) {
      print('[v0] Error computing reserved qty for $inventoryId: $e');
    }
    return 0;
  }

  void _populateFormFields(Map<String, dynamic> data) {
    setState(() {
      // Basic fields
      _taskTitleController.text = data['task_title'] ?? data['taskTitle'] ?? '';
      _taskCodeController.text =
          data['task_code'] ?? data['id']?.toString() ?? '';
      _descriptionController.text =
          data['task_description'] ?? data['description'] ?? '';
      _estimatedDurationController.text = data['estimated_duration'] ?? '';

      // Contractor information
      _contractorNameController.text =
          data['contractor_name'] ?? data['contractorName'] ?? '';
      _contactPersonController.text =
          data['contact_person'] ?? data['contactPerson'] ?? '';
      _contactNumberController.text =
          data['contact_number'] ?? data['contactNumber'] ?? '';
      _emailController.text = data['email'] ?? '';

      // Assessment fields
      _assessmentController.text = data['assessment'] ?? '';
      _recommendationController.text = data['recommendation'] ?? '';

      // Dropdowns - validate values are in options list
      final priority = data['priority']?.toString();
      _selectedPriority = _priorityOptions.contains(priority) ? priority : null;

      final location = data['location'] ?? data['area'];
      if (location != null && _locationOptions.contains(location.toString())) {
        _selectedLocation = location.toString();
      } else if (location != null && location.toString().isNotEmpty) {
        // If location is not in the list, set it as "Other" and populate the text field
        _selectedLocation = 'Other';
        _isOtherLocation = true;
        _otherLocationController.text = location.toString();
      }

      final serviceCategory = data['service_category'] ?? data['category'];
      if (serviceCategory != null &&
          _serviceCategoryOptions.contains(serviceCategory.toString())) {
        _selectedServiceCategory = serviceCategory.toString();
      } else if (serviceCategory != null &&
          serviceCategory.toString().isNotEmpty) {
        // If service category is not in the list, set it as "Other" and populate the text field
        _selectedServiceCategory = 'Other';
        _isOtherServiceCategory = true;
        _otherServiceCategoryController.text = serviceCategory.toString();
      }

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
        final validRecurrences = ['Weekly', 'Monthly', 'Quarterly', 'Annually'];
        _selectedRecurrence =
            validRecurrences.contains(recurrenceCapitalized)
                ? recurrenceCapitalized
                : null;
      }

      final assessmentReceived = data['assessment_received'];
      _selectedAssessmentReceived =
          _assessmentOptions.contains(assessmentReceived)
              ? assessmentReceived
              : 'No';

      _selectedAdminNotifications = data['admin_notification'];

      // Task type
      // Task type ID for automatic inventory population
      _selectedTaskTypeId = data['task_type_id']?.toString();

      // Find task type name from loaded options
      if (_selectedTaskTypeId != null) {
        final selectedTaskType = _taskTypeOptions.firstWhere(
          (taskType) => taskType['id'] == _selectedTaskTypeId,
          orElse: () => {'name': ''},
        );
        _selectedTaskType = selectedTaskType['name'];
      }

      _loggedByController.text = data['logged_by'] ?? _loggedByController.text;

      // Dates
      if (data['created_at'] != null) {
        try {
          _dateCreated = DateTime.parse(data['created_at']);
        } catch (e) {
          print('Error parsing created_at: $e');
        }
      }

      if (data['start_date'] != null) {
        try {
          _startDate = DateTime.parse(data['start_date']);
          _startDateController.text = _formatDateYYYYMMDD(_startDate!);
        } catch (e) {
          print('Error parsing start_date: $e');
        }
      }

      if (data['next_due_date'] != null) {
        try {
          _nextDueDate = DateTime.parse(data['next_due_date']);
          _nextDueDateController.text = _formatDateYYYYMMDD(_nextDueDate!);
        } catch (e) {
          print('Error parsing next_due_date: $e');
        }
      }

      if (data['logged_date'] != null) {
        try {
          _loggedDate = DateTime.parse(data['logged_date']);
        } catch (e) {
          print('Error parsing logged_date: $e');
        }
      }

      if (data['service_window_start'] != null) {
        try {
          _serviceWindowStart = DateTime.parse(data['service_window_start']);
        } catch (e) {
          print('Error parsing service_window_start: $e');
        }
      }

      if (data['service_window_end'] != null) {
        try {
          _serviceWindowEnd = DateTime.parse(data['service_window_end']);
        } catch (e) {
          print('Error parsing service_window_end: $e');
        }
      }

      // Inventory items - preserve inventory identifiers so edits keep stable ids
      if (data['parts_used'] != null && data['parts_used'] is List) {
        _selectedInventoryItems.clear();
        for (var item in data['parts_used']) {
          _selectedInventoryItems.add({
            'inventory_id':
                item['inventory_id'] ?? item['id'] ?? item['_doc_id'],
            'item_name': item['item_name'] ?? item['name'] ?? '',
            'item_code': item['item_code'] ?? item['code'] ?? '',
            'unit':
                item['unit'] ?? item['uom'] ?? item['unit_of_measure'] ?? 'pcs',
            'quantity': item['quantity'] ?? 1,
            'available_stock':
                item['available_stock'] ??
                item['stock'] ??
                item['current_stock'] ??
                0,
            'reserve': item['reserve'] ?? item['reserved'] ?? true,
          });
        }
      }

      // Created by
      _createdByController.text = data['created_by'] ?? 'Admin User';
    });
  }

  // Simple inventory helpers so the UI can function here.
  // These are lightweight stubs. Replace with full selection dialog/API as needed.
  void _addInventoryItem() async {
    if (_availableInventoryItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No inventory items available')),
      );
      return;
    }

    // Filter items based on selected location (if provided)
    List<Map<String, dynamic>> filteredItems = _availableInventoryItems;
    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
      filteredItems =
          _availableInventoryItems.where((item) {
            final recommendedOn = item['recommended_on'];
            if (recommendedOn == null) return true;
            if (recommendedOn is List) {
              return recommendedOn.contains(_selectedLocation);
            }
            return true;
          }).toList();
    }

    // Open the inventory selection dialog using filtered items
    await showDialog(
      context: context,
      builder:
          (context) => _InventorySelectionDialog(
            availableItems: filteredItems,
            selectedLocation: _selectedLocation,
            onItemSelected: (item, quantity) {
              setState(() {
                _selectedInventoryItems.add({
                  'inventory_id': item['id'] ?? item['_doc_id'],
                  'item_name': item['item_name'] ?? item['name'] ?? 'Unknown',
                  'item_code': item['item_code'] ?? item['code'] ?? 'N/A',
                  'unit':
                      item['unit'] ??
                      item['uom'] ??
                      item['unit_of_measure'] ??
                      'pcs',
                  'available_stock':
                      item['current_stock'] ?? item['available_stock'] ?? 0,
                  'quantity': quantity,
                  'reserve': true,
                });
              });
            },
          ),
    );
  }

  void _removeInventoryItem(int index) {
    if (index < 0 || index >= _selectedInventoryItems.length) return;
    setState(() {
      _selectedInventoryItems.removeAt(index);
    });
  }

  /// Load available task types from API
  Future<void> _loadTaskTypes() async {
    try {
      print('[DEBUG] _loadTaskTypes called');
      print('[DEBUG] API Service instance: $_apiService');
      print('[v0] Loading task types...');

      // Check if token is set
      final token = await AuthStorage.getToken();
      print('[DEBUG] Auth token available: ${token != null}');

      final taskTypes = await _apiService.getTaskTypesForDropdown();
      print('[v0] Loaded ${taskTypes.length} task types: $taskTypes');
      print('[DEBUG] Raw task types data: $taskTypes');
      print('[DEBUG] Task types type: ${taskTypes.runtimeType}');

      // If we get empty data, try the fallback method
      if (taskTypes.isEmpty) {
        print('[DEBUG] Got empty task types, trying fallback method...');
        throw Exception('Empty task types returned, triggering fallback');
      }

      setState(() {
        _taskTypeOptions =
            taskTypes
                .map(
                  (taskType) => {
                    'id': taskType['id']?.toString() ?? '',
                    'name': taskType['name']?.toString() ?? '',
                  },
                )
                .toList();
      });
      print('[v0] Task type options set: $_taskTypeOptions');
      print('[DEBUG] _taskTypeOptions.isEmpty: ${_taskTypeOptions.isEmpty}');
      print(
        '[DEBUG] Task types loaded successfully, dropdown should now be enabled',
      );
    } catch (e) {
      print('[v0] Error loading task types: $e');
      print('[DEBUG] Exception details: ${e.toString()}');
      print('[DEBUG] Exception type: ${e.runtimeType}');

      // Try alternative API method as fallback
      try {
        print('[DEBUG] Attempting fallback API call...');
        // If getTaskTypesForDropdown fails, try a more basic approach
        final fallbackData = await _apiService.listTaskTypes();
        print('[DEBUG] Fallback data: $fallbackData');

        if (fallbackData != null && fallbackData.isNotEmpty) {
          setState(() {
            _taskTypeOptions =
                fallbackData
                    .map(
                      (item) => {
                        'id':
                            item['id']?.toString() ??
                            item['formatted_id']?.toString() ??
                            '',
                        'name':
                            '${item['category']?.toString() ?? 'Unknown'} - ${item['description']?.toString() ?? 'No Description'}',
                      },
                    )
                    .toList();
          });
          print('[DEBUG] Fallback task types loaded: $_taskTypeOptions');
          return;
        }
      } catch (fallbackError) {
        print('[DEBUG] Fallback also failed: $fallbackError');
      }

      // Add a fallback with some test options if all loading fails
      setState(() {
        _taskTypeOptions = [
          {
            'id': 'TT-2025-00015',
            'name': 'Corrective - Fixing plumbing leaks (From DB)',
          },
          {'id': 'temp_1', 'name': 'Corrective Maintenance (Temporary)'},
          {'id': 'temp_2', 'name': 'Preventive Maintenance (Temporary)'},
          {'id': 'temp_3', 'name': 'Emergency Repair (Temporary)'},
          {'id': '', 'name': 'API Error - Using fallback options'},
        ];
      });

      print('[DEBUG] Using fallback task types, dropdown should now work!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Using fallback task types due to API error')),
        );
      }
    }
  }

  /// Handle task type selection and populate associated inventory
  Future<void> _handleTaskTypeChange(String? taskTypeId) async {
    setState(() {
      _selectedTaskTypeId = taskTypeId;
    });

    if (taskTypeId != null) {
      try {
        print('[v0] Task type changed to: $taskTypeId');
        print('[v0] Fetching inventory items for task type: $taskTypeId');

        // Check if this is a temporary/fallback task type ID
        if (taskTypeId.startsWith('temp_') || taskTypeId.isEmpty) {
          print(
            '[DEBUG] Skipping inventory fetch for temporary task type: $taskTypeId',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This is a temporary task type. No inventory items available.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        final taskTypeInventory = await _apiService.getTaskTypeInventoryItems(
          taskTypeId,
        );
        print('[v0] Task type inventory response: $taskTypeInventory');

        // Merge new inventory items with existing selections (avoid duplicates)
        final existingIds =
            _selectedInventoryItems
                .map((item) => item['inventory_id']?.toString())
                .where((id) => id != null)
                .toSet();

        final newItems = <Map<String, dynamic>>[];
        for (final item in taskTypeInventory) {
          final inventoryId = item['inventory_id']?.toString();
          if (inventoryId != null && !existingIds.contains(inventoryId)) {
            // Handle multiple possible field names from backend
            final defaultQuantity =
                item['default_quantity'] ?? item['quantity'] ?? 1;
            final currentStock =
                item['current_stock'] ??
                item['available_stock'] ??
                item['stock'] ??
                0;
            final itemName = item['item_name'] ?? item['name'] ?? '';
            final itemCode = item['item_code'] ?? item['code'] ?? '';
            final unit =
                item['unit'] ?? item['uom'] ?? item['unit_of_measure'] ?? 'pcs';

            newItems.add({
              'inventory_id': inventoryId,
              'item_name': itemName,
              'item_code': itemCode,
              'quantity':
                  defaultQuantity, // Use default quantity from task type
              'available_stock': currentStock,
              'unit': unit,
              'from_task_type': true, // Mark as coming from task type
            });

            print(
              '[v0] Added task type inventory item: $itemName (ID: $inventoryId, Qty: $defaultQuantity)',
            );
          }
        }

        if (newItems.isNotEmpty) {
          setState(() {
            _selectedInventoryItems.addAll(newItems);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Added ${newItems.length} inventory item(s) for selected task type',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        print('[v0] Error loading task type inventory: $e');
        print('[DEBUG] Task type inventory error details: ${e.toString()}');

        // Show user-friendly error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not load inventory for this task type. You can still add items manually.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Add Manually',
                textColor: Colors.white,
                onPressed: () {
                  _addInventoryItem();
                },
              ),
            ),
          );
        }
        // Don't fail if task type inventory loading fails
      }
    }
  }

  Future<void> _loadInventoryItems() async {
    try {
      print('[v0] Loading inventory items...');
      // Use admin API service to get inventory items
      final response = await _apiService.getInventoryItems(
        buildingId: 'default_building_id',
      );

      print('[v0] Inventory response: $response');
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _availableInventoryItems = List<Map<String, dynamic>>.from(
            response['data'],
          );
        });
        print('[v0] Loaded ${_availableInventoryItems.length} inventory items');
      } else {
        print('[v0] No inventory data returned or unsuccessful response');
      }
    } catch (e) {
      print('[v0] Error loading inventory items: $e');
      // Don't fail the whole form if inventory loading fails
    }
  }

  Future<List<Map<String, String>>> _createInventoryReservations(
    String taskId,
  ) async {
    if (_selectedInventoryItems.isEmpty) return [];

    final List<Map<String, String>> createdReservations = [];

    try {
      // DUPLICATE PREVENTION: Fetch existing reservations for this task
      print('[v0] Checking for existing reservations for task: $taskId');
      Map<String, dynamic>? existingReservationsData;
      Set<String> existingInventoryIds = {};

      try {
        existingReservationsData = await _apiService.getInventoryReservations(
          maintenanceTaskId: taskId,
        );

        if (existingReservationsData != null &&
            existingReservationsData['reservations'] is List) {
          final reservations = existingReservationsData['reservations'] as List;
          for (final reservation in reservations) {
            if (reservation is Map<String, dynamic>) {
              final invId = reservation['inventory_id']?.toString() ?? '';
              if (invId.isNotEmpty) {
                existingInventoryIds.add(invId);
                print(
                  '[v0] Found existing reservation for inventory_id: $invId',
                );
              }
            }
          }
        }
        print(
          '[v0] Found ${existingInventoryIds.length} existing reservations to skip',
        );
      } catch (e) {
        print('[v0] Error fetching existing reservations (will continue): $e');
        // Continue with creation - if we can't check, better to try and let backend handle
      }

      for (final item in _selectedInventoryItems) {
        final qty = item['quantity'];
        final fromTaskType = item['from_task_type'] == true;
        final itemName = item['item_name'] ?? 'Unknown Item';
        final inventoryId = item['inventory_id']?.toString() ?? '';

        if (qty == null || qty <= 0) {
          print(
            '[v0] Skipping reservation for $itemName due to invalid quantity: $qty',
          );
          continue;
        }

        if (inventoryId.isEmpty) {
          print(
            '[v0] Skipping reservation for $itemName due to missing inventory ID',
          );
          continue;
        }

        // DUPLICATE PREVENTION: Skip if reservation already exists
        if (existingInventoryIds.contains(inventoryId)) {
          print(
            '[v0] SKIPPING - Reservation already exists for $itemName (ID: $inventoryId)',
          );
          continue;
        }

        print(
          '[v0] Creating reservation for $itemName (Qty: $qty)${fromTaskType ? ' [FROM TASK TYPE]' : ''}',
        );
        final response = await _apiService.createInventoryReservation(
          inventoryId: item['inventory_id'],
          quantity: qty,
          maintenanceTaskId: taskId,
        );

        // Extract the reservation ID from the response
        if (response['success'] == true && response['reservation_id'] != null) {
          final rid = response['reservation_id'].toString();
          createdReservations.add({
            'inventory_id': item['inventory_id']?.toString() ?? '',
            'reservation_id': rid,
          });
          print(
            '[v0] Created inventory reservation: $rid for inventory ${item['inventory_id']}',
          );
        }
      }
      print(
        '[v0] Processed ${_selectedInventoryItems.length} items, skipped ${existingInventoryIds.length} existing, created ${createdReservations.length} new reservations',
      );
      return createdReservations;
    } catch (e) {
      print('[v0] Error creating inventory reservations: $e');
      throw Exception('Failed to create inventory reservations: $e');
    }
  }

  // Keep location field but remove auto-population
  void _handleLocationChange(String? location) {
    setState(() {
      _selectedLocation = location;
      _isOtherLocation = (location == 'Other');
      if (!_isOtherLocation) {
        _otherLocationController.clear();
      }
    });
  }

  Future<void> _initAutoFields() async {
    setState(() => _isLoadingCode = true);

    try {
      final code = await _apiService.getNextEPMCode();
      _taskCodeController.text = code;

      final profile = await AuthStorage.getProfile();
      if (profile != null && profile['full_name'] != null) {
        _createdByController.text = profile['full_name'];
        // Don't set logged by for new tasks - only for post-service logging
        // _loggedByController.text = profile['full_name'];
      } else {
        _createdByController.text = 'Admin User';
        // Don't set logged by for new tasks
        // _loggedByController.text = 'Admin User';
      }

      // Don't set logged date for new tasks - only when logging completed service
      // _loggedDate = DateTime.now();
    } catch (e) {
      print('[v0] Error initializing auto fields: $e');
      _taskCodeController.text =
          'EPM-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 100000}';
      _createdByController.text = 'Admin User';
      // Don't set logged by for new tasks even on error
      // _loggedByController.text = 'Admin User';
      // Don't set logged date for new tasks
      // _loggedDate = DateTime.now();
    } finally {
      setState(() => _isLoadingCode = false);
    }
  }

  Future<void> _fetchTaskData() async {
    if (widget.maintenanceData == null) return;

    setState(() => _isLoadingData = true);

    try {
      final taskId =
          widget.maintenanceData!['id']?.toString() ??
          widget.maintenanceData!['task_code']?.toString() ??
          widget.maintenanceData!['taskCode']?.toString();

      if (taskId == null) {
        print('[v0] No task ID found in maintenanceData');
        _populateFormFields(widget.maintenanceData!);
        return;
      }

      // Try to get full task details from API
      try {
        final taskData = await _apiService.getMaintenanceTaskById(taskId);
        if (taskData['success'] == true && taskData['data'] != null) {
          // Use API data which should be more complete
          final completeData = taskData['data'] as Map<String, dynamic>;

          // Merge with passed data to ensure we don't lose any fields
          final mergedData = Map<String, dynamic>.from(widget.maintenanceData!);
          mergedData.addAll(completeData);

          _populateFormFields(mergedData);
        } else {
          print(
            '[v0] Failed to fetch complete task data: ${taskData['message'] ?? 'Unknown error'}',
          );
          // Use passed data as fallback
          _populateFormFields(widget.maintenanceData!);
        }
      } catch (apiError) {
        print('[v0] API error fetching task data: $apiError');
        // Use passed data as fallback
        _populateFormFields(widget.maintenanceData!);
      }
    } catch (e) {
      print('[v0] Error in _fetchTaskData: $e');
      // Always populate with available data
      _populateFormFields(widget.maintenanceData!);
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  // ---------- Date picker ----------
  Future<void> _selectDate(
    BuildContext context,
    Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) onDateSelected(picked);
  }

  // ---------- Validators ----------
  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(v.trim()) ? null : 'Enter a valid email';
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7 ? null : 'Enter a valid phone';
  }

  String? _durationValidator(String? v) {
    // Estimated duration is optional; accept common duration formats like:
    // "3 hrs 30 mins", "2 hrs", "45 mins" or time formats like "9:00 AM".
    if (v == null || v.trim().isEmpty) return null;

    final s = v.trim();
    final durationRe = RegExp(
      r'^\s*\d+\s*(hrs?|hours?)\s*(\d+\s*mins?)?\s*$',
      caseSensitive: false,
    );
    final minutesRe = RegExp(r'^\s*\d+\s*mins?\s*$', caseSensitive: false);
    final timeRe = RegExp(r'^\s*\d{1,2}:\d{2}\s*(AM|PM|am|pm)?\s*$');

    if (durationRe.hasMatch(s) || minutesRe.hasMatch(s) || timeRe.hasMatch(s)) {
      return null;
    }
    return 'Enter a valid duration (e.g. 3 hrs 30 mins) or time';
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'work_maintenance',
      onNavigate: (routeKey) {
        print('[DEBUG] onNavigate called with routeKey: $routeKey');
        final routePath = _getRoutePath(routeKey);
        if (routePath != null) {
          print('[DEBUG] Navigating to route: $routePath');
          context.go(routePath);
        } else if (routeKey == 'logout') {
          print('[DEBUG] Logout route detected, calling _handleLogout');
          _handleLogout(context);
        } else {
          print('[DEBUG] Unknown routeKey: $routeKey');
        }
      },
      body:
          _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header & breadcrumb
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
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => context.go('/dashboard'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: const Text('Maintenance Tasks'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Main form container
                    Container(
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _autoValidateMode,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                "Basic Information",
                                "General details about the maintenance task",
                              ),
                              const SizedBox(height: 24),

                              // Task Title + Task Code
                              Row(
                                children: [
                                  // Task Type (Dynamic from AdminTaskTypePage)
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: 'Task Type',
                                      value: _selectedTaskTypeId,
                                      placeholder: 'Select Task Type...',
                                      options: _taskTypeOptions,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedTaskTypeId = value;
                                          // Find the selected task type name for display
                                          final selectedTaskType =
                                              _taskTypeOptions.firstWhere(
                                                (taskType) =>
                                                    taskType['id'] == value,
                                                orElse:
                                                    () => {'name': 'Unknown'},
                                              );
                                          _selectedTaskType =
                                              selectedTaskType['name'];
                                        });
                                        // Automatically populate inventory items for this task type
                                        _handleTaskTypeChange(value);
                                      },
                                      validator: _req,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildTextField(
                                      label: "Task Code",
                                      controller: _taskCodeController,
                                      placeholder: "Auto-generated",
                                      enabled: false,
                                      validator: _req,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Created By + Date Created
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      label: "Created By",
                                      controller: _createdByController,
                                      placeholder: "Auto-filled",
                                      enabled: false,
                                      validator: _req,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildDateField(
                                      label: "Date Created",
                                      selectedDate: _dateCreated,
                                      placeholder: "DD / MM / YY",
                                      onDateSelected:
                                          (d) =>
                                              setState(() => _dateCreated = d),
                                      enabled: true,
                                      requiredField: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Priority only (Status auto-set to "New")
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: "Priority",
                                      value: _selectedPriority,
                                      placeholder: "Select Priority...",
                                      options: _priorityOptions,
                                      onChanged:
                                          (v) => setState(
                                            () => _selectedPriority = v,
                                          ),
                                      validator:
                                          (v) => v == null ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  const Expanded(
                                    child: SizedBox(),
                                  ), // keep right column space
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Divider(
                                color: Color(0xFFE2E8F0),
                                height: 1,
                                thickness: 1,
                              ),
                              const SizedBox(height: 32),

                              // Task Scope & Description
                              _buildSectionHeader(
                                "Task Scope & Description",
                                "Detailed description of what needs to be done",
                              ),
                              const SizedBox(height: 24),

                              // First row: Always show dropdowns for Location/Area and Service Category
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: "Location / Area",
                                      value: _selectedLocation,
                                      placeholder: "Select Location...",
                                      options: _locationOptions,
                                      onChanged: _handleLocationChange,
                                      validator:
                                          (v) => v == null ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: "Service Category",
                                      value: _selectedServiceCategory,
                                      placeholder: "Select Category...",
                                      options: _serviceCategoryOptions,
                                      onChanged: _handleServiceCategoryChange,
                                      validator:
                                          (v) => v == null ? 'Required' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Second row: Show input fields only if "Other" is selected for either
                              if (_isOtherLocation || _isOtherServiceCategory)
                                Row(
                                  children: [
                                    if (_isOtherLocation)
                                      Expanded(
                                        child: _buildTextField(
                                          label: "Location / Area",
                                          controller: _otherLocationController,
                                          placeholder: "Enter Location...",
                                          validator: _req,
                                        ),
                                      )
                                    else
                                      const Expanded(child: SizedBox()),
                                    const SizedBox(width: 24),
                                    if (_isOtherServiceCategory)
                                      Expanded(
                                        child: _buildTextField(
                                          label: "Service Category",
                                          controller:
                                              _otherServiceCategoryController,
                                          placeholder:
                                              "Enter Service Category...",
                                          validator: _req,
                                        ),
                                      )
                                    else
                                      const Expanded(child: SizedBox()),
                                  ],
                                ),
                              if (_isOtherLocation || _isOtherServiceCategory)
                                const SizedBox(height: 24),

                              _buildTextAreaField(
                                label: "Description",
                                controller: _descriptionController,
                                placeholder: "Enter Description...",
                                validator: _req,
                              ),
                              const SizedBox(height: 24),
                              const Divider(
                                color: Color(0xFFE2E8F0),
                                height: 1,
                                thickness: 1,
                              ),
                              const SizedBox(height: 32),

                              // Contractor Info
                              _buildSectionHeader(
                                "Contractor Information",
                                "Details of the external contractor assigned to this task or a company",
                              ),
                              const SizedBox(height: 24),

                              // Contractor Name (left) + Contact Number (right)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      label: "Contractor (Company) Name",
                                      controller: _contractorNameController,
                                      placeholder: "Enter Name",
                                      validator: _req,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildTextField(
                                      label: "Contact Number",
                                      controller: _contactNumberController,
                                      placeholder: "Input Contact Number",
                                      validator: _phoneValidator,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Email below aligned to the left (matches width of Contractor Name)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      label: "Email",
                                      controller: _emailController,
                                      placeholder: "Input Email",
                                      validator: _emailValidator,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  const Expanded(child: SizedBox()),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Divider(
                                color: Color(0xFFE2E8F0),
                                height: 1,
                                thickness: 1,
                              ),
                              const SizedBox(height: 32),

                              // Recurrence & Schedule
                              _buildSectionHeader(
                                "Recurrence & Schedule",
                                "Define when and how often this maintenance task occurs",
                              ),
                              const SizedBox(height: 24),

                              // Row 1: Recurrence and Estimated Duration
                              Row(
                                children: [
                                  // Recurrence
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: 'Recurrence Frequency',
                                      value: _selectedRecurrence,
                                      placeholder: 'Select frequency...',
                                      options: const [
                                        'Weekly',
                                        'Monthly',
                                        'Quarterly',
                                        'Annually',
                                      ],
                                      onChanged: _handleRecurrenceChange,
                                      validator:
                                          (v) => v == null ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 24),

                                  // Estimated Duration
                                  Expanded(
                                    child: _buildTextField(
                                      label: 'Estimated Duration',
                                      controller: _estimatedDurationController,
                                      placeholder: 'e.g., 3 hrs / 45 mins',
                                      validator: _durationValidator,
                                      onTap: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: const TimeOfDay(
                                            hour: 0,
                                            minute: 30,
                                          ),
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
                                            _estimatedDurationController.text =
                                                formatted;
                                          });
                                        }
                                      },
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _fieldLabel('Start Date'),
                                        Container(
                                          height: _kFieldHeight,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: TextFormField(
                                            controller: _startDateController,
                                            validator: _req,
                                            readOnly: true,
                                            onTap:
                                                () => _pickDate(
                                                  initial:
                                                      _startDate ??
                                                      DateTime.now(),
                                                  onPick:
                                                      _handleStartDateChange,
                                                ),
                                            decoration: InputDecoration(
                                              hintText: 'YYYY-MM-DD',
                                              hintStyle: TextStyle(
                                                color: Colors.grey[240],
                                                fontSize: 14,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _fieldLabel('Next Due Date'),
                                        Container(
                                          height: _kFieldHeight,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            color: Colors.grey[50],
                                          ),
                                          child: TextFormField(
                                            controller: _nextDueDateController,
                                            validator: _req,
                                            readOnly: true,
                                            decoration: InputDecoration(
                                              hintText: 'YYYY-MM-DD',
                                              hintStyle: TextStyle(
                                                color: Colors.grey[240],
                                                fontSize: 14,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
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

                              // Place inventory UI on the right side
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left column containing the Inventory section
                                  SizedBox(
                                    width: 520,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: _buildSectionHeader(
                                                "Inventory Items",
                                                "Request parts or supplies for the task",
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: _addInventoryItem,
                                              icon: const Icon(
                                                Icons.add,
                                                size: 18,
                                              ),
                                              label: const Text("Add Item"),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF2E7D32,
                                                ),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.grey[200]!,
                                              ),
                                            ),
                                            child: Text(
                                              'No inventory items added yet. Click "Add Item" to request inventory.',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        else
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: ListView.separated(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount:
                                                  _selectedInventoryItems
                                                      .length,
                                              separatorBuilder:
                                                  (context, index) => Divider(
                                                    height: 1,
                                                    color: Colors.grey[300],
                                                  ),
                                              itemBuilder: (context, index) {
                                                final item =
                                                    _selectedInventoryItems[index];
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
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
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.inventory_2,
                                                          color: Color(
                                                            0xFF2E7D32,
                                                          ),
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),

                                                      // Item details
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              item['item_name'] ??
                                                                  'Unknown Item',
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              'Code: ${item['item_code'] ?? 'N/A'}',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors
                                                                        .grey[600],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              'Stock: ${item['available_stock']}',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color:
                                                                    Colors
                                                                        .grey[600],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              'Unit: ${item['unit'] ?? item['uom'] ?? item['unit_of_measure'] ?? '—'}',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color:
                                                                    Colors
                                                                        .grey[600],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      // Quantity controls (fixed increments/decrements and display)
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color:
                                                                Colors
                                                                    .grey[300]!,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
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
                                                                  const EdgeInsets.all(
                                                                    4,
                                                                  ),
                                                              constraints:
                                                                  const BoxConstraints(
                                                                    minWidth:
                                                                        32,
                                                                    minHeight:
                                                                        32,
                                                                  ),
                                                              onPressed: () {
                                                                setState(() {
                                                                  final currentQtyRaw =
                                                                      item['quantity'];
                                                                  final currentQty =
                                                                      (currentQtyRaw
                                                                              is int)
                                                                          ? currentQtyRaw
                                                                          : int.tryParse(
                                                                                currentQtyRaw?.toString() ??
                                                                                    '',
                                                                              ) ??
                                                                              1;
                                                                  if (currentQty >
                                                                      1) {
                                                                    _selectedInventoryItems[index]['quantity'] =
                                                                        currentQty -
                                                                        1;
                                                                  }
                                                                });
                                                              },
                                                              color:
                                                                  Colors
                                                                      .grey[700],
                                                            ),

                                                            // Quantity display (non-editable text to ensure updates reflect immediately)
                                                            SizedBox(
                                                              width: 50,
                                                              child: Center(
                                                                child: Text(
                                                                  '${(item['quantity'] is int) ? item['quantity'] : (int.tryParse(item['quantity']?.toString() ?? '') ?? 1)}',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),

                                                            // Increment button
                                                            IconButton(
                                                              icon: const Icon(
                                                                Icons.add,
                                                                size: 16,
                                                              ),
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    4,
                                                                  ),
                                                              constraints:
                                                                  const BoxConstraints(
                                                                    minWidth:
                                                                        32,
                                                                    minHeight:
                                                                        32,
                                                                  ),
                                                              onPressed: () {
                                                                setState(() {
                                                                  final currentQtyRaw =
                                                                      item['quantity'];
                                                                  final availableRaw =
                                                                      item['available_stock'];
                                                                  final currentQty =
                                                                      (currentQtyRaw
                                                                              is int)
                                                                          ? currentQtyRaw
                                                                          : int.tryParse(
                                                                                currentQtyRaw?.toString() ??
                                                                                    '',
                                                                              ) ??
                                                                              1;
                                                                  final availableStock =
                                                                      (availableRaw
                                                                              is int)
                                                                          ? availableRaw
                                                                          : int.tryParse(
                                                                                availableRaw?.toString() ??
                                                                                    '',
                                                                              ) ??
                                                                              0;

                                                                  if (currentQty <
                                                                      availableStock) {
                                                                    _selectedInventoryItems[index]['quantity'] =
                                                                        currentQty +
                                                                        1;
                                                                  } else {
                                                                    ScaffoldMessenger.of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      const SnackBar(
                                                                        content:
                                                                            Text(
                                                                              'Cannot exceed available stock',
                                                                            ),
                                                                        duration: Duration(
                                                                          seconds:
                                                                              2,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }
                                                                });
                                                              },
                                                              color:
                                                                  const Color(
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
                                                            () =>
                                                                _removeInventoryItem(
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
                              const SizedBox(height: 24),
                              const Divider(
                                color: Color(0xFFE2E8F0),
                                height: 1,
                                thickness: 1,
                              ),
                              const SizedBox(height: 32),

                              // Post-Service Assessment Logging
                              _buildSectionTitle(
                                "Post-Service Assessment Logging",
                              ),
                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.info, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Information",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "These fields will be filled after the 3rd-party service visit is completed",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: "Assessment Received",
                                      value: _selectedAssessmentReceived,
                                      placeholder: "Input",
                                      options: _assessmentOptions,
                                      onChanged:
                                          (v) => setState(
                                            () =>
                                                _selectedAssessmentReceived = v,
                                          ),
                                      enabled: widget.isEditMode,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  const Expanded(
                                    child: SizedBox(),
                                  ), // Left spacer
                                ],
                              ),
                              const SizedBox(height: 24),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      label: "Logged By",
                                      controller: _loggedByController,
                                      placeholder: "Auto-filled",
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildDateField(
                                      label: "Logged Date",
                                      selectedDate: _loggedDate,
                                      placeholder: "Auto-generated",
                                      onDateSelected:
                                          (d) =>
                                              setState(() => _loggedDate = d),
                                      enabled: widget.isEditMode,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextAreaField(
                                      label: "Assessment",
                                      controller: _assessmentController,
                                      placeholder: "Enter Assessment...",
                                      readOnly: !widget.isEditMode,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildTextAreaField(
                                      label: "Recommendation",
                                      controller: _recommendationController,
                                      placeholder: "Enter Recommendation...",
                                      readOnly: !widget.isEditMode,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: _onCancel,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.grey[700],
                                        side: BorderSide(
                                          color: Colors.grey[300]!,
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 100,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _onNext,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        widget.isEditMode ? 'Save' : 'Submit',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // ---------- Actions ----------
  void _onCancel() {
    context.go('/work/maintenance');
  }

  int? _parseDuration(String duration) {
    final trimmed = duration.trim();
    if (trimmed.isEmpty) return null;

    final reg = RegExp(
      r'(\d+)\s*(hrs?|hours?|mins?|minutes?)',
      caseSensitive: false,
    );
    final match = reg.firstMatch(trimmed);
    if (match != null) {
      final num = int.tryParse(match.group(1)!);
      if (num != null) {
        final unit = match.group(2)!.toLowerCase();
        if (unit.startsWith('h')) {
          return num * 60; // convert hours to minutes
        } else {
          return num; // minutes
        }
      }
    }
    return null;
  }

  Future<void> _onNext() async {
    setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);

    if ((_serviceWindowStart != null && _serviceWindowEnd == null) ||
        (_serviceWindowEnd != null && _serviceWindowStart == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete both Service Window dates.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_serviceWindowStart != null &&
        _serviceWindowEnd != null &&
        _serviceWindowEnd!.isBefore(_serviceWindowStart!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service Window end must be after start.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the highlighted fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_dateCreated == null || _startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select required dates.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get actual location (use Other input if selected)
    final actualLocation =
        _isOtherLocation
            ? _otherLocationController.text.trim()
            : (_selectedLocation ?? '');

    // Get actual service category (use Other input if selected)
    final actualServiceCategory =
        _isOtherServiceCategory
            ? _otherServiceCategoryController.text.trim()
            : (_selectedServiceCategory ?? '');

    String formatDate(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    final scheduledDateIso = _startDate!.toUtc().toIso8601String();

    // Parse estimated duration to minutes
    final estimatedDurationMinutes = _parseDuration(
      _estimatedDurationController.text.trim(),
    );
    if (estimatedDurationMinutes == null &&
        _estimatedDurationController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid estimated duration (e.g., 3 hrs or 45 mins)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final taskData = {
      'task_code': _taskCodeController.text.trim(),
      'task_title': _taskTitleController.text.trim(),
      'task_description': _descriptionController.text.trim(),
      'maintenance_type': 'external',
      'service_category': actualServiceCategory,
      'created_by': _createdByController.text.trim(),
      'priority': _selectedPriority ?? 'medium',
      'status': 'New', // Auto-set to "New" for external maintenance
      'location': actualLocation,

      // Contractor Information
      'contractor_name': _contractorNameController.text.trim(),
      'contact_person': _contactPersonController.text.trim(),
      'contact_number': _contactNumberController.text.trim(),
      'email': _emailController.text.trim(),

      // Scheduling Information
      'recurrence_type': _selectedRecurrence?.toLowerCase() ?? 'none',
      'start_date': formatDate(_startDate!),
      'scheduled_date': scheduledDateIso,
      'next_due_date': _nextDueDate != null ? formatDate(_nextDueDate!) : null,
      'estimated_duration': estimatedDurationMinutes,

      // Assessment and Tracking
      'assessment_received': _selectedAssessmentReceived,
      'logged_by':
          _loggedByController.text.isNotEmpty ? _loggedByController.text : null,
      'logged_date': _loggedDate != null ? formatDate(_loggedDate!) : null,
      'assessment': _assessmentController.text.trim(),
      'recommendation': _recommendationController.text.trim(),

      // Admin Notifications (Auto-generated from start date)
      'admin_notification': _selectedAdminNotifications,

      // System Fields
      'building_id': 'default_building',
      'task_type': 'external',
      'task_type_id': _selectedTaskTypeId, // Include selected task type ID
      'category': actualServiceCategory,
      'assigned_to': _contractorNameController.text.trim(),

      // Required Arrays
      'checklist_completed': <Map<String, dynamic>>[],
      'parts_used':
          _selectedInventoryItems
              .map(
                (it) => {
                  'inventory_id':
                      it['inventory_id'] ?? it['id'] ?? it['_doc_id'],
                  'item_name': it['item_name'],
                  'item_code': it['item_code'],
                  'unit': it['unit'] ?? 'pcs',
                  'quantity': it['quantity'] ?? 1,
                  'available_stock': it['available_stock'] ?? 0,
                  'reserve': it['reserve'] ?? true,
                },
              )
              .toList(),
      'tools_used': <String>[],
      'photos': <String>[],
    };

    try {
      if (widget.isEditMode && widget.maintenanceData != null) {
        // UPDATE existing task
        final taskId =
            widget.maintenanceData!['id']?.toString() ??
            _taskCodeController.text;
        print('[v0] Updating external maintenance task: $taskId');

        final result = await _apiService.updateMaintenanceTask(
          taskId,
          taskData,
        );
        print('[v0] External maintenance task updated successfully');
        print('[v0] Backend response: $result');

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
        final result = await _apiService.createMaintenanceTask(taskData);
        final createdTask =
            result['task'] is Map<String, dynamic>
                ? result['task'] as Map<String, dynamic>
                : null;
        final createdId =
            createdTask?['id'] ?? result['id'] ?? result['task_id'];
        print('[v0] External maintenance task created: $createdId');

        // Create inventory reservations for selected items
        if (createdId != null && _selectedInventoryItems.isNotEmpty) {
          try {
            final createdPairs = await _createInventoryReservations(
              createdId.toString(),
            );
            // Attach reservation ids back to the maintenance task's parts_used
            if (createdPairs.isNotEmpty) {
              // Build a mapping from inventory_id -> reservation_id
              final Map<String, String> reservationMap = {};
              for (var p in createdPairs) {
                final invId = p['inventory_id']?.toString() ?? '';
                final rid = p['reservation_id']?.toString() ?? '';
                if (invId.isNotEmpty && rid.isNotEmpty)
                  reservationMap[invId] = rid;
              }

              final List<Map<String, dynamic>> updatedParts =
                  _selectedInventoryItems.map((it) {
                    final invId = it['inventory_id']?.toString() ?? '';
                    final copy = Map<String, dynamic>.from(it);
                    if (reservationMap.containsKey(invId)) {
                      copy['reservation_id'] = reservationMap[invId];
                    }
                    return copy;
                  }).toList();

              // Also update the UI list with reservation ids
              for (final it in _selectedInventoryItems) {
                final inv = it['inventory_id']?.toString() ?? '';
                if (reservationMap.containsKey(inv)) {
                  it['reservation_id'] = reservationMap[inv];
                }
              }

              // Update the maintenance task with reservation ids embedded in parts_used
              try {
                await _apiService.updateMaintenanceTask(createdId.toString(), {
                  'parts_used': updatedParts,
                });
                // Notify inventory listeners for each created reservation / inventory id
                try {
                  final notifier = InventoryUpdateNotifier();
                  reservationMap.forEach((inv, rid) {
                    notifier.notifyItemUpdated(inv);
                  });
                } catch (e) {
                  print(
                    '[v0] Failed to notify inventory after attaching reservation ids: $e',
                  );
                }
                print(
                  '[v0] Updated maintenance task $createdId parts_used with reservation ids.',
                );
              } catch (e) {
                print(
                  '[v0] Failed to update maintenance task with reservation ids: $e',
                );
              }
            }
          } catch (e) {
            print('[v0] Warning: Failed to create inventory reservations: $e');
            // Don't fail the whole task creation if reservations fail
          }
        }

        if (mounted) {
          context.push('/work/maintenance', extra: taskData);
        }
      }
    } catch (e) {
      print('[v0] Error creating external maintenance task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---------- Shared UI helpers ----------
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

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
  );

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

  // Helper box used to wrap inline field widgets so _fieldBox calls compile.
  Widget _fieldBox({required Widget child, double? height}) => Container(
    height: height ?? _kFieldHeight,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: child,
  );

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    String? Function(String?)? validator,
    bool enabled = true,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        SizedBox(
          height: _kFieldHeight,
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            readOnly: readOnly,
            onTap: onTap,
            validator: validator,
            decoration: _decoration(placeholder).copyWith(
              filled: !enabled,
              fillColor: enabled ? Colors.white : Colors.grey[50],
              suffixIcon:
                  _isLoadingCode && controller == _taskCodeController
                      ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String placeholder,
    required List<dynamic> options,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
    bool fullWidth = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) _fieldLabel(label),
        SizedBox(
          height: _kFieldHeight,
          width: fullWidth ? double.infinity : null,
          child: DropdownButtonFormField<String>(
            value: value,
            validator: validator,
            decoration: _decoration(placeholder).copyWith(
              filled: !enabled,
              fillColor: enabled ? Colors.white : Colors.grey[50],
            ),
            dropdownColor: Colors.white,
            items:
                options
                    .map((opt) {
                      if (opt is String) {
                        return DropdownMenuItem<String>(
                          value: opt,
                          child: Text(opt),
                        );
                      } else if (opt is Map<String, String>) {
                        return DropdownMenuItem<String>(
                          value: opt['id'],
                          child: Text(opt['name'] ?? ''),
                        );
                      }
                      return null;
                    })
                    .whereType<DropdownMenuItem<String>>()
                    .toList(),
            onChanged: enabled ? onChanged : null,
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required String placeholder,
    required Function(DateTime) onDateSelected,
    bool enabled = true,
    bool showLabel = true,
    bool requiredField = false,
  }) {
    return FormField<DateTime>(
      validator: (_) {
        if (!requiredField) return null;
        return (selectedDate == null) ? 'Required' : null;
      },
      builder: (state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLabel && label.isNotEmpty) _fieldLabel(label),
            SizedBox(
              height: _kFieldHeight,
              child: InkWell(
                onTap:
                    enabled
                        ? () => _selectDate(context, (d) {
                          onDateSelected(d);
                          state.didChange(d);
                        })
                        : null,
                child: InputDecorator(
                  decoration: _decoration(placeholder).copyWith(
                    filled: !enabled,
                    fillColor: enabled ? Colors.white : Colors.grey[50],
                    errorText: hasError ? state.errorText : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: enabled ? Colors.blue : Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedDate != null
                              ? "${selectedDate.day.toString().padLeft(2, '0')} / ${selectedDate.month.toString().padLeft(2, '0')} / ${selectedDate.year.toString().substring(2)}"
                              : placeholder,
                          style: TextStyle(
                            color:
                                selectedDate != null
                                    ? Colors.black87
                                    : Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextAreaField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: 5,
          readOnly: readOnly,
          decoration: _decoration(placeholder),
        ),
      ],
    );
  }

  // ---------- Dispose ----------
  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskCodeController.dispose();
    _createdByController.dispose();
    _descriptionController.dispose();
    _contractorNameController.dispose();
    _contactPersonController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _assessmentController.dispose();
    _recommendationController.dispose();
    _loggedByController.dispose();
    _otherLocationController.dispose();
    _otherServiceCategoryController.dispose();
    _estimatedDurationController.dispose();
    _startDateController.dispose();
    _nextDueDateController.dispose();
    super.dispose();
  }
}

// Inventory Selection Dialog (copied from internalmaintenance_form)
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
                                    'Unit: ${item['unit'] ?? item['uom'] ?? item['unit_of_measure'] ?? 'pcs'}',
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
