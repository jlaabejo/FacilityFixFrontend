import 'package:flutter/material.dart';

// `MaintenanceHistoryDetailsDialog` accepts `maintenanceHistory` via the `show` method.

class MaintenanceHistoryDetailsDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    List<Map<String, dynamic>>? maintenanceHistory,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 760),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _MaintenanceHistoryContent(
              title: title,
              subtitle: subtitle,
              maintenanceHistory: maintenanceHistory ?? [],
            ),
          ),
        );
      },
    );
  }

  // NOTE: `showSample` removed; call `show` directly to display the dialog. If
  // you need a quick sample for demo purposes, pass a small list directly to
  // `maintenanceHistory` when calling `show`.
}

class _MaintenanceHistoryContent extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Map<String, dynamic>> maintenanceHistory;

  const _MaintenanceHistoryContent({
    Key? key,
    required this.title,
    this.subtitle,
    required this.maintenanceHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Title + Subtitle Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 28,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF191B1C),
                        fontSize: 18,
                        fontFamily: 'Public Sans',
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 380,
                    child: Text(
                      subtitle ?? '',
                      style: const TextStyle(
                        color: Color(0xFF626C70),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.grey),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // List of maintenance cards
        Expanded(
          child: maintenanceHistory.isEmpty
              ? Center(
                  child: Text(
                    'No maintenance logs available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.separated(
                  itemBuilder: (context, index) {
                    final rec = maintenanceHistory[index];
                    return _buildMaintenanceCard(context, rec);
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemCount: maintenanceHistory.length,
                ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceCard(BuildContext context, Map<String, dynamic> record) {
    // Record fields (with fallbacks)
    // Allow `date` to be either a String or DateTime (we'll format it with _formatDate).
    final dynamic date = record['date'] ?? record['created_at'] ?? record['createdAt'] ?? '';
    // Cast/format all other fields to strings safely so UI Text widgets don't get a non-string type.
    final String logId = (record['log_id'] ?? record['id'] ?? record['maintenanceId'] ?? '').toString();
    final String title = (record['title'] ?? record['subject'] ?? 'Maintenance Task').toString();
    final String notes = (record['notes'] ?? record['description'] ?? '').toString();
    final String staff = (record['staff'] ?? record['technician'] ?? record['performedBy'] ?? '').toString();
    final String department = (record['department'] ?? record['dept'] ?? record['team'] ?? '').toString();
    final parts = record['partsUsed'] as List? ?? record['parts'] as List? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 0.8, color: const Color(0xFFE5E7E8)),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: date and log id badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(date),
                style: const TextStyle(
                  color: Color(0xFF191B1C),
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withOpacity(0.10), width: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  logId,
                  style: const TextStyle(fontSize: 10, fontFamily: 'Arial'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Title & notes
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4A5154),
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            notes,
            style: const TextStyle(
              color: Color(0xFF626C70),
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 10),

          // Staff
          Text(
            'Staff: ${staff.isNotEmpty ? staff : 'N/A'}',
            style: const TextStyle(
              color: Color(0xFF626C70),
              fontSize: 11,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 6),
          // Department
          Text(
            'Department: ${department.isNotEmpty ? department : 'N/A'}',
            style: const TextStyle(
              color: Color(0xFF626C70),
              fontSize: 11,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // Parts used container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(width: 0.8, color: const Color(0xFFE5E7E8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parts Used:',
                  style: TextStyle(
                    color: Color(0xFF4A5154),
                    fontSize: 11,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                ...parts.map((p) {
                  final label = p is String
                      ? p
                      : (p['name'] ?? p['label'] ?? p['part'] ?? 'Unknown Part');
                  return Text(
                    '• $label',
                    style: const TextStyle(
                      color: Color(0xFF626C70),
                      fontSize: 11,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      if (value is DateTime) {
        return '${value.year}-${_twoDigits(value.month)}-${_twoDigits(value.day)}';
      }
      if (value is String) {
        final dt = DateTime.tryParse(value);
        if (dt != null) {
          return '${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)}';
        }
        return value;
      }
    } catch (_) {}
    return value.toString();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
