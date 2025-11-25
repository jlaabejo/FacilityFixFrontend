import 'package:facilityfix/adminweb/inventory_management/inventory_item_create_page.dart';
import 'package:facilityfix/adminweb/widgets/logout_popup.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../widgets/delete_popup.dart';
import '../services/api_service.dart';
// auth storage not required here — ApiService handles auth internally
import 'pop_up/inventoryitem_details_popup.dart';
import '../popupwidgets/stock_management_popup.dart';
import '../widgets/tags.dart';
import '../report_files/inventory_report.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';

class InventoryManagementItemsPage extends StatefulWidget {
  const InventoryManagementItemsPage({super.key});

  @override
  State<InventoryManagementItemsPage> createState() =>
      _InventoryManagementItemsPageState();
}

class _InventoryManagementItemsPageState
    extends State<InventoryManagementItemsPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _inventoryItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'All Status';
  String _selectedClassification = 'All Classifications';

  // Search and pagination
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _itemsPerPage = 10;

  // TODO: Replace with actual building ID from user session
  final String _buildingId = 'default_building_id';

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
  }

  Future<void> _loadInventoryItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the ApiService helper that fetches items for a building
      // typed as dynamic because the backend may return different shapes
      final dynamic data = await _apiService.getInventoryItems(
        buildingId: _buildingId,
      );

      List<Map<String, dynamic>> items = [];

      // Backend usually returns a map like { success: true, data: [...] }
      if (data is Map) {
        final maybeList =
            data['data'] ??
            data['items'] ??
            data['results'] ??
            data['inventory_items'];
        if (maybeList is List) {
          items = List<Map<String, dynamic>>.from(maybeList);
        }
      } else if (data is List) {
        items = List<Map<String, dynamic>>.from(data);
      }

      if (mounted) {
        setState(() {
          _inventoryItems = items;
          _updateFilteredItems();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[v0] Error fetching inventory items: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
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

  // Column widths for table
  final List<double> _colW = <double>[
    140, // ITEM NO.
    250, // ITEM NAME
    100, // STOCK
    180, // CLASSIFICATION
    160, // STATUS
    48, // ACTION
  ];

  // Fixed width cell helper
  Widget _fixedCell(
    int i,
    Widget child, {
    Alignment align = Alignment.centerLeft,
  }) {
    return SizedBox(
      width: _colW[i],
      child: Align(alignment: align, child: child),
    );
  }

  // Text with ellipsis helper
  Text _ellipsis(String s, {TextStyle? style}) => Text(
    s,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    softWrap: false,
    style: style,
  );

  // Action dropdown menu methods
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> item,
    Offset position,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                color: Colors.green[600],
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'View',
                style: TextStyle(color: Colors.green[600], fontSize: 14),
              ),
            ],
          ),
        ),
        // 'Manage Stock' action removed — use Details -> Update Stock which
        // delegates to the centralized StockManagementPopup for validation.
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: Colors.blue[600], size: 18),
              const SizedBox(width: 12),
              Text(
                'Edit',
                style: TextStyle(color: Colors.blue[600], fontSize: 14),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red[600], size: 18),
              const SizedBox(width: 12),
              Text(
                'Delete',
                style: TextStyle(color: Colors.red[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
    ).then((value) {
      if (value != null) {
        _handleActionSelection(value, item);
      }
    });
  }

  // Handle action selection
  void _handleActionSelection(String action, Map<String, dynamic> item) {
    switch (action) {
      case 'view':
        _viewItem(item);
        break;
      case 'manage_stock':
        _manageStock(item);
        break;
      case 'edit':
        _editItem(item);
        break;
      case 'delete':
        _deleteItem(item);
        break;
    }
  }

  // View item method
  Future<void> _viewItem(Map<String, dynamic> item) async {
    // Prepare item data for the popup
    final itemData = {
      'itemName': item['item_name'] ?? 'N/A',
      'itemCode': item['item_code'] ?? item['id'] ?? 'N/A',
      'classification': _getItemClassification(item),
      'department': item['department'] ?? 'N/A',
      'quantityInStock': item['current_stock'] ?? 0,
      'reorderLevel': item['reorder_level'] ?? 0,
      'unit': item['unit'] ?? 'pcs',
      'tag': _getItemTag(item),
      'status': _getItemStatus(item),
      'supplier': item['supplier'] ?? 'Not Specified',
      'supplierContact': item['supplier_contact'] ?? 'N/A',
      'supplierEmail': item['supplier_email'] ?? 'N/A',
      'createdAt': item['created_at'] ?? item['createdAt'],
      'updatedBy': item['updated_by'] ?? item['updatedBy'],
      'history': item['history'] ?? [],
      'id': item['id'],
    };

    // Show the details popup and get updated data
    final updatedData = await InventoryItemDetailsDialog.show(
      context,
      itemData,
    );

    // If data was updated, sync it back to the local list
    if (updatedData != null) {
      // Update the local item with new values
      final itemIndex = _inventoryItems.indexWhere(
        (i) => i['id'] == item['id'],
      );
      if (itemIndex != -1) {
        // Get the updated stock value. Accept multiple possible keys returned
        // by various dialogs or API responses for robustness.
        final newStock =
            updatedData['quantityInStock'] ??
            updatedData['currentStock'] ??
            updatedData['current_stock'] ??
            updatedData['quantity'] ??
            0;

        setState(() {
          // Normalize and write multiple key variants so other UI
          // code reading either form will see the updated value.
          _inventoryItems[itemIndex]['current_stock'] = newStock;
          _inventoryItems[itemIndex]['quantity_in_stock'] = newStock;
          _inventoryItems[itemIndex]['quantityInStock'] = newStock;
          _inventoryItems[itemIndex]['currentStock'] = newStock;

          // Optional fields returned from the dialog
          if (updatedData.containsKey('history')) {
            _inventoryItems[itemIndex]['history'] = updatedData['history'];
          }
          if (updatedData.containsKey('updatedBy')) {
            _inventoryItems[itemIndex]['updated_by'] = updatedData['updatedBy'];
          } else if (updatedData.containsKey('updated_by')) {
            _inventoryItems[itemIndex]['updated_by'] =
                updatedData['updated_by'];
          }
        });
        _updateFilteredItems();
      }

      // TODO: Send update to backend API if persistent sync is desired.
      // await _apiService.updateInventoryItem(item['id'], updatedData);
    }
  }

  // Manage stock method
  Future<void> _manageStock(Map<String, dynamic> item) async {
    final result = await StockManagementPopup.show(context, item);

    // If stock was updated, reload the inventory items
    if (result == true) {
      _loadInventoryItems();
    }
  }

  // Edit item method
  void _editItem(Map<String, dynamic> item) {
    // Open the InventoryItemCreatePage in edit mode and reload list on save.
    final itemId = item['id']?.toString() ?? item['item_code']?.toString();
    if (itemId == null) return;

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => InventoryItemCreatePage())).then(
      (result) {
        try {
          if (result is Map && result['saved'] == true) {
            // If edit/save succeeded, reload inventory items to reflect changes
            _loadInventoryItems();
          }
        } catch (e) {
          // ignore
        }
      },
    );
  }

  void _updateFilteredItems() {
    setState(() {
      var items = List<Map<String, dynamic>>.from(_inventoryItems);

      // Apply status filter
      if (_selectedStatus != 'All Status') {
        items =
            items
                .where((item) => _getItemStatus(item) == _selectedStatus)
                .toList();
      }

      // Apply classification filter
      if (_selectedClassification != 'All Classifications') {
        items =
            items
                .where((item) => _getItemClassification(item) == _selectedClassification)
                .toList();
      }

      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        final searchLower = _searchController.text.toLowerCase();
        items =
            items.where((item) {
              final itemNo =
                  (item['item_code'] ?? item['id'] ?? '')
                      .toString()
                      .toLowerCase();
              final itemName =
                  (item['item_name'] ?? '').toString().toLowerCase();
              final stock =
                  (item['current_stock'] ?? '').toString().toLowerCase();
              final classification =
                  (item['classification'] ?? '').toString().toLowerCase();

              return itemNo.contains(searchLower) ||
                  itemName.contains(searchLower) ||
                  stock.contains(searchLower) ||
                  classification.contains(searchLower);
            }).toList();
      }

      // Sort by status low->high: Out of Stock, Low Stock, In Stock
      items.sort((a, b) {
        final statusA = _getItemStatus(a);
        final statusB = _getItemStatus(b);
        final rankA = _statusRank(statusA);
        final rankB = _statusRank(statusB);
        if (rankA != rankB) return rankA.compareTo(rankB);

        // Within same status, sort by quantity ascending (lower stock first)
        final stockA = (a['current_stock'] ?? 0) as num;
        final stockB = (b['current_stock'] ?? 0) as num;
        final stockComp = stockA.compareTo(stockB);
        if (stockComp != 0) return stockComp;

        // Fallback: sort by item name
        final nameA = (a['item_name'] ?? '').toString().toLowerCase();
        final nameB = (b['item_name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      _filteredItems = items;
      _currentPage = 1; // Reset to first page when filter changes
    });
  }

  // Helper to rank statuses so sorting places low stock items first
  int _statusRank(String status) {
    final s = status.toLowerCase();
    if (s.contains('out')) return 0;
    if (s.contains('low')) return 1;
    // default / in stock / high
    return 2;
  }

  void _deleteItem(Map<String, dynamic> item) {
    final itemName = item['item_name'] ?? item['id'] ?? 'Item';

    showDeleteDialog(
      context,
      itemName: itemName.toString(),
      description:
          'Are you sure you want to delete item $itemName? This action cannot be undone.',
    ).then((confirmed) async {
      if (confirmed != true) return;

      try {
        await _apiService.deleteInventoryItem(item['id']);
        // Reload the list
        await _loadInventoryItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item $itemName deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error deleting item: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  String _getItemStatus(Map<String, dynamic> item) {
    final currentStock = item['current_stock'] ?? 0;
    final reorderLevel = item['reorder_level'] ?? 0;

    if (currentStock == 0) {
      return 'Out of Stock';
    } else if (currentStock <= reorderLevel) {
      return 'Low Stock';
    } else {
      return 'In Stock';
    }
  }

  String _getItemTag(Map<String, dynamic> item) {
    final isCritical = item['is_critical'] ?? false;
    final currentStock = item['current_stock'] ?? 0;
    final reorderLevel = item['reorder_level'] ?? 0;

    if (isCritical) {
      return 'Critical';
    } else if (currentStock > reorderLevel * 2) {
      return 'High-Turnover';
    } else {
      return 'Essential';
    }
  }

  String _getItemClassification(Map<String, dynamic> item) {
    // Get classification from item data, or use category/type as fallback
    return item['classification'] ??
        item['category'] ??
        item['type'] ??
        'General';
  }

  // Pagination methods
  List<Map<String, dynamic>> _getPaginatedItems() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _filteredItems.length) return [];

    return _filteredItems.sublist(
      startIndex,
      endIndex > _filteredItems.length ? _filteredItems.length : endIndex,
    );
  }

  int get _totalPages {
    return _filteredItems.isEmpty
        ? 1
        : (_filteredItems.length / _itemsPerPage).ceil();
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pageButtons = [];

    // Show max 5 page numbers at a time
    int startPage = _currentPage - 2;
    int endPage = _currentPage + 2;

    if (startPage < 1) {
      startPage = 1;
      endPage = 5;
    }

    if (endPage > _totalPages) {
      endPage = _totalPages;
      startPage = _totalPages - 4;
    }

    if (startPage < 1) startPage = 1;

    for (int i = startPage; i <= endPage; i++) {
      pageButtons.add(
        GestureDetector(
          onTap: () => _goToPage(i),
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color:
                  i == _currentPage
                      ? const Color(0xFF1976D2)
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                i.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: i == _currentPage ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return pageButtons;
  }

  Future<void> _exportToWord() async {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email ?? 'Admin User';

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    // Create HTML content with styling similar to PDF
    String htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Inventory Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            line-height: 1.6;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .logo {
            width: 80px;
            height: 80px;
            margin: 0 auto 10px;
            background-color: #f0f0f0;
            display: flex;
            align-items: center;
            justify-content: center;
            border: 1px solid #ccc;
        }
        .facility-name {
            font-size: 16px;
            font-weight: bold;
            margin: 10px 0;
        }
        .location, .contact {
            font-size: 12px;
            color: #666;
            margin: 5px 0;
        }
        .report-title {
            font-size: 20px;
            font-weight: bold;
            margin: 20px 0;
        }
        .generated-info {
            display: flex;
            justify-content: space-between;
            font-size: 12px;
            margin-bottom: 30px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            border: 1px solid #ccc;
            border-radius: 8px;
            overflow: hidden;
        }
        th {
            background-color: #1976d2;
            color: white;
            padding: 12px 8px;
            text-align: left;
            font-weight: bold;
            font-size: 13px;
        }
        td {
            padding: 10px 8px;
            border-bottom: 1px solid #ddd;
            font-size: 12px;
        }
        tr:nth-child(odd) {
            background-color: #f9f9f9;
        }
        tr:nth-child(even) {
            background-color: #ffffff;
        }
        .summary {
            background-color: #e3f2fd;
            border: 1px solid #bbdefb;
            border-radius: 8px;
            padding: 20px;
            margin-top: 20px;
        }
        .summary-title {
            font-size: 16px;
            font-weight: bold;
            color: #1976d2;
            margin-bottom: 15px;
        }
        .summary-grid {
            display: flex;
            justify-content: space-around;
            flex-wrap: wrap;
        }
        .summary-item {
            text-align: center;
            margin: 10px;
        }
        .summary-label {
            font-size: 12px;
            color: #666;
            margin-bottom: 5px;
        }
        .summary-value {
            font-size: 18px;
            font-weight: bold;
        }
        .total-value { color: #1976d2; }
        .in-stock-value { color: #2e7d32; }
        .low-stock-value { color: #f57c00; }
        .out-stock-value { color: #d32f2f; }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">[LOGO]</div>
        <div class="facility-name">Facility: Smart Maintenance and Repair Analytics Management System</div>
        <div class="location">Location: Default Location</div>
        <div class="contact">Contact: +1-234-567-8900 | Email: admin@facilityfix.com</div>
        <div class="report-title">Inventory and Procurement Reports</div>
        <div class="generated-info">
            <span>Generated by: $userName</span>
            <span>Generated at: $formattedDate</span>
        </div>
    </div>

    <table>
        <thead>
            <tr>
                <th>Item No.</th>
                <th>Item Name</th>
                <th>Stock</th>
                <th>Classification</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
''';

    // Add table rows
    for (var item in _inventoryItems) {
      final itemNo = item['item_code'] ?? item['id'] ?? 'N/A';
      final itemName = item['item_name'] ?? 'Unknown';
      final stock = (item['current_stock'] ?? 0).toString();
      final classification = _getItemClassification(item);
      final status = _getItemStatus(item);

      htmlContent += '''
            <tr>
                <td>$itemNo</td>
                <td>$itemName</td>
                <td>$stock</td>
                <td>$classification</td>
                <td>$status</td>
            </tr>
''';
    }

    // Add summary section
    final totalItems = _inventoryItems.length;
    final inStock = _inventoryItems.where((item) => _getItemStatus(item) == 'In Stock').length;
    final lowStock = _inventoryItems.where((item) => _getItemStatus(item) == 'Low Stock').length;
    final outStock = _inventoryItems.where((item) => _getItemStatus(item) == 'Out of Stock').length;

    htmlContent += '''
        </tbody>
    </table>

    <div class="summary">
        <div class="summary-title">Report Summary</div>
        <div class="summary-grid">
            <div class="summary-item">
                <div class="summary-label">Total Items</div>
                <div class="summary-value total-value">$totalItems</div>
            </div>
            <div class="summary-item">
                <div class="summary-label">In Stock</div>
                <div class="summary-value in-stock-value">$inStock</div>
            </div>
            <div class="summary-item">
                <div class="summary-label">Low Stock</div>
                <div class="summary-value low-stock-value">$lowStock</div>
            </div>
            <div class="summary-item">
                <div class="summary-label">Out of Stock</div>
                <div class="summary-value out-stock-value">$outStock</div>
            </div>
        </div>
    </div>
</body>
</html>
''';

    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'inventory_report.doc')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with breadcrumbs and Create New button
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
                    const SizedBox(height: 8),
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
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 16,
                        ),
                        TextButton(
                          onPressed: () => context.go('/inventory/items'),
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
                          child: const Text('Items'),
                        ),
                      ],
                    ),
                  ],
                ),
                // Buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        context.goNamed('inventory_item_create');
                      },
                      icon: const Icon(Icons.add, size: 22),
                      label: const Text(
                        "Create New",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Search, Filter, and Refresh Row
            Row(
              children: [
                // Search Field with white background
                SizedBox(
                  width: 400,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                    onChanged: (value) => _updateFilteredItems(),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        hintText: "Search",
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Status Dropdown
                IntrinsicWidth(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: [
                          'All Status',
                          'Out of Stock',
                          'Low Stock',
                          'In Stock',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedStatus = newValue;
                              _updateFilteredItems();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Classification Dropdown
                IntrinsicWidth(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedClassification,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: [
                          'All Classifications',
                          'General',
                          'Electrical',
                          'Plumbing',
                          'Carpentry',
                          'Masonry',
                          'HVAC',
                          'Security',
                          'Fire Safety',
                          'Pest Control',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedClassification = newValue;
                              _updateFilteredItems();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Refresh Button
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: _loadInventoryItems,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: Colors.blue[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main Content Container
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
              child: Column(
                children: [
                  // Table header with title and export
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Inventory Items",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        // Export button
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'pdf') {
                                final user = FirebaseAuth.instance.currentUser;
                                final userName =
                                    user?.displayName ??
                                    user?.email ??
                                    'Admin User';
                                await InventoryReport.generateAndDownloadPDF(
                                  inventoryItems:
                                      _inventoryItems.isNotEmpty
                                          ? _inventoryItems
                                          : null,
                                  userName: userName,
                                  location: 'Default Location',
                                  contactNumber: '+1-234-567-8900',
                                  email: 'admin@facilityfix.com',
                                );
                              } else if (value == 'word') {
                                await _exportToWord();
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  PopupMenuItem(
                                    value: 'pdf',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text('PDF'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'word',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.description,
                                          color: Colors.blue,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Word'),
                                      ],
                                    ),
                                  ),
                                ],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.download,
                                  size: 20,
                                  color: Colors.blue[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Export',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[400]),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadInventoryItems,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_inventoryItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: Text(
                          'No inventory items found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    // Data Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 43,
                        headingRowHeight: 56,
                        dataRowHeight: 64,
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey[50],
                        ),
                        headingTextStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                        dataTextStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        columns: [
                          DataColumn(
                            label: _fixedCell(0, const Text("ITEM ID")),
                          ),
                          DataColumn(label: _fixedCell(1, const Text("NAME"))),
                          DataColumn(label: _fixedCell(2, const Text("STOCK"))),
                          DataColumn(
                            label: _fixedCell(3, const Text("CLASSIFICATION")),
                          ),
                          DataColumn(
                            label: _fixedCell(4, const Text("STATUS")),
                          ),
                          DataColumn(label: _fixedCell(5, const Text(""))),
                        ],
                        rows:
                            _getPaginatedItems().map((item) {
                              final itemNo =
                                  item['item_code'] ?? item['id'] ?? 'N/A';
                              final itemName = item['item_name'] ?? 'Unknown';
                              final stock =
                                  (item['current_stock'] ?? 0).toString();
                              final classification = _getItemClassification(
                                item,
                              );
                              final status = _getItemStatus(item);

                              return DataRow(
                                cells: [
                                  DataCell(
                                    _fixedCell(
                                      0,
                                      _ellipsis(
                                        itemNo,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(_fixedCell(1, _ellipsis(itemName))),
                                  DataCell(_fixedCell(2, _ellipsis(stock))),
                                  DataCell(
                                    _fixedCell(
                                      3,
                                      InventoryClassification(classification),
                                    ),
                                  ),
                                  DataCell(
                                    _fixedCell(4, StockStatusTag(status)),
                                  ),
                                  DataCell(
                                    _fixedCell(
                                      5,
                                      Builder(
                                        builder: (context) {
                                          return IconButton(
                                            onPressed: () {
                                              final rbx =
                                                  context.findRenderObject()
                                                      as RenderBox;
                                              final position = rbx
                                                  .localToGlobal(Offset.zero);
                                              // Anchor the popup below the icon for better positioning
                                              final Offset menuPosition =
                                                  position +
                                                  Offset(
                                                    0,
                                                    rbx.size.height + 6,
                                                  );
                                              _showActionMenu(
                                                context,
                                                item,
                                                menuPosition,
                                              );
                                            },
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: Colors.grey[400],
                                              size: 20,
                                            ),
                                          );
                                        },
                                      ),
                                      align: Alignment.center,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[400]),

                  // Pagination section
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _filteredItems.isEmpty
                              ? "No entries found"
                              : "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage) > _filteredItems.length ? _filteredItems.length : _currentPage * _itemsPerPage} of ${_filteredItems.length} entries",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        // Pagination controls
                        Row(
                          children: [
                            IconButton(
                              onPressed:
                                  _currentPage > 1 ? _previousPage : null,
                              icon: Icon(
                                Icons.chevron_left,
                                color:
                                    _currentPage > 1
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                              ),
                            ),
                            ..._buildPageNumbers(),
                            IconButton(
                              onPressed:
                                  _currentPage < _totalPages ? _nextPage : null,
                              icon: Icon(
                                Icons.chevron_right,
                                color:
                                    _currentPage < _totalPages
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
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
          ],
        ),
      ),
    );
  }
}
