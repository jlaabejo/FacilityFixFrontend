import 'package:facilityfix/adminweb/widgets/tags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:facilityfix/utils/ui_format.dart';

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
  int _currentStep = 0; // 0 = CS Details, 1 = WOP Details
  bool _isProcessing = false;

  // Helper to check status
  bool get _isPendingStatus {
    final status = widget.task['status']?.toString().toLowerCase() ?? '';
    return status == 'pending' || status == 'pending review';
  }
  
  bool get _isInProgressStatus {
    final status = widget.task['status']?.toString().toLowerCase() ?? '';
    return status == 'in progress' || status == 'inprogress';
  }
  
  bool get _isAcceptedStatus {
    final status = widget.task['status']?.toString().toLowerCase() ?? '';
    return status == 'accepted';
  }
  
  bool get _isCompletedStatus {
    final status = widget.task['status']?.toString().toLowerCase() ?? '';
    return status == 'completed';
  }
  
  // Check if we should show WOP details
  bool get _shouldShowWOPDetails {
    return _isPendingStatus || _isInProgressStatus || _isAcceptedStatus || _isCompletedStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: _currentStep > 0 ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: _isProcessing ? null : () {
                setState(() {
                  _currentStep--;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              child: const Text('Back'),
            ),
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
          // Show Accept/Reject buttons on step 1 only if status is pending
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with CS ID
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task['title'] ?? 'Aircon is not cooling properly',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'CS ID: ${widget.task['id'] ?? 'CS-2025-00012'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Status and Priority Tags
        Row(
          children: [
            PriorityTag(priority: widget.task['priority'] ?? 'High'),
            const SizedBox(width: 8),
            StatusTag(status: widget.task['status'] ?? 'Pending Review'),
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
                widget.task['requestedBy'] ?? 'Erika De Guzman',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDetailItem(
                'ACCOUNT TYPE',
                widget.task['accountType'] ?? 'Resident - Owner',
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
                widget.task['buildingUnit'] ?? 'Bldg A - Unit 302',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDetailItem(
                'DATE REQUESTED',
                widget.task['dateRequested'] ?? 'July 15, 2025',
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
          widget.task['description'] ?? 
          'Air conditioner is no longer cooling properly. The unit is making unusual noises and leaks water occasionally.',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Colors.grey[700],
          ),
        ),
        
        // Assessment Section with Resolution Type and Staff Details
        if (widget.task['assessment'] != null || widget.task['recommendation'] != null || widget.task['resolutionType'] != null) ...[
          const SizedBox(height: 24),
          Divider(color: Colors.grey[200], thickness: 1, height: 1),
          const SizedBox(height: 24),
          _buildAssessmentSection(),
        ],
      ],
    );
  }

  // Step 1: Work Order Details
  Widget _buildWorkOrderDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Work Order Title
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Work Order Permit',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'WOP ID: ${widget.task['wopId'] ?? widget.task['rawData']?['wop_id'] ?? 'WOP-2025-00045'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: Colors.grey[200], thickness: 1, height: 1),
        const SizedBox(height: 24),
        
        // Show accepted status message if accepted
        if (_isAcceptedStatus || _isCompletedStatus) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Work Order Permit has been accepted and approved.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey[200], thickness: 1, height: 1),
          const SizedBox(height: 24),
        ],
        
        // Contractor Information
        _buildSectionTitle('Contractor Information'),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'CONTRACTOR NAME',
                widget.task['contractorName'] ?? widget.task['rawData']?['contractor_name'] ?? 'Juan Dela Cruz',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDetailItem(
                'COMPANY',
                widget.task['company'] ?? widget.task['rawData']?['company'] ?? 'JDC HVAC Services',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        _buildDetailItem(
          'CONTACT NUMBER',
          widget.task['contactNumber'] ?? widget.task['rawData']?['contact_number'] ?? '+63 917 123 4567',
        ),
        const SizedBox(height: 24),
        
        Divider(color: Colors.grey[200], thickness: 1, height: 1),
        const SizedBox(height: 24),
        
        // Specific Instructions
        _buildSectionTitle('Specific Instructions'),
        const SizedBox(height: 16),
        Text(
          widget.task['specificInstructions'] ?? widget.task['rawData']?['specific_instructions'] ??
          'Contractor will inspect the air conditioning unit and perform necessary repairs. Unit is located in the living room. Please ensure all tools are properly handled.',
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
        
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'SCHEDULED DATE',
                _formatScheduledDateAndTime(widget.task['scheduledDate'] ?? widget.task['rawData']?['scheduled_date'], widget.task['scheduledTime'] ?? widget.task['rawData']?['scheduled_time'])['date'] ?? 'N/A',
              ),
            ),
            // const SizedBox(width: 24),
            // Expanded(
            //   child: _buildDetailItem(
            //     'SCHEDULED TIME',
            //     _formatScheduledDateAndTime(widget.task['scheduledDate'] ?? widget.task['rawData']?['scheduled_date'], widget.task['scheduledTime'] ?? widget.task['rawData']?['scheduled_time'])['time'] ?? 'N/A',
            //   ),
            // ),
          ],
        ),
        
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
      // TODO: Implement work order approval logic here
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Work order permit accepted successfully'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Close dialog and refresh
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
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Work Order Permit'),
          content: const Text(
            'Are you sure you want to reject this work order permit? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
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
      // TODO: Implement work order rejection logic here
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Work order permit rejected'),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Close dialog and refresh
      Navigator.of(context).pop();
      widget.onAssignmentComplete?.call();
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting work order: $e'),
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
    final staffName = widget.task['staffName'] ?? widget.task['rawData']?['staff_name'] ?? 'Staff Member';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Assessment and Resolution Details'),
        const SizedBox(height: 16),
        
        // Resolution Type with Staff Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  // Resolution Type Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.task['resolutionType'] ?? 'Work Permit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Assessment with Staff Avatar
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
        
        // Staff Info Row
        Row(
          children: [
            _buildSimpleAvatar(staffName, size: 32),
            const SizedBox(width: 12),
            Text(
              staffName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Assessment Text
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Text(
            widget.task['assessment'] ?? widget.task['rawData']?['staff_assessment'] ?? 'No assessment available.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey[800],
            ),
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
        } else if (RegExp(r'^\d{4}-\d{2}-\d{2}\$').hasMatch(dateStr)) {
          final p = dateStr.split('-');
          datePart = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
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
              // also provide a combined schedule string if desired
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

      // parse right (may be time-only)
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

    if (RegExp(r'^\d{4}-\d{2}-\d{2}\$').hasMatch(s)) {
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
    print('[WOPDialog] Error formatting schedule: $e');
  }
  return raw;
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

  // Helper to check status
  bool get _isPendingStatus {
    final status = widget.task['status']?.toString().toLowerCase() ?? '';
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: _showAssignmentForm ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
        children: [
          if (_showAssignmentForm) ...[
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _showAssignmentForm = false;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () {
                _handleApproval(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                elevation: 0,
              ),
              child: const Text('Approve'),
            ),
          ] else ...[
            // Cancel Request Button
            OutlinedButton(
              onPressed: () => _showCancelConfirmation(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[700],
                side: BorderSide(color: Colors.red[300]!),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              child: const Text('Cancel Request'),
            ),
            const SizedBox(width: 12),
            // Only show Next button if status is pending
            if (_isPendingStatus)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showAssignmentForm = true;
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
          ],
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
                    widget.task['title'] ?? 'Aircon Repair - Unit Replacement',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'WOP ID: ${widget.task['id'] ?? 'WOP-2025-00001'}',
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
            PriorityTag(priority: widget.task['urgency'] ?? widget.task['priority'] ?? 'High'),
            const SizedBox(width: 8),
            StatusTag(status: widget.task['status'] ?? 'Pending Review'),
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
                widget.task['requestedBy'] ?? 'Admin Department',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDetailItem(
                'DEPARTMENT',
                widget.task['department'] ?? 'Maintenance',
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
                widget.task['buildingUnit'] ?? 'Bldg A - Unit 302',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDetailItem(
                'DATE REQUESTED',
                widget.task['dateRequested'] ?? 'July 15, 2025',
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
          widget.task['specificInstructions'] ?? 
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
          _formatScheduleString(widget.task['schedule'] ?? widget.task['rawData']?['schedule'] ?? widget.task['rawData']?['schedule_availability'] ?? widget.task['schedule'] ?? ''),
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
        _buildDetailItem('WORK ORDER ID', widget.task['id'] ?? 'WOP-2025-00001'),
        const SizedBox(height: 24),
        _buildDetailItem('CONTRACTOR', widget.task['contractorName'] ?? 'AC Pro Services'),
        const SizedBox(height: 24),
  _buildDetailItem('SCHEDULE', _formatScheduleString(widget.task['schedule'] ?? widget.task['rawData']?['schedule'] ?? widget.task['rawData']?['schedule_availability'] ?? '')),
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
    String contractorName = widget.task['contractorName'] ?? 'Leo Fernandez';
    String companyName = widget.task['companyName'] ?? 'AC Pro Services';
    String phoneNumber = widget.task['phoneNumber'] ?? '0917-456-7890';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Contractor\'s Side'),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildDetailItem('CONTRACTOR NAME', contractorName),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDetailItem('COMPANY NAME', companyName),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildDetailItem('PHONE NUMBER', phoneNumber),
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

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Request'),
          content: const Text('Are you sure you want to cancel this work order permit request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _handleApproval(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Work order permit approved successfully!'),
        backgroundColor: Color(0xFF38A169),
      ),
    );
    widget.onAssignmentComplete?.call();
  }
}
