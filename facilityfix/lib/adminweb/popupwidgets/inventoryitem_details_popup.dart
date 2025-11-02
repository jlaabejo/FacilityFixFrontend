import 'package:flutter/material.dart';
import 'inventoryrestock_popup.dart';
import 'inventoryitem_history_popup.dart';
import '../widgets/tags.dart';

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

  @override
  void initState() {
    super.initState();
    _itemData = Map<String, dynamic>.from(widget.itemData);
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
                        "Unit",
                        _itemData['unit'] ?? 'pcs',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                const SizedBox(height: 24),

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
              final result = await RestockDialog.show(
                context,
                {
                  'id': _itemData['itemCode'],
                  'name': _itemData['itemName'],
                  'unit': _itemData['unit'],
                  'currentStock': _itemData['quantityInStock'],
                  'performedBy': _itemData['updatedBy'] ?? _itemData['managedBy'] ?? 'Admin',
                },
              );

              if (result != null && result['success'] == true) {
                final addedQuantity = (result['quantity'] as int?) ?? 0;
                final currentStock = int.tryParse((_itemData['quantityInStock'] ?? '0').toString()) ?? 0;
                final newStock = currentStock + addedQuantity;

                setState(() {
                  _itemData['quantityInStock'] = newStock;
                  _itemData['currentStock'] = newStock;
                  _itemData['updatedBy'] = result['actor'] ?? 'Admin';

          final existingHistory = ((_itemData['history'] as List?) ?? [])
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();

                  existingHistory.insert(0, {
                    'timestamp': result['timestamp'],
                    'action': result['action'] ?? 'Stock Updated',
                    'quantity': addedQuantity,
                    'note': result['note'] ?? 'Stock adjusted from $currentStock to $newStock',
                    'actor': result['actor'] ?? 'Admin',
                  });

                  _itemData['history'] = existingHistory;
                });
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
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              InventoryItemHistoryDialog.show(context, _itemData);
            },
            icon: const Icon(Icons.history, size: 16),
            label: const Text('View History'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(_itemData);
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