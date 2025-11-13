import 'package:facilityfix/adminweb/inventory_management/admininventoryitems_page.dart';
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

  // Common input decoration
  InputDecoration _getInputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.grey[700]),
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
    );
  }

  // Form controllers
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemCodeController = TextEditingController();
  final TextEditingController _currentStockController = TextEditingController();
  final TextEditingController _reorderLevelController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Dropdown values
  String? _selectedClassification;
  String? _selectedDepartment;
  String? _selectedUnit;
  bool _isCritical = false;
  List<String> _selectedRecommendedLocations = [];

  // State
  bool _isLoading = false;
  String? _errorMessage;

  // TODO: Replace with actual building ID from user session
  final String _buildingId = 'default_building_id';

  // Helper function to get classification code
  String _getClassificationCode(String classification) {
    final codes = {
      'consumable': 'CON',
      'equipment': 'EQP',
      'tool': 'TOL',
      'spare_part': 'SPR',
    };
    return codes[classification] ?? 'ITM';
  }

  // Helper function to get department code
  String _getDepartmentCode(String department) {
    final codes = {
      'electrical': 'ELC',
      'plumbing': 'PLB',
      'masonry': 'MSN',
      'carpentry': 'CRP',
      'maintenance': 'MNT',
    };
    return codes[department] ?? 'GEN';
  }

  // Generate item code based on classification and department
  void _generateItemCode() {
    if (_selectedClassification != null && _selectedDepartment != null) {
      final classCode = _getClassificationCode(_selectedClassification!);
      final deptCode = _getDepartmentCode(_selectedDepartment!);
      final timestamp = DateTime.now().millisecondsSinceEpoch % 10000; // Last 4 digits
      final itemCode = '$classCode-$deptCode-${timestamp.toString().padLeft(4, '0')}';

      setState(() {
        _itemCodeController.text = itemCode;
      });
    }
  }

  // Dropdown options
  final List<String> _classifications = [
    'consumable',
    'equipment',
    'tool',
    'spare_part',
  ];

  final List<String> _departments = [
    'electrical',
    'plumbing',
    'masonry',
    'carpentry',
    'maintenance',
  ];

  final List<String> _units = [
    'pcs',
    'liters',
    'kg',
    'meters',
    'boxes',
    'sets',
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
  ];

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemCodeController.dispose();
    _currentStockController.dispose();
    _reorderLevelController.dispose();
    _supplierController.dispose();
    _descriptionController.dispose();
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

      final itemData = {
        'building_id': _buildingId,
        'item_name': _itemNameController.text.trim(),
        'item_code': _itemCodeController.text.trim(),
        'classification': _selectedClassification,
        'department': _selectedDepartment,
        'current_stock': int.parse(_currentStockController.text.trim()),
        'reorder_level': int.parse(_reorderLevelController.text.trim()),
        'unit': _selectedUnit,
        'is_critical': _isCritical,
        'supplier': _supplierController.text.trim(),
        'recommended_on': _selectedRecommendedLocations,
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
            // Header Section
            Row(
              children: [
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
                      const SizedBox(height: 5),
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

            // Form Container
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
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Basic Information Section
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Item Name
                    TextFormField(
                      controller: _itemNameController,
                      decoration: InputDecoration(
                      labelText: 'Item Name *',
                      hintText: 'Enter item name',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      ),
                      validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Item name is required';
                      }
                      return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Item Code (Row)
                    Row(
                      children: [
                      Expanded(
                        child: TextFormField(
                        controller: _itemCodeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Item Code (Auto-generated) *',
                          hintText: 'Select classification & department',
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          suffixIcon: const Tooltip(
                          message: 'Auto-generated based on classification and department',
                          child: Icon(Icons.auto_awesome, size: 18, color: Colors.blue),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                          return 'Please select classification & department';
                          }
                          return null;
                        },
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Classification & Department (Row)
                    Row(
                      children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                        value: _selectedClassification,
                        decoration: InputDecoration(
                          labelText: 'Classification *',
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                          ),
                        ),
                        items: _classifications.map((classification) {
                          return DropdownMenuItem(
                          value: classification,
                          child: Text(classification.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                          _selectedClassification = value;
                          });
                          _generateItemCode(); // Auto-generate item code
                        },
                        validator: (value) {
                          if (value == null) {
                          return 'Classification is required';
                          }
                          return null;
                        },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                        value: _selectedDepartment,
                        decoration: _getInputDecoration('Department *'),
                        items: _departments.map((department) {
                          return DropdownMenuItem(
                          value: department,
                          child: Text(department.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                          _selectedDepartment = value;
                          });
                          _generateItemCode(); // Auto-generate item code
                        },
                        validator: (value) {
                          if (value == null) {
                          return 'Department is required';
                          }
                          return null;
                        },
                        ),
                      ),
                      ],
                    ),

                    // Item Code Format Info
                    if (_itemCodeController.text.isNotEmpty)
                      Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Row(
                        children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                          'Item code format: [Classification]-[Department]-[Unique ID]',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                          ),
                          ),
                        ),
                        ],
                      ),
                      ),

                    const SizedBox(height: 24),

                    // Stock Information Section
                    const Divider(),
                    const SizedBox(height: 24),
                    const Text(
                      'Stock Information',
                      style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Current Stock, Reorder Level, Unit (Row)
                    Row(
                      children: [
                      Expanded(
                        child: TextFormField(
                        controller: _currentStockController,
                        decoration: _getInputDecoration('Current Stock *', hint: '0'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                          return 'Current stock is required';
                          }
                          if (int.tryParse(value) == null) {
                          return 'Enter a valid number';
                          }
                          return null;
                        },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                        controller: _reorderLevelController,
                        decoration: _getInputDecoration('Reorder Level *', hint: '0'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                          return 'Reorder level is required';
                          }
                          if (int.tryParse(value) == null) {
                          return 'Enter a valid number';
                          }
                          return null;
                        },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: _getInputDecoration('Unit *'),
                        items: _units.map((unit) {
                          return DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                          _selectedUnit = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                          return 'Unit is required';
                          }
                          return null;
                        },
                        ),
                      ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Additional Information Section
                    const Divider(),
                    const SizedBox(height: 24),
                    const Text(
                      'Supplier Information',
                      style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Supplier Name
                    TextFormField(
                      controller: _supplierController,
                      decoration: _getInputDecoration('Supplier Name *', hint: 'Enter supplier name'),
                      validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                      return 'Supplier name is required';
                      }
                      return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Supplier Contact Number
                    TextFormField(
                      decoration: _getInputDecoration('Contact Number', hint: 'e.g. +1234567890'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                      if (value == null || value.trim().isEmpty) return null; // optional
                      final pattern = RegExp(r'^\+?[0-9\s\-]{6,20}$');
                      if (!pattern.hasMatch(value.trim())) {
                      return 'Enter a valid phone number';
                      }
                      return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Supplier Email
                    TextFormField(
                      decoration: _getInputDecoration('Email', hint: 'supplier@example.com'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                      if (value == null || value.trim().isEmpty) return null; // optional
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                      }
                      return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Recommended On (Multi-select)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      const Text(
                        'Recommend On (Locations)',
                        style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _locations.map((location) {
                          final isSelected = _selectedRecommendedLocations.contains(location);
                          return FilterChip(
                          label: Text(location),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                            if (selected) {
                              _selectedRecommendedLocations.add(location);
                            } else {
                              _selectedRecommendedLocations.remove(location);
                            }
                            });
                          },
                          selectedColor: const Color(0xFF1976D2).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF1976D2),
                          backgroundColor: Colors.grey[50],
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: isSelected ? const Color(0xFF1976D2) : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          );
                        }).toList(),
                        ),
                      ),
                      if (_selectedRecommendedLocations.isNotEmpty)
                        Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${_selectedRecommendedLocations.length} location(s) selected',
                          style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          ),
                        ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Critical Item Checkbox
                  
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                      OutlinedButton(
                        onPressed: _isLoading
                          ? null
                          : () {
                            // Navigate to InventoryManagementItemsPage when cancelling
                            Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InventoryManagementItemsPage(),
                            ),
                            );
                          },
                        style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isLoading
                          ? null
                          : () async {
                            // Submit the form first
                            await _submitForm();
                            // If submission succeeded (no error message), navigate to InventoryManagementItemsPage
                            if (mounted && _errorMessage == null) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                              builder: (_) => InventoryManagementItemsPage(),
                              ),
                            );
                            }
                          },
                        style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        ),
                        child: _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                            ),
                          )
                          : const Text(
                            'Create Item',
                            style: TextStyle(color: Colors.white),
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
}
