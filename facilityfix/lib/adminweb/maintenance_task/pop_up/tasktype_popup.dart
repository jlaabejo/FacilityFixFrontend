import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/tags.dart';
import 'package:facilityfix/utils/ui_format.dart';

class TaskTypeViewDialog extends StatelessWidget {
  final Map<String, dynamic> taskType;

  const TaskTypeViewDialog({super.key, required this.taskType});

  static Future<void> show(BuildContext context, Map<String, dynamic> taskType) {
    return showDialog<void>(
      context: context,
      builder: (_) => TaskTypeViewDialog(taskType: taskType),
    );
  }

  // Note: Date formatting is handled via UiDateUtils for relative formatting and full human readable timestamps.

  @override
  Widget build(BuildContext context) {
    print('[DEBUG] TaskType popup data: $taskType');
    final name = taskType['name'] ?? taskType['taskTypeName'] ?? taskType['task_title'] ?? '';
    final id = taskType['id'] ?? taskType['task_type_id'] ?? taskType['taskCode'] ?? '';
    final category = taskType['category'] ?? taskType['department'] ?? '';
    final description = taskType['description'] ?? taskType['task_description'] ?? '';
    final dateCreatedRaw = taskType['date_created'] ?? taskType['dateCreated'] ?? taskType['created_at'] ?? '';
    DateTime? _parseDate(String? raw) {
      if (raw == null || raw.toString().isEmpty) return null;
      final s = raw.toString();
      // try ISO first
      final iso = DateTime.tryParse(s);
      if (iso != null) return iso;
      try {
        return UiDateUtils.parse(s);
      } catch (_) {
        return null;
      }
    }
    final createdAtDt = _parseDate(dateCreatedRaw?.toString());
    final createdBy = taskType['created_by_name'] ?? taskType['creator_name'] ?? taskType['created_by'] ?? taskType['creator'] ?? taskType['createdBy'] ?? '';
    print('[DEBUG] Created by value: $createdBy');
    print('[DEBUG] Available created_by fields: created_by_name=${taskType['created_by_name']}, creator_name=${taskType['creator_name']}, created_by=${taskType['created_by']}, creator=${taskType['creator']}');
    final dateUpdatedRaw = taskType['date_updated'] ?? taskType['updated_at'] ?? taskType['updatedAt'] ?? '';
    final updatedAtDt = _parseDate(dateUpdatedRaw?.toString());
    final updatedBy = taskType['updated_by_name'] ?? taskType['updated_by'] ?? taskType['updatedBy'] ?? taskType['managedBy'] ?? '';
    // Determine whether a meaningful update exists - show if there's an update date that's after creation
    final bool hasUpdated = updatedAtDt != null && createdAtDt != null && updatedAtDt.isAfter(createdAtDt);
    final inventory = List<Map<String, dynamic>>.from(taskType['inventory_items'] ?? taskType['parts_used'] ?? taskType['inventoryItems'] ?? []);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
        padding: const EdgeInsets.only(top: 0, left: 0, right: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header (rendered by helper)
                      _buildHeader(context, taskType),
                      const SizedBox(height: 16),
                      // Content (scrollable)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display the task type name (title) + metadata
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: Color(0xFF191B1C),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // move maintenance type tag next to the title (on the right)
                                  MaintenanceTypeTag((taskType['maintenance_type'] ?? taskType['task_type'] ?? category).toString()),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Metadata: Id, Created/Updated info
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$id',
                                    style: const TextStyle(
                                      color: Color(0xFF626C70),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Move created/updated metadata below ID (content area only)
                                  if (createdBy.isNotEmpty || createdAtDt != null)
                                    Row(
                                      children: [
                                        if (createdBy.isNotEmpty) Text('Created by: $createdBy', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        if (createdAtDt != null) ...[
                                          if (createdBy.isNotEmpty) const SizedBox(width: 12),
                                          Tooltip(
                                            message: UiDateUtils.humanDateTime(createdAtDt),
                                            child: Text(UiDateUtils.timeAgo(createdAtDt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  if (hasUpdated)
                                    Row(
                                      children: [
                                        if (updatedBy.isNotEmpty) Text('Updated by: $updatedBy', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        if (updatedBy.isNotEmpty && updatedAtDt != null) const SizedBox(width: 12),
                                        if (updatedAtDt != null) 
                                          Tooltip(
                                            message: UiDateUtils.humanDateTime(updatedAtDt!),
                                            child: Text('Updated ${UiDateUtils.timeAgo(updatedAtDt!)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                                _buildSectionTitle('Description'),
                                const SizedBox(height: 6),
                                Text(
                                description.toString(),
                                style: const TextStyle(
                                  color: Color(0xFF626C70),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.29,
                                ),
                                ),

                              const SizedBox(height: 24),
                              Divider(color: Colors.grey[200], thickness: 1, height: 1),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(minHeight: 100),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(width: 1.0, color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(child: _buildSectionTitle('Inventory Items')),
                                        Text('(${inventory.length})', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                      ],
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
                                          final iStock = item['available_stock'] ?? item['stock'] ?? '';
                                          final iUnit = item['unit'] ?? item['uom'] ?? item['unit_of_measure'] ?? '';

                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey[200]!),
                                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
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
                                                    const SizedBox(width: 12),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[100],
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text('Qty: $iQty', style: const TextStyle(color: Color(0xFF626C70), fontSize: 12)),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'ID: $iId • Stock: $iStock • Unit: $iUnit',
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
                      // Footer
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.go(
                                  '/work/task_type/create?edit=1',
                                  extra: taskType,
                                );
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
                      ),
                    ],
                  ),
                ),
              );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> taskType) {
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
            'Task Type Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          const Spacer(),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
            tooltip: 'Close',
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
}
