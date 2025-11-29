import 'package:facilityfix/adminweb/widgets/logout_popup.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../services/api_service.dart';
import '../../services/auth_storage.dart';

class EquipmentRegisterNewPage extends StatefulWidget {
  final String? equipmentId;
  final bool startInEditMode;
  const EquipmentRegisterNewPage({super.key, this.equipmentId, this.startInEditMode = false});

  @override
  State<EquipmentRegisterNewPage> createState() =>
      _EquipmentRegisterNewPageState();
}

class _EquipmentRegisterNewPageState extends State<EquipmentRegisterNewPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isEditMode = false;

  // For consistent field heights
  static const double _kFieldHeight = 48;

  // Common input decoration
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

  // Form controllers
  final TextEditingController _equipmentNameController =
      TextEditingController();
  final TextEditingController _equipmentIdController = TextEditingController();
  final TextEditingController _assetTagController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _modelNumberController = TextEditingController();
  final TextEditingController _acquisitionDateController = TextEditingController();
  final TextEditingController _installationDateController = TextEditingController();
  final TextEditingController _createdByController = TextEditingController();
  final TextEditingController _createdAtController = TextEditingController();
  final TextEditingController _updatedAtController = TextEditingController();
  final TextEditingController _lastMaintenanceDateController =
      TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();

  // Dropdown values
  String? _selectedCategory;
  String? _selectedLocation;
  String _selectedStatus = 'Operational';
  bool _isLoading = false;
  String? _errorMessage;

  // TODO: Replace with actual building ID from user session
  String _buildingId = 'default_building_id';

  // Dropdown options
  final List<String> _categories = [
    'HVAC',
    'Plumbing',
    'Electrical',
    'Masonry',
    'Carpentry',
    'Other',
  ];

  final List<String> _locations = [
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

  // Equipment Types
  final List<String> _equipmentTypes = [
    'HVAC System',
    'Elevator',
    'Generator',
    'Water System',
    'Safety Equipment',
    'Lighting',
    'Electrical System',
    'Plumbing',
    'Fire Safety',
    'Security System',
    'Other',
  ];
  String? _selectedEquipmentType;

  final List<String> _statusOptions = [
    'Operational',
    'Under Maintenance',
    'Under Repair',
    'Out of Service',
  ];

  @override
  void dispose() {
    _equipmentNameController.dispose();
    _equipmentIdController.dispose();
    _assetTagController.dispose();
    _serialNumberController.dispose();
    _manufacturerController.dispose();
    _modelNumberController.dispose();
    _acquisitionDateController.dispose();
    _installationDateController.dispose();
    _createdByController.dispose();
    _createdAtController.dispose();
    _updatedAtController.dispose();
    _lastMaintenanceDateController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // auto-generate equipment id and timestamps
    _equipmentIdController.text = 'EQ-${DateTime.now().millisecondsSinceEpoch}';
    final nowIso = DateTime.now().toIso8601String();
    _createdAtController.text = nowIso;
    _updatedAtController.text = nowIso;
    AuthStorage.getProfile().then((profile) {
      setState(() {
        _createdByController.text = profile != null
            ? ((profile['first_name'] ?? '') + ' ' + (profile['last_name'] ?? '')).trim()
            : 'system';
        _buildingId = profile != null
            ? profile['building_id'] ?? profile['buildingId'] ?? profile['building'] ?? 'default_building_id'
            : 'default_building_id';
      });
    });
    // If opened in edit mode, load equipment details
    if (widget.equipmentId != null || widget.startInEditMode) {
      _isEditMode = true;
      final idToLoad = widget.equipmentId;
      if (idToLoad != null && idToLoad.isNotEmpty) {
        _loadEquipmentForEdit(idToLoad);
      }
    }
  }

  Future<void> _loadEquipmentForEdit(String id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final token = await AuthStorage.getToken();
      if (token != null && token.isNotEmpty) {
        _apiService.setAuthToken(token);
      }
      final detailResp = await _apiService.getEquipmentDetails(id);
      if (detailResp != null) {
        // Normalize the response - backend may return {'success': true, 'data': {...}} or raw object
        Map<String, dynamic> payload = {};
        if (detailResp.containsKey('data') && detailResp['data'] is Map) {
          payload = Map<String, dynamic>.from(detailResp['data']);
        } else if (detailResp.containsKey('data') && detailResp['data'] is Map<String, dynamic>) {
          payload = Map<String, dynamic>.from(detailResp['data']);
        } else {
          payload = Map<String, dynamic>.from(detailResp);
        }
        _populateFormFromPayload(payload);
      }
    } catch (e) {
      print('[EquipmentRegister] Failed to load equipment for edit: $e');
      setState(() {
        _errorMessage = 'Failed to load equipment details: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFormFromPayload(Map<String, dynamic> p) {
    setState(() {
      _equipmentIdController.text = p['equipment_id']?.toString() ?? p['formatted_id']?.toString() ?? p['id']?.toString() ?? '';
      _equipmentNameController.text = p['equipment_name'] ?? p['name'] ?? '';
      _assetTagController.text = p['asset_tag'] ?? '';
      _manufacturerController.text = p['manufacturer'] ?? '';
      _modelNumberController.text = p['model_number'] ?? '';
      _serialNumberController.text = p['serial_number'] ?? '';
      _selectedCategory = p['category'] ?? p['type'] ?? null;
      _selectedEquipmentType = p['equipment_type'] ?? null;
      _selectedLocation = p['location'] ?? p['area'] ?? null;
      _selectedStatus = p['status'] ?? _selectedStatus;
      // Display dates as ISO date-only strings (YYYY-MM-DD)
      _acquisitionDateController.text = _dateOnlyStringFromPayloadField(p['acquisition_date']);
      _installationDateController.text = _dateOnlyStringFromPayloadField(p['installation_date']);
      _lastMaintenanceDateController.text = _dateOnlyStringFromPayloadField(p['last_maintenance_date']);
      _additionalNotesController.text = p['additional_notes']?.toString() ?? '';
      _createdAtController.text = p['created_at']?.toString() ?? p['createdAt']?.toString() ?? '';
      _updatedAtController.text = p['updated_at']?.toString() ?? p['updatedAt']?.toString() ?? '';
      _createdByController.text = p['created_by'] ?? p['createdBy'] ?? _createdByController.text;
      _equipmentIdController.selection = TextSelection.fromPosition(TextPosition(offset: _equipmentIdController.text.length));
    });
  }

  String _dateOnlyStringFromPayloadField(dynamic v) {
    if (v == null) return '';
    if (v is DateTime) return _formatDateOnly(v);
    final s = v.toString();
    // try parse ISO
    final dt = DateTime.tryParse(s);
    if (dt != null) return _formatDateDisplay(dt);
    // try MM/DD/YYYY
    final mdMatch = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(s);
    if (mdMatch != null) {
      final m = int.tryParse(mdMatch.group(1) ?? '1') ?? 1;
      final d = int.tryParse(mdMatch.group(2) ?? '1') ?? 1;
      final y = int.tryParse(mdMatch.group(3) ?? '1970') ?? 1970;
      try { return _formatDateDisplay(DateTime(y, m, d)); } catch (_) {}
    }
    // fallback: return string trimmed (may already be date-only)
    return s;
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

  Widget _fieldLabel(String text, {bool isRequired = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        if (isRequired)
          const Text(' *', style: TextStyle(color: Colors.red, fontSize: 14)),
      ],
    ),
  );

  // Wrap inputs to enforce consistent heights
  Widget _fieldBox({required Widget child}) =>
      SizedBox(height: _kFieldHeight, child: child);

  // Route mapping helper function
  static String? _getRoutePath(String routeKey) {
      final Map<String, String> pathMap = {
        'dashboard': '/dashboard',
        'user_users': '/user/users',
        'user_scheduling': '/user/scheduling',
        'work_maintenance': '/work/maintenance',
        'work_repair': '/work/repair',
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

  // Date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _lastMaintenanceDateController.text = _formatDateDisplay(picked);
      });
    }
  }

  Future<void> _selectDateForController(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = _formatDateDisplay(picked);
      });
    }
  }

  String _formatDateDisplay(DateTime dateTime) {
    return '${_twoDigits(dateTime.month)}/${_twoDigits(dateTime.day)}/${dateTime.year}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatDateOnly(DateTime dateTime) {
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}';
  }

  /// Normalize dates submitted via controllers to ISO date only (YYYY-MM-DD).
  String? _normalizeDateField(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    // Try ISO parse
    try {
      final dt = DateTime.tryParse(trimmed);
      if (dt != null) return _formatDateOnly(dt);
    } catch (_) {}
    // Try MM/DD/YYYY parse
    final mdMatch = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(trimmed);
    if (mdMatch != null) {
      final m = int.tryParse(mdMatch.group(1) ?? '1') ?? 1;
      final d = int.tryParse(mdMatch.group(2) ?? '1') ?? 1;
      final y = int.tryParse(mdMatch.group(3) ?? '1970') ?? 1970;
      try {
        return _formatDateOnly(DateTime(y, m, d));
      } catch (_) {}
    }
    // Fallback: return raw if we could not parse
    return trimmed;
  }

  // Convert localized display string (MM/dd/YYYY) to DateTime
  DateTime? _parseLocalDisplayDate(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    // Try parsing ISO first
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;
    // Try MM/dd/yyyy
    final mdMatch = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(trimmed);
    if (mdMatch != null) {
      final m = int.tryParse(mdMatch.group(1) ?? '1') ?? 1;
      final d = int.tryParse(mdMatch.group(2) ?? '1') ?? 1;
      final y = int.tryParse(mdMatch.group(3) ?? '1970') ?? 1970;
      try {
        return DateTime(y, m, d);
      } catch (_) {}
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Authentication required. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      _apiService.setAuthToken(token);

      final equipmentData = {
        'building_id': _buildingId,
        'equipment_id': _equipmentIdController.text.trim(),
        'name': _equipmentNameController.text.trim(),
        'asset_tag': _assetTagController.text.trim(),
        'manufacturer': _manufacturerController.text.trim(),
        'model_number': _modelNumberController.text.trim(),
        'serial_number': _serialNumberController.text.trim(),
        'category': _selectedCategory,
        'equipment_type': _selectedEquipmentType,
        'location': _selectedLocation,
        'status': _selectedStatus,
        'acquisition_date': _normalizeDateField(_acquisitionDateController.text),
        'installation_date': _normalizeDateField(_installationDateController.text),
        'last_maintenance_date': _normalizeDateField(_lastMaintenanceDateController.text),
        'additional_notes': _additionalNotesController.text.trim(),
        'created_by': _createdByController.text.trim(),
      };

      // TODO: Replace with actual API endpoint
      // final response = await _apiService.registerEquipment(equipmentData);

      // Call server API to register equipment or update if editing
      Map<String, dynamic> response;
      if (_isEditMode && (widget.equipmentId != null && widget.equipmentId!.isNotEmpty)) {
        response = await _apiService.updateEquipment(widget.equipmentId!, equipmentData);
      } else {
        response = await _apiService.registerEquipment(equipmentData);
      }

      // The backend may return the created equipment record, or a success flag.
      final createdId = response['equipment_id'] ?? response['id'] ?? response['equipment']?['equipment_id'];
      final createdAt = response['created_at'] ?? response['createdAt'] ?? response['equipment']?['created_at'];
      final updatedAt = response['updated_at'] ?? response['updatedAt'] ?? response['equipment']?['updated_at'];

      if (response.isNotEmpty) {
        // update local controllers with server-generated timestamps
        if (createdAt != null) _createdAtController.text = createdAt.toString();
        if (updatedAt != null) _updatedAtController.text = updatedAt.toString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isEditMode ? 'Equipment updated successfully' : 'Equipment registered successfully'),
                backgroundColor: Colors.green,
              ),
            );
          if (createdId != null && createdId.toString().isNotEmpty) {
            // Optionally show generated equipment id in the snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Equipment ID: $createdId'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          if (createdAt != null && createdAt.toString().isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Created At: $createdAt'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          if (updatedAt != null && updatedAt.toString().isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Updated At: $updatedAt'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          context.go('/inventory/equipment');
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to register equipment';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[v0] Error registering equipment: $e');
      setState(() {
        // try to surface server message from thrown exception
        final msg = e.toString().replaceFirst('Exception: ', '');
        _errorMessage = msg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'inventory_equipment',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- HEADER ----------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Register New Equipment",
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
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Dashboard'),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                        size: 16,
                      ),
                      TextButton(
                        onPressed: () => context.go('/inventory/equipment'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Inventory Management'),
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
                        child: const Text('Equipment Registry'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),

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
                      // ===== Equipment Information =====
                      _buildSectionHeader(
                        "Equipment Information",
                        "Details about the equipment being registered",
                      ),
                      const SizedBox(height: 24),

                      // Equipment Name and Equipment Id (Row)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Equipment Name', isRequired: true),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _equipmentNameController,
                                    decoration: _decoration(
                                      'e.g., Main HVAC Unit',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Equipment name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Equipment Id'),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _equipmentIdController,
                                    decoration: _decoration(
                                      'Auto-generated ID',
                                    ),
                                    readOnly: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Manufacturer and Asset Tag (Row)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Manufacturer', isRequired: true),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _manufacturerController,
                                    decoration: _decoration('e.g., ACME Corp'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Manufacturer is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Asset Tag'),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _assetTagController,
                                    decoration: _decoration('e.g., ACME Corp'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Model Number and Serial Number (Row)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Model Number', isRequired: true),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _modelNumberController,
                                    decoration: _decoration('e.g., ACME Corp'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Model number is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Serial Number', isRequired: true),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _serialNumberController,
                                    decoration: _decoration('e.g., S/N 12345'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Serial number is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ===== Status and Timeline =====
                      _buildSectionHeader(
                        "Operational Details and Classification",
                        "Details about the equipment being registered",
                      ),
                      const SizedBox(height: 24),

                      // Location and Category (Row)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Location', isRequired: true),
                                _fieldBox(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedLocation,
                                    decoration: _decoration('Select location'),
                                    items:
                                        _locations.map((String location) {
                                          return DropdownMenuItem<String>(
                                            value: location,
                                            child: Text(location),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedLocation = newValue;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Location is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Category', isRequired: true),
                                _fieldBox(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    decoration: _decoration('Select category'),
                                    items: _categories.map((String category) {
                                      return DropdownMenuItem<String>(
                                        value: category,
                                        child: Text(category),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedCategory = newValue;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Category is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Equipment Type
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Equipment Type', isRequired: true),
                                _fieldBox(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedEquipmentType,
                                    decoration: _decoration('Select equipment type'),
                                    items:
                                        _equipmentTypes.map((String t) {
                                          return DropdownMenuItem<String>(
                                            value: t,
                                            child: Text(t),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedEquipmentType = newValue;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Equipment type is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          const Expanded(
                            child: SizedBox(),
                          ), // keep right column space
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ===== Operational Details and Classification =====
                      _buildSectionHeader(
                        "Status and Timeline",
                        "Status and last maintenance information",
                      ),
                      const SizedBox(height: 24),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Installation Date
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Installation Date'),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _installationDateController,
                                    decoration: _decoration('MM/DD/YYYY'),
                                    readOnly: true,
                                    onTap: () => _selectDateForController(_installationDateController),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Acquisition Date'),
                                _fieldBox(
                                  child: TextFormField(
                                    controller: _acquisitionDateController,
                                    decoration: _decoration('MM/DD/YYYY'),
                                    readOnly: true,
                                    onTap: () => _selectDateForController(_acquisitionDateController),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      // Created and updated timestamps are fetched in initState
                      // but not shown in the UI. They remain in payload via controllers.
                      const SizedBox(height: 24),

                      // Information Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Equipment Registry',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Once registered, this equipment will be available for maintenance task assignments and tracking. Make sure all required information is accurate for proper maintenance scheduling.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
            const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => context.go('/inventory/equipment'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              side: const BorderSide(color: Colors.grey),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _submitForm,
                            icon: const Icon(Icons.check),
                            label: Text(
                              _isLoading
                                  ? (_isEditMode ? 'Updating...' : 'Registering...')
                                  : (_isEditMode ? 'Update Equipment' : 'Register Equipment'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
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
}
