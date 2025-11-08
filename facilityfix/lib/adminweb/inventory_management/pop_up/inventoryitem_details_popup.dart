import 'package:facilityfix/adminweb/inventory_management/inventory_item_create_page.dart';
import 'package:flutter/material.dart';
import 'inventoryrestock_popup.dart';
import '../../widgets/tags.dart';
import '../../services/api_service.dart';
import '../../../services/auth_storage.dart';

class InventoryItemDetailsDialog {
  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    Map<String, dynamic> itemData,
  ) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            constraints: const BoxConstraints(
              maxWidth: 1000,
              maxHeight: 800,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _InventoryItemDetailsContent(itemData: itemData),
          ),
        );
      },
    );
  }
}

class _InventoryItemDetailsContent extends StatefulWidget {
  final Map<String, dynamic> itemData;

  const _InventoryItemDetailsContent({required this.itemData});

  @override
  State<_InventoryItemDetailsContent> createState() => _InventoryItemDetailsContentState();
}

class _InventoryItemDetailsContentState extends State<_InventoryItemDetailsContent> {
  late Map<String, dynamic> _itemData;
  final ApiService _api = ApiService();
  final String _buildingId = 'default_building_id';

  @override
  void initState() {
    super.initState();
    _itemData = Map<String, dynamic>.from(widget.itemData);
    // Try to populate reservedStock by querying reserved inventory requests
    // for this item if backend did not already include it.
    _maybeLoadReservedStock();
  }

  Future<void> _maybeLoadReservedStock() async {
    try {
      final id = _itemData['id'] ?? _itemData['itemCode'] ?? _itemData['item_code'];
      if (id == null) return;

      final token = await AuthStorage.getToken();
      if (token != null && token.isNotEmpty) {
        _api.setAuthToken(token);
      }

      // Fetch ALL inventory requests with status='reserved' for this item
      // These are requests created by maintenance tasks that allocate inventory
      final resp = await _api.getInventoryRequests(buildingId: _buildingId, status: 'reserved');
      if (resp['success'] == true && resp['data'] is List) {
        final List list = resp['data'];
        int reservedTotal = 0;
        List<Map<String, dynamic>> reservedRequests = [];
        
        for (var r in list) {
          try {
            final invId = r['inventory_id'] ?? r['inventoryId'] ?? r['item_id'];
            if (invId != null && invId.toString() == id.toString()) {
              final qty = (r['quantity_requested'] ?? r['quantity'] ?? 0) as int;
              reservedTotal += qty;
              reservedRequests.add({
                'requestId': r['_doc_id'] ?? r['id'],
                'maintenanceTaskId': r['maintenance_task_id'] ?? r['reference_id'],
                'quantity': qty,
                'date': r['requested_date'],
              });
            }
          } catch (_) {}
        }

        if (reservedTotal > 0 || reservedRequests.isNotEmpty) {
          setState(() {
            _itemData['reservedStock'] = reservedTotal;
            _itemData['reserved_stock'] = reservedTotal;
            _itemData['reservedRequests'] = reservedRequests; // Store for display
          });
        }
      }
    } catch (e) {
      print('[InventoryDetails] Failed to load reserved stock: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Section
        _buildHeader(context),

        // Content with scroll
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Title and Code + Status
                _buildItemHeader(),
                const SizedBox(height: 24),
                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                const SizedBox(height: 24),

                // Basic Information Section
                _buildSectionTitle("Basic Info"),
                const SizedBox(height: 12),
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildInfoTile("Item Name", _itemData['itemName'] ?? 'N/A'),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          child: _buildInfoTile("Item Code", _itemData['itemCode'] ?? 'N/A'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildInfoTile("Department", _itemData['department'] ?? 'N/A'),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          child: _buildClassificationTile("Classification", _itemData['classification'] ?? 'N/A'),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                const SizedBox(height: 24),

                // Stock summary
                _buildSectionTitle("Stock Information"),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 48,
                  runSpacing: 24,
                  children: [
                    SizedBox(
                      width: 220,
                      child: _buildInfoTile(
                        "Current Stock",
                        "${_itemData['quantityInStock'] ?? 0} ${_itemData['unit'] ?? 'pcs'}",
                        valueColor: const Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: _buildInfoTile(
                        "Reorder Level",
                        "${_itemData['reorderLevel'] ?? 0} ${_itemData['unit'] ?? 'pcs'}",
                        valueColor: const Color(0xFFD32F2F),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: _buildInfoTile(
                        "Reserved Stock",
                        "${_itemData['reservedStock'] ?? 0} ${_itemData['unit'] ?? 'pcs'}",
                        valueColor: const Color(0xFFEF6C00),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: _buildInfoTile(
                        "Unit",
                        _itemData['unit'] ?? 'pcs',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                const SizedBox(height: 24),

                // Reserved by maintenance tasks (if any)
                if ((_itemData['reservedRequests'] as List?)?.isNotEmpty == true) ...[
                  _buildSectionTitle("Reserved by Maintenance Tasks"),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.build_circle_outlined, size: 18, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Text(
                              'This item is reserved for scheduled maintenance',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...(_itemData['reservedRequests'] as List).map((req) {
                          final taskId = req['maintenanceTaskId'] ?? 'Unknown';
                          final qty = req['quantity'] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.orange[700],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Task $taskId: $qty ${_itemData['unit'] ?? 'pcs'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey[200], thickness: 1, height: 1),
                  const SizedBox(height: 24),
                ],

                // Supplier details
                _buildSectionTitle("Supplier Information"),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 48,
                  runSpacing: 20,
                  children: [
                    SizedBox(
                      width: 240,
                      child: _buildInfoTile("Supplier Name", _itemData['supplier'] ?? 'Not Specified'),
                    ),
                    SizedBox(
                      width: 240,
                      child: _buildInfoTile("Contact Number", _itemData['supplierContact'] ?? 'N/A'),
                    ),
                    SizedBox(
                      width: 240,
                      child: _buildInfoTile("Email", _itemData['supplierEmail'] ?? 'N/A'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Footer with action buttons
        _buildFooter(context),
      ],
    );
  }

  // Header with title and close button
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 32, right: 24, top: 20, bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Item Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(_itemData),
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Section title
  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
        letterSpacing: 0.8,
      ),
    );
  }

  // Item header with name and code
  Widget _buildItemHeader() {
    final status = (_itemData['status'] ?? '').toString();
    final createdAt = _itemData['createdAt'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _itemData['itemName'] ?? 'Item Name',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _itemData['itemCode'] ?? 'Item Code',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (createdAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Created: ${_formatDate(createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (status.isNotEmpty) ...[
          const SizedBox(width: 16),
          // Use shared StockStatusTag from adminweb widgets
          StockStatusTag(status),
        ],
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    
    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return date.toString();
      }
      
      return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} ${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
    } catch (e) {
      return date.toString();
    }
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  // Footer with divider and action buttons
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              // Use RestockDialog for manual restocking. After a successful
              // restock, refresh the item from the API and close this dialog
              // returning the updated item so the parent page can sync.
              final result = await RestockDialog.show(context, {
                'id': _itemData['id'] ?? _itemData['itemCode'] ?? _itemData['_doc_id'],
                'name': _itemData['itemName'] ?? _itemData['name'],
                'unit': _itemData['unit'] ?? 'pcs',
                'currentStock': _itemData['quantityInStock'] ?? _itemData['currentStock'] ?? 0,
                'performedBy': _itemData['updatedBy'] ?? _itemData['managedBy'] ?? 'Admin',
              });

              if (result != null && result['success'] == true) {
                try {
                  final api = ApiService();
                  final token = await AuthStorage.getToken();
                  if (token != null && token.isNotEmpty) api.setAuthToken(token);

                  final itemId = _itemData['id'] ?? _itemData['itemCode'] ?? _itemData['_doc_id'];
                  if (itemId != null) {
                    final resp = await api.getInventoryItem(itemId.toString());
                    if (resp['success'] == true && resp['data'] is Map) {
                      final updated = Map<String, dynamic>.from(resp['data']);
                      setState(() {
                        // Normalize keys used in this dialog
                        _itemData['quantityInStock'] = updated['current_stock'] ?? updated['quantity_in_stock'] ?? updated['quantityInStock'] ?? _itemData['quantityInStock'];
                        _itemData['currentStock'] = _itemData['quantityInStock'];
                        _itemData['updatedBy'] = updated['updated_by'] ?? updated['updatedBy'] ?? _itemData['updatedBy'];
                        _itemData['history'] = updated['history'] ?? _itemData['history'];
                        _itemData['reorderLevel'] = updated['reorder_level'] ?? updated['reorderLevel'] ?? _itemData['reorderLevel'];
                        _itemData['current_stock'] = updated['current_stock'] ?? updated['quantity_in_stock'] ?? _itemData['current_stock'];
                      });

                      // Refresh reserved stock info (in case a maintenance-linked
                      // inventory request was created/updated) before returning.
                      await _maybeLoadReservedStock();

                      // Close dialog and return updated data to caller
                      Navigator.of(context).pop(_itemData);
                    }
                  }
                } catch (e) {
                  // If refresh fails, still attempt to close and return current data
                  print('[InventoryDetails] Failed to refresh item after restock: $e');
                  Navigator.of(context).pop(_itemData);
                }
              }
            },
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text('Update Stock'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          // const SizedBox(width: 8),
          // OutlinedButton.icon(
          //   onPressed: () {
          //     InventoryItemHistoryDialog.show(context, _itemData);
          //   },
          //   icon: const Icon(Icons.history, size: 16),
          //   label: const Text('View History'),
          //   style: OutlinedButton.styleFrom(
          //     foregroundColor: Colors.grey[700],
          //     side: BorderSide(color: Colors.grey[300]!),
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          //     textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          //   ),
          // ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () async {
              // Navigate to edit page
              final itemId = _itemData['id'] ?? _itemData['itemCode'] ?? _itemData['_doc_id'];
              if (itemId != null) {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => InventoryItemCreatePage(),
                  ),
                );
                
                // If edit was successful, refresh the item data
                if (result != null && result['saved'] == true) {
                  try {
                    final api = ApiService();
                    final token = await AuthStorage.getToken();
                    if (token != null && token.isNotEmpty) api.setAuthToken(token);

                    final resp = await api.getInventoryItem(itemId.toString());
                    if (resp['success'] == true && resp['data'] is Map) {
                      final updated = Map<String, dynamic>.from(resp['data']);
                      setState(() {
                        // Update all fields with normalized keys
                        _itemData['itemName'] = updated['item_name'] ?? updated['name'] ?? updated['itemName'];
                        _itemData['itemCode'] = updated['item_code'] ?? updated['itemCode'];
                        _itemData['classification'] = updated['classification'];
                        _itemData['department'] = updated['department'];
                        _itemData['quantityInStock'] = updated['current_stock'] ?? updated['quantity_in_stock'] ?? updated['quantityInStock'];
                        _itemData['currentStock'] = _itemData['quantityInStock'];
                        _itemData['reorderLevel'] = updated['reorder_level'] ?? updated['reorderLevel'];
                        _itemData['unit'] = updated['unit'];
                        _itemData['supplier'] = updated['supplier'];
                        _itemData['supplierContact'] = updated['supplier_contact'] ?? updated['supplierContact'];
                        _itemData['supplierEmail'] = updated['supplier_email'] ?? updated['supplierEmail'];
                        _itemData['status'] = updated['status'];
                      });
                      
                      // Refresh reserved stock info
                      await _maybeLoadReservedStock();
                    }
                  } catch (e) {
                    print('[InventoryDetails] Failed to refresh item after edit: $e');
                  }
                }
              }
            },
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildClassificationTile(String label, String classification) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        // Use the InventoryClassification tag widget for a compact visual
        InventoryClassification(classification),
      ],
    );
  }


  // Status rendering moved to shared StockStatusTag in widgets/tags.dart
}