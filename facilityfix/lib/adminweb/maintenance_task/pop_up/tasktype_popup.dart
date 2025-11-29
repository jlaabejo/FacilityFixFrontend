import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TaskTypeViewDialog extends StatelessWidget {
  final Map<String, dynamic> taskType;

  const TaskTypeViewDialog({super.key, required this.taskType});

  static Future<void> show(BuildContext context, Map<String, dynamic> taskType) {
    return showDialog<void>(
      context: context,
      builder: (_) => TaskTypeViewDialog(taskType: taskType),
    );
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return '';
    try {
      final dt = DateTime.parse(d);
      return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = taskType['name'] ?? taskType['taskTypeName'] ?? taskType['task_title'] ?? '';
    final id = taskType['id'] ?? taskType['task_type_id'] ?? taskType['taskCode'] ?? '';
    final category = taskType['category'] ?? taskType['department'] ?? '';
    final description = taskType['description'] ?? taskType['task_description'] ?? '';
    final dateCreatedRaw = taskType['date_created'] ?? taskType['dateCreated'] ?? taskType['created_at'] ?? '';
    final dateCreated = _fmtDate(dateCreatedRaw?.toString());
    final createdBy = taskType['created_by'] ?? taskType['creator'] ?? ''; // Assuming this field exists; adjust if needed
    final inventory = List<Map<String, dynamic>>.from(taskType['inventory_items'] ?? taskType['parts_used'] ?? []);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: 500,
          height: 301, // fixed height to match the design sample
        padding: const EdgeInsets.only(top: 24, left: 24, bottom: 24),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 0.89, color: Colors.black.withOpacity(0.10)),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView( // Make content scrollable
                child: SizedBox(
                  width: 454,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                          color: Color(0xFF191B1C),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.31,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        ),
                        const SizedBox(width: 12),
                        Chip(
                        label: Text(
                          category.toString(),
                          style: const TextStyle(
                          color: Color(0xFF0A0A0A),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          ),
                        ),
                        backgroundColor: Colors.grey[200],
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        ),
                      ],
                      ),
                      const SizedBox(height: 16),
                      // Improved display for Id, Created by, Created at
                      Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                        'Id: $id',
                        style: const TextStyle(
                          color: Color(0xFF626C70),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                        'Created by: $createdBy',
                        style: const TextStyle(
                          color: Color(0xFF626C70),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                        'Created at: $dateCreated',
                        style: const TextStyle(
                          color: Color(0xFF626C70),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                        ),
                      ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                      description.toString(),
                      style: const TextStyle(
                        color: Color(0xFF626C70),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.29,
                      ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 100),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(width: 0.89, color: const Color(0xFFE5E7E8)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          'Inventory Items (${inventory.length})',
                          style: const TextStyle(
                          color: Color(0xFF4A5154),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (inventory.isEmpty)
                          Text(
                          'No inventory linked to this task type',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          )
                        else
                          ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: inventory.length,
                          itemBuilder: (context, index) {
                            final item = inventory[index];
                            final iName = item['item_name'] ?? item['itemName'] ?? item['name'] ?? '';
                            final iQty = item['quantity'] ?? item['qty'] ?? 0;
                            final iId = item['inventory_id'] ?? item['item_id'] ?? item['item_code'] ?? item['itemCode'] ?? '';
                            final iStock = item['available_stock'] ?? item['current_stock'] ?? item['stock'] ?? '';
                            final iUnit = item['unit'] ?? item['uom'] ?? '';

                            return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Row(
                                children: [
                                Expanded(
                                  child: Text(
                                  iName,
                                  style: const TextStyle(
                                    color: Color(0xFF4A5154),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  ),
                                ),
                                Text(
                                  'Qty: $iQty',
                                  style: const TextStyle(
                                  color: Color(0xFF626C70),
                                  fontSize: 12,
                                  ),
                                ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: $iId • Stock: $iStock $iUnit',
                                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                              ),
                              ],
                            ),
                            );
                          },
                          ),
                        ],
                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
                      Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to Task Type form in edit mode with data
                    context.go('/work/tasktypes/create?edit=1', extra: taskType);
                  },
                  child: const Text(
                    'Edit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF005CE7),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.43,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
