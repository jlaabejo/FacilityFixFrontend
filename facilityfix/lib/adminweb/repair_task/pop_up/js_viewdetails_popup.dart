import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/tags.dart';
import '../../../services/api_services.dart';
import '../../../utils/ui_format.dart';
import 'package:intl/intl.dart';


class JobServiceConcernSlipDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onAssignmentComplete;

  const JobServiceConcernSlipDialog({
    super.key,
    required this.task,
    this.onAssignmentComplete,
  });

  @override
  State<JobServiceConcernSlipDialog> createState() => _JobServiceConcernSlipDialogState();

  static void show(
    BuildContext context,
    Map<String, dynamic> task, {
    VoidCallback? onAssignmentComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return JobServiceConcernSlipDialog(
          task: task,
          onAssignmentComplete: onAssignmentComplete,
        );
      },
    );
  }
}

class _JobServiceConcernSlipDialogState extends State<JobServiceConcernSlipDialog> {
  final _formKey = GlobalKey<FormState>();
  final APIService _apiService = APIService();
  
  bool _formValid = false;
  bool _isLoading = false;
  bool _isAssigning = false;
  int _currentStep = 0; // 0 = CS Details, 1 = JS Details, 2 = Assign & Schedule
  
  String? selectedStaffId;
  String? selectedStaffName;
  DateTime? selectedDate;
  final TextEditingController notesController = TextEditingController();
  
  List<Map<String, dynamic>> _staffList = [];
  
  // Helper to check status
  bool get _isPendingStatus {
    final status = widget.task['status']?.toString().toLowerCase() ?? '';
    return status == 'pending';
  }
  
  @override
  void initState() {
    super.initState();
    notesController.addListener(_revalidate);
    _initializeScheduleDate();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revalidate();
    });
  }
  
  void _initializeScheduleDate() {
    final raw = widget.task['rawData']?['schedule_availability'] ?? widget.task['schedule'] ?? widget.task['dateRequested'] ?? widget.task['availability'];
    final sa = raw?.toString() ?? '';
    if (sa.isNotEmpty) {
      try {
        // Tenant often sends ranges like: "Oct 12, 2025 9:00 AM - 11:00 AM"
        if (sa.contains(' - ')) {
          final parts = sa.split(' - ');
          final left = parts[0].trim();
          try {
            // Try full datetime
            selectedDate = DateTime.parse(left);
          } catch (_) {
            try {
              selectedDate = DateFormat('MMM d, yyyy h:mm a').parse(left);
            } catch (e) {
              try {
                final dateOnly = DateFormat('MMM d, yyyy').parse(left);
                selectedDate = DateTime(dateOnly.year, dateOnly.month, dateOnly.day, 9, 0);
              } catch (e2) {
                // ignore
              }
            }
          }
        } else if (sa.contains('T')) {
          selectedDate = DateTime.parse(sa);
        } else if (RegExp(r'^\d{4}-\d{2}-\d{2}\$').hasMatch(sa)) {
          final parts = sa.split('-');
          selectedDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]), 9, 0);
        } else {
          try {
            selectedDate = DateTime.parse(sa);
          } catch (_) {
            // last resort: try UiDateUtils.parse
            try {
              selectedDate = UiDateUtils.parse(sa);
            } catch (_) {}
          }
        }
      } catch (e) {
        print('[JobServiceDialog] Error parsing schedule date: $e');
      }
    }
  }
  
  Future<void> _loadStaffMembers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      String? taskCategory = widget.task['department']?.toString().toLowerCase();
      String? department;
      
      switch (taskCategory) {
        case 'electrical':
          department = 'electrical';
          break;
        case 'plumbing':
          department = 'plumbing';
          break;
        case 'carpentry':
          department = 'carpentry';
          break;
        case 'masonry':
          department = 'masonry';
          break;
        case 'hvac':
          department = 'electrical';
          break;
        default:
          department = null;
      }
      
      final staffData = await _apiService.getStaffMembers(
        department: department,
        availableOnly: true,
      );
      
      setState(() {
        _staffList = staffData;
        _isLoading = false;
      });
      
      _autoAssignStaff();
      print('[JobServiceDialog] Loaded ${_staffList.length} staff members');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('[JobServiceDialog] Error loading staff: $e');
    }
  }
  
  void _revalidate() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (ok != _formValid) setState(() => _formValid = ok);
  }
  
  void _autoAssignStaff() {
    if (_staffList.isEmpty) return;
    
    _staffList.sort((a, b) {
      final workloadA = a['current_workload'] ?? 0;
      final workloadB = b['current_workload'] ?? 0;
      return workloadA.compareTo(workloadB);
    });
    
    final autoSelectedStaff = _staffList.first;
    setState(() {
      selectedStaffId = _getStaffId(autoSelectedStaff);
      selectedStaffName = _getStaffDisplayName(autoSelectedStaff);
    });
    _revalidate();
    
    print('[JobServiceDialog] Auto-assigned staff: $selectedStaffName (ID: $selectedStaffId)');
  }
  
  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
  
  String _getStaffDisplayName(Map<String, dynamic> staff) {
    final firstName = staff['first_name'] ?? '';
    final lastName = staff['last_name'] ?? '';
    String name = '$firstName $lastName'.trim();
    if (name.isEmpty) name = 'Staff Member';
    return name;
  }
  
  String _getStaffId(Map<String, dynamic> staff) {
    return staff['user_id'] ?? staff['id'] ?? '';
  }

  String _extractStaffName() {
    try {
      final s = widget.task['staffName'];
      if (s != null && s.toString().trim().isNotEmpty) return s.toString();

      final raw = widget.task['rawData'];
      if (raw is Map) {
        final profile = raw['staff_profile'];
        if (profile is Map) {
          final first = profile['first_name'] ?? profile['firstName'] ?? '';
          final last = profile['last_name'] ?? profile['lastName'] ?? '';
          final full = '${first.toString()} ${last.toString()}'.trim();
          if (full.isNotEmpty) return full;
        }

        final staffNameField = raw['staff_name'] ?? raw['staff'] ?? raw['assignee'];
        if (staffNameField != null && staffNameField.toString().trim().isNotEmpty) {
          return staffNameField.toString();
        }
      }
    } catch (e) {
      print('[JobServiceDialog] _extractStaffName error: $e');
    }
    return 'Staff Member';
  }

  Widget _buildSimpleAvatar(String name, {double size = 32}) {
    final parts = name.trim().split(' ');
    String initials = '';
    if (parts.isNotEmpty) {
      initials = parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
      if (parts.length > 1 && parts.last.isNotEmpty) {
        initials += parts.last[0].toUpperCase();
      }
    }
    if (initials.isEmpty) initials = '?';
    
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

      // Try to parse generic tenant formats
      try {
        final d = DateFormat('MMM d, yyyy h:mm a').parse(s);
        return UiDateUtils.dateTimeRange(d);
      } catch (_) {}

      return s;
    } catch (e) {
      print('[JobServiceDialog] Error formatting schedule: $e');
    }
    return dateString;
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
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: _currentStep == 0
                      ? _buildConcernSlipDetails()
                      : _currentStep == 1
                          ? _buildJobServiceDetails()
                          : _buildAssignmentForm(),
                ),
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
        title = 'Job Service Details';
        break;
      case 2:
        title = 'Assign & Schedule Work';
        break;
      default:
        title = 'Job Service';
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
            onPressed: _isAssigning ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Step 0: Concern Slip Details
  Widget _buildConcernSlipDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with CS ID and Status/Priority (matching CS dialog style)
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
                    widget.task['concernId'] ?? widget.task['id'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Date Requested: ${widget.task['dateRequested'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            PriorityTag(priority: widget.task['priority'] ?? 'Low'),
            const SizedBox(width: 8),
            StatusTag(status: widget.task['status'] ?? 'Pending'),
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
                widget.task['created_by'] ?? 'N/A',
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
                widget.task['buildingUnit'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDetailItem(
                'SCHEDULE AVAILABILITY',
                widget.task['dateRequested'] ?? 'N/A',
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
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 24),
        
        Divider(color: Colors.grey[200], thickness: 1, height: 1),
        const SizedBox(height: 24),
        
        // Assessment & Resolution Details
        _buildAssessmentSection(),
      ],
    );
  }

  // Assessment Section (matching WOP dialog style)
  Widget _buildAssessmentSection() {
    final staffName = _extractStaffName();
    
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
                      widget.task['resolutionType'] ?? 'Job Service',
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

  // Step 1: Job Service Details
  Widget _buildJobServiceDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with JS ID (matching CS dialog style)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Service',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.task['serviceId'] ?? widget.task['id'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
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
        
        // Service Details
        _buildSectionTitle('Service Details'),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'REQUESTED BY',
                widget.task['requestedBy'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDetailItem(
                'PREFERRED SCHEDULE',
                _formatScheduleDate(widget.task['schedule']),
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
                widget.task['buildingUnit'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 24),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 24),
        
        Divider(color: Colors.grey[200], thickness: 1, height: 1),
        const SizedBox(height: 24),
        
        // Additional Notes
        _buildSectionTitle('Additional Notes'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            widget.task['additionalNotes'] ?? 'Please notify me 30 minutes before arrival.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  // Step 2: Assignment Form
  Widget _buildAssignmentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Assign & Schedule Work Card (matching CS dialog style)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment_ind, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Assign & Schedule Work',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'JS: ${widget.task['serviceId'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.task['title'] ?? 'Job Service Request',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        PriorityTag(priority: widget.task['priority'] ?? 'Low'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Auto-assigned Staff and Schedule
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildAutoAssignedStaffDisplay(),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDatePicker(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Admin Notes
        _buildNotesSection(),
      ],
    );
  }

  Widget _buildAutoAssignedStaffDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Auto-assigned Staff',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
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
          child: _isLoading
              ? Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Assigning staff...'),
                  ],
                )
              : selectedStaffId == null
                  ? Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _staffList.isEmpty 
                                ? 'No staff available for this department'
                                : 'No staff assigned yet',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _buildSimpleAvatar(selectedStaffName ?? ''),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedStaffName ?? 'Unknown Staff',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.task['department'] ?? 'No Department',
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

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Inspection Schedule',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        FormField<DateTime>(
          validator: (_) {
            if (selectedDate == null) return 'Please pick a date';
            final today = DateTime.now();
            final floor = DateTime(today.year, today.month, today.day);
            if (selectedDate!.isBefore(floor)) return 'Date can\'t be in the past';
            return null;
          },
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _selectDateTime(context).then((_) => _revalidate()),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: state.hasError ? Colors.red : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: state.hasError ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedDate != null
                              ? '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year} ${selectedDate!.hour}:${selectedDate!.minute.toString().padLeft(2, '0')}'
                              : 'DD/MM/YYYY HH:MM',
                          style: TextStyle(
                            color: selectedDate != null
                                ? Colors.black87
                                : (state.hasError ? Colors.red : Colors.grey[500]),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.hasError) ...[
                const SizedBox(height: 6),
                Text(
                  state.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    // First select date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030, 12),
    );
    
    if (pickedDate != null) {
      // Then select time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedDate != null 
            ? TimeOfDay.fromDateTime(selectedDate!)
            : const TimeOfDay(hour: 9, minute: 0),
      );
      
      if (pickedTime != null) {
        setState(() {
          selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
        _revalidate();
      }
    }
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin Notes (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: notesController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Enter Notes....',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          inputFormatters: [LengthLimitingTextInputFormatter(500)],
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            if (v.trim().length < 5) return 'Add a bit more detail or leave blank';
            return null;
          },
        ),
      ],
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
              onPressed: _isAssigning ? null : () {
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
          if (_currentStep == 0 && _isPendingStatus)
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
          if (_currentStep == 1)
            ElevatedButton.icon(
              onPressed: () async {
                setState(() {
                  _currentStep = 2;
                });
                await _loadStaffMembers();
                _autoAssignStaff();
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
          if (_currentStep == 2)
            ElevatedButton(
              onPressed: (_formValid && !_isAssigning) ? _handleSaveAndAssign : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                elevation: 0,
              ),
              child: _isAssigning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save and Assign'),
            ),
        ],
      ),
    );
  }

  Future<void> _handleSaveAndAssign() async {
    if (!_formValid || selectedStaffId == null || selectedStaffId!.toString().trim().isEmpty) {
      // Ensure a staff member is selected before proceeding
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a staff member to assign'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    setState(() => _isAssigning = true);
    
    try {
      // Resolve job service id (support both 'serviceId' and 'id') and ensure it's a string
      final jobServiceIdRaw = widget.task['serviceId'] ?? widget.task['id'];
      final jobServiceId = jobServiceIdRaw?.toString();
      if (jobServiceId == null || jobServiceId.isEmpty) throw Exception('Job Service ID not found');

      final staffId = selectedStaffId!.toString();
      print('[JobServiceDialog] Assigning staff $staffId to job service $jobServiceId');

      final result = await _apiService.assignStaffToJobService(
        jobServiceId,
        staffId,
      );

      print('[JobServiceDialog] Assignment successful: $result');

      if (mounted) {
        // Show confirmation before closing the dialog so the SnackBar is visible in the app scaffold
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff assigned successfully to $jobServiceId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
        widget.onAssignmentComplete?.call();
      }
    } catch (e) {
      print('[JobServiceDialog] Assignment failed: $e');
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign staff: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
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

  Widget _buildDetailItem(String label, String value) {
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
        if (value.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ],
    );
  }
}
