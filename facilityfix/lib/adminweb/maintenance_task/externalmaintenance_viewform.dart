import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../services/api_service.dart';
import 'package:facilityfix/adminweb/widgets/tags.dart';
import '../../utils/ui_format.dart';
import '../../services/api_services.dart' as main_api;
import 'externalmaintenance_form.dart';

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
  final _contractorDeptCtrl = TextEditingController();
  final _contractPhoneCtrl = TextEditingController();
  final _contractEmailCtrl = TextEditingController();

  // loading indicator specifically for fetching staff/contractor details
  bool _isLoadingStaff = false;

  // Snapshot for Cancel
  late Map<String, String> _original;

  // Checklist items for the task (used when opening full edit form)
  List<Map<String, dynamic>> _checklistItems = [];

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
          
          // Ensure assigned contractor/staff details are loaded (if assigned_to is an id)
          Future.microtask(() => _ensureAssignedStaffLoaded());

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
        taskData['task_type']?.toString() ??
        'External';
    _serviceCategoryCtrl.text =
        taskData['service_category']?.toString() ??
        taskData['serviceCategory']?.toString() ??
        taskData['category']?.toString() ?? '';
    _createdByCtrl.text = 
        taskData['created_by']?.toString() ??
        taskData['createdBy']?.toString() ?? 
        'Unknown';
    
  // Fix date created parsing and present as full human date
  final dateCreated = taskData['created_at'] ??
    taskData['date_created'] ??
    taskData['dateCreated'];
  _dateCreatedCtrl.text = _formatDateFull(dateCreated);

    // Recurrence & Schedule - fix mapping
    final recurrence = taskData['recurrence_type']?.toString() ?? 
                       taskData['recurrence']?.toString() ?? '';
    // Capitalize first letter to match display format
    if (recurrence.isNotEmpty) {
      _recurrenceCtrl.text = recurrence.split('_').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    } else {
      _recurrenceCtrl.text = 'None';
    }
    
  _startDateCtrl.text = _formatDateFull(taskData['start_date'] ?? taskData['startDate'] ?? taskData['scheduled_date']);
  _nextDueCtrl.text = _formatDateFull(taskData['next_due_date'] ?? taskData['nextDueDate']);

    // Task Scope & Description
    _locationCtrl.text = 
        taskData['location']?.toString() ?? 
        taskData['area']?.toString() ?? '';
    _descriptionCtrl.text = 
        taskData['task_description']?.toString() ??
        taskData['description']?.toString() ?? '';

    // Assessment Tracking - set default to 'No' if not specified
  _serviceDateActualCtrl.text = _formatDateFull(taskData['service_date_actual'] ?? taskData['serviceDateActual']);
    
    final assessmentValue = taskData['assessment_received']?.toString() ??
                            taskData['assessmentReceived']?.toString();
    _assessmentReceived = (assessmentValue == 'Yes' || assessmentValue == 'No') 
        ? (assessmentValue ?? 'No')
        : 'No';
    
    _loggedByCtrl.text = 
        taskData['logged_by']?.toString() ??
        taskData['loggedBy']?.toString() ?? 
        'Auto-filled';
  _loggedDateCtrl.text = _formatDateFull(taskData['logged_date'] ?? taskData['loggedDate']);

    // Contractor Information
    _contractorNameCtrl.text =
        taskData['contractor_name']?.toString() ??
        taskData['contractorName']?.toString() ??
        taskData['assigned_to']?.toString() ?? '';
    _contractPhoneCtrl.text =
        taskData['contact_number']?.toString() ??
        taskData['contractPhone']?.toString() ?? '';
    _contractEmailCtrl.text = 
        taskData['email']?.toString() ??
        taskData['contractEmail']?.toString() ?? '';
  // Contractor department / assigned department
  _contractorDeptCtrl.text =
    taskData['contractor_department']?.toString() ??
    taskData['assigned_department']?.toString() ??
    taskData['department']?.toString() ?? '';

    // Assessment Notes & Recommendations
    _assessmentNotesCtrl.text =
        taskData['assessment']?.toString() ??
        taskData['assessment_notes']?.toString() ??
        taskData['assessmentNotes']?.toString() ?? '';
    _recommendationsCtrl.text =
        taskData['recommendation']?.toString() ??
        taskData['recommendations']?.toString() ?? '';
  }

  // Ensure we have assigned contractor/staff details when needed (fallback fetch)
  Future<void> _ensureAssignedStaffLoaded() async {
    final assignedId = _currentTaskData['assigned_to']?.toString() ?? _currentTaskData['assignedTo']?.toString();
    if (assignedId == null || assignedId.isEmpty) return;
    // If we already have a contractor name and department populated, skip
    if (_contractorNameCtrl.text.isNotEmpty && _contractorDeptCtrl.text.isNotEmpty) return;

    setState(() => _isLoadingStaff = true);
    try {
      Map<String, dynamic>? staff;
      // Prefer the main API's getUserById which reliably finds user/profile data
      try {
        staff = await main_api.APIService().getUserById(assignedId);
      } catch (_) {
        staff = null;
      }

      if (staff != null && staff.isNotEmpty) {
        final s = staff;
        setState(() {
          final first = (s['first_name'] ?? s['firstName'] ?? '').toString();
          final last = (s['last_name'] ?? s['lastName'] ?? '').toString();
          final name = ('$first $last').trim().isNotEmpty ? ('$first $last').trim() : (s['name'] ?? s['username'] ?? '').toString();
          if (name.isNotEmpty) _contractorNameCtrl.text = name;
          _contractorDeptCtrl.text = (s['staff_department'] ?? s['department'] ?? s['dept'] ?? '').toString();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingStaff = false);
    }
  }
  
  String? _error;

  // Helper method to format dates consistently
  // Format a raw date/string into UiDateUtils.fullDate presentation. Returns empty string if invalid.
  String _formatDateFull(dynamic date) {
    if (date == null) return '';
    try {
      DateTime? dt;
      if (date is DateTime) dt = date;
      else if (date is String && date.isNotEmpty) {
        dt = DateTime.tryParse(date) ?? UiDateUtils.parse(date);
      }
      return dt != null ? UiDateUtils.fullDate(dt) : '';
    } catch (e) {
      return '';
    }
  }

  // Helper to format a raw display string (used in banners) falling back to raw value
  String _formatDateForDisplay(String raw) {
    if (raw.trim().isEmpty) return '';
    try {
      final dt = DateTime.tryParse(raw) ?? UiDateUtils.parse(raw);
      return dt != null ? UiDateUtils.fullDate(dt) : raw;
    } catch (_) {
      return raw;
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
  _contractorDeptCtrl.dispose();
    _contractPhoneCtrl.dispose();
    _contractEmailCtrl.dispose();

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
    'contact_number': _contractPhoneCtrl.text,
    'email': _contractEmailCtrl.text,
    'assessment_notes': _assessmentNotesCtrl.text,
    'recommendations': _recommendationsCtrl.text,
  };

  void _enterEditMode() {
    setState(() => _isEditMode = true);
    // Ensure assigned contractor/staff details are loaded when switching to edit
    Future.microtask(() => _ensureAssignedStaffLoaded());
  }

  void _cancelEdit() {
    // revert to snapshot - guard in case snapshot isn't initialized
    try {
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
      _contractPhoneCtrl.text = s['contact_number']!;
      _contractEmailCtrl.text = s['email']!;

      _assessmentNotesCtrl.text = s['assessment_notes']!;
      _recommendationsCtrl.text = s['recommendations']!;
    } catch (e) {
      print('[ExternalView] _cancelEdit: snapshot unavailable, clearing edits: $e');
      _maintenanceTypeCtrl.text = '';
      _serviceCategoryCtrl.text = '';
      _createdByCtrl.text = '';
      _dateCreatedCtrl.text = '';

      _recurrenceCtrl.text = '';
      _startDateCtrl.text = '';
      _nextDueCtrl.text = '';
      _serviceWindowCtrl.text = '';

      _locationCtrl.text = '';
      _descriptionCtrl.text = '';

      _serviceDateActualCtrl.text = '';
      _assessmentReceived = 'No';
      _loggedByCtrl.text = '';
      _loggedDateCtrl.text = '';

      _contractorNameCtrl.text = '';
      _contractPhoneCtrl.text = '';
      _contractEmailCtrl.text = '';

      _assessmentNotesCtrl.text = '';
      _recommendationsCtrl.text = '';
    }
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
  final nextDue = _formatDateForDisplay(_nextDueCtrl.text.trim());
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
            // Show formatted id (if backend provides it) and the underlying request id.
            Text(
              _currentTaskData['formatted_id'] ?? _currentTaskData['maintenance_id'] ?? widget.taskId,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Date Created: ${_dateCreatedCtrl.text.isNotEmpty ? _dateCreatedCtrl.text : (_currentTaskData['created_at'] ?? _currentTaskData['date_created'] ?? _currentTaskData['dateCreated'] ?? '')}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Use shared tag widgets for status/type/priority
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // StatusTag (uses internal style mapping)
                StatusTag((_currentTaskData?['status'] ?? '').toString()),
                const SizedBox(width: 8),
                // Maintenance type tag
                MaintenanceTypeTag((_currentTaskData?['maintenance_type'] ?? _currentTaskData?['task_type'] ?? 'External').toString()),
                const SizedBox(width: 8),
                // Priority tag (optional)
                if ((_currentTaskData?['priority'] ?? '').toString().trim().isNotEmpty)
                  PriorityTag((_currentTaskData?['priority'] ?? '').toString()),
              ],
            ),
          ],
        ),
      ],
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
        width: 320,
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          // Outlined Back button with clearer affordance
          OutlinedButton.icon(
            onPressed: () {
            try {
              if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              } else {
              context.go('/work/maintenance');
              }
            } catch (e) {
              // fallback: try a simple pop
              try {
              Navigator.of(context).pop();
              } catch (_) {}
            }
            },
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Back',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            ),
            style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF1976D2)),
            foregroundColor: const Color(0xFF1976D2),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            ),
          ),
          const SizedBox(width: 12),
          // Edit task button - kept prominent
            SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: () async {
              // Open the external maintenance form in edit mode and pass the current task data
              try {
                await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ExternalMaintenanceFormPage(
                  maintenanceData: _currentTaskData,
                  isEditMode: true,
                  ),
                ),
                );
              } catch (e, st) {
                print('[ExternalView] Failed to open edit form: $e\n$st');
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open edit form: $e')));
              }
              },
              style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: 3),
                Text(
                "Edit Task",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
              ),
            ),
            ),
          ],
        ),
        ),
      ],
      );
    }

    // Edit mode: Cancel+Edit (open full form) + Save
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () async {
            try {
              // Cancel inline edits safely
              try {
                _cancelEdit();
              } catch (e) {
                setState(() => _isEditMode = false);
              }

              // Prepare edit payload
              final Map<String, dynamic> editData = Map<String, dynamic>.from(_currentTaskData ?? {});
              if ((editData['remarks'] == null || editData['remarks'].toString().isEmpty) && _assessmentNotesCtrl.text.trim().isNotEmpty) {
                editData['remarks'] = _assessmentNotesCtrl.text.trim();
              }

              if (editData['checklist'] == null) {
                if (_checklistItems.isNotEmpty) {
                  editData['checklist'] = _checklistItems.map((e) => {
                        'task': e['task'] ?? e['text'] ?? '',
                        'completed': e['completed'] ?? false,
                      }).toList();
                } else if (editData['checklist_completed'] != null) {
                  editData['checklist'] = editData['checklist_completed'];
                }
              }

              // Ensure dates
              if ((editData['scheduled_date'] == null || editData['scheduled_date'].toString().isEmpty) && _startDateCtrl.text.isNotEmpty) {
                editData['scheduled_date'] = _startDateCtrl.text;
              }
              if ((editData['next_due_date'] == null || editData['next_due_date'].toString().isEmpty) && _nextDueCtrl.text.isNotEmpty) {
                editData['next_due_date'] = _nextDueCtrl.text;
              }

              // Navigate to full edit form
              try {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ExternalMaintenanceFormPage(
                    maintenanceData: editData,
                    isEditMode: true,
                  ),
                ));
              } catch (e, st) {
                print('[ExternalView] Failed to open edit form: $e\n$st');
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open edit form: $e')));
              }
            } catch (e) {
              print('[ExternalView] Cancel+Edit failed: $e');
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
            }
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: const Text('Cancel and Edit Task'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saveEdit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 0,
          ),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
