import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../popupwidgets/inventoryrestock_popup.dart';

class InventoryItemDetailsPage extends StatefulWidget {
  final String itemId; // Pass item ID through route parameters
  
  const InventoryItemDetailsPage({
    super.key,
    required this.itemId,
  });

  @override
  State<InventoryItemDetailsPage> createState() => _InventoryItemDetailsPageState();
}

class _InventoryItemDetailsPageState extends State<InventoryItemDetailsPage> {
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

  // Sample item data (in real app, this would come from API/database)
  final Map<String, dynamic> _itemData = {
    'itemName': 'Galvanized Screw 3mm',
    'itemCode': 'MAT-CIV-003',
    'dateAdded': 'Automated',
    'classification': 'Materials',
    'department': 'Civil/Carpentry',
    'brandName': '-',
    'quantityInStock': 150,
    'reorderLevel': 50,
    'unit': 'pcs',
    'tag': 'High-Turnover',
    'status': 'In Stock',
    'supplier': 'Not Specified',
    'warrantyUntil': 'DD / MM / YY',
  };

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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with breadcrumbs and action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Inventory Management",
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
                          child: const Text('Items'),
                        ),
                      ],
                    ),
                  ],
                ),
                // Action buttons (Edit & Export)
                Row(
                  children: [
                    // Edit button
                    OutlinedButton.icon(
                      onPressed: () {
                        // Handle edit functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit functionality will go here')),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        "Edit",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Export button
                    ElevatedButton.icon(
                      onPressed: () {
                        // Handle export functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Export functionality will go here')),
                        );
                      },
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text(
                        "Export",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Main Content Sections
            Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header inside card: item title/code on left, chips on right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _itemData['itemName'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _itemData['itemCode'],
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    // chips: auto-size using Wrap 
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildTagChip(_itemData['tag']),
                        _buildStatusChip(_itemData['status']),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // === Sections ===

                _buildInfoSection(
                  title: "Basic Information",
                  icon: Icons.info_outline,
                  iconColor: const Color(0xFF1976D2),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow("Item Name", _itemData['itemName']),
                              _buildInfoRow("Item Code", _itemData['itemCode']),
                              _buildInfoRow("Date Added", _itemData['dateAdded']),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Right Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow("Classification", _itemData['classification']),
                              _buildInfoRow("Department", _itemData['department']),
                              _buildInfoRow("Brand Name", _itemData['brandName']),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),


                const SizedBox(height: 24),

                // 2) SECOND ROW — Stock (left) + Supplier (right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stock Details (left)
                    Expanded(
                      flex: 2,
                      child: _buildInfoSection(
                        title: "Stock Details",
                        icon: Icons.inventory_2_outlined,
                        iconColor: const Color(0xFF4CAF50),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildStockRowStacked(
                                      "Quantity in Stock",
                                      "${_itemData['quantityInStock']} ${_itemData['unit']}",
                                      valueColor: Colors.green,
                                    ),
                                    _buildInfoRowStacked("Unit", _itemData['unit']),
                                    
                                  ],
                                ),
                              ),
                              const SizedBox(width: 32),
                              // Right Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildStockRowStacked(
                                      "Reorder Level",
                                      "${_itemData['reorderLevel']} ${_itemData['unit']}",
                                      valueColor: Colors.red,
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Tag",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        _buildTagChip(_itemData['tag']), // chip under label
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Supplier Information (right)
                    Expanded(
                      flex: 1,
                      child: _buildInfoSection(
                        title: "Supplier Information",
                        icon: Icons.local_shipping_outlined,
                        iconColor: const Color(0xFFFF9800),
                        children: [
                          _buildInfoRowStacked("Supplier", _itemData['supplier']),
                          _buildInfoRowStacked("Warranty Until", _itemData['warrantyUntil']),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Bottom action buttons inside the card
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Show the restock dialog
                        final result = await RestockDialog.show(
                          context,
                          {
                            'id': _itemData['itemCode'],
                            'name': _itemData['itemName'],
                            'unit': _itemData['unit'],
                            'currentStock': _itemData['quantityInStock'],
                          },
                        );
                        
                        // Handle the result if user completed restocking
                        if (result != null && result['success'] == true) {
                          // Update the local state with new quantity
                          setState(() {
                            _itemData['quantityInStock'] += result['quantity'] as int;
                          });
                          
                          // TODO: 
                          // await InventoryService.updateStock(
                          //   itemId: result['itemId'],
                          //   newQuantity: _itemData['quantityInStock'],
                          // );
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        "Update Stock",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('View history functionality will go here')),
                        );
                      },
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text(
                        "View History",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
    );
  }

  // Build information section widget
  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),   
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
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
          // Section content
          ...children,
        ],
      ),
    );
  }

  // Build information row widget
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInfoRowStacked(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Build stock row with colored values
  Widget _buildStockRowStacked(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  

  // Tag chip widget
  Widget _buildTagChip(String tag) {
    Color bgColor;
    Color textColor;
    
    switch (tag) {
      case 'High-Turnover':
        bgColor = const Color(0xFFE8F5E8);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'Critical':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        break;
      case 'Essential':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Status chip widget
  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    
    switch (status) {
      case 'In Stock':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        break;
      case 'Low Stock':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        break;
      case 'Out of Stock':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}