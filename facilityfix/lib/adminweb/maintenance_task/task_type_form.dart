import 'package:facilityfix/adminweb/widgets/logout_popup.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_storage.dart';
import '../../services/api_services_mobile.dart' as main_api;
import '../layout/facilityfix_layout.dart';
import '../services/api_service_web.dart';

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

// Manual Inventory Input Dialog (for input-only Task Type form)
class _ManualInventoryInputDialog extends StatefulWidget {
  final Function(Map<String, dynamic> item, int quantity) onItemAdded;

  const _ManualInventoryInputDialog({required this.onItemAdded});

  @override
  State<_ManualInventoryInputDialog> createState() =>
      _ManualInventoryInputDialogState();
}

class _ManualInventoryInputDialogState extends State<_ManualInventoryInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _unitController = TextEditingController();
  final _availableStockController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _unitController.dispose();
    _availableStockController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onAdd() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final unit = _unitController.text.trim();
    final qty = int.tryParse(_quantityController.text.trim()) ?? 1;
    final availableStock = int.tryParse(_availableStockController.text.trim()) ?? 0;

    final item = <String, dynamic>{
      'item_name': name,
      'item_code': code,
      'unit': unit,
      'available_stock': availableStock,
    };
    widget.onItemAdded(item, qty);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Inventory Item',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Item name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(labelText: 'Item code', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: InputDecoration(labelText: 'Unit', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _availableStockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Available stock', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Quantity', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      validator: (v) {
                        final n = int.tryParse(v ?? '0') ?? 0;
                        if (n <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _onAdd, child: const Text('Add Item'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTypeFormPageState
    extends State<TaskTypeFormPage> {

  // -------------------- FORM & VALIDATION --------------------
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoMode = AutovalidateMode.disabled; // turn on after first submit

  // For consistent field heights (match external design)
  static const double _kFieldHeight = 48;


  // -------------------- CONTROLLERS --------------------
  final _taskTitleController = TextEditingController();
  final _taskIdController = TextEditingController(); // Auto-generated, read-only
  final _dateCreatedController = TextEditingController(); // read-only display
  final _descriptionController = TextEditingController();
  final _otherCategoryController = TextEditingController();
  
  // -------------------- STATE --------------------
  String? _createdByName;
  DateTime? _dateCreated;
  DateTime? _dateUpdated;
  String? _selectedCategory;

  // Maintenance Types
  final List<String> _maintenanceTypes = [
    'Preventive',
    'Corrective',
    'Proactive',
    'Emergency',
    'Inspection',
    'Repair',
    'Other',
  ];

  // Inventory management (manual input only for Task Type form)
  List<Map<String, dynamic>> _selectedInventoryItems = [];
  List<Map<String, dynamic>> _availableInventoryItems = [];
  final _mainApiService = main_api.APIService();
  final ApiService _adminApi = ApiService();
  bool _isLoadingExisting = false;
  bool _isSubmitting = false;
  String? _currentTaskTypeId;

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

  // -------------------- HELPERS --------------------
  // Date formatting utility
  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _initAutoFields() async {
    // Input-only Task Type form: generate local code and set dates
    final year = DateTime.now().year;
    final number = DateTime.now().millisecondsSinceEpoch % 100000;
    _taskIdController.text = 'TT-$year-${number.toString().padLeft(5, '0')}';

    // Date Created
    _dateCreated = DateTime.now();
    _dateCreatedController.text = _fmtDate(_dateCreated!);

    // Populate created by from stored profile if available
    try {
      final profile = await AuthStorage.getProfile();
      if (profile != null) {
        final firstName = profile['first_name'] ?? '';
        final lastName = profile['last_name'] ?? '';
        final fullName = '$firstName $lastName'.trim();
        setState(() {
          _createdByName = fullName.isNotEmpty ? fullName : null;
        });
      }
    } catch (_) {
      // ignore profile errors in this input-only flow
    }
  }

  Future<void> _loadInventoryItems() async {
    try {
      // Load building ID from profile when available
      String? buildingId;
      try {
        final profile = await AuthStorage.getProfile();
        buildingId = profile?['building_id'] as String? ?? profile?['buildingId'] as String?; 
      } catch (_) {
        buildingId = null;
      }
      buildingId ??= 'default_building_id';
      print('[v0] TaskTypeForm: loading inventory for building: $buildingId');
      final response = await _mainApiService.getBuildingInventory(buildingId);
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _availableInventoryItems = List<Map<String, dynamic>>.from(response['data']);
        });
        print('[DEBUG] TaskTypeForm loaded ${_availableInventoryItems.length} inventory items');
        // Update stock info for any existing selected items
        _updateInventoryStock();
      }
    } catch (e) {
      // Don't fail the whole form if inventory loading fails
      print('[v0] Error loading inventory items: $e');
    }
  }


  void _addInventoryItem() {
    // Use building inventory dialog (no recommendation filtering)
    if (_availableInventoryItems.isEmpty) {
      // When no items are returned from the API, fall back to manual entry dialog
      showDialog(
        context: context,
        builder: (context) => _ManualInventoryInputDialog(
          onItemAdded: (item, qty) {
            setState(() {
              _selectedInventoryItems.add({
                'inventory_id': item['item_code'] ?? item['id'] ?? item['_doc_id'] ?? '',
                'item_name': item['item_name'] ?? item['name'] ?? '',
                'item_code': item['item_code'] ?? item['code'] ?? '',
                'quantity': qty,
                'available_stock': item['available_stock'] ?? item['stock'] ?? 0,
                'unit': item['unit'] ?? item['uom'] ?? item['unit_of_measure'] ?? '',
              });
            });
          },
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _InventorySelectionDialog(
        availableItems: _availableInventoryItems,
        selectedLocation: null,
        onItemSelected: (item, quantity) {
          final qty = (quantity <= 0) ? 1 : quantity;
          setState(() {
            _selectedInventoryItems.add({
              'inventory_id': item['item_code'] ?? item['id'] ?? item['_doc_id'],
              'item_name': item['item_name'] ?? item['name'] ?? '',
              'item_code': item['item_code'] ?? item['code'] ?? '',
              'quantity': qty,
              'available_stock': item['current_stock'] ?? item['available_stock'] ?? item['stock'] ?? 0,
              'unit': item['unit'] ?? item['uom'] ?? item['unit_of_measure'] ?? '',
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

  void _updateInventoryStock() {
    // Update stock info for selected items from available inventory
    if (_availableInventoryItems.isEmpty || _selectedInventoryItems.isEmpty) return;
    
    for (int i = 0; i < _selectedInventoryItems.length; i++) {
      final selectedItem = _selectedInventoryItems[i];
      final inventoryId = selectedItem['inventory_id'] ?? selectedItem['item_code'];
      
      // Find matching item in available inventory
      final matchingItem = _availableInventoryItems.firstWhere(
        (item) => 
          (item['item_code'] == inventoryId) ||
          (item['id'] == inventoryId) ||
          (item['_doc_id'] == inventoryId),
        orElse: () => <String, dynamic>{},
      );
      
      if (matchingItem.isNotEmpty) {
        final currentStock = matchingItem['current_stock'] ?? matchingItem['available_stock'] ?? matchingItem['stock'] ?? 0;
        print('[DEBUG] TaskTypeForm updating stock for ${selectedItem['item_name']}: $currentStock');
        setState(() {
          _selectedInventoryItems[i]['available_stock'] = currentStock;
        });
      }
    }
  }

  Future<List<String>> _createInventoryReservations(String taskId) async {
    // Input-only form helper: does nothing and returns empty list. Kept for compatibility.
    return [];
  }

  // No inventory counts are maintained for TaskTypeFormPage.

  // -------------------- VALIDATORS --------------------
  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _reqDropdown<T>(T? v) => (v == null) ? 'Required' : null;

  String? _validateCategory(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (v == 'Other' && (_otherCategoryController.text.trim().isEmpty)) return 'Please specify the category name';
    return null;
  }

  // -------------------- INIT/DISPOSE --------------------
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    print('[DEBUG] TaskTypeForm initializing - isEditMode: ${widget.isEditMode}');
    print('[DEBUG] TaskTypeForm maintenanceData: ${widget.maintenanceData}');
    await _initAutoFields();
    if (widget.isEditMode) {
      final candidateId = _resolveTaskTypeId(widget.maintenanceData);
      print('[DEBUG] TaskTypeForm candidateId: $candidateId');
      if (candidateId != null) {
        _currentTaskTypeId = candidateId;
        print('[DEBUG] TaskTypeForm fetching data for ID: $candidateId');
        await _loadTaskType(candidateId);
      } else if (widget.maintenanceData != null) {
        print('[DEBUG] TaskTypeForm using provided data directly');
        _populateFormFields(widget.maintenanceData!);
      }
    } else if (widget.maintenanceData != null) {
      _populateFormFields(widget.maintenanceData!);
    }
    await _loadInventoryItems();
  }

  String? _resolveTaskTypeId(Map<String, dynamic>? data) {
    if (data == null) return null;
    return (data['id'] ?? data['formatted_id'] ?? data['task_type_id'] ?? data['taskTypeId'])?.toString();
  }

  Future<void> _loadTaskType(String taskTypeId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingExisting = true;
    });
    try {
      print('[DEBUG] TaskTypeForm fetching task type: $taskTypeId');
      final data = await _adminApi.getTaskType(taskTypeId);
      print('[DEBUG] TaskTypeForm received data: $data');
      _populateFormFields(data);
    } catch (e) {
      print('[DEBUG] TaskTypeForm load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load task type: $e')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingExisting = false;
      });
    }
  }

  // If widget provided data via maintenanceData, _populateFormFields will populate _selectedInventoryItems.

  void _populateFormFields(Map<String, dynamic> data) {
    print('[DEBUG] TaskTypeForm populating fields with data: $data');
    setState(() {
      // Basic fields - task types use 'name' field
      _taskTitleController.text = data['name'] ?? data['task_title'] ?? data['taskTitle'] ?? '';
      print('[DEBUG] TaskTypeForm task title set to: ${_taskTitleController.text}');
      final resolvedId = _resolveTaskTypeId(data) ?? '';
      print('[DEBUG] TaskTypeForm resolved ID: $resolvedId');
      _taskIdController.text = resolvedId;
      if (resolvedId.isNotEmpty) {
        _currentTaskTypeId = resolvedId;
      }
      _descriptionController.text =
          data['task_description'] ?? data['description'] ?? '';

      // Attempt to populate maintenance type from 'category' or 'maintenance_type' if present
      final categoryVal = data['category'] ?? data['maintenance_type'] ?? data['type'];
      if (categoryVal != null) {
        final catStr = categoryVal.toString();
        try {
          _selectedCategory = _maintenanceTypes.firstWhere(
            (d) => d.toLowerCase() == catStr.toLowerCase(),
          );
          _otherCategoryController.text = '';
        } catch (_) {
          _selectedCategory = 'Other';
          _otherCategoryController.text = catStr;
        }
      }

      // Inventory items - need to fetch stock info since backend doesn't include it
      final inventoryList = data['inventory_items'] ?? data['parts_used'] ?? data['inventoryItems'];
      if (inventoryList is List) {
        _selectedInventoryItems.clear();
        for (final item in inventoryList) {
          final rawQuantity = item['quantity'] ?? item['qty'] ?? 0;
          final qty = rawQuantity is int
              ? rawQuantity
              : int.tryParse(rawQuantity?.toString() ?? '0') ?? 0;
          
          // Stock info not provided by backend, will be populated when available inventory loads
          final rawStock = item['available_stock'] ?? item['stock'] ?? item['current_stock'] ?? 0;
          final availableStock = rawStock is int
              ? rawStock
              : int.tryParse(rawStock?.toString() ?? '0') ?? 0;
          
          print('[DEBUG] TaskTypeForm adding inventory item: ${item['item_name']} (${item['inventory_id']}) qty: $qty, stock: $availableStock');
          _selectedInventoryItems.add({
            'inventory_id': item['inventory_id'] ?? item['item_id'] ?? item['item_code'] ?? '',
            'item_name': item['item_name'] ?? item['name'] ?? '',
            'item_code': item['item_code'] ?? item['code'] ?? '',
            'quantity': qty,
            'available_stock': availableStock,
            'unit': item['unit'] ?? item['uom'] ?? item['unit_of_measure'] ?? ''
          });
        }
        // Update stock info from available inventory after items are loaded
        _updateInventoryStock();
      }
      // Populate created/updated metadata if present
      try {
        final createdVal = data['created_at'] ?? data['date_created'] ?? data['createdAt'] ?? data['created_by_date'];
        if (createdVal != null) {
          if (createdVal is int) {
            _dateCreated = DateTime.fromMillisecondsSinceEpoch(createdVal);
          } else if (createdVal is String) {
            _dateCreated = DateTime.tryParse(createdVal) ?? _dateCreated;
          }
          if (_dateCreated != null) {
            _dateCreatedController.text = _fmtDate(_dateCreated!);
          }
        }

        final updatedVal = data['updated_at'] ?? data['date_updated'] ?? data['updatedAt'];
        if (updatedVal != null) {
          if (updatedVal is int) {
            _dateUpdated = DateTime.fromMillisecondsSinceEpoch(updatedVal);
          } else if (updatedVal is String) {
            _dateUpdated = DateTime.tryParse(updatedVal) ?? _dateUpdated;
          }
        }

        final createdBy = data['created_by'] ?? data['createdBy'] ?? data['created_by_name'];
        if (createdBy != null) {
          _createdByName = createdBy.toString();
        }
      } catch (e) {
        // Ignore any parsing errors on optional metadata
      }
    });
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskIdController.dispose();
    _dateCreatedController.dispose();
    _descriptionController.dispose();
    _otherCategoryController.dispose();
    super.dispose();
  }

  // -------------------- ACTIONS --------------------
  void _cancelEdit() {
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

    final id = _taskIdController.text;
    final dateCreatedIso = _dateCreated?.toIso8601String() ?? DateTime.now().toIso8601String();

    final categoryValue = (_selectedCategory == 'Other') ? _otherCategoryController.text.trim() : (_selectedCategory ?? _maintenanceTypes.first);
    final payload = <String, dynamic>{
      'name': _taskTitleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': categoryValue,
      'maintenance_type': categoryValue,
      'inventory_items': _selectedInventoryItems.map((i) => {
        'inventory_id': i['inventory_id'],
        'item_name': i['item_name'],
        'item_code': i['item_code'],
        'quantity': i['quantity'] ?? 0,
        'unit': i['unit'] ?? '',
      }).toList(),
    };
    if (_currentTaskTypeId != null) {
      payload['task_type_id'] = _currentTaskTypeId;
    }

    final isEdit = widget.isEditMode && _currentTaskTypeId != null;
    print('[DEBUG] TaskTypeForm saving - isEdit: $isEdit, ID: $_currentTaskTypeId');
    print('[DEBUG] TaskTypeForm payload: $payload');
    setState(() => _isSubmitting = true);
    try {
      if (isEdit) {
        print('[DEBUG] TaskTypeForm updating task type: $_currentTaskTypeId');
        final result = await _adminApi.updateTaskType(_currentTaskTypeId!, payload);
        print('[DEBUG] TaskTypeForm update result: $result');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task type saved')), 
          );
        }
      } else {
        print('[DEBUG] TaskTypeForm creating new task type');
        final created = await _adminApi.createTaskType(payload);
        print('[DEBUG] TaskTypeForm create result: $created');
        _currentTaskTypeId = _resolveTaskTypeId(created);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task type created')), 
          );
        }
      }
      if (mounted) {
        context.go('/work/task_type');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save task type: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'work_task_type_create',
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
                            onPressed: () => context.go('/work/task_type'),
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
              if (_isLoadingExisting)
                const LinearProgressIndicator(minHeight: 3),

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
                                    controller: _taskIdController,
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
                                _fieldLabel('Maintenance Type'),
                                  _fieldBox(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCategory ?? _maintenanceTypes.first,
                                    validator: _validateCategory,
                                    decoration: _decoration('Select Maintenance Type...'),
                                    items: _maintenanceTypes.map((v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    )).toList(),
                                    onChanged: (v) => setState(() {
                                      _selectedCategory = v;
                                      if (v != 'Other') _otherCategoryController.text = '';
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Specify Category (only shown when "Others" is selected, on the right)
                      if ((_selectedCategory ?? '') == 'Other')
                        Row(
                          children: [
                            const Expanded(child: SizedBox()), // Left spacer
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel('Specify Maintenance Type'),
                                  _fieldBox(
                                    child: TextFormField(
                                      controller: _otherCategoryController,
                                      validator: _req,
                                      decoration: _decoration(
                                        'Enter custom category...',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      
                      // Description
                      _fieldLabel('Description'),
                      TextFormField(
                        controller: _descriptionController,
                        validator: _req,
                        maxLines: 3,
                        decoration: _decoration('Enter a short description for this task type...'),
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
                                          "Add parts or supplies to the task",
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
                                      'No inventory items added yet. Click "Add Item" to add an inventory item.',
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
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    '${item['item_code'] ?? 'N/A'}',
                                                    style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                    Text(
                                                      'Stock: ${item['available_stock']}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Unit: ${item['unit'] ?? item['uom'] ?? item['unit_of_measure'] ?? '—'}',
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


                      // ===== Actions =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cancel / Close
                          TextButton(
                            onPressed: _cancelEdit,
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey[800]),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Primary action (Submit / Save)
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _onNext, // VALIDATE then NAVIGATE
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
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    widget.isEditMode
                                        ? "Save Changes"
                                        : "Create Task Type",
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
  final _quantityController = TextEditingController(text: '0');
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
                                  if (item['unit'] != null && item['unit'].toString().isNotEmpty)
                                    Text(
                                      'Unit: ${item['unit'] ?? item['uom'] ?? item['unit_of_measure']}',
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
