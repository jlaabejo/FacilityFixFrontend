import 'package:facilityfix/adminweb/widgets/tags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:facilityfix/utils/ui_format.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/adminweb/widgets/pop_up_dialog.dart';
import 'package:facilityfix/adminweb/services/api_service.dart' as AdminApi;

class WorkOrderConcernSlipDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onAssignmentComplete;

  const WorkOrderConcernSlipDialog({
    super.key,
    required this.task,
    this.onAssignmentComplete,
  });

  @override
  State<WorkOrderConcernSlipDialog> createState() => _WorkOrderConcernSlipDialogState();

  static void show(
    BuildContext context, 
    Map<String, dynamic> task, {
    VoidCallback? onAssignmentComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WorkOrderConcernSlipDialog(
          task: task,
          onAssignmentComplete: onAssignmentComplete,
        );
      },
    );
  }
}

class _WorkOrderConcernSlipDialogState extends State<WorkOrderConcernSlipDialog> {
  int _currentStep = 1; // 0 = CS Details, 1 = WOP Details (open on WOP details by default)
  bool _isProcessing = false;
  String? selectedStaffName;
  DateTime? selectedDate;
  final APIService _apiService = APIService();
  Map<String, dynamic>? _taskData;

  Map<String, dynamic> get task => _taskData ?? widget.task;

  // Helper to check status
  bool get _isPendingStatus {
    final status = task['status']?.toString().toLowerCase() ?? '';
    return status == 'pending' || status == 'pending review';
  }
  
  bool get _isInProgressStatus {
    final status = task['status']?.toString().toLowerCase() ?? '';
    return status == 'in progress' || status == 'inprogress';
  }
  
  bool get _isAcceptedStatus {
    final status = task['status']?.toString().toLowerCase() ?? '';
    return status == 'accepted';
  }
  
  bool get _isCompletedStatus {
    final status = task['status']?.toString().toLowerCase() ?? '';
    return status == 'completed';
  }
  
  // Check if we should show WOP details
  bool get _shouldShowWOPDetails {
    return _isPendingStatus || _isInProgressStatus || _isAcceptedStatus || _isCompletedStatus;
  }

  @override
  void initState() {
    super.initState();
    // Local copy of task so we can attach fetched rawData without mutating the incoming map
    _taskData = Map<String, dynamic>.from(widget.task);
    // Ensure concern slip raw data is available for the CS details view
    _loadConcernSlipDetails();
  }

  /// Fetch concern slip details if the dialog was opened with only a job/work/order reference
  /// and attach them to `widget.task['rawData']` so the CS details view can render.
  Future<void> _loadConcernSlipDetails() async {
    try {
      // Try common keys for concern slip id
  dynamic csId = task['concern_slip_id'] ?? task['concernSlipId'] ?? task['cs_id'] ?? task['csId'] ?? task['rawData']?['concern_slip_id'];
      if (csId == null) return;

      final id = csId.toString();
      final cs = await _apiService.getConcernSlipById(id);
      if (cs != null) {
        try {
          // attach to local task copy
          _taskData ??= Map<String, dynamic>.from(widget.task);
          _taskData?['rawData'] = cs;
          // Initialize schedule and populate assigned staff display similar to ConcernSlipDetailDialog
          try {
            _initializeScheduleDate();
          } catch (_) {}
          try {
            _populateAssignedStaffName();
          } catch (_) {}
          if (mounted) setState(() {});
        } catch (_) {
          print('[WOPDialog] Warning: could not set rawData on _taskData');
        }
      }
    } catch (e) {
      print('[WOPDialog] Error loading concern slip details: $e');
    }
  }

  void _populateAssignedStaffName() {
    try {
      final data = task;
      dynamic assigned = data['rawData']?['assigned_staff'] ??
          data['rawData']?['assigned_to'] ?? data['assigned_staff'] ?? data['assigned_to'] ?? data['assigned_staff_name'];

      if (assigned == null) return;

      if (assigned is String) {
        final s = assigned.trim();
        final looksLikeId = RegExp(r'^[0-9]+$').hasMatch(s) || s.contains('_');
        if (!looksLikeId) {
          selectedStaffName = s;
          return;
        }
        selectedStaffName = s;
        return;
      }

      if (assigned is Map<String, dynamic>) {
        final name = assigned['name'] ?? assigned['full_name'] ?? ((assigned['first_name'] ?? '') + ' ' + (assigned['last_name'] ?? '')).trim();
        if (name != null && name.toString().isNotEmpty) selectedStaffName = name.toString();
        return;
      }

      selectedStaffName = assigned.toString();
    } catch (e) {
      print('[WOPDialog] _populateAssignedStaffName error: $e');
    }
  }

    void _initializeScheduleDate() {
    // Auto-populate inspection schedule from schedule availability
    final scheduleAvailability =
        widget.task['dateRequested'] ??
        widget.task['rawData']?['schedule_availability'];
    if (scheduleAvailability != null && scheduleAvailability.isNotEmpty) {
      try {
        // Try to parse the date string (with or without time)
        if (scheduleAvailability.toString().contains('T')) {
          // ISO format with time
          selectedDate = DateTime.parse(scheduleAvailability.toString());
        } else {
          // Date only format
          final parts = scheduleAvailability.toString().split('-');
          if (parts.length == 3) {
            selectedDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
              9, // Default to 9 AM if no time provided
              0,
            );
          }
        }
      } catch (e) {
        print('[ConcernSlipDetail] Error parsing schedule date: $e');
      }
    }
  }

  Widget build(BuildContext context) {
    return Dialog(
          backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 500),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: _currentStep == 0 
                    ? _buildConcernSlipDetails()
                    : _buildWorkOrderDetails(),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    String title;
    switch (_currentStep) {
      case 0:
        title = 'Concern Slip Details';
        break;
      case 1:
        title = 'Work Order Details';
        break;
      default:
        title = 'Work Order';
    }
    
    return Container(
      padding: const EdgeInsets.only(left: 32, right: 24, top: 20, bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final bool showBack = (_currentStep > 0 && _currentStep != 1); // hide Back on step 1 (Work Order Details)

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (showBack)
            OutlinedButton(
              onPressed: _isProcessing
                  ? null
                  : () {
                      setState(() {
                        _currentStep--;
                      });
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Back'),
            ),

          const Spacer(), // ensure action buttons are grouped on the right

          // Show Next button on step 0 if status requires WOP details view
          if (_currentStep == 0 && _shouldShowWOPDetails)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                });
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                elevation: 0,
              ),
            ),

          // Show Reject/Accept buttons on step 1 only if status is pending
          if (_currentStep == 1 && _isPendingStatus) ...[
            OutlinedButton(
              onPressed: _isProcessing ? null : () => _handleReject(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[700],
                side: BorderSide(color: Colors.red[300]!),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              child: const Text('Reject'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isProcessing ? null : () => _handleAccept(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Accept'),
            ),
          ],
        ],
      ),
    );
  }

  // Step 0: Concern Slip Details
  Widget _buildConcernSlipDetails() {
    // Title, IDs, and meta info
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.task['id'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    // Format date as: "Aug 23, 2025"
                    'Date Requested: ${(() {
                      final ds = widget.task['dateRequested'] ?? widget.task['rawData']?['schedule_availability'];
                      if (ds == null) return 'N/A';
                      try {
                        DateTime date;
                        final s = ds.toString();
                        if (s.contains('T')) {
                          date = DateTime.parse(s);
                        } else {
                          final parts = s.split('-');
                          if (parts.length == 3) {
                            date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                          } else {
                            return s;
                          }
                        }
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                        return '${months[date.month - 1]} ${date.day}, ${date.year}';
                      } catch (_) {
                        return ds.toString();
                      }
                    })()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: Colors.grey[200], thickness: 1, height: 1),
        const SizedBox(height: 24),
        // Requester Details
        _buildSectionTitle('Requester Details'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'REQUESTED BY',
                widget.task['rawData']?['reported_by'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDetailItem(
                'DEPARTMENT',
                widget.task['department'] ?? 'N/A',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'BLDG & UNIT NO.',
                _formatBuildingUnit(widget.task['buildingUnit'] ?? 'N/A'),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: InkWell(
                child: _buildDetailItem(
                  _isCompletedStatus
                      ? 'DATE COMPLETED'
                      : 'SCHEDULE AVAILABILITY',
                  _isCompletedStatus
                      ? (() {
                        final dateVal =
                            widget.task['dateCompleted'] ??
                            widget.task['rawData']?['date_completed'] ??
                            widget.task['completed_at'] ??
                            widget.task['rawData']?['completedAt'];
                        if (dateVal == null) return 'N/A';
                        try {
                          final d =
                              dateVal is DateTime
                                  ? dateVal
                                  : DateTime.parse(dateVal.toString());
                          return UiDateUtils.fullDate(d);
                        } catch (_) {
                          return dateVal.toString();
                        }
                      })()
                      : (selectedDate != null
                          ? UiDateUtils.dateTimeRange(selectedDate!)
                          : _formatScheduleDate(
                            widget.task['dateRequested'] ??
                                widget
                                    .task['rawData']?['schedule_availability'],
                          )),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: Colors.grey[200], thickness: 1, height: 1),
        const SizedBox(height: 24),
        // Work Description
        _buildSectionTitle('Work Description'),
        const SizedBox(height: 16),
        Text(
          widget.task['description'] ?? 'No description available.',
          style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey[700]),
        ),
      ],
    );
  }

    String _formatBuildingUnit(String buildingUnit) {
    // Convert "Bldg A - Unit 302" to "A - 1010" format
    if (buildingUnit.contains('Unit')) {
      final parts = buildingUnit.split(' - Unit ');
      if (parts.length == 2) {
        final building = parts[0].replaceAll('Bldg ', '');
        return '$building - 1010';
      }
    }
    return buildingUnit;
  }

    String _formatScheduleDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final s = dateString.trim();
      if (s.contains(' - ')) {
        final parts = s.split(' - ');
        final left = parts[0].trim();
        final right = parts[1].trim();
        DateTime? start;
        DateTime? end;

        // Parse start
        try {
          start = DateTime.parse(left);
        } catch (_) {
          try {
            start = DateFormat('MMM d, yyyy h:mm a').parse(left);
          } catch (_) {
            try {
              final d = DateFormat('MMM d, yyyy').parse(left);
              start = DateTime(d.year, d.month, d.day, 9, 0);
            } catch (_) {}
          }
        }

        // Parse end (may be time-only)
        try {
          final t = DateFormat('h:mm a').parse(right);
          if (start != null)
            end = DateTime(
              start.year,
              start.month,
              start.day,
              t.hour,
              t.minute,
            );
        } catch (_) {
          try {
            end = DateTime.parse(right);
          } catch (_) {
            try {
              end = DateFormat('MMM d, yyyy h:mm a').parse(right);
            } catch (_) {}
          }
        }

        if (start != null && end != null)
          return UiDateUtils.dateTimeRange(start, end);
        return s;
      }

      if (s.contains('T')) {
        final d = DateTime.parse(s);
        return UiDateUtils.dateTimeRange(d);
      }

      if (RegExp(r'^\d{4}-\d{2}-\d{2}\$').hasMatch(s)) {
        final parts = s.split('-');
        final d = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        return UiDateUtils.fullDate(d);
      }

      // Try to parse generic tenant formats
      try {
        final d = DateFormat('MMM d, yyyy h:mm a').parse(s);
        return UiDateUtils.dateTimeRange(d);
      } catch (_) {}

      return s;
    } catch (e) {
      print('[WorkOrderDialog] Error formatting schedule: $e');
    }
    return dateString;
  }

  // Step 1: Work Order Details
  Widget _buildWorkOrderDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Work Order Title
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Work Order',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task['serviceId'] ?? task['id'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),   
                  Text(
                  // Format date as: "Aug 23, 2025"
                  'Date Requested: ${(() {
                    final ds = task['dateRequested'] ?? task['rawData']?['schedule_availability'];
                    if (ds == null) return 'N/A';
                    try {
                    DateTime date;
                    final s = ds.toString();
                    if (s.contains('T')) {
                      date = DateTime.parse(s);
                    } else {
                      final parts = s.split('-');
                      if (parts.length == 3) {
                      date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                      } else {
                      return s;
                      }
                    }
                    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                    return '${months[date.month - 1]} ${date.day}, ${date.year}';
                    } catch (_) {
                    return ds.toString();
                    }
                  })()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                  ),
                  const SizedBox(height: 8),
                  // Small action to view the originating concern slip
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentStep = 0; // show concern slip details
                        });
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Concern Slip'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            PriorityTag(task['priority'] ?? ''),
            const SizedBox(width: 8),
            StatusTag(task['status'] ?? ''),
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: Colors.grey[200], thickness: 1, height: 1),
        const SizedBox(height: 24),
        
                // Permit Validation
        _buildSectionTitle('Permit Validation'),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'SCHEDULED DATE',
                _formatScheduledDateRange(
                  task['scheduledDate'] ?? task['rawData']?['scheduled_date'],
                  task['scheduledTime'] ?? task['rawData']?['scheduled_time'],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Contractor/Personnel Information
        _buildSectionTitle('Contractor/Personnel Information'),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'CONTRACTOR/ COMPANY NAME',
                task['contractorName'] ?? task['rawData']?['contractor_name'] ?? 'Juan Dela Cruz',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDetailItem(
                'CONTACT NUMBER',
                task['contactNumber'] ?? task['rawData']?['contact_number'] ?? '+63 917 123 4567',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        _buildDetailItem(
          'EMAIL ADDRESS',
          task['emailAddress'] ?? task['rawData']?['email_address'] ?? 'juan.delacruz@example.com',
        ),
        const SizedBox(height: 24),

        // Show return notes if present (persisted after a deny/return action)
        if ((_taskData?['return_notes'] ?? task['return_notes'] ?? task['rawData']?['return_notes']) != null &&
            (_taskData?['return_notes'] ?? task['return_notes'] ?? task['rawData']?['return_notes']).toString().trim().isNotEmpty) ...[
          _buildSectionTitle('Return Notes'),
          const SizedBox(height: 8),
          Text(
            (_taskData?['return_notes'] ?? task['return_notes'] ?? task['rawData']?['return_notes']).toString(),
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 24),
        ],

        Divider(color: Colors.grey[200], thickness: 1, height: 1),
        const SizedBox(height: 24),
        
        // Specific Instructions
        _buildSectionTitle('Additional Notes'),
        const SizedBox(height: 16),
        Text(
          task['additionalNotes'] ?? task['rawData']?['additional_notes'] ?? '',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 24),
        
        Divider(color: Colors.grey[200], thickness: 1, height: 1),
        const SizedBox(height: 24),
        
        // Show validation note only if status is pending
        if (_isPendingStatus) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Review the work order details carefully before accepting or rejecting the permit.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber[900],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Accept button handler
  Future<void> _handleAccept(BuildContext context) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      final adminApi = AdminApi.ApiService();

      // Determine permit id from common keys
      final permitId = task['permitId'] ?? task['id'] ?? task['serviceId'] ?? task['workOrderId'];
      if (permitId == null) throw Exception('Could not determine permit id for approval');

      final resp = await adminApi.approveWorkOrderPermit(permitId.toString());

      _taskData ??= Map<String, dynamic>.from(widget.task);
      _taskData?['status'] = resp['status'] ?? 'approved';
      _taskData?['approval_notes'] = resp['approval_notes'] ?? '';
      _taskData?['rawResponse'] = resp;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Work order permit accepted successfully'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
      widget.onAssignmentComplete?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting work order: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Reject button handler
  Future<void> _handleReject(BuildContext context) async {
    // Ask for rejection notes and mark as returned to tenant
    final TextEditingController _reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Return Work Order to Tenant'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide notes for returning this work order to the tenant.'),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                minLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter notes (required)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter notes explaining the return to tenant.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Return'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final reason = _reasonController.text.trim();

      final adminApi = AdminApi.ApiService();
      final permitId = task['permitId'] ?? task['id'] ?? task['serviceId'] ?? task['workOrderId'];
      if (permitId == null) throw Exception('Could not determine permit id');

      final resp = await adminApi.rejectWorkOrderPermit(permitId.toString(), reason);

      _taskData ??= Map<String, dynamic>.from(widget.task);
      _taskData?['status'] = resp['status'] ?? 'returned_to_tenant';
      _taskData?['return_notes'] = reason;
      _taskData?['rawResponse'] = resp;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Work order permit returned to tenant'),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
      widget.onAssignmentComplete?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error returning work order: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }


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

  Widget _buildAssessmentSection() {
    // Use assessment and recommendation from rawData
    final assessment = task['rawData']?['staff_assessment'];
    final recommendation = task['rawData']?['staff_recommendation'];
    final resolutionType = task['rawData']?['resolution_type'];

    if (assessment == null && recommendation == null && resolutionType == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Assessment and Resolution Details'),
        const SizedBox(height: 16),
        // Use the shared assigned staff display
        _buildAutoAssignedStaffDisplay(),
        const SizedBox(height: 24),
        if (resolutionType != null) ...[
          Text(
            'RESOLUTION TYPE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          RequestTypeTag(
            resolutionType.toString().replaceAll('_', ' '),
          ),
          const SizedBox(height: 24),
        ],
        if (assessment != null) ...[
          Text(
            'ASSESSMENT',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              assessment,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
        if (recommendation != null) ...[
          const SizedBox(height: 24),
          Text(
            'RECOMMENDATION',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Text(
              recommendation,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAutoAssignedStaffDisplay() {
    // Use assigned staff or fallback to selectedStaffName
    String staffName = selectedStaffName ?? '';
    if (staffName.isEmpty) {
      final data = task;
      dynamic assignedStaff = data['rawData']?['assigned_staff'] ??
          data['rawData']?['assigned_to'] ??
          data['assigned_staff'] ??
          data['assigned_to'] ??
          data['assigned_staff_name'];

      if (assignedStaff != null) {
        if (assignedStaff is String) {
          staffName = assignedStaff;
        } else if (assignedStaff is Map<String, dynamic>) {
          staffName = assignedStaff['name'] ??
              assignedStaff['full_name'] ??
              ((assignedStaff['first_name'] ?? '') + ' ' + (assignedStaff['last_name'] ?? '')).trim();
        } else {
          staffName = assignedStaff.toString();
        }
      }
    }
    if (staffName.isEmpty) staffName = 'Staff Member';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ASSIGNED STAFF',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              _buildSimpleAvatar(staffName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staffName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task['department'] ?? 'No Department',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Helper method to build avatar (similar to ConcernSlipDetailDialog)
  Widget _buildSimpleAvatar(String name, {double size = 32}) {
    // Get initials from name
    final parts = name.trim().split(' ');
    String initials = '';
    if (parts.isNotEmpty) {
      initials = parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
      if (parts.length > 1 && parts.last.isNotEmpty) {
        initials += parts.last[0].toUpperCase();
      }
    }
    if (initials.isEmpty) initials = '?';
    
    // Generate color from name
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final colors = [
      Colors.blue[700]!,
      Colors.green[700]!,
      Colors.orange[700]!,
      Colors.purple[700]!,
      Colors.teal[700]!,
      Colors.pink[700]!,
    ];
    final color = colors[hash.abs() % colors.length];
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        if (value.isNotEmpty)
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
      ],
    );
  }

  /// Helper: format separate scheduled date and time fields into displayable strings.
  /// Returns a map with keys 'date' and 'time'.
  Map<String, String> _formatScheduledDateAndTime(dynamic dateField, dynamic timeField) {
    String dateOut = 'N/A';
    String timeOut = 'N/A';

    try {
      final dateStr = dateField?.toString() ?? '';
      final timeStr = timeField?.toString() ?? '';

      DateTime? datePart;
      if (dateStr.isNotEmpty) {
        if (dateStr.contains('T')) {
          datePart = DateTime.parse(dateStr);
        } else if (RegExp(r'^\d{4}-\d{2}-\d{2}?').hasMatch(dateStr) || RegExp(r'^\d{4}-\d{2}-\d{2}\$').hasMatch(dateStr)) {
          final p = dateStr.split('-');
          if (p.length >= 3) datePart = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        } else {
          try {
            datePart = DateFormat('MMM d, yyyy').parse(dateStr);
          } catch (_) {}
        }
      }

      if (datePart != null) dateOut = UiDateUtils.fullDate(datePart);

      if (timeStr.isNotEmpty) {
        // time might be a range
        if (timeStr.contains('-')) {
          final parts = timeStr.split('-');
          final left = parts[0].trim();
          final right = parts[1].trim();
          try {
            final t1 = DateFormat('h:mm a').parse(left);
            final t2 = DateFormat('h:mm a').parse(right);
            if (datePart != null) {
              final start = DateTime(datePart.year, datePart.month, datePart.day, t1.hour, t1.minute);
              final end = DateTime(datePart.year, datePart.month, datePart.day, t2.hour, t2.minute);
              timeOut = '${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}';
            } else {
              timeOut = '$left - $right';
            }
          } catch (_) {
            timeOut = timeStr;
          }
        } else {
          timeOut = timeStr;
        }
      }
    } catch (e) {
      print('[WOPDialog] Error formatting scheduled date/time: $e');
    }

    return {'date': dateOut, 'time': timeOut};
  }
}

/// Helper to format scheduled date (and optional time) into a date-range string
String _formatScheduledDateRange(dynamic dateField, dynamic timeField) {
  final dateStr = dateField?.toString() ?? '';
  final timeStr = timeField?.toString() ?? '';

  if (dateStr.isEmpty) return 'N/A';

  // If date is a range like '2025-08-10 - 2025-08-12' or 'Aug 10, 2025 - Aug 12, 2025'
  if (dateStr.contains(' - ')) {
    final parts = dateStr.split(' - ');
    DateTime? start;
    DateTime? end;
    try {
      start = DateTime.parse(parts[0].trim());
    } catch (_) {
      try {
        start = DateFormat('MMM d, yyyy').parse(parts[0].trim());
      } catch (_) {}
    }
    try {
      end = DateTime.parse(parts[1].trim());
    } catch (_) {
      try {
        end = DateFormat('MMM d, yyyy').parse(parts[1].trim());
      } catch (_) {}
    }
    if (start != null && end != null) return UiDateUtils.formatDateRange(start, end);
  }

  // Single date: parse and return fullDate
  try {
    DateTime d;
    if (dateStr.contains('T')) {
      d = DateTime.parse(dateStr);
    } else if (RegExp(r'^\d{4}-\d{2}-\d{2}\$').hasMatch(dateStr)) {
      final p = dateStr.split('-');
      d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    } else {
      d = DateFormat('MMM d, yyyy').parse(dateStr);
    }

    // If there's an associated time range, try to present a dateTimeRange
    if (timeStr.isNotEmpty && timeStr.contains('-')) {
      final tparts = timeStr.split('-');
      try {
        final t1 = DateFormat('h:mm a').parse(tparts[0].trim());
        final t2 = DateFormat('h:mm a').parse(tparts[1].trim());
        final start = DateTime(d.year, d.month, d.day, t1.hour, t1.minute);
        final end = DateTime(d.year, d.month, d.day, t2.hour, t2.minute);
        return UiDateUtils.dateTimeRange(start, end);
      } catch (_) {
        return UiDateUtils.fullDate(d);
      }
    }

    return UiDateUtils.fullDate(d);
  } catch (e) {
    // Fallback to raw string
    return dateStr.toString();
  }
}

/// Format arbitrary schedule strings into a friendly representation using UiDateUtils when possible.
String _formatScheduleString(String? raw) {
  if (raw == null || raw.isEmpty) return 'N/A';
  final s = raw.trim();
  try {
    if (s.contains(' - ')) {
      final parts = s.split(' - ');
      final left = parts[0].trim();
      final right = parts[1].trim();

      DateTime? start;
      DateTime? end;
      try {
        start = DateTime.parse(left);
      } catch (_) {
        try {
          start = DateFormat('MMM d, yyyy h:mm a').parse(left);
        } catch (_) {
          try {
            final d = DateFormat('MMM d, yyyy').parse(left);
            start = DateTime(d.year, d.month, d.day, 9, 0);
          } catch (_) {}
        }
      }

      try {
        final t = DateFormat('h:mm a').parse(right);
        if (start != null) end = DateTime(start.year, start.month, start.day, t.hour, t.minute);
      } catch (_) {
        try {
          end = DateTime.parse(right);
        } catch (_) {
          try {
            end = DateFormat('MMM d, yyyy h:mm a').parse(right);
          } catch (_) {}
        }
      }

      if (start != null && end != null) return UiDateUtils.dateTimeRange(start, end);
      return s;
    }

    if (s.contains('T')) {
      final d = DateTime.parse(s);
      return UiDateUtils.dateTimeRange(d);
    }

    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
      final parts = s.split('-');
      final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return UiDateUtils.fullDate(d);
    }

    try {
      final d = DateFormat('MMM d, yyyy h:mm a').parse(s);
      return UiDateUtils.dateTimeRange(d);
    } catch (_) {}

    return s;
  } catch (e) {
    // Ensure we return the raw input on unexpected errors and log for debugging.
    print('[WOPDialog] Error formatting schedule: $e');
    return raw;
  }
}

// Keep the WorkOrderPermitDialog class unchanged below...
class WorkOrderPermitDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onAssignmentComplete;

  const WorkOrderPermitDialog({
    super.key,
    required this.task,
    this.onAssignmentComplete,
  });

  @override
  State<WorkOrderPermitDialog> createState() => _WorkOrderPermitDialogState();

  static void show(
    BuildContext context, 
    Map<String, dynamic> task, {
    VoidCallback? onAssignmentComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WorkOrderPermitDialog(
          task: task,
          onAssignmentComplete: onAssignmentComplete,
        );
      },
    );
  }
}

class _WorkOrderPermitDialogState extends State<WorkOrderPermitDialog> {
  bool _showAssignmentForm = false;
  bool _isProcessing = false;

  Map<String, dynamic>? _taskData;

  Map<String, dynamic> get task => _taskData ?? widget.task;

  @override
  void initState() {
    super.initState();
    _taskData = Map<String, dynamic>.from(widget.task);
  }

  // Helper to check status
  bool get _isPendingStatus {
    final status = task['status']?.toString().toLowerCase() ?? '';
    return status == 'pending' || status == 'pending review';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: _showAssignmentForm 
                    ? _buildAssignmentFormView()
                    : _buildDetailsView(),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

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
          Text(
            _showAssignmentForm ? 'Assign & Schedule Work' : 'Work Order Permit Details',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
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

  Widget _buildFooter(BuildContext context) {
    // Single consistent footer: Reject and Approve aligned to right.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Left side reserved (keep spacing consistent)
          const SizedBox.shrink(),
          const Spacer(),

          // Reject button (calls confirmation handler)
          OutlinedButton(
            onPressed: () => _showRejectConfirmation(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[700],
              side: BorderSide(color: Colors.red[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            child: const Text('Reject'),
          ),
          const SizedBox(width: 12),

          // Approve button wired to _handleApproval
          ElevatedButton(
            onPressed: () => _handleApproval(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              elevation: 0,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with WOP ID and Status/Priority
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] ?? 'Aircon Repair - Unit Replacement',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'WOP ID: ${task['id'] ?? 'WOP-2025-00001'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            PriorityTag(task['priority'] ?? ''),
            const SizedBox(width: 8),
            StatusTag(task['status'] ?? ''),
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: Colors.grey[200], thickness: 1, height: 1),
        const SizedBox(height: 24),
        
        // Request Details
        _buildSectionTitle('Request Details'),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'REQUESTED BY',
                task['requestedBy'] ?? 'Admin Department',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDetailItem(
                'DEPARTMENT',
                task['department'] ?? 'Maintenance',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'BUILDING & UNIT NO.',
                task['buildingUnit'] ?? 'Bldg A - Unit 302',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDetailItem(
                'DATE REQUESTED',
                task['dateRequested'] ?? 'July 15, 2025',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        Divider(color: Colors.grey[200], thickness: 1, height: 1),
        const SizedBox(height: 24),
        
        // Specific Instructions
        _buildSectionTitle('Specific Instructions'),
        const SizedBox(height: 16),
        Text(
          task['specificInstructions'] ?? 
          'Replace fan motor and refill refrigerant. Indoor and outdoor access needed. Power shutdown may be required.',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 24),
        
        Divider(color: Colors.grey[200], thickness: 1, height: 1),
        const SizedBox(height: 24),
        
        // Permit Validation
        _buildSectionTitle('Permit Validation'),
        const SizedBox(height: 16),
        _buildDetailItem(
          'SCHEDULE VISIBILITY',
          _formatScheduleString(task['schedule'] ?? task['rawData']?['schedule'] ?? task['rawData']?['schedule_availability'] ?? task['schedule'] ?? ''),
        ),
        const SizedBox(height: 24),
        
        Divider(color: Colors.grey[200], thickness: 1, height: 1),
        const SizedBox(height: 24),
        
        // Contractor's Side
        _buildContractorSection(),
      ],
    );
  }

  Widget _buildAssignmentFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Assignment Info Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Approve Work Order Permit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Review and approve this work order permit to allow the contractor to proceed with the work.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue[800],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
    // Work Order Details
    _buildDetailItem('WORK ORDER ID', task['id'] ?? 'WOP-2025-00001'),
        const SizedBox(height: 24),
    _buildDetailItem('CONTRACTOR', task['contractorName'] ?? 'AC Pro Services'),
        const SizedBox(height: 24),
  _buildDetailItem('SCHEDULE', _formatScheduleString(task['schedule'] ?? task['rawData']?['schedule'] ?? task['rawData']?['schedule_availability'] ?? '')),
      ],
    );
  }

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

  Widget _buildContractorSection() {
    // Prefer a list of contractors if provided. Otherwise fall back to single contractor fields.
    final contractorsRaw = task['contractors'];
    List<dynamic>? contractorsList;
    if (contractorsRaw is List) contractorsList = contractorsRaw;

    if (contractorsList != null && contractorsList.isNotEmpty) {
      // Limit to 3 entries
      final shown = contractorsList.take(3).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Contractor\'s Side'),
          const SizedBox(height: 12),
          ...shown.map((c) {
            final name = c is Map ? (c['name'] ?? c['contractor_name'] ?? c['contractorName'] ?? '') : c.toString();
            final phone = c is Map ? (c['contact_number'] ?? c['phone'] ?? c['contactNumber'] ?? '') : '';
            final email = c is Map ? (c['email'] ?? c['email_address'] ?? c['emailAddress'] ?? '') : '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('NAME', name?.toString() ?? ''),
                const SizedBox(height: 6),
                _buildDetailItem('CONTACT NUMBER', phone?.toString() ?? ''),
                const SizedBox(height: 6),
                _buildDetailItem('EMAIL', (email?.toString() ?? '')),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ],
      );
    }

    // Single contractor fallback
    final contractorName = task['contractorName'] ?? task['rawData']?['contractor_name'] ?? 'Leo Fernandez';
    final phoneNumber = task['contactNumber'] ?? task['rawData']?['contact_number'] ?? '0917-456-7890';
    final emailAddress = task['emailAddress'] ?? task['rawData']?['email_address'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Contractor\'s Side'),
        const SizedBox(height: 16),
        _buildDetailItem('NAME', contractorName),
        const SizedBox(height: 12),
        _buildDetailItem('CONTACT NUMBER', phoneNumber),
        const SizedBox(height: 12),
        _buildDetailItem('EMAIL', emailAddress.isNotEmpty ? emailAddress : 'N/A'),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        if (value.isNotEmpty)
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
      ],
    );
  }

  Future<void> _showRejectConfirmation(BuildContext context) async {
    // Show a modal that collects rejection notes before returning to tenant.
    final TextEditingController _reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Return Work Order to Tenant'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide notes for returning this work order to the tenant.'),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                minLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter notes (required)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // require some notes before proceeding
                if (_reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter notes explaining the return to tenant.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Return'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final reason = _reasonController.text.trim();

      // Attempt to persist the denial via admin API
      final adminApi = AdminApi.ApiService();

      // Try several common keys for permit id
      final permitId = task['permitId'] ?? task['id'] ?? task['serviceId'] ?? task['workOrderId'];

      if (permitId == null) {
        throw Exception('Could not determine permit id for this work order');
      }

      final resp = await adminApi.rejectWorkOrderPermit(permitId.toString(), reason);

      // Update local task with server response
      _taskData ??= Map<String, dynamic>.from(widget.task);
      _taskData?['status'] = resp['status'] ?? 'returned_to_tenant';
      _taskData?['return_notes'] = reason;
      // also attach raw response for debugging
      _taskData?['rawResponse'] = resp;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Work order permit returned to tenant'),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
      widget.onAssignmentComplete?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error returning work order: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleApproval(BuildContext context) async {
    final confirmed = await showAppDialog<bool>(
      context,
      config: DialogConfig.confirmation(
        title: 'Approve Work Order Permit',
        description: 'Are you sure you want to approve this work order permit? This will allow the contractor to proceed.',
        primaryButtonLabel: 'Approve',
        primaryAction: () {},
        secondaryButtonLabel: 'Cancel',
        secondaryAction: () {},
      ),
      barrierDismissible: false,
    );

    if (confirmed != true) return;

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Work order permit approved successfully!'),
        backgroundColor: Color(0xFF38A169),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Close main dialog and notify caller
    Navigator.of(context).pop();
    widget.onAssignmentComplete?.call();
  }
}