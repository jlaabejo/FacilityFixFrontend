import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../services/api_service.dart';
import '../../services/auth_storage.dart';

class InventoryItemCreatePage extends StatefulWidget {
  const InventoryItemCreatePage({super.key});

  @override
  State<InventoryItemCreatePage> createState() =>
      _InventoryItemCreatePageState();
}

class _InventoryItemCreatePageState extends State<InventoryItemCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Form controllers
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemCodeController = TextEditingController();
  final TextEditingController _currentStockController = TextEditingController();
  final TextEditingController _reorderLevelController = TextEditingController();
  final TextEditingController _supplierNameController = TextEditingController();
  final TextEditingController _supplierContactController = TextEditingController();
  final TextEditingController _supplierEmailController = TextEditingController();
  final TextEditingController _customUnitController = TextEditingController();

  // Dropdown values
  String? _selectedClassification;
  String? _selectedDepartment;
  String? _selectedUnit;
  bool _showCustomUnitField = false;

  // State
  bool _isLoading = false;
  String? _errorMessage;
  int _sequenceNumber = 1;

  // TODO: Replace with actual building ID from user session
  final String _buildingId = 'default_building_id';

  // Dropdown options - Updated with display names
  final List<Map<String, String>> _classifications = [
    {'value': 'CON', 'label': 'Consumable'},
    {'value': 'EQP', 'label': 'Equipment'},
    {'value': 'TOL', 'label': 'Tool'},
    {'value': 'SPR', 'label': 'Spare Part'},
  ];

  final List<String> _departments = [
    'Electrical',
    'Plumbing',
    'Masonry',
    'Carpentry',
    'Maintenance',
  ];

  final List<String> _units = [
    'pcs',
    'liters',
    'kg',
    'meters',
    'boxes',
    'sets',
    'others',
  ];

  // Field height constant
  static const double _kFieldHeight = 48;

  @override
  void initState() {
    super.initState();
    _generateItemCode();
  }

  void _generateItemCode() {
    final now = DateTime.now();
    final year = now.year;
    final classificationPrefix = _selectedClassification ?? 'INV';
    _sequenceNumber++;
    final sequenceStr = _sequenceNumber.toString().padLeft(5, '0');
    _itemCodeController.text = '$classificationPrefix-$year-$sequenceStr';
  }

  void _onClassificationChanged(String? value) {
    setState(() {
      _selectedClassification = value;
      _generateItemCode();
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemCodeController.dispose();
    _currentStockController.dispose();
    _reorderLevelController.dispose();
    _supplierNameController.dispose();
    _supplierContactController.dispose();
    _supplierEmailController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  // Route mapping helper function
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
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

      final unitValue = _selectedUnit == 'others' && _customUnitController.text.isNotEmpty
          ? _customUnitController.text.trim()
          : _selectedUnit;

      final itemData = {
        'building_id': _buildingId,
        'item_name': _itemNameController.text.trim(),
        'item_code': _itemCodeController.text.trim(),
        'classification': _selectedClassification?.toLowerCase(),
        'department': _selectedDepartment?.toLowerCase(),
        'current_stock': int.parse(_currentStockController.text.trim()),
        'reorder_level': int.parse(_reorderLevelController.text.trim()),
        'unit': unitValue,
        'supplier': _supplierNameController.text.trim(),
        'supplier_contact': _supplierContactController.text.trim(),
        'supplier_email': _supplierEmailController.text.trim(),
      };

      final response = await _apiService.createInventoryItem(itemData);

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inventory item created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/inventory/items');
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to create inventory item';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[v0] Error creating inventory item: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'inventory_items',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with Breadcrumb
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Create New Item",
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
                      onPressed: () => context.go('/inventory/items'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Inventory Management'),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                    TextButton(
                      onPressed: null,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Create Item'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
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

            // Form Container
            Container(
              width: double.infinity,
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Basic Information Section =====
                    _sectionHeader('Basic Information'),
                    const SizedBox(height: 20),

                    // Item Name (full width)
                    _fieldLabel('Item Name *'),
                    _fieldBox(
                      child: TextFormField(
                        controller: _itemNameController,
                        decoration: _decoration('Enter item name'),
                        validator: _req,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Item Code (read-only, auto-generated)
                    _fieldLabel('Item Code'),
                    _fieldBox(
                      child: TextFormField(
                        controller: _itemCodeController,
                        readOnly: true,
                        decoration: _decoration('Auto-generated').copyWith(
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Classification & Department (Row)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Classification *'),
                              _fieldBox(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedClassification,
                                  decoration: _decoration('Select classification'),
                                  items: _classifications.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item['value'],
                                      child: Text(item['label']!),
                                    );
                                  }).toList(),
                                  onChanged: _onClassificationChanged,
                                  validator: _reqDropdown,
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
                              _fieldLabel('Department *'),
                              _fieldBox(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedDepartment,
                                  decoration: _decoration('Select department'),
                                  items: _departments.map((dept) {
                                    return DropdownMenuItem<String>(
                                      value: dept,
                                      child: Text(dept),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDepartment = value;
                                    });
                                  },
                                  validator: _reqDropdown,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ===== Stock Information Section =====
                    const Divider(),
                    const SizedBox(height: 24),
                    _sectionHeader('Stock Information'),
                    const SizedBox(height: 20),

                    // Current Stock, Reorder Level, Unit (Row)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Current Stock *'),
                              _fieldBox(
                                child: TextFormField(
                                  controller: _currentStockController,
                                  decoration: _decoration('0'),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Invalid number';
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
                              _fieldLabel('Reorder Level *'),
                              _fieldBox(
                                child: TextFormField(
                                  controller: _reorderLevelController,
                                  decoration: _decoration('0'),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Invalid number';
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
                              _fieldLabel('Unit *'),
                              _fieldBox(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedUnit,
                                  decoration: _decoration('Select unit'),
                                  items: _units.map((unit) {
                                    return DropdownMenuItem<String>(
                                      value: unit,
                                      child: Text(unit),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUnit = value;
                                      _showCustomUnitField = value == 'others';
                                    });
                                  },
                                  validator: _reqDropdown,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Custom Unit field (if "others" selected)
                    if (_showCustomUnitField) ...[
                      const SizedBox(height: 16),
                      _fieldLabel('Custom Unit *'),
                      _fieldBox(
                        child: TextFormField(
                          controller: _customUnitController,
                          decoration: _decoration('Enter custom unit (e.g., rolls, pairs)'),
                          validator: _showCustomUnitField ? _req : null,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ===== Supplier Information Section =====
                    const Divider(),
                    const SizedBox(height: 24),
                    _sectionHeader('Supplier Information'),
                    const SizedBox(height: 20),

                    // Supplier Name
                    _fieldLabel('Supplier Name'),
                    _fieldBox(
                      child: TextFormField(
                        controller: _supplierNameController,
                        decoration: _decoration('Enter supplier name'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contact Number & Email (Row)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Contact Number'),
                              _fieldBox(
                                child: TextFormField(
                                  controller: _supplierContactController,
                                  decoration: _decoration('Enter contact number'),
                                  keyboardType: TextInputType.phone,
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
                              _fieldLabel('Email (Optional)'),
                              _fieldBox(
                                child: TextFormField(
                                  controller: _supplierEmailController,
                                  decoration: _decoration('Enter email address'),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ===== Action Buttons =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _isLoading ? null : () => context.go('/inventory/items'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Create Item',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
    );
  }

  // ===== UI Helper Methods =====
  Widget _sectionHeader(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D3748),
        ),
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      );

  Widget _fieldBox({required Widget child}) =>
      SizedBox(height: _kFieldHeight, child: child);

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

  // ===== Validators =====
  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _reqDropdown<T>(T? v) => (v == null) ? 'Required' : null;
}
