import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/tags.dart';

class JobServiceConcernSlipDialog extends StatelessWidget {
  final Map<String, dynamic> task;

  const JobServiceConcernSlipDialog({
    super.key,
    required this.task,
  });

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
                child: _buildDetailsView(),
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
          const Text(
            'Job Service Details',
            style: TextStyle(
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
  
  // Helper to check status
  bool get _isPendingStatus {
    final status = task['status']?.toString().toLowerCase() ?? '';
    return status == 'pending';
  }
  
  bool get _isAssignedStatus {
    final status = task['status']?.toString().toLowerCase() ?? '';
    return status == 'assigned';
  }
  
  bool get _isSentStatus {
    final status = task['status']?.toString().toLowerCase() ?? '';
    return status == 'sent';
  }
  
  bool get _isCompletedStatus {
    final status = task['status']?.toString().toLowerCase() ?? '';
    return status == 'completed';
  }

  Widget _buildDetailsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with JS ID and Status/Priority
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] ?? 'Leaking Faucet in Kitchen',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task['serviceId'] ?? task['id'] ?? 'JS-2025-00045',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Date Created: ${task['dateCreated'] ?? task['dateRequested'] ?? 'July 21, 2025'}',
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
            PriorityTag(priority: task['priority'] ?? 'Medium'),
            const SizedBox(width: 8),
            StatusTag(status: task['status'] ?? 'Pending'),
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
                'NAME',
                task['requestedBy'] ?? task['requesterName'] ?? 'Erika De Guzman',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDetailItem(
                'DEPARTMENT',
                task['department'] ?? 'Plumbing',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'UNIT',
                task['buildingUnit'] ?? task['unit'] ?? 'A - 1010',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDetailItem(
                'SCHEDULE AVAILABILITY',
                task['scheduleAvailability'] ?? task['preferredSchedule'] ?? 'July 21, 2025',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Additional Notes Section
        if (task['additionalNotes'] != null && task['additionalNotes'].toString().isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'ADDITIONAL NOTES',
                  task['additionalNotes'] ?? '',
                ),
              ),
              const SizedBox(width: 24),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 24),
        ],
        
        Divider(color: Colors.grey[200], thickness: 1, height: 1),
        const SizedBox(height: 24),
        
        // Staff Details Section (show for assigned, sent, or completed status)
        if (_isAssignedStatus || _isSentStatus || _isCompletedStatus) ...[
          _buildStaffDetailsSection(),
          const SizedBox(height: 24),
          Divider(color: Colors.grey[200], thickness: 1, height: 1),
          const SizedBox(height: 24),
        ],
        
        // Assessment Section (show for sent or completed status)
        if (_isSentStatus || _isCompletedStatus) ...[
          _buildAssessmentSection(),
        ],
      ],
    );
  }
  
  Widget _buildStaffDetailsSection() {
    final assignedStaff = task['assignedStaff'] ?? task['rawData']?['assigned_staff'];
    
    if (assignedStaff == null) {
      return const SizedBox.shrink();
    }
    
    final staffName = assignedStaff['name'] ?? 
                     '${assignedStaff['first_name'] ?? ''} ${assignedStaff['last_name'] ?? ''}'.trim();
    final assessedAt = task['assessedAt'] ?? task['rawData']?['assessed_at'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Assigned Staff'),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSimpleAvatar(staffName, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staffName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (assessedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Assessed: $assessedAt',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAssessmentSection() {
    final resolutionType = task['resolutionType'] ?? task['rawData']?['resolution_type'];
    final assessment = task['assessment'] ?? task['rawData']?['staff_assessment'];
    
    if (resolutionType == null && assessment == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Assessment and Resolution Details'),
        const SizedBox(height: 16),
        
        if (resolutionType != null) ...[
          Text(
            'Resolution Type',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              resolutionType.toString().replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        
        if (assessment != null) ...[
          _buildDetailItem('ASSESSMENT', ''),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              assessment.toString(),
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ],
    );
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
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Show Next button only if status is pending (to assign staff)
          if (_isPendingStatus)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                JobServiceScheduleDialog.show(context, task);
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
          
          // Show View Concern Slip button if status is assigned or sent
          if (_isAssignedStatus || _isSentStatus)
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to concern slip details
                final concernSlipId = task['concernSlipId'] ?? task['rawData']?['concern_slip_id'];
                if (concernSlipId != null) {
                  // TODO: Open concern slip dialog with the concernSlipId
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('View Concern Slip: $concernSlipId'),
                      backgroundColor: Colors.blue[600],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No concern slip associated'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.description, size: 16),
              label: const Text('View Concern Slip'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                elevation: 0,
              ),
            ),
          
          // No buttons for completed status (view only)
        ],
      ),
    );
  }

  // Static method to show the dialog
  static void show(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return JobServiceConcernSlipDialog(task: task);
      },
    );
  }
}

class JobServiceScheduleDialog extends StatefulWidget {
  final Map<String, dynamic> task;

  const JobServiceScheduleDialog({
    super.key,
    required this.task,
  });

  @override
  State<JobServiceScheduleDialog> createState() => _JobServiceScheduleDialogState();

  // Static method to show the dialog
  static void show(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return JobServiceScheduleDialog(task: task);
      },
    );
  }
}

class _JobServiceScheduleDialogState extends State<JobServiceScheduleDialog> {
  String? selectedStaff;
  DateTime? selectedDate;
  final TextEditingController notesController = TextEditingController();

  final List<String> staffList = [
    'John Smith - Plumber',
    'Maria Garcia - Electrician',
    'David Johnson - Maintenance',
    'Sarah Wilson - General Repair',
  ];

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
                child: _buildAssignmentForm(),
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
          const Text(
            'Assign & Schedule Work',
            style: TextStyle(
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
  
  Widget _buildAssignmentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Job Service Info Box
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
                    'Job Service Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service ID',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.task['serviceId'] ?? widget.task['id'] ?? 'JS-2025-00045',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requester',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.task['requestedBy'] ?? widget.task['requesterName'] ?? 'Erika De Guzman',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Assign Staff and Inspection Schedule
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildStaffDropdown(),
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
  
  Widget _buildStaffDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign Staff',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedStaff,
              hint: Text(
                'Select Staff...',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  selectedStaff = newValue;
                });
              },
              items: staffList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
            ),
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
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  selectedDate != null
                      ? '${selectedDate!.day.toString().padLeft(2, '0')} / ${selectedDate!.month.toString().padLeft(2, '0')} / ${selectedDate!.year}'
                      : 'Select Date',
                  style: TextStyle(
                    color: selectedDate != null ? Colors.black87 : Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
        TextField(
          controller: notesController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Enter Notes....',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[600]!),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: _handleSaveAndAssign,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              elevation: 0,
            ),
            child: const Text('Save and Assign'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030, 12),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
  
  void _handleSaveAndAssign() {
    if (selectedStaff == null || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select staff and schedule date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Handle save logic here
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Work assigned to $selectedStaff'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class AssignScheduleWorkDialog extends StatefulWidget {
  final Map<String, dynamic> task;

  const AssignScheduleWorkDialog({
    super.key,
    required this.task,
  });

  @override
  State<AssignScheduleWorkDialog> createState() => _AssignScheduleWorkDialogState();

  // Static method to show the dialog
  static void show(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AssignScheduleWorkDialog(task: task);
      },
    );
  }
}

class _AssignScheduleWorkDialogState extends State<AssignScheduleWorkDialog> {
  String? selectedStaff;
  String? selectedStatus;
  DateTime? selectedDate;
  final TextEditingController notesController = TextEditingController();

  final List<String> staffList = [
    'John Smith - Plumber',
    'Maria Garcia - Electrician', 
    'David Johnson - Maintenance',
    'Sarah Wilson - General Repair',
  ];

  final List<String> statusList = [
    'Pending',
    'In Progress',
    'Assigned',
    'On Hold',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 600,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildAssignHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Priority Chip
                    PriorityTag(priority: widget.task['urgency'] ?? widget.task['priority'] ?? 'Medium'),
                    const SizedBox(height: 32),

                    // Assign Staff and Schedule Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildStaffDropdown()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildDatePicker()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Job Status Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildStatusDropdown()),
                        const SizedBox(width: 24),
                        const Expanded(child: SizedBox()), // Empty space for alignment
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Internal Notes
                    _buildNotesSection(),
                  ],
                ),
              ),
            ),

            Divider(
              color: Colors.grey[300],
              thickness: 1,
              height: 1,
            ),

            // Footer
            _buildAssignFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 32, right: 24, top: 24, bottom: 16),
      child: Row(
        children: [
          const Text(
            'Assign & Schedule Work',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.grey,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign Staff',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedStaff,
              hint: Text(
                'Select Staff...',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  selectedStaff = newValue;
                });
              },
              items: staffList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
            ),
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
          'Work Order Schedule',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  selectedDate != null
                      ? '${selectedDate!.day.toString().padLeft(2, '0')} / ${selectedDate!.month.toString().padLeft(2, '0')} / ${selectedDate!.year.toString().substring(2)}'
                      : 'DD / MM / YY',
                  style: TextStyle(
                    color: selectedDate != null ? Colors.black87 : Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedStatus,
              hint: Text(
                'Select Status...',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  selectedStatus = newValue;
                });
              },
              items: statusList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Internal Notes (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: notesController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Enter Notes....',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1976D2),
              side: const BorderSide(color: Color(0xFF1976D2)),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Back',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _handleSaveAndAssign(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save, size: 18),
                SizedBox(width: 8),
                Text(
                  'Save & Assign Staff',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2025, 12),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _handleSaveAndAssign() {
    if (selectedStaff == null || selectedDate == null || selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select staff, status, and schedule date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Handle save logic here
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Work assigned to $selectedStaff with status: $selectedStatus'),
        backgroundColor: Colors.green,
      ),
    );
  }
}