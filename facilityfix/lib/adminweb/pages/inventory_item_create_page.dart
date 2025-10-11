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
  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _currentStockController = TextEditingController();
  final TextEditingController _reorderLevelController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Dropdown values
  String? _selectedClassification;
  String? _selectedDepartment;
  String? _selectedUnit;
  bool _isCritical = false;

  // State
  bool _isLoading = false;
  String? _errorMessage;

  // TODO: Replace with actual building ID from user session
  final String _buildingId = 'default_building_id';

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
    'hvac',
    'general',
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

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemCodeController.dispose();
    _brandNameController.dispose();
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
        'brand_name': _brandNameController.text.trim(),
        'current_stock': int.parse(_currentStockController.text.trim()),
        'reorder_level': int.parse(_reorderLevelController.text.trim()),
        'unit': _selectedUnit,
        'is_critical': _isCritical,
        'supplier': _supplierController.text.trim(),
        'description': _descriptionController.text.trim(),
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
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/inventory/items'),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Create New Inventory Item',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a new item to your inventory',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF718096),
              ),
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
                      decoration: const InputDecoration(
                        labelText: 'Item Name *',
                        hintText: 'Enter item name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Item name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Item Code & Brand Name (Row)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _itemCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Item Code *',
                              hintText: 'SKU or barcode',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Item code is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _brandNameController,
                            decoration: const InputDecoration(
                              labelText: 'Brand Name',
                              hintText: 'Enter brand name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Classification & Department (Row)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedClassification,
                            decoration: const InputDecoration(
                              labelText: 'Classification *',
                              border: OutlineInputBorder(),
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
                            decoration: const InputDecoration(
                              labelText: 'Department *',
                              border: OutlineInputBorder(),
                            ),
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
                            decoration: const InputDecoration(
                              labelText: 'Current Stock *',
                              hintText: '0',
                              border: OutlineInputBorder(),
                            ),
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
                            decoration: const InputDecoration(
                              labelText: 'Reorder Level *',
                              hintText: '0',
                              border: OutlineInputBorder(),
                            ),
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
                            decoration: const InputDecoration(
                              labelText: 'Unit *',
                              border: OutlineInputBorder(),
                            ),
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
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Supplier
                    TextFormField(
                      controller: _supplierController,
                      decoration: const InputDecoration(
                        labelText: 'Supplier',
                        hintText: 'Enter supplier name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter item description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Critical Item Checkbox
                    CheckboxListTile(
                      title: const Text('Mark as Critical Item'),
                      subtitle: const Text(
                        'Critical items require immediate attention when stock is low',
                      ),
                      value: _isCritical,
                      onChanged: (value) {
                        setState(() {
                          _isCritical = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => context.go('/inventory/items'),
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
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
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
