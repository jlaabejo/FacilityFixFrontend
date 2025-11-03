import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../services/api_service.dart';

class ExternalViewTaskPage extends StatefulWidget {
  /// Deep-linkable view with optional edit mode.
  final String taskId;
  final Map<String, dynamic>? initialTask;
  final bool startInEditMode;

  const ExternalViewTaskPage({
    super.key,
    required this.taskId,
    this.initialTask,
    this.startInEditMode = false,
  });

  @override
  State<ExternalViewTaskPage> createState() => _ExternalViewTaskPageState();
}

class _ExternalViewTaskPageState extends State<ExternalViewTaskPage> {
  // -------- Route mapping helper --------
  String? _getRoutePath(String routeKey) {
    final Map<String, String> pathMap = {
      'dashboard': '/dashboard',
      'user_users': '/user/users',
      'user_roles': '/user/roles',
      'work_maintenance': '/work/maintenance',
      'work_repair': '/work/repair',
      'calendar': '/calendar',
      'inventory_items': '/inventory/items',
      'inventory_request': '/inventory/request',
      'analytics': '/analytics',
      'announcement': '/announcement',
      'settings': '/settings',
    };
    return pathMap[routeKey];
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/');
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  // ---------------- Edit mode + form state ----------------
  final _formKey = GlobalKey<FormState>();
  bool _isEditMode = false;

  // Basic Information
  final _maintenanceTypeCtrl = TextEditingController();
  final _serviceCategoryCtrl = TextEditingController();
  final _createdByCtrl = TextEditingController();
  final _dateCreatedCtrl = TextEditingController();

  // Recurrence & Schedule
  final _recurrenceCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _nextDueCtrl = TextEditingController();
  final _serviceWindowCtrl =
      TextEditingController(); // "YYYY-MM-DD to YYYY-MM-DD"

  // Task Scope & Description
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // Assessment Tracking
  final _serviceDateActualCtrl = TextEditingController();
  String _assessmentReceived = 'Yes'; // dropdown
  final _loggedByCtrl = TextEditingController();
  final _loggedDateCtrl = TextEditingController();
  final _assessmentNotesCtrl = TextEditingController();
  final _recommendationsCtrl = TextEditingController();

  // Contractor
  final _contractorNameCtrl = TextEditingController();
  final _contractPersonCtrl = TextEditingController();
  final _contractPhoneCtrl = TextEditingController();
  final _contractEmailCtrl = TextEditingController();

  // Notifications (editable)
  final _adminNotifyCtrl = TextEditingController();

  // Snapshot for Cancel
  late Map<String, String> _original;

  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic> _currentTaskData = {};

  // ---------------- Init / Dispose ----------------
  @override
  void initState() {
    super.initState();
    
    // Always fetch the latest data from the API
    _fetchTaskData();
    
    // Set initial edit mode
    _isEditMode = widget.startInEditMode;
  }

  Future<void> _fetchTaskData() async {
    try {
      // Set loading state
      if (mounted) {
        setState(() {
          _error = null;
          _isLoading = true;
        });
      }

      final taskData = await _apiService.getMaintenanceTaskById(widget.taskId);
      
      if (mounted) {
        setState(() {
          // Store the current task data
          _currentTaskData = taskData;
          
          // Update controllers with fetched data using comprehensive mapping
          _populateFormWithTaskData(taskData);
          
          // Take snapshot for cancel functionality
          _original = _takeSnapshot();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[v0] Error fetching task data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load task data: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  void _populateFormWithTaskData(Map<String, dynamic> taskData) {
    // Basic Information
    _maintenanceTypeCtrl.text =
        taskData['maintenance_type']?.toString() ??
        taskData['maintenanceType']?.toString() ??
        'External';
    _serviceCategoryCtrl.text =
        taskData['service_category']?.toString() ??
        taskData['serviceCategory']?.toString() ?? '';
    _createdByCtrl.text = 
        taskData['created_by']?.toString() ??
        taskData['createdBy']?.toString() ?? '';
    _dateCreatedCtrl.text = 
        _formatDate(taskData['date_created'] ?? taskData['dateCreated']);

    // Recurrence & Schedule
    _recurrenceCtrl.text = 
        taskData['recurrence']?.toString() ??
        taskData['recurrence_type']?.toString() ?? '';
    _startDateCtrl.text = 
        _formatDate(taskData['start_date'] ?? taskData['startDate']);
    _nextDueCtrl.text = 
        _formatDate(taskData['next_due_date'] ?? taskData['nextDueDate']);

    // Service Window
    if (taskData['service_window_start'] != null &&
        taskData['service_window_end'] != null) {
      _serviceWindowCtrl.text =
          '${_formatDate(taskData['service_window_start'])} to ${_formatDate(taskData['service_window_end'])}';
    } else if (taskData['serviceWindowStart'] != null &&
               taskData['serviceWindowEnd'] != null) {
      _serviceWindowCtrl.text =
          '${_formatDate(taskData['serviceWindowStart'])} to ${_formatDate(taskData['serviceWindowEnd'])}';
    } else {
      _serviceWindowCtrl.text = '';
    }

    // Task Scope & Description
    _locationCtrl.text = taskData['location']?.toString() ?? '';
    _descriptionCtrl.text = 
        taskData['description']?.toString() ??
        taskData['task_description']?.toString() ?? '';

    // Assessment Tracking
    _serviceDateActualCtrl.text =
        _formatDate(taskData['service_date_actual'] ?? taskData['serviceDateActual']);
    _assessmentReceived =
        taskData['assessment_received']?.toString() ??
        taskData['assessmentReceived']?.toString() ?? 'Yes';
    _loggedByCtrl.text = 
        taskData['logged_by']?.toString() ??
        taskData['loggedBy']?.toString() ?? '';
    _loggedDateCtrl.text = 
        _formatDate(taskData['logged_date'] ?? taskData['loggedDate']);

    // Contractor Information
    _contractorNameCtrl.text =
        taskData['contractor_name']?.toString() ??
        taskData['contractorName']?.toString() ?? '';
    _contractPersonCtrl.text =
        taskData['contact_person']?.toString() ??
        taskData['contractPerson']?.toString() ?? '';
    _contractPhoneCtrl.text =
        taskData['contact_number']?.toString() ??
        taskData['contractPhone']?.toString() ?? '';
    _contractEmailCtrl.text = 
        taskData['email']?.toString() ??
        taskData['contractEmail']?.toString() ?? '';

    // Notifications
    _adminNotifyCtrl.text =
        taskData['admin_notification']?.toString() ??
        taskData['adminNotify']?.toString() ?? '';

    // Assessment Notes & Recommendations
    _assessmentNotesCtrl.text =
        taskData['assessment_notes']?.toString() ??
        taskData['assessmentNotes']?.toString() ?? '';
    _recommendationsCtrl.text =
        taskData['recommendations']?.toString() ??
        taskData['recommendation']?.toString() ?? '';
  }
  
  String? _error;

  // Helper method to format dates consistently
  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      if (date is String) {
        if (date.isEmpty) return '';
        final dt = DateTime.parse(date);
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
      if (date is DateTime) {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      return date.toString();
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _maintenanceTypeCtrl.dispose();
    _serviceCategoryCtrl.dispose();
    _createdByCtrl.dispose();
    _dateCreatedCtrl.dispose();

    _recurrenceCtrl.dispose();
    _startDateCtrl.dispose();
    _nextDueCtrl.dispose();
    _serviceWindowCtrl.dispose();

    _locationCtrl.dispose();
    _descriptionCtrl.dispose();

    _serviceDateActualCtrl.dispose();
    _loggedByCtrl.dispose();
    _loggedDateCtrl.dispose();

    _contractorNameCtrl.dispose();
    _contractPersonCtrl.dispose();
    _contractPhoneCtrl.dispose();
    _contractEmailCtrl.dispose();

    _adminNotifyCtrl.dispose();
    _assessmentNotesCtrl.dispose();
    _recommendationsCtrl.dispose();
    super.dispose();
  }

  // ---------------- Snapshot / Edit handlers ----------------
  Map<String, String> _takeSnapshot() => {
    'maintenance_type': _maintenanceTypeCtrl.text,
    'service_category': _serviceCategoryCtrl.text,
    'created_by': _createdByCtrl.text,
    'date_created': _dateCreatedCtrl.text,
    'recurrence_type': _recurrenceCtrl.text,
    'start_date': _startDateCtrl.text,
    'next_due_date': _nextDueCtrl.text,
    'service_window': _serviceWindowCtrl.text,
    'location': _locationCtrl.text,
    'task_description': _descriptionCtrl.text,
    'service_date_actual': _serviceDateActualCtrl.text,
    'assessment_received': _assessmentReceived,
    'logged_by': _loggedByCtrl.text,
    'logged_date': _loggedDateCtrl.text,
    'contractor_name': _contractorNameCtrl.text,
    'contact_person': _contractPersonCtrl.text,
    'contact_number': _contractPhoneCtrl.text,
    'email': _contractEmailCtrl.text,
    'admin_notification': _adminNotifyCtrl.text,
    'assessment_notes': _assessmentNotesCtrl.text,
    'recommendations': _recommendationsCtrl.text,
  };

  void _enterEditMode() => setState(() => _isEditMode = true);

  void _cancelEdit() {
    final s = _original;
    _maintenanceTypeCtrl.text = s['maintenance_type']!;
    _serviceCategoryCtrl.text = s['service_category']!;
    _createdByCtrl.text = s['created_by']!;
    _dateCreatedCtrl.text = s['date_created']!;

    _recurrenceCtrl.text = s['recurrence_type']!;
    _startDateCtrl.text = s['start_date']!;
    _nextDueCtrl.text = s['next_due_date']!;
    _serviceWindowCtrl.text = s['service_window']!;

    _locationCtrl.text = s['location']!;
    _descriptionCtrl.text = s['task_description']!;

    _serviceDateActualCtrl.text = s['service_date_actual']!;
    _assessmentReceived = s['assessment_received']!;
    _loggedByCtrl.text = s['logged_by']!;
    _loggedDateCtrl.text = s['logged_date']!;

    _contractorNameCtrl.text = s['contractor_name']!;
    _contractPersonCtrl.text = s['contact_person']!;
    _contractPhoneCtrl.text = s['contact_number']!;
    _contractEmailCtrl.text = s['email']!;

    _adminNotifyCtrl.text = s['admin_notification']!;
    _assessmentNotesCtrl.text = s['assessment_notes']!;
    _recommendationsCtrl.text = s['recommendations']!;

    setState(() => _isEditMode = false);
  }

  Future<void> _saveEdit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors.')),
      );
      return;
    }

    try {
      final updateData = _takeSnapshot();
      await _apiService.updateMaintenanceTask(widget.taskId, updateData);

      // Refetch the latest data to ensure form is synchronized
      await _fetchTaskData();
      
      setState(() => _isEditMode = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task saved successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[v0] Error saving external maintenance task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---------------- Validators ----------------
  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _dateValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final ok = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v.trim());
    return ok ? null : 'Use YYYY-MM-DD';
  }

  String? _serviceWindowValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final ok = RegExp(
      r'^\d{4}-\d{2}-\d{2}\s+to\s+\d{4}-\d{2}-\d{2}$',
    ).hasMatch(v.trim());
    return ok ? null : 'Use "YYYY-MM-DD to YYYY-MM-DD"';
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    // basic PH/intl-ish check; tweak as needed
    final ok = RegExp(r'^[\d\-\+\s$$$$]{7,}$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid phone number';
  }

  /// Accept strings like: "1 week before, 3 days before, 1 day before"
  String? _notifyValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final parts = v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    final re = RegExp(
      r'^\d+\s*(day|days|week|weeks)\s+before$',
      caseSensitive: false,
    );
    for (final p in parts) {
      if (!re.hasMatch(p))
        return 'Use "1 week before", "3 days before", comma-separated';
    }
    return null;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'work_maintenance',
      onNavigate: (routeKey) {
        final routePath = _getRoutePath(routeKey);
        if (routePath != null) {
          context.go(routePath);
        } else if (routeKey == 'logout') {
          _handleLogout(context);
        }
      },
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                      });
                      _fetchTaskData();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading maintenance task...'),
                    ],
                  ),
                )
              : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Management Title
                    const Text(
                      "Task Management",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildBreadcrumb(),
                    const SizedBox(height: 24),

                    // Main content container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNotificationBanner(),
                          const SizedBox(height: 32),

                          // Task header (title + code + assignee) + status chips
                          _buildTaskHeader(),
                          const SizedBox(height: 32),

                          // Two columns
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildBasicInformationCard(),
                                    const SizedBox(height: 24),
                                    _buildTaskScopeCard(),
                                    const SizedBox(height: 24),
                                    _buildContractorInformationCard(),
                                    const SizedBox(height: 24),
                                    _buildAttachmentsCard(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),

                              // Right column
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildRecurrenceScheduleCard(),
                                    const SizedBox(height: 24),
                                    _buildAssessmentTrackingCard(),
                                    const SizedBox(height: 24),
                                    _buildNotificationsCard(),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Bottom actions: Edit (view) / Cancel+Save (edit)
                          _buildBottomActionBar(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // -------- Breadcrumb --------
  Widget _buildBreadcrumb() {
    return Row(
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
          onPressed: () => context.go('/work/maintenance'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text('Task Management'),
        ),
        const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
        TextButton(
          onPressed: null,
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text('Maintenance Tasks'),
        ),
      ],
    );
  }

  // -------- Notification banner (uses next due) --------
  Widget _buildNotificationBanner() {
    final nextDue = _nextDueCtrl.text.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFF1976D2),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            "Tasks Scheduled",
            style: TextStyle(
              color: Color(0xFF1976D2),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            nextDue.isEmpty ? "Next Service: —" : "Next Service: $nextDue",
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // -------- Task header + status badges --------
  Widget _buildTaskHeader() {
    final taskTitle =
        _currentTaskData['taskTitle']?.toString() ??
        _currentTaskData['task_title']?.toString() ??
        _currentTaskData['title']?.toString() ??
        'External Maintenance Task';

    final assignedTo = 
        _currentTaskData['assigned_to']?.toString() ??
        _currentTaskData['assignedTo']?.toString() ??
        (_contractorNameCtrl.text.isNotEmpty ? _contractorNameCtrl.text : 'External');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side text block
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taskTitle,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.taskId,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              "Assigned To: $assignedTo",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            if (_currentTaskData['priority'] == 'High' ||
                _currentTaskData['priority'] == 'Critical')
              _buildStatusBadge(
                "High Priority",
                const Color(0xFFFFEBEE),
                const Color(0xFFD32F2F),
              ),
            const SizedBox(width: 12),
            if (_currentTaskData['status'] != null)
              _buildStatusBadge(
                _currentTaskData['status'].toString(),
                Colors.grey[200]!,
                Colors.grey[700]!,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    String text,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // -------- Cards (converted rows to editable where appropriate) --------
  Widget _buildBasicInformationCard() {
    return _buildCard(
      icon: Icons.info_outline,
      iconColor: const Color(0xFF1976D2),
      title: "Basic Information",
      child: Column(
        children: [
          // Keep maintenance type view-only (external)
          _viewOnlyRow("Maintenance Type", _maintenanceTypeCtrl.text),
          _editableInfoRow(
            "Service Category",
            _serviceCategoryCtrl,
            validator: _req,
          ),
          _editableInfoRow("Created By", _createdByCtrl, validator: _req),
          _editableInfoRow(
            "Date Created",
            _dateCreatedCtrl,
            validator: _dateValidator,
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceScheduleCard() {
    return _buildCard(
      icon: Icons.calendar_today_outlined,
      iconColor: const Color(0xFF1976D2),
      title: "Recurrence & Schedule",
      child: Column(
        children: [
          _editableInfoRow("Recurrence", _recurrenceCtrl, validator: _req),
          _editableInfoRow(
            "Start Date",
            _startDateCtrl,
            validator: _dateValidator,
          ),
          _editableInfoRow(
            "Next Due Date",
            _nextDueCtrl,
            validator: _dateValidator,
            highlight: true,
          ),
          _editableInfoRow(
            "Service Window",
            _serviceWindowCtrl,
            validator: _serviceWindowValidator,
            hint: 'YYYY-MM-DD to YYYY-MM-DD',
          ),
        ],
      ),
    );
  }

  Widget _buildTaskScopeCard() {
    return _buildCard(
      icon: Icons.location_on_outlined,
      iconColor: Colors.grey[600]!,
      title: "Task Scope & Description",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _editableInfoRow("Location / Area", _locationCtrl, validator: _req),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Task Description",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _isEditMode
              ? TextFormField(
                controller: _descriptionCtrl,
                minLines: 3,
                maxLines: 6,
                validator: _req,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: 'Describe the work to be done...',
                ),
              )
              : Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _descriptionCtrl.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildAssessmentTrackingCard() {
    return Column(
      children: [
        _buildCard(
          icon: Icons.person_outline,
          iconColor: const Color(0xFF1976D2),
          title: "Assessment Tracking",
          child: Column(
            children: [
              // Service Date (Actual)
              _editableInfoRow(
                "Service Date (Actual)",
                _serviceDateActualCtrl,
                validator: _dateValidator,
                trailingCalendarIconWhenView: true,
              ),

              // Assessment Received
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        "Assessment Received",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child:
                          _isEditMode
                              ? Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _assessmentReceived,
                                    isDense: true,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: "Yes",
                                        child: Text("Yes"),
                                      ),
                                      DropdownMenuItem(
                                        value: "No",
                                        child: Text("No"),
                                      ),
                                    ],
                                    onChanged:
                                        (v) => setState(
                                          () =>
                                              _assessmentReceived = v ?? 'Yes',
                                        ),
                                  ),
                                ),
                              )
                              : Text(
                                _assessmentReceived,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                    ),
                  ],
                ),
              ),

              _editableInfoRow("Logged By", _loggedByCtrl, validator: _req),
              _editableInfoRow(
                "Logged Date",
                _loggedDateCtrl,
                validator: _dateValidator,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Assessment (outside card) – editable content
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Assessment",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _isEditMode
                  ? TextFormField(
                      controller: _assessmentNotesCtrl,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'Enter assessment notes...',
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        _assessmentNotesCtrl.text.isNotEmpty 
                            ? _assessmentNotesCtrl.text
                            : 'No assessment notes available.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Recommend (outside card) – editable content
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Recommendations",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _isEditMode
                  ? TextFormField(
                      controller: _recommendationsCtrl,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        hintText: 'Enter recommendations...',
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        _recommendationsCtrl.text.isNotEmpty 
                            ? _recommendationsCtrl.text
                            : 'No recommendations available.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  // Contractor Information (editable)
  Widget _buildContractorInformationCard() {
    return _buildCard(
      icon: Icons.person_outline,
      iconColor: const Color(0xFF1976D2),
      title: "Contractor Information",
      child: Column(
        children: [
          _editableInfoRow(
            "Contractor Name",
            _contractorNameCtrl,
            validator: _req,
          ),
          _editableInfoRow(
            "Contact Person",
            _contractPersonCtrl,
            validator: _req,
          ),
          _editableInfoRow(
            "Phone Number",
            _contractPhoneCtrl,
            validator: _phoneValidator,
          ),
          _editableInfoRow(
            "Email",
            _contractEmailCtrl,
            validator: _emailValidator,
          ),
        ],
      ),
    );
  }

  // Notifications (editable)
  Widget _buildNotificationsCard() {
    return _buildCard(
      icon: Icons.notifications_outlined,
      iconColor: const Color(0xFF1976D2),
      title: "Notifications",
      child: Column(
        children: [
          _editableInfoRow(
            "Admin",
            _adminNotifyCtrl,
            validator: _notifyValidator,
            hint: 'e.g., 1 week before, 3 days before, 1 day before',
          ),
        ],
      ),
    );
  }

  // Attachments - placeholder for future dynamic implementation
  Widget _buildAttachmentsCard() {
    // Get attachments from current task data
    final attachments = _currentTaskData['attachments'] as List<dynamic>? ?? [];
    
    return _buildCard(
      icon: Icons.attach_file_outlined,
      iconColor: Colors.orange,
      title: "Attachments",
      child: attachments.isEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Center(
                child: Text(
                  'No attachments available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          : Column(
              children: attachments.map<Widget>((attachment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAttachmentItem(
                    attachment['filename']?.toString() ?? 'Unknown file',
                    _getFileIcon(attachment['type']?.toString() ?? ''),
                    _getFileColor(attachment['type']?.toString() ?? ''),
                    attachment['type']?.toString() ?? 'FILE',
                  ),
                );
              }).toList(),
            ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.attach_file;
    }
  }

  Color _getFileColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.green;
      case 'doc':
      case 'docx':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAttachmentItem(
    String filename,
    IconData icon,
    Color iconColor,
    String type,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Image File",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              /* TODO: preview/download */
            },
            icon: Icon(
              Icons.visibility_outlined,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // -------- Card wrapper --------
  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // -------- Shared row helpers --------
  Widget _viewOnlyRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              "Maintenance Type",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: highlight ? Colors.red[600] : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableInfoRow(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    String? hint,
    bool highlight = false,
    bool trailingCalendarIconWhenView = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child:
                _isEditMode
                    ? TextFormField(
                      controller: controller,
                      validator: validator,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: hint,
                        border: const OutlineInputBorder(),
                        errorMaxLines: 2,
                      ),
                    )
                    : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            controller.text,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  highlight ? Colors.red[600] : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (trailingCalendarIconWhenView) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.calendar_today_outlined,
                            color: const Color(0xFF1976D2),
                            size: 18,
                          ),
                        ],
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  // -------- Bottom actions --------
  Widget _buildBottomActionBar() {
    if (!_isEditMode) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 200,
            height: 48,
            child: ElevatedButton(
              onPressed: _enterEditMode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Edit Task",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Edit mode: Cancel + Save
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _cancelEdit,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _saveEdit,
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}
