import 'package:facilityfix/adminweb/widgets/tags.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/utils/ui_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConcernSlipDetailDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onAssignmentComplete;

  const ConcernSlipDetailDialog({
    super.key, 
    required this.task,
    this.onAssignmentComplete,
  });

  @override
  State<ConcernSlipDetailDialog> createState() => _ConcernSlipDetailDialogState();

  static void show(
    BuildContext context, 
    Map<String, dynamic> task, {
    VoidCallback? onAssignmentComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ConcernSlipDetailDialog(
          task: task,
          onAssignmentComplete: onAssignmentComplete,
        );
      },
    );
  }
}

class _ConcernSlipDetailDialogState extends State<ConcernSlipDetailDialog> {
  final _formKey = GlobalKey<FormState>();
  final APIService _apiService = APIService();
  
  bool _formValid = false;
  bool _isLoading = false;
  bool _isAssigning = false;
  bool _showAssignmentForm = false; // Track which view to show
  
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
  
  bool get _isAssignedStatus {
    final status = widget.task['status']?.toString().toLowerCase() ?? '';
    return status == 'assigned';
  }
  
  bool get _isSentStatus {
    final status = widget.task['status']?.toString().toLowerCase() ?? '';
    return status == 'sent';
  }
  
  bool get _isCompletedStatus {
    final status = widget.task['status']?.toString().toLowerCase() ?? '';
    return status == 'completed';
  }
  
  @override
  void initState() {
    super.initState();
    notesController.addListener(_revalidate);
    _initializeScheduleDate(); // Auto-populate schedule date
    
    // Load staff details if status is assigned, sent, or completed
    if (_isAssignedStatus || _isSentStatus || _isCompletedStatus) {
      _loadAssignedStaffDetails();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revalidate();
      // Auto-load and assign staff when showing assignment form
      if (_showAssignmentForm) {
        _loadStaffMembers().then((_) => _autoAssignStaff());
      }
    });
  }
  
  void _initializeScheduleDate() {
    // Auto-populate inspection schedule from schedule availability
    final scheduleAvailability = widget.task['dateRequested'] ?? 
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
  
  Future<void> _loadStaffMembers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      String? taskCategory = widget.task['category']?.toString().toLowerCase();
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
        case 'pest control':
        case 'pest_control':
          department = 'masonry';
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
      
      print('[ConcernSlipDetail] Loaded ${_staffList.length} staff members');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('[ConcernSlipDetail] Error loading staff: $e');
    }
  }
  
  void _revalidate() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (ok != _formValid) setState(() => _formValid = ok);
  }
  
  void _autoAssignStaff() {
    // Auto-assign staff based on department using round-robin or first available
    if (_staffList.isEmpty) return;
    
    // Sort by workload if available, otherwise use first staff
    _staffList.sort((a, b) {
      final workloadA = a['current_workload'] ?? 0;
      final workloadB = b['current_workload'] ?? 0;
      return workloadA.compareTo(workloadB);
    });
    
    // Auto-select the staff member with lowest workload
    final autoSelectedStaff = _staffList.first;
    setState(() {
      selectedStaffId = _getStaffId(autoSelectedStaff);
      selectedStaffName = _getStaffDisplayName(autoSelectedStaff);
    });
    _revalidate();
    
    print('[ConcernSlipDetail] Auto-assigned staff: $selectedStaffName (ID: $selectedStaffId)');
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


  String _fmtDateTime(DateTime d) {
    // Use UiDateUtils for consistent formatting
    return UiDateUtils.dateTimeRange(d);
  }
  
  String _formatScheduleAvailability(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      DateTime date;
      if (dateString.contains('T')) {
        date = DateTime.parse(dateString);
      } else {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        } else {
          return dateString;
        }
      }
      // Use UiDateUtils for consistent formatting
      return UiDateUtils.dateTimeRange(date);
    } catch (e) {
      print('[ConcernSlipDetail] Error formatting schedule: $e');
    }
    return dateString;
  }
  
  void _loadAssignedStaffDetails() {
    // Load staff details from the task data
    final assignedStaff = widget.task['rawData']?['assigned_staff'];
    if (assignedStaff != null) {
      setState(() {
        selectedStaffId = assignedStaff['user_id'] ?? assignedStaff['id'];
        selectedStaffName = assignedStaff['name'] ?? 
                           '${assignedStaff['first_name'] ?? ''} ${assignedStaff['last_name'] ?? ''}'.trim();
      });
    }
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
                child: _showAssignmentForm 
                    ? Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: _buildAssignmentFormView(),
                      )
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
            _showAssignmentForm ? 'Assign & Schedule Work' : 'Concern Slip Details',
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
              onPressed: _isAssigning ? null : () {
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
          ] else ...[
            // Only show Next button if status is pending
            if (_isPendingStatus)
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _showAssignmentForm = true;
                  });
                  await _loadStaffMembers();
                  _autoAssignStaff(); // Auto-assign based on department
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
        // Title with CS ID and Status/Priority
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
                widget.task['rawData']?['reported_by'] ?? 'Erika De Guzman',
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
              child: _buildDetailItem(
                'SCHEDULE AVAILABILITY',
                _formatScheduleAvailability(widget.task['dateRequested'] ?? widget.task['rawData']?['schedule_availability']),
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
        
        // Staff Details Section (show for assigned, sent, or completed status)
        if (_isAssignedStatus || _isSentStatus || _isCompletedStatus) ...[
          const SizedBox(height: 24),
          _buildStaffDetailsSection(),
        ],
        
        // Assessment Section (show for sent or completed status)
        if (_isSentStatus || _isCompletedStatus) ...[
          const SizedBox(height: 24),
          Divider(color: Colors.grey[200], thickness: 1, height: 1),
          const SizedBox(height: 24),
          _buildAssessmentSection(),
        ],
      ],
    );
  }
  
  Widget _buildAssignmentFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Assign & Schedule Work Card
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
                                'CS: ${widget.task['id'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.task['title'] ?? 'No Title',
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
                        _buildPriorityChip(widget.task['priority'] ?? 'Low'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Assign Staff and Inspection Schedule in one row
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
  
  Widget _buildStaffDetailsSection() {
    final assignedStaff = widget.task['rawData']?['assigned_staff'];
    
    // Debug: Print what we're getting
    print('[StaffDetails] rawData: ${widget.task['rawData']}');
    print('[StaffDetails] assigned_staff: $assignedStaff');
    
    if (assignedStaff == null) {
      print('[StaffDetails] No assigned staff found');
      return const SizedBox.shrink();
    }
    
    final staffName = assignedStaff['name'] ?? 
                     '${assignedStaff['first_name'] ?? ''} ${assignedStaff['last_name'] ?? ''}'.trim();
    final assessedAt = widget.task['rawData']?['assessed_at'];
    
    print('[StaffDetails] Staff name: $staffName');
    print('[StaffDetails] Assessed at: $assessedAt');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Assigned Staff'),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and Name
            Row(
              children: [
                _buildSimpleAvatar(staffName.isNotEmpty ? staffName : 'Staff Member', size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    staffName.isNotEmpty ? staffName : 'Staff Member',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Date Assessed
            if (assessedAt != null)
              _buildDetailItem(
                'DATE ASSESSED',
                _formatScheduleAvailability(assessedAt),
              ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAssessmentSection() {
    final resolutionType = widget.task['rawData']?['resolution_type'];
    final assessment = widget.task['rawData']?['staff_assessment'];
    final recommendation = widget.task['rawData']?['staff_recommendation'];
    
    // Debug: Check what we're receiving
    print('[Assessment] resolution_type: $resolutionType');
    print('[Assessment] staff_assessment: $assessment');
    
    if (resolutionType == null && assessment == null && recommendation == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Assessment and Resolution Details'),
        const SizedBox(height: 16),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Resolution Type
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
                  if (resolutionType != null)
                    RequestTypeTag(
                      resolutionType.toString().replaceAll('_', ' '),
                    )
                  else
                    Text(
                      'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right column: Recommendation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECOMMENDATION',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommendation ?? 'N/A',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: recommendation != null ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Assessment section
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
                          selectedDate != null ? _fmtDateTime(selectedDate!) : 'DD/MM/YYYY HH:MM',
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
  
  Future<void> _handleSaveAndAssign() async {
    if (!_formValid || selectedStaffId == null) return;
    setState(() => _isAssigning = true);
    
    try {
      final concernSlipId = widget.task['rawData']?['id'] ?? 
                           widget.task['rawData']?['_doc_id'] ?? 
                           widget.task['id'];
      if (concernSlipId == null) throw Exception('Concern slip ID not found');
      
      print('[ConcernSlipDetail] Assigning staff $selectedStaffId to concern slip $concernSlipId');
      
      final result = await _apiService.assignStaffToConcernSlip(
        concernSlipId,
        selectedStaffId!,
      );
      
      print('[ConcernSlipDetail] Assignment successful: $result');
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff assigned successfully to ${widget.task['id']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onAssignmentComplete?.call();
      }
    } catch (e) {
      print('[ConcernSlipDetail] Assignment failed: $e');
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

  Widget _buildPriorityChip(String priority) {
    // This method is kept for backward compatibility but not used
    // Using PriorityTag widget instead
    return PriorityTag(priority: priority);
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
}
