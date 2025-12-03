import 'package:facilityfix/adminweb/widgets/logout_popup.dart';
import 'package:facilityfix/adminweb/widgets/export_widgets.dart' as widgets;
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  void _handleLogout(BuildContext context) async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const LogoutPopup();
      },
    );

    if (result == true && mounted) {
      context.go('/');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    // Format as YYYY-MM-DD
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final initialDate = DateTime.now();
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_fromDate ?? initialDate) : (_toDate ?? initialDate),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _clearDates() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  void _exportAll() {
    // TODO: implement export logic here (placeholder)
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export All clicked')));
  }

  void _exportType(String type) {
    // TODO: implement export for a specific type
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export: $type')));
  }

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'export',
      onNavigate: (routeKey) {
        if (routeKey == 'logout') {
          _handleLogout(context);
        } else {
          final routes = {
            'dashboard': '/dashboard',
            'user_users': '/user/users',
            'user_scheduling': '/user/scheduling',
            'work_maintenance': '/work/maintenance',
            'work_task_type': '/work/task_type',
            'work_repair': '/work/repair',
            'calendar': '/calendar',
            'inventory_equipment': '/inventory/equipment',
            'inventory_items': '/inventory/items',
            'inventory_request': '/inventory/request',
            'analytics': '/analytics',
            'announcement': '/announcement',
            'settings': '/settings',
          };
          final route = routes[routeKey];
          if (route != null) {
            context.go(route);
          }
        }
      },
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Export Page",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
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
                  onPressed: null,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Export'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Container with 24px padding on each side (additional inner container)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxCardWidth = 1074.98;
                  final containerInnerPadding = 48.0; // 24 left + 24 right used above
                  final cardWidth = math.min(maxCardWidth, constraints.maxWidth - containerInnerPadding);
                  final cardHeight = constraints.maxWidth > 1100 ? 200.59 : 160.0;
                  return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range filters and clear button
                  Row(
                    children: [
                      widgets.LabeledDateContainer(
                        label: 'From',
                        dateText: _fromDate != null ? _formatDate(_fromDate) : null,
                        onTap: () => _selectDate(context, true),
                        prefixIcon: const Icon(Icons.calendar_today, size: 18),
                        width: 240,
                      ),
                      const SizedBox(width: 8),
                      widgets.LabeledDateContainer(
                        label: 'To',
                        dateText: _toDate != null ? _formatDate(_toDate) : null,
                        onTap: () => _selectDate(context, false),
                        prefixIcon: const Icon(Icons.calendar_today, size: 18),
                        width: 240,
                      ),
                      const SizedBox(width: 8),
                      widgets.ClearButton(
                        onPressed: _clearDates,
                        text: 'Clear Dates',
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Export card with ExportButton and OutlinedButtons as bottom content
                  widgets.ExportCard(
                    title: 'Repair Tasks',
                    description: 'Export concern slips, job services, and work orders',
                    badges: const [
                      widgets.StatusBadge(text: '125 Records', dotColor: Color(0xFF005CE7)),
                      widgets.StatusBadge(text: '12 Pending', dotColor: Color(0xFFFF8C42)),
                    ],
                    actionButtons: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        widgets.ExportButton(
                          onPressed: _exportAll,
                          text: 'Export All',
                          icon: const Icon(Icons.file_download, color: Colors.white),
                        ),
                      ],
                    ),
                    bottomContent: Row(
                      children: [
                        widgets.OutlinedButton(
                          onPressed: () => _exportType('Concern Slips'),
                          text: 'Concern Slips',
                          icon: const Icon(Icons.file_download, color: Color(0xFF005CE7)),
                        ),
                        const SizedBox(width: 12),
                        widgets.OutlinedButton(
                          onPressed: () => _exportType('Job Services'),
                          text: 'Job Services',
                          icon: const Icon(Icons.file_download, color: Color(0xFF005CE7)),
                        ),
                        const SizedBox(width: 12),
                        widgets.OutlinedButton(
                          onPressed: () => _exportType('Work Orders'),
                          text: 'Work Orders',
                          icon: const Icon(Icons.file_download, color: Color(0xFF005CE7)),
                        ),
                      ],
                    ),
                    width: double.infinity,
                    height: 180,
                  ),
                  const SizedBox(height: 24),
                  // Second container: Maintenance, Inventory, Users
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        widgets.ExportCard(
                          title: 'Maintenance Tasks',
                          description: 'Export maintenance tasks (internal / external)',
                          badges: const [
                            widgets.StatusBadge(text: '78 Records', dotColor: Color(0xFF005CE7)),
                            widgets.StatusBadge(text: '15 Pending', dotColor: Color(0xFFFF8C42)),
                          ],
                          actionButtons: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              widgets.ExportButton(
                                onPressed: () => _exportAll(),
                                text: 'Export All',
                                icon: const Icon(Icons.file_download, color: Colors.white),
                              ),
                            ],
                          ),
                          bottomContent: Row(
                            children: [
                              widgets.OutlinedButton(
                                onPressed: () => _exportType('Maintenance - Internal'),
                                text: 'Internal',
                                icon: const Icon(Icons.file_download, color: Color(0xFF005CE7)),
                              ),
                              const SizedBox(width: 12),
                              widgets.OutlinedButton(
                                onPressed: () => _exportType('Maintenance - External'),
                                text: 'External',
                                icon: const Icon(Icons.file_download, color: Color(0xFF005CE7)),
                              ),
                            ],
                          ),
                          width: cardWidth,
                          height: cardHeight,
                        ),
                        const SizedBox(height: 16),
                        widgets.ExportCard(
                          title: 'Inventory Items',
                          description: 'Export equipment and items',
                          badges: const [
                            widgets.StatusBadge(text: '248 Records', dotColor: Color(0xFF005CE7)),
                            widgets.StatusBadge(text: '3 Pending', dotColor: Color(0xFFFF8C42)),
                          ],
                          actionButtons: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              widgets.ExportButton(
                                onPressed: () => _exportAll(),
                                text: 'Export All',
                                icon: const Icon(Icons.file_download, color: Colors.white),
                              ),
                            ],
                          ),
                          bottomContent: Wrap(
                            spacing: 12,
                            children: [
                              widgets.OutlinedButton(
                                onPressed: () => _exportType('Inventory - Equipment'),
                                text: 'Equipment',
                                icon: const Icon(Icons.file_download, color: Color(0xFF005CE7)),
                              ),
                              widgets.OutlinedButton(
                                onPressed: () => _exportType('Inventory - Items'),
                                text: 'Items',
                                icon: const Icon(Icons.file_download, color: Color(0xFF005CE7)),
                              ),
                              widgets.OutlinedButton(
                                onPressed: () => _exportType('Inventory - Requests'),
                                text: 'Requests',
                                icon: const Icon(Icons.file_download, color: Color(0xFF005CE7)),
                              ),
                            ],
                          ),
                          width: cardWidth,
                          height: cardHeight,
                        ),
                        const SizedBox(height: 16),
                        widgets.ExportCard(
                          title: 'Users',
                          description: 'Export user lists (Tenant / Staff)',
                          badges: const [
                            widgets.StatusBadge(text: '345 Records', dotColor: Color(0xFF005CE7)),
                            widgets.StatusBadge(text: '5 Pending', dotColor: Color(0xFFFF8C42)),
                          ],
                          actionButtons: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              widgets.ExportButton(
                                onPressed: () => _exportAll(),
                                text: 'Export All',
                                icon: const Icon(Icons.file_download, color: Colors.white),
                              ),
                            ],
                          ),
                          bottomContent: Row(
                            children: [
                              widgets.OutlinedButton(
                                onPressed: () => _exportType('Users - Tenant'),
                                text: 'Tenant',
                                icon: const Icon(Icons.file_download, color: Color(0xFF005CE7)),
                              ),
                              const SizedBox(width: 12),
                              widgets.OutlinedButton(
                                onPressed: () => _exportType('Users - Staff'),
                                text: 'Staff',
                                icon: const Icon(Icons.file_download, color: Color(0xFF005CE7)),
                              ),
                            ],
                          ),
                          width: cardWidth,
                          height: cardHeight,
                            ),
                         ],
                      ),
                     ),
                   ],
                  );  
                },
              ),
            ),
          ],
        )
      ),
    );
  }
}
