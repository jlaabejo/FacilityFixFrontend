import 'dart:math' as math;
import 'package:facilityfix/adminweb/widgets/logout_popup.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../services/api_service.dart';
import '../services/round_robin_assignment_service.dart';
import '../../services/auth_storage.dart';
import '../../utils/inventory_notifier.dart';
import '../../services/api_services.dart' as main_api;
import 'package:file_picker/file_picker.dart';
import 'package:facilityfix/services/api_services.dart' as SecondaryAPI;

class TaskTypeFormPage extends StatefulWidget {
  final Map<String, dynamic>? maintenanceData;
  final bool isEditMode;

  const TaskTypeFormPage({
    super.key,
    this.maintenanceData,
    this.isEditMode = false,
  });

  @override
  State<TaskTypeFormPage> createState() =>
      _TaskTypeFormPageState();
}

class _TaskTypeFormPageState
    extends State<TaskTypeFormPage> {
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
  final _checklistItemController =
      TextEditingController(); // For checklist input

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
  List<Map<String, dynamic>> get _filteredStaffMembers {
    if (_selectedDepartment == null || _selectedDepartment!.isEmpty)
      return _staffMembers;
    return _staffMembers.where((staff) {
      final staffDept =
          (staff['staff_department'] ?? staff['department'])
              ?.toString()
              .toLowerCase();
      return staffDept == _selectedDepartment!.toLowerCase();
    }).toList();
  }

  List<Map<String, dynamic>> _availableInventoryItems = [];
  List<Map<String, dynamic>> _selectedInventoryItems = [];
  String? _buildingId;
  final _apiService = ApiService();
  final _mainApiService = main_api.APIService();
  final _roundRobinService = RoundRobinAssignmentService();

  // Local editing toggle used when the parent did not supply edit mode
  bool _isLocalEdit = false;

  bool get _isEditing => widget.isEditMode || _isLocalEdit;

  static String? _getRoutePath(String routeKey) {
      final Map<String, String> pathMap = {
        'dashboard': '/dashboard',
        'user_users': '/user/users',
        'user_scheduling': '/user/scheduling',
        'work_maintenance': '/work/maintenance',
        'work_repair': '/work/repair',
        'disaster_prepardness': '/disaster_prepardness',
        'calendar': '/calendar',
        'inventory_equipment': '/inventory/equipment',
        'inventory_items': '/inventory/items',
        'inventory_request': '/inventory/request',
        'analytics': '/analytics',
        'announcement': '/announcement',
        'settings': '/settings',
        'logout': '/logout',
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
  String _getCurrentUserName() => 'Michelle Reyes';

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
      // Try to fetch an IPM/ID from the API - fallback to a Task Type code if unavailable
      final codeId = await _apiService.getNextIPMCode();
      _codeIdController.text = codeId;
      print('[v0] Generated code: $codeId');
    } catch (e) {
      print('[v0] Error fetching code from backend: $e');
      // Fallback to timestamp-based code for Task Type
      final year = DateTime.now().year;
      final number = DateTime.now().millisecondsSinceEpoch % 100000;
      _codeIdController.text = 'TT-$year-${number.toString().padLeft(5, '0')}';
    }

    // Date Created (default to now)
    _dateCreated = DateTime.now();
    _dateCreatedController.text = _fmtDate(_dateCreated!);

    _startDate = DateTime.now();
    _startDateController.text = _fmtDate(_startDate!);

    // Load staff members
    await _loadStaffMembers();

    // Load inventory items
    // Save building id and use it when loading inventory
    _buildingId = profile != null ? (profile['building_id'] ?? profile['buildingId'] ?? profile['building'])?.toString() : null;
    await _loadInventoryItems();
  }

  Future<int> _getReservedQty(String inventoryId) async {
    try {
      final resp = await _apiService.getInventoryReservations();
      if (resp['success'] == true && resp['data'] != null) {
        final reservations = List<Map<String, dynamic>>.from(resp['data']);
        int reservedTotal = 0;
        for (var r in reservations) {
          if ((r['inventory_id']?.toString() ?? '') == inventoryId) {
            final status = (r['status'] ?? r['request_status'] ?? 'reserved').toString().toLowerCase();
            if (status == 'reserved' || status == 'approved' || status == 'pending') {
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

  Future<void> _loadInventoryItems() async {
    try {
      // TODO: Replace with actual building ID from user session
      final response = await _mainApiService.getBuildingInventory(_buildingId ?? 'default_building_id');

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
            onItemSelected: (item, quantity) async {
              // Validate quantity and clamp to minimum 1
              final parsedQty = (quantity is int) ? quantity : int.tryParse(quantity?.toString() ?? '') ?? 1;
              final qty = parsedQty <= 0 ? 1 : parsedQty;
              print('[Form] _addInventoryItem callback -> item: ${item['item_name'] ?? item['name'] ?? item['item_code']}, qty: $qty');
              final inventoryId = item['id'] ?? item['_doc_id'] ?? item['item_code'] ?? item['itemCode'];
              final reservedQty = (inventoryId != null) ? await _getReservedQty(inventoryId.toString()) : 0;
              setState(() {
                _selectedInventoryItems.add({
                  'inventory_id': inventoryId,
                  'item_name': item['item_name'],
                  'item_code': item['item_code'],
                  'quantity': qty,
                  'available_stock': item['current_stock'],
                  'unit': item['unit'] ?? '',
                  'reserved_stock': reservedQty,
                  'autoReserve': false, // manually-added items should not auto-reserve
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

      // Fix: Pass departmentKey as a positional argument to getNextStaffForDepartment
      final nextStaff = await _roundRobinService.getNextStaffForDepartment(
        departmentKey,
      );

      if (nextStaff != null) {
        final firstName = nextStaff['first_name'] ?? '';
        final lastName = nextStaff['last_name'] ?? '';
        final staffName = '$firstName $lastName'.trim();
        // Use Firebase UID or staff_id from auto-assigned staff
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
            'quantity': 0, // Default quantity
            'available_stock': item['current_stock'],
            'unit': item['unit'] ?? '',
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
        // Only create reservations for items marked as autoReserve
        if (!(item['autoReserve'] == true || item['reserve'] == true)) {
          print('[v0] Skipping reservation for ${item['item_name']} as autoReserve is false');
          continue;
        }
        final qty = item['quantity'];
        if (qty == null || qty <= 0) {
          print(
            '[v0] Skipping reservation for ${item['item_name']} due to invalid quantity: $qty',
          );
          continue;
        }
        // Resolve inventoryId if it's a SKU or not resolved yet
          String? inventoryId = item['inventory_id']?.toString() ?? item['item_code']?.toString() ?? '';

        if (inventoryId == null || inventoryId.isEmpty) {
          print('[v0] Skipping reservation for ${item['item_name']} - unresolved inventory id');
          continue;
        }

        final response = await _apiService.createInventoryReservation(
          inventoryId: inventoryId,
          quantity: qty,
          maintenanceTaskId: taskId,
        );

        // Extract the reservation ID from the response
        if (response['success'] == true && response['reservation_id'] != null) {
          createdReservationIds.add(response['reservation_id']);
          print('[v0] Created inventory reservation: ${response['reservation_id']}');
          try {
            InventoryUpdateNotifier().notifyItemUpdated(inventoryId.toString());
          } catch (_) {}
          // Refresh local reserved counts immediately after creating each reservation
          try {
            await _refreshSelectedReservedCounts();
          } catch (_) {}
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

  // Refresh reserved counts for the selected inventory items.
  Future<void> _refreshSelectedReservedCounts() async {
    if (_selectedInventoryItems.isEmpty) return;
    for (int i = 0; i < _selectedInventoryItems.length; i++) {
      final item = _selectedInventoryItems[i];
      final invId = item['inventory_id']?.toString();
      if (invId != null && invId.isNotEmpty) {
        final qty = await _getReservedQty(invId);
        setState(() {
          _selectedInventoryItems[i]['reserved_stock'] = qty;
        });
      }
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
    _initialize();
  }

  Future<void> _initialize() async {
    await _initAutoFields();
    // If the parent passed maintenanceData without explicit isEditMode, treat as local edit
    if (widget.maintenanceData != null) {
      setState(() {
        _isLocalEdit = true;
      });
      await _fetchAndPopulateMaintenanceData();
      await _loadReservedInventoryItems();
    } else if (widget.isEditMode && widget.maintenanceData != null) {
      await _fetchAndPopulateMaintenanceData();
      await _loadReservedInventoryItems();
    }
  }

  Future<void> _fetchAndPopulateMaintenanceData() async {
    try {
      final id = widget.maintenanceData!['id']?.toString();
      if (id != null) {
        final response = await _apiService.getAdminMaintenanceTaskById(id);
        if (response['success'] == true && response['data'] != null) {
          _populateFormFields(response['data']);
        } else {
          // Fallback to passed data if fetch fails
          _populateFormFields(widget.maintenanceData!);
        }
      } else {
        // Fallback to passed data
        _populateFormFields(widget.maintenanceData!);
      }
    } catch (e) {
      print('[Form] Error fetching maintenance data: $e');
      // Fallback to passed data
      _populateFormFields(widget.maintenanceData!);
    }
  }

  Future<void> _loadReservedInventoryItems() async {
    try {
      final taskId = widget.maintenanceData!['id']?.toString();
      if (taskId != null) {
        final response = await _apiService.getInventoryReservations(
          maintenanceTaskId: taskId,
        );
        if (response['success'] == true && response['data'] != null) {
          final reservations = List<Map<String, dynamic>>.from(
            response['data'],
          );

          // Fetch details for each reserved item
          final List<Map<String, dynamic>> itemsWithDetails = [];
          for (final res in reservations) {
            final inventoryId = res['inventory_id'] ?? res['item_id'];
            if (inventoryId != null) {
              try {
                final itemResponse = await _apiService.getInventoryItem(
                  inventoryId,
                );
                if (itemResponse['success'] == true &&
                    itemResponse['data'] != null) {
                  final item = itemResponse['data'];
                  itemsWithDetails.add({
                    'inventory_id': inventoryId,
                    'item_name': item['item_name'] ?? item['name'] ?? '',
                    'item_code': item['item_code'] ?? item['code'] ?? '',
                    'quantity': res['quantity'] ?? 0,
                    'available_stock':
                        item['current_stock'] ?? item['stock'] ?? '',
                    'unit': item['unit'] ?? '',
                  });
                }
              } catch (e) {
                print('Error fetching details for inventory $inventoryId: $e');
                // Add with limited info if fetch fails
                itemsWithDetails.add({
                  'inventory_id': inventoryId,
                  'item_name': res['item_name'] ?? '',
                  'item_code': res['item_code'] ?? inventoryId,
                  'quantity': res['quantity'] ?? 0,
                  'available_stock': '',
                  'unit': '',
                });
              }
            }
          }

          setState(() {
            _selectedInventoryItems = itemsWithDetails;
          });
        }
      }
    } catch (e) {
      print('Error loading reserved inventory: $e');
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
      for (final k in [
        'remarks',
        'additional_notes',
        'additional_note',
        'additional_comments',
        'notes',
        'admin_notification',
      ]) {
        final v = data[k];
        if (v != null) {
          remarksVal = v.toString();
          break;
        }
      }
      _remarksController.text = remarksVal ?? '';

      // Admin notes - accept several possible backend keys
      String? adminNotesVal;
      for (final k in [
        'admin_notes',
        'admin_notification',
        'notes',
        'adminNote',
      ]) {
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
        final validRecurrences = ['Weekly', 'Monthly', 'Quarterly', 'Annually'];
        _selectedRecurrence =
            validRecurrences.contains(recurrenceCapitalized)
                ? recurrenceCapitalized
                : null;
      }

      // Department: validate against department options
      final department = data['department'];
      final validDepartments = [
        'Carpentry',
        'Electrical',
        'Masonry',
        'Plumbing',
      ];
      final deptStr = department?.toString();
      try {
        _selectedDepartment = validDepartments.firstWhere(
          (d) => d.toLowerCase() == deptStr?.toLowerCase(),
        );
      } catch (_) {
        _selectedDepartment = null;
      }

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

      // Populate template (if present)
      final templateKey = data['template_id'] ?? data['templateId'] ?? data['template'];

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

      final startAt = parseFlexibleDate(
        data['start_date'] ?? data['scheduled_date'],
      );
      if (startAt != null) {
        _startDate = startAt;
        _startDateController.text = _fmtDate(_startDate!);
      }

      final nextAt = parseFlexibleDate(
        data['next_due_date'] ?? data['next_due'] ?? data['next_occurrence'],
      );
      if (nextAt != null) {
        _nextDueDate = nextAt;
        _nextDueDateController.text = _fmtDate(_nextDueDate!);
      }

      // Checklist items
      final checklistData =
          data['checklist_completed'] ??
          data['checklistItems'] ??
          data['checklist'] ??
          data['tasks'] ??
          data['task_list'];
      if (checklistData != null && checklistData is List) {
        print('[Form] Populating checklist from data: $checklistData');
        _checklistItems.clear();
        for (var item in checklistData) {
          if (item is Map) {
            _checklistItems.add({
              'id':
                  item['id'] ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              'task': item['task'] ?? item['description'] ?? '',
              'completed': item['completed'] ?? false,
            });
          } else if (item is String) {
            _checklistItems.add({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'task': item,
              'completed': false,
            });
          }
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
            'quantity': item['quantity'] ?? 0,
            'available_stock': item['available_stock'] ?? item['stock'] ?? '',
            'unit': item['unit'] ?? '',
            'autoReserve': item['reserve'] ?? item['reserved'] ?? item['autoReserve'] ?? true,
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
    final dateCreatedIso = _dateCreated?.toIso8601String() ?? DateTime.now().toIso8601String();

    final taskType = <String, dynamic>{
      'id': id,
      'name': _taskTitleController.text.trim(),
      'task_type_id': id,
      'description': _descriptionController.text.trim(),
      'category': _selectedDepartment ?? 'Maintenance',
      'date_created': dateCreatedIso,
      'inventory_items': _selectedInventoryItems.map((i) => {
            'inventory_id': i['inventory_id'],
            'quantity': i['quantity'] ?? 0,
            'autoReserve': i['autoReserve'] ?? false,
          }).toList(),
    };

    // Debug: print the task type payload being sent
    print('[Form] Task type payload: $taskType');

    try {
      if (widget.isEditMode && widget.maintenanceData != null) {
        // Update: for now, we just print and pop
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task type updated (local-only)')),
        );
        Navigator.of(context).pop(taskType);
      } else {
        // Create: push to list - no backend endpoint implemented in codebase
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task type created (local-only)')),
        );
        // Navigate back to the task types list passing the new item as extra
        if (mounted) {
          context.push('/work/tasktypes', extra: taskType);
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
      currentRoute: 'work_task_types_create',
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
                    "Task Type Form",
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
                            onPressed: () => context.go('/work/tasktypes'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const Text('Task Types'),
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
                            child: const Text('Create Task Type'),
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
                      // ===== Task Details =====
                      _buildSectionHeader(
                        "Task Type Details",
                        "Define a reusable task type and link inventory items",
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          // Task Type Name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Task Type Name'),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _taskTitleController,
                                    validator: _req,
                                    decoration: _decoration('Enter Task Type Name'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Type ID
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Task Type ID'),
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

                      // Date Created and Category
                        Row(
                        children: [
                          // Date Created (display only)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Date Created'),
                                Container(
                                  height: _kFieldHeight,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(_dateCreatedController.text.isNotEmpty
                                        ? _dateCreatedController.text
                                        : _fmtDate(DateTime.now()),
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Category Dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Category'),
                                _fieldBox(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedDepartment ?? 'Maintenance',
                                    validator: _reqDropdown,
                                    decoration: _decoration('Select Category...'),
                                    items: const [
                                      'Maintenance',
                                      'Repair',
                                      'Cleaning',
                                      'Inspection',
                                      'Disaster Preparedness',
                                      'Other',
                                    ].map((v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    )).toList(),
                                    onChanged: (v) => setState(() => _selectedDepartment = v),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

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
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          item['item_name'] ??
                                                            'Unknown Item',
                                                          style: const TextStyle(
                                                          fontWeight:
                                                            FontWeight.w600,
                                                          fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      if ((item['reserved_stock'] ?? 0) > 0)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(6)),
                                                          child: Text('Reserved: ${item['reserved_stock'] ?? 0}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${item['item_code'] ?? 'N/A'}',
                                                    style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                    Text(
                                                      'Stock: ${item['available_stock']} ${item['unit'] ?? ''} (Reserved: ${item['reserved_stock'] ?? 0})',
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
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
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
                                                            _selectedInventoryItems[index]['quantity'] =
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
                                                                      seconds:
                                                                          1,
                                                                    ),
                                                              ),
                                                            );
                                                          }

                                                          // Ensure consistency if available stock dropped to 0
                                                          if (availableStock <=
                                                              0) {
                                                            _selectedInventoryItems[index]['quantity'] =
                                                                0;
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
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
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
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
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

                                                          if (availableStock <=
                                                              0) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'No stock available',
                                                                ),
                                                                duration:
                                                                    Duration(
                                                                      seconds:
                                                                          2,
                                                                    ),
                                                              ),
                                                            );
                                                            return;
                                                          }

                                                          final newQty =
                                                              (currentQty + 1)
                                                                  .clamp(
                                                                    1,
                                                                    availableStock,
                                                                  );

                                                          _selectedInventoryItems[index]['quantity'] =
                                                              newQty;
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
                      const SizedBox(height: 24),
                      // Description
                      _fieldLabel('Description'),
                      TextFormField(
                        controller: _descriptionController,
                        validator: _req,
                        maxLines: 3,
                        decoration: _decoration('Enter a short description for this task type...'),
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
                                _isEditing ? "Save Changes" : "Create Task Type",
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
                                      // Prefill quantity to 1 for convenience
                                      if ((_quantityController.text.trim() == '0' || _quantityController.text.trim().isEmpty)) {
                                        _quantityController.text = '1';
                                      }
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
                                    'ID: ${item['item_code'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Stock Available: $currentStock',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (item['unit'] != null &&
                                      item['unit'].toString().isNotEmpty)
                                    Text(
                                      'Unit: ${item['unit']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
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
                    'Stock: ${_selectedItem!['current_stock'] ?? 0}',
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
                            final quantity = int.tryParse(_quantityController.text) ?? 1;
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
                            // Debug info so we can trace add callback behavior
                            print('DEBUG: Inventory dialog add -> item=${_selectedItem!['item_name'] ?? _selectedItem!['name'] ?? _selectedItem!['item_code']}, quantity=$quantity');
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
