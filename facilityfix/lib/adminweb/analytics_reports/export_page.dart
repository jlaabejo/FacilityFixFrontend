import 'package:facilityfix/adminweb/widgets/logout_popup.dart';
import 'package:facilityfix/adminweb/widgets/export_widgets.dart' as widgets;
import 'package:facilityfix/adminweb/analytics_reports/files/concern_slip_report.dart';
import 'package:facilityfix/adminweb/analytics_reports/files/job_service_report.dart';
import 'package:facilityfix/adminweb/services/api_service_web.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../layout/facilityfix_layout.dart';
import '../report_files/work_order_report.dart';
import 'package:printing/printing.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isExporting = false;
  bool _isLoadingDialogVisible = false;

  final ApiService _apiService = ApiService();

  // Ensures we always clean up loading UI and state before returning early
  void _finishExportEarly() {
    _hideLoadingDialog();
    if (mounted) {
      setState(() => _isExporting = false);
    } else {
      _isExporting = false;
    }
  }

  void _showLoadingDialog(String message) {
    if (!mounted || _isLoadingDialogVisible) return;

    _isLoadingDialogVisible = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.15),
      builder: (dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    if (!_isLoadingDialogVisible || !mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _isLoadingDialogVisible = false;
  }

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
      initialDate:
          isFrom ? (_fromDate ?? initialDate) : (_toDate ?? initialDate),
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
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date range to export all reports'),
        ),
      );
      return;
    }

    // Show a dialog informing the user that multiple PDFs will be generated
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Export All Reports'),
            content: const Text(
              'This will generate and export three summary reports:\n\n'
              '• Concern Slip Summary Report\n'
              '• Job Service Summary Report\n'
              '• Work Order Summary Report\n\n'
              'This may take a moment. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _executeExportAll();
                },
                child: const Text('Export'),
              ),
            ],
          ),
    );
  }

  Future<void> _executeExportAll() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    _showLoadingDialog('Exporting all reports...');

    try {
      int exportCount = 0;
      final exportResults = <String, bool>{
        'Concern Slips': false,
        'Job Services': false,
        'Work Orders': false,
      };

      // Export Concern Slips
      try {
        final allConcernSlips = await _apiService.getAllConcernSlips();
        List<Map<String, dynamic>> concernSlipsToExport = [];

        for (final slip in allConcernSlips) {
          final slipMap = slip as Map<String, dynamic>;
          final createdAtStr =
              slipMap['created_at'] ?? slipMap['date_requested'];

          if (createdAtStr != null) {
            try {
              final createdAt = DateTime.parse(createdAtStr.toString());

              bool withinRange = true;
              if (_fromDate != null && createdAt.isBefore(_fromDate!)) {
                withinRange = false;
              }
              if (_toDate != null &&
                  createdAt.isAfter(_toDate!.add(Duration(days: 1)))) {
                withinRange = false;
              }

              if (withinRange) {
                concernSlipsToExport.add(slipMap);
              }
            } catch (e) {
              concernSlipsToExport.add(slipMap);
            }
          } else {
            concernSlipsToExport.add(slipMap);
          }
        }

        if (concernSlipsToExport.isNotEmpty) {
          final user = FirebaseAuth.instance.currentUser;
          final userName = user?.displayName ?? user?.email ?? 'Admin User';

          await ConcernSlipReport.generateAndDownloadBulkPDF(
            concernSlips: concernSlipsToExport,
            userName: userName,
            location: 'Default Location',
            contactNumber: '+1-234-567-8900',
            email: 'admin@facilityfix.com',
          );

          exportResults['Concern Slips'] = true;
          exportCount++;
        }
      } catch (e) {
        print('[ERROR] Error exporting concern slips in export all: $e');
      }

      // Add a small delay between exports for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Export Job Services
      try {
        final allJobServices = await _apiService.getAllJobServices();
        List<Map<String, dynamic>> jobServicesToExport = [];

        for (final service in allJobServices) {
          final serviceMap = service as Map<String, dynamic>;
          final createdAtStr =
              serviceMap['created_at'] ?? serviceMap['date_requested'];

          if (createdAtStr != null) {
            try {
              final createdAt = DateTime.parse(createdAtStr.toString());

              bool withinRange = true;
              if (_fromDate != null && createdAt.isBefore(_fromDate!)) {
                withinRange = false;
              }
              if (_toDate != null &&
                  createdAt.isAfter(_toDate!.add(Duration(days: 1)))) {
                withinRange = false;
              }

              if (withinRange) {
                jobServicesToExport.add(serviceMap);
              }
            } catch (e) {
              jobServicesToExport.add(serviceMap);
            }
          } else {
            jobServicesToExport.add(serviceMap);
          }
        }

        if (jobServicesToExport.isNotEmpty) {
          final user = FirebaseAuth.instance.currentUser;
          final userName = user?.displayName ?? user?.email ?? 'Admin User';

          await JobServiceReport.generateAndDownloadBulkPDF(
            jobServices: jobServicesToExport,
            userName: userName,
            location: 'Default Location',
            contactNumber: '+1-234-567-8900',
            email: 'admin@facilityfix.com',
          );

          exportResults['Job Services'] = true;
          exportCount++;
        }
      } catch (e) {
        print('[ERROR] Error exporting job services in export all: $e');
      }

      // Add a small delay between exports for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Export Work Orders
      try {
        final permits = await _apiService.getAllWorkOrderPermits();

        final filteredPermits =
            permits.where((permit) {
              final createdAtStr = permit['created_at'];
              if (createdAtStr == null) return false;

              try {
                final createdAt = DateTime.parse(createdAtStr.toString());

                if (_fromDate != null && createdAt.isBefore(_fromDate!)) {
                  return false;
                }
                if (_toDate != null) {
                  final toDateEnd = DateTime(
                    _toDate!.year,
                    _toDate!.month,
                    _toDate!.day,
                    23,
                    59,
                    59,
                  );
                  if (createdAt.isAfter(toDateEnd)) {
                    return false;
                  }
                }

                return true;
              } catch (e) {
                return false;
              }
            }).toList();

        if (filteredPermits.isNotEmpty) {
          final items =
              filteredPermits.map((permit) {
                return <String, dynamic>{
                  'id': permit['formatted_id'] ?? permit['id'] ?? '',
                  'title': permit['title'] ?? 'Untitled Work Order',
                  'dateRequested': permit['created_at'],
                  'buildingUnit': permit['location'] ?? '',
                  'priority': permit['priority'] ?? 'low',
                  'category': permit['category'] ?? '',
                  'status': permit['status'] ?? 'pending',
                };
              }).toList();

          final bytes = await WorkOrderReport.generate(
            items,
            generatedBy: 'Admin User',
            generatedAt: DateTime.now(),
          );

          await Printing.sharePdf(
            bytes: bytes,
            filename: 'work_order_summary.pdf',
          );

          exportResults['Work Orders'] = true;
          exportCount++;
        }
      } catch (e) {
        print('[ERROR] Error exporting work orders in export all: $e');
      }

      // Show completion message
      if (mounted) {
        String completionMessage = '';
        if (exportCount == 0) {
          completionMessage =
              'No records found to export in the selected date range';
        } else {
          final exportedReports = exportResults.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .join(', ');
          completionMessage =
              'Successfully exported $exportCount report(s): $exportedReports';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(completionMessage),
            backgroundColor: exportCount > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Error in export all: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting all reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _hideLoadingDialog();
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportConcernSlips() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    _showLoadingDialog('Exporting concern slips...');

    try {
      // Fetch all concern slips
      final allConcernSlips = await _apiService.getAllConcernSlips();

      // Filter by date range if specified
      List<Map<String, dynamic>> concernSlipsToExport = [];

      for (final slip in allConcernSlips) {
        final slipMap = slip as Map<String, dynamic>;
        final createdAtStr = slipMap['created_at'] ?? slipMap['date_requested'];

        if (createdAtStr != null) {
          try {
            final createdAt = DateTime.parse(createdAtStr.toString());

            // Check if within date range
            bool withinRange = true;
            if (_fromDate != null && createdAt.isBefore(_fromDate!)) {
              withinRange = false;
            }
            if (_toDate != null &&
                createdAt.isAfter(_toDate!.add(Duration(days: 1)))) {
              withinRange = false;
            }

            if (withinRange) {
              concernSlipsToExport.add(slipMap);
            }
          } catch (e) {
            print('[ERROR] Error parsing date: $e');
            // If date parsing fails, include the slip
            concernSlipsToExport.add(slipMap);
          }
        } else {
          // If no date, include the slip
          concernSlipsToExport.add(slipMap);
        }
      }

      if (concernSlipsToExport.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _fromDate != null || _toDate != null
                    ? 'No concern slips found in the selected date range'
                    : 'No concern slips found',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        _finishExportEarly();
        return;
      }

      // Get current user info
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? user?.email ?? 'Admin User';

      // Export as bulk summary report (same as Repair Task page)
      await ConcernSlipReport.generateAndDownloadBulkPDF(
        concernSlips: concernSlipsToExport,
        userName: userName,
        location: 'Default Location',
        contactNumber: '+1-234-567-8900',
        email: 'admin@facilityfix.com',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Concern slips (${concernSlipsToExport.length}) exported successfully as Summary Report',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Error exporting concern slips: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting concern slips: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _hideLoadingDialog();
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportJobServices() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    _showLoadingDialog('Exporting job services...');

    try {
      // Fetch all job services
      final allJobServices = await _apiService.getAllJobServices();

      // Filter by date range if specified
      List<Map<String, dynamic>> jobServicesToExport = [];

      for (final service in allJobServices) {
        final serviceMap = service as Map<String, dynamic>;
        final createdAtStr =
            serviceMap['created_at'] ?? serviceMap['date_requested'];

        if (createdAtStr != null) {
          try {
            final createdAt = DateTime.parse(createdAtStr.toString());

            // Check if within date range
            bool withinRange = true;
            if (_fromDate != null && createdAt.isBefore(_fromDate!)) {
              withinRange = false;
            }
            if (_toDate != null &&
                createdAt.isAfter(_toDate!.add(Duration(days: 1)))) {
              withinRange = false;
            }

            if (withinRange) {
              jobServicesToExport.add(serviceMap);
            }
          } catch (e) {
            print('[ERROR] Error parsing date: $e');
            // If date parsing fails, include the service
            jobServicesToExport.add(serviceMap);
          }
        } else {
          // If no date, include the service
          jobServicesToExport.add(serviceMap);
        }
      }

      if (jobServicesToExport.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _fromDate != null || _toDate != null
                    ? 'No job services found in the selected date range'
                    : 'No job services found',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        _finishExportEarly();
        return;
      }

      // Get current user info
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? user?.email ?? 'Admin User';

      // Export as bulk summary report (same as Repair Task page)
      await JobServiceReport.generateAndDownloadBulkPDF(
        jobServices: jobServicesToExport,
        userName: userName,
        location: 'Default Location',
        contactNumber: '+1-234-567-8900',
        email: 'admin@facilityfix.com',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Job services (${jobServicesToExport.length}) exported successfully as Summary Report',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[ERROR] Error exporting job services: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting job services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _hideLoadingDialog();
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _exportOtherType(String type) {
    if (_isExporting) return;
    if (type == 'Job Services') {
      _exportJobServices();
    } else if (type == 'Work Orders') {
      _exportWorkOrders();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export: $type')));
    }
  }

  Future<void> _exportWorkOrders() async {
    if (_fromDate == null && _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date range to export work orders'),
        ),
      );
      return;
    }

    setState(() => _isExporting = true);
    _showLoadingDialog('Exporting work orders...');
    try {
      // Fetch all work order permits from the API
      final permits = await _apiService.getAllWorkOrderPermits();

      if (permits.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No work orders found')));
        }
        _finishExportEarly();
        return;
      }

      // Filter work orders by date range if provided
      final filteredPermits =
          permits.where((permit) {
            final createdAtStr = permit['created_at'];
            if (createdAtStr == null) return false;

            try {
              final createdAt = DateTime.parse(createdAtStr.toString());

              // Apply date filters
              if (_fromDate != null && createdAt.isBefore(_fromDate!)) {
                return false;
              }
              if (_toDate != null) {
                final toDateEnd = DateTime(
                  _toDate!.year,
                  _toDate!.month,
                  _toDate!.day,
                  23,
                  59,
                  59,
                );
                if (createdAt.isAfter(toDateEnd)) {
                  return false;
                }
              }

              return true;
            } catch (e) {
              return false;
            }
          }).toList();

      if (filteredPermits.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No work orders found in the selected date range'),
            ),
          );
        }
        _finishExportEarly();
        return;
      }

      // Prepare a list expected by the WorkOrderReport generator
      final items =
          filteredPermits.map((permit) {
            return <String, dynamic>{
              'id': permit['formatted_id'] ?? permit['id'] ?? '',
              'title': permit['title'] ?? 'Untitled Work Order',
              'dateRequested': permit['created_at'],
              'buildingUnit': permit['location'] ?? '',
              'priority': permit['priority'] ?? 'low',
              'category': permit['category'] ?? '',
              'status': permit['status'] ?? 'pending',
            };
          }).toList();

      // Generate the Work Order Summary Report PDF
      final bytes = await WorkOrderReport.generate(
        items,
        generatedBy: 'Admin User',
        generatedAt: DateTime.now(),
      );

      // Export the PDF using printing package
      await Printing.sharePdf(bytes: bytes, filename: 'work_order_summary.pdf');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully exported ${filteredPermits.length} work order(s)',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting work orders: $e')),
        );
      }
      print('[Export] Error exporting work orders: $e');
    } finally {
      _hideLoadingDialog();
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
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
                  // Allow wider cards by increasing the max width and reducing
                  // the inner padding subtracted from the available width.
                  final maxCardWidth = 1400.0;
                  final containerInnerPadding =
                      24.0; // reduce side subtraction to make cards wider
                  final cardWidth = math.min(
                    maxCardWidth,
                    constraints.maxWidth - containerInnerPadding,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date range filters and clear button
                      Row(
                        children: [
                          widgets.LabeledDateContainer(
                            label: 'From',
                            dateText:
                                _fromDate != null
                                    ? _formatDate(_fromDate)
                                    : null,
                            onTap: () => _selectDate(context, true),
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              size: 18,
                            ),
                            width: 240,
                          ),
                          const SizedBox(width: 8),
                          widgets.LabeledDateContainer(
                            label: 'To',
                            dateText:
                                _toDate != null ? _formatDate(_toDate) : null,
                            onTap: () => _selectDate(context, false),
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              size: 18,
                            ),
                            width: 240,
                          ),
                          const SizedBox(width: 8),
                          // Align ClearButton with the date fields (label is above date container)
                          Padding(
                            padding: const EdgeInsets.only(top: 28.0),
                            child: widgets.ClearButton(
                              onPressed: _clearDates,
                              text: 'Clear Dates',
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Export card with ExportButton and OutlinedButtons as bottom content
                      Center(
                        child: SizedBox(
                          width: cardWidth,
                          child: widgets.ExportCard(
                            title: 'Repair Tasks',
                            description:
                                'Export concern slips, job services, and work orders',
                            badges: const [
                              widgets.StatusBadge(
                                text: '125 Records',
                                dotColor: Color(0xFF005CE7),
                              ),
                              widgets.StatusBadge(
                                text: '12 Pending',
                                dotColor: Color(0xFFFF8C42),
                              ),
                            ],
                            actionButtons: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                widgets.ExportButton(
                                  onPressed: _isExporting ? null : _exportAll,
                                  text: 'Export All',
                                  icon: const Icon(
                                    Icons.file_download,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            bottomContent: Row(
                              children: [
                                widgets.OutlinedButton(
                                  onPressed:
                                      _isExporting ? null : _exportConcernSlips,
                                  text: 'Concern Slips',
                                  icon: const Icon(
                                    Icons.file_download,
                                    color: Color(0xFF005CE7),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                widgets.OutlinedButton(
                                  onPressed:
                                      _isExporting
                                          ? null
                                          : () =>
                                              _exportOtherType('Job Services'),
                                  text: 'Job Services',
                                  icon: const Icon(
                                    Icons.file_download,
                                    color: Color(0xFF005CE7),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                widgets.OutlinedButton(
                                  onPressed:
                                      _isExporting
                                          ? null
                                          : () =>
                                              _exportOtherType('Work Orders'),
                                  text: 'Work Orders',
                                  icon: const Icon(
                                    Icons.file_download,
                                    color: Color(0xFF005CE7),
                                  ),
                                ),
                              ],
                            ),
                            width: cardWidth,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Second container: Maintenance, Inventory, Users
                      Container(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: SizedBox(
                                width: cardWidth,
                                child: widgets.ExportCard(
                                  title: 'Maintenance Tasks',
                                  description:
                                      'Export maintenance tasks (internal / external)',
                                  badges: const [
                                    widgets.StatusBadge(
                                      text: '78 Records',
                                      dotColor: Color(0xFF005CE7),
                                    ),
                                    widgets.StatusBadge(
                                      text: '15 Pending',
                                      dotColor: Color(0xFFFF8C42),
                                    ),
                                  ],
                                  actionButtons: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      widgets.ExportButton(
                                        onPressed:
                                            _isExporting ? null : _exportAll,
                                        text: 'Export All',
                                        icon: const Icon(
                                          Icons.file_download,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  bottomContent: Row(
                                    children: [
                                      widgets.OutlinedButton(
                                        onPressed:
                                            _isExporting
                                                ? null
                                                : () => _exportOtherType(
                                                  'Maintenance - Internal',
                                                ),
                                        text: 'Internal',
                                        icon: const Icon(
                                          Icons.file_download,
                                          color: Color(0xFF005CE7),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      widgets.OutlinedButton(
                                        onPressed:
                                            _isExporting
                                                ? null
                                                : () => _exportOtherType(
                                                  'Maintenance - External',
                                                ),
                                        text: 'External',
                                        icon: const Icon(
                                          Icons.file_download,
                                          color: Color(0xFF005CE7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  width: cardWidth,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: SizedBox(
                                width: cardWidth,
                                child: widgets.ExportCard(
                                  title: 'Inventory Items',
                                  description: 'Export equipment and items',
                                  badges: const [
                                    widgets.StatusBadge(
                                      text: '248 Records',
                                      dotColor: Color(0xFF005CE7),
                                    ),
                                    widgets.StatusBadge(
                                      text: '3 Pending',
                                      dotColor: Color(0xFFFF8C42),
                                    ),
                                  ],
                                  actionButtons: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      widgets.ExportButton(
                                        onPressed:
                                            _isExporting ? null : _exportAll,
                                        text: 'Export All',
                                        icon: const Icon(
                                          Icons.file_download,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  bottomContent: Wrap(
                                    spacing: 12,
                                    children: [
                                      widgets.OutlinedButton(
                                        onPressed:
                                            _isExporting
                                                ? null
                                                : () => _exportOtherType(
                                                  'Inventory - Equipment',
                                                ),
                                        text: 'Equipment',
                                        icon: const Icon(
                                          Icons.file_download,
                                          color: Color(0xFF005CE7),
                                        ),
                                      ),
                                      widgets.OutlinedButton(
                                        onPressed:
                                            _isExporting
                                                ? null
                                                : () => _exportOtherType(
                                                  'Inventory - Items',
                                                ),
                                        text: 'Items',
                                        icon: const Icon(
                                          Icons.file_download,
                                          color: Color(0xFF005CE7),
                                        ),
                                      ),
                                      widgets.OutlinedButton(
                                        onPressed:
                                            _isExporting
                                                ? null
                                                : () => _exportOtherType(
                                                  'Inventory - Requests',
                                                ),
                                        text: 'Requests',
                                        icon: const Icon(
                                          Icons.file_download,
                                          color: Color(0xFF005CE7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  width: cardWidth,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: SizedBox(
                                width: cardWidth,
                                child: widgets.ExportCard(
                                  title: 'Users',
                                  description:
                                      'Export user lists (Tenant / Staff)',
                                  badges: const [
                                    widgets.StatusBadge(
                                      text: '345 Records',
                                      dotColor: Color(0xFF005CE7),
                                    ),
                                    widgets.StatusBadge(
                                      text: '5 Pending',
                                      dotColor: Color(0xFFFF8C42),
                                    ),
                                  ],
                                  actionButtons: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      widgets.ExportButton(
                                        onPressed:
                                            _isExporting ? null : _exportAll,
                                        text: 'Export All',
                                        icon: const Icon(
                                          Icons.file_download,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  bottomContent: Row(
                                    children: [
                                      widgets.OutlinedButton(
                                        onPressed:
                                            _isExporting
                                                ? null
                                                : () => _exportOtherType(
                                                  'Users - Tenant',
                                                ),
                                        text: 'Tenant',
                                        icon: const Icon(
                                          Icons.file_download,
                                          color: Color(0xFF005CE7),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      widgets.OutlinedButton(
                                        onPressed:
                                            _isExporting
                                                ? null
                                                : () => _exportOtherType(
                                                  'Users - Staff',
                                                ),
                                        text: 'Staff',
                                        icon: const Icon(
                                          Icons.file_download,
                                          color: Color(0xFF005CE7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  width: cardWidth,
                                ),
                              ),
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
        ),
      ),
    );
  }
}
