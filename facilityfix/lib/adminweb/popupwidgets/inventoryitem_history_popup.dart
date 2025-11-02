import 'package:flutter/material.dart';

class InventoryItemHistoryDialog {
  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> itemData,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.45,
            constraints: const BoxConstraints(
              maxWidth: 650,
              maxHeight: 600,
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
            child: _InventoryItemHistoryContent(itemData: itemData),
          ),
        );
      },
    );
  }
}

class _InventoryItemHistoryContent extends StatelessWidget {
  final Map<String, dynamic> itemData;

  const _InventoryItemHistoryContent({required this.itemData});

  List<Map<String, dynamic>> _parseHistory() {
    final rawHistory = itemData['history'];

    if (rawHistory is List) {
      return rawHistory
          .whereType<Map>()
          .map(
            (entry) => {
              'timestamp': entry['timestamp'],
              'action': entry['action'],
              'quantity': entry['quantity'],
              'note': entry['note'],
              'actor': entry['actor'],
            },
          )
          .toList();
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final historyEntries = _parseHistory();
    final itemName = itemData['itemName'] ?? 'Item';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context, itemName),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: historyEntries.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(historyEntries),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String itemName) {
    return Container(
      padding: const EdgeInsets.only(left: 28, right: 20, top: 20, bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stock History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  itemName,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.blueGrey,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No stock history yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stock updates for this item will appear here once recorded.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<Map<String, dynamic>> entries) {
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) {
        final entry = entries[index];
        return _HistoryEntryCard(entry: entry);
      },
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _HistoryEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final timestamp = entry['timestamp'];
    final action = entry['action'] ?? 'Adjustment';
    final quantity = entry['quantity'];
    final note = entry['note'];
    final actor = entry['actor'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              _buildQuantityBadge(quantity),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            action,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (note != null && note.toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note.toString(),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
          if (actor != null && actor.toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Updated by ${actor.toString()}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantityBadge(dynamic quantity) {
    if (quantity == null) {
      return const SizedBox.shrink();
    }

    final intAmount = int.tryParse(quantity.toString());
    final isPositive = (intAmount ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isPositive ? const Color(0xFFE8F5E8) : const Color(0xFFFFEBEE)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${isPositive ? '+' : ''}${intAmount ?? quantity}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isPositive ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return 'No timestamp';
    }

    if (timestamp is DateTime) {
      return '${timestamp.year}-${_twoDigits(timestamp.month)}-${_twoDigits(timestamp.day)} ${_twoDigits(timestamp.hour)}:${_twoDigits(timestamp.minute)}';
    }

    if (timestamp is String && DateTime.tryParse(timestamp) != null) {
      final parsed = DateTime.parse(timestamp);
      return '${parsed.year}-${_twoDigits(parsed.month)}-${_twoDigits(parsed.day)} ${_twoDigits(parsed.hour)}:${_twoDigits(parsed.minute)}';
    }

    return timestamp.toString();
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
