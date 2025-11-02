import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../services/api_service.dart';
import '../../services/auth_storage.dart';

class ExternalMaintenanceFormPage extends StatefulWidget {
  const ExternalMaintenanceFormPage({super.key});

  @override
  State<ExternalMaintenanceFormPage> createState() =>
      _ExternalMaintenanceFormPageState();
}

class _ExternalMaintenanceFormPageState
    extends State<ExternalMaintenanceFormPage> {
  // ---------- Form + autovalidate gating ----------
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  // ---------- Controllers ----------
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskCodeController = TextEditingController();
  final TextEditingController _createdByController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contractorNameController =
      TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _assessmentController = TextEditingController();
  final TextEditingController _recommendationController =
      TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _maintenanceTypeController =
      TextEditingController();

  // ---------- State (dropdowns/dates) ----------
  String? _selectedServiceCategory;
  DateTime? _dateCreated;
  String? _selectedPriority;
  String? _selectedStatus;
  String? _selectedLocation;
  String? _selectedRecurrence;
  DateTime? _startDate;
  DateTime? _nextDueDate;
  DateTime? _serviceWindowStart;
  DateTime? _serviceWindowEnd;
  DateTime? _serviceDateActual;
  DateTime? _loggedDate;
  String? _selectedAssessmentReceived;
  String? _selectedLoggedBy = 'Auto-filled';
  String? _selectedAdminNotifications;

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // ---------- Options ----------
  final List<String> _serviceCategoryOptions = [
    'HVAC Systems',
    'Electrical Systems',
    'Plumbing',
    'Fire Safety',
    'Security Systems',
    'Elevators',
    'Cleaning Services',
    'Pest Control',
  ];
  final List<String> _priorityOptions = ['Low', 'Medium', 'High', 'Critical'];
  final List<String> _statusOptions = [
    'New',
    'In Progress',
    'Completed',
    'On Hold',
  ];
  final List<String> _locationOptions = [
    'Swimming pool',
    'Basketball Court',
    'Gym',
    'Parking area',
    'Lobby',
    'Elevators',
    'Halls',
    'Garden',
    'Corridors',
  ];
  final List<String> _recurrenceOptions = [
    'Weekly',
    'Monthly',
    '3 Months',
    '6 Months',
    'Yearly',
  ];
  final List<String> _assessmentOptions = ['Yes', 'No', 'Pending'];
  final List<String> _loggedByOptions = [
    'Auto-filled',
    'Manual Entry',
    'System Generated',
  ];
  final List<String> _adminNotificationOptions = [
    'Before due date',
    'On due date',
    '1 day before',
    '1 week before',
  ];

  DateTime _calculateNextDueDate(DateTime base, String frequency) {
    switch (frequency) {
      case 'Weekly':
        return base.add(const Duration(days: 7));
      case 'Monthly':
        return _addMonths(base, 1);
      case '3 Months':
        return _addMonths(base, 3);
      case '6 Months':
        return _addMonths(base, 6);
      case 'Yearly':
        return _addMonths(base, 12);
      default:
        return base;
    }
  }

  DateTime _addMonths(DateTime date, int monthsToAdd) {
    final totalMonths = date.month + monthsToAdd;
    final year = date.year + ((totalMonths - 1) ~/ 12);
    final month = ((totalMonths - 1) % 12) + 1;
    final day = math.min(date.day, _daysInMonth(year, month));
    return DateTime(year, month, day);
  }

  int _daysInMonth(int year, int month) {
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextMonthYear = month == 12 ? year + 1 : year;
    return DateTime(nextMonthYear, nextMonth, 1)
        .subtract(const Duration(days: 1))
        .day;
  }

  void _applyRecurrenceSchedule(String? value) {
    if (value == null) {
      setState(() => _selectedRecurrence = null);
      return;
    }

  final rawStart = _startDate ?? DateTime.now();
  final baseStart = DateTime(rawStart.year, rawStart.month, rawStart.day);
  final nextDue = _calculateNextDueDate(baseStart, value);

    setState(() {
      _selectedRecurrence = value;
      _startDate = baseStart;
      _nextDueDate = nextDue;
      _serviceWindowStart = baseStart;
      _serviceWindowEnd = nextDue;
    });
  }

  void _handleStartDateChange(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);

    setState(() {
      _startDate = normalized;
      if (_selectedRecurrence != null) {
        final nextDue = _calculateNextDueDate(normalized, _selectedRecurrence!);
        _nextDueDate = nextDue;
        _serviceWindowStart = normalized;
        _serviceWindowEnd = nextDue;
      }
    });
  }

  String _formatFriendlyDate(DateTime date) {
    final month = _monthNames[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  String? _recurrenceSummaryText() {
    if (_selectedRecurrence == null || _startDate == null || _nextDueDate == null) {
      return null;
    }

    final start = _formatFriendlyDate(_startDate!);
    final next = _formatFriendlyDate(_nextDueDate!);
    final windowStart = _serviceWindowStart != null
        ? _formatFriendlyDate(_serviceWindowStart!)
        : null;
    final windowEnd = _serviceWindowEnd != null
        ? _formatFriendlyDate(_serviceWindowEnd!)
        : null;

    final buffer = StringBuffer('Repeats $_selectedRecurrence starting $start. Next occurrence $next');
    if (windowStart != null && windowEnd != null) {
      buffer.write(' - Service window $windowStart to $windowEnd');
    }
    return buffer.toString();
  }

  Widget _buildRecurrenceSummary() {
    final summary = _recurrenceSummaryText();
    if (summary == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_repeat, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(color: Colors.blue, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Routing helpers ----------
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
          (_) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/');
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  // ---------- Init: auto-fill automated fields ----------
  final ApiService _apiService = ApiService();
  bool _isLoadingCode = false;

  @override
  void initState() {
    super.initState();
    _maintenanceTypeController.text =
        'External / 3rd-Party'; // automated + read-only
    _dateCreated = DateTime.now(); // prefill but user can change

    _initAutoFields();
  }

  Future<void> _initAutoFields() async {
    setState(() => _isLoadingCode = true);

    try {
      final code = await _apiService.getNextEPMCode();
      _taskCodeController.text = code;

      final profile = await AuthStorage.getProfile();
      if (profile != null && profile['full_name'] != null) {
        _createdByController.text = profile['full_name'];
      } else {
        _createdByController.text = 'Admin User';
      }
    } catch (e) {
      print('[v0] Error initializing auto fields: $e');
      _taskCodeController.text =
          'EPM-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 100000}';
      _createdByController.text = 'Admin User';
    } finally {
      setState(() => _isLoadingCode = false);
    }
  }

  // ---------- Date picker ----------
  Future<void> _selectDate(
    BuildContext context,
    Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) onDateSelected(picked);
  }

  // ---------- Validators ----------
  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(v.trim()) ? null : 'Enter a valid email';
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7 ? null : 'Enter a valid phone';
  }

  // ---------- UI ----------
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & breadcrumb
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Work Management",
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
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 16,
                    ),
                    TextButton(
                      onPressed: () => context.go('/work/maintenance'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Maintenance Tasks'),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 16,
                    ),
                    TextButton(
                      onPressed: null,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('External Maintenance Form'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Main form container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autoValidateMode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Basic Information"),
                      const SizedBox(height: 24),

                      // Task Title + Task Code
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: "Task Title",
                              controller: _taskTitleController,
                              placeholder: "Enter Item Name",
                              validator: _req,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildTextField(
                              label: "Task Code",
                              controller: _taskCodeController,
                              placeholder: "Code Id",
                              enabled: false,
                              validator: _req,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Maintenance Type (auto) + Service Category
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: "Maintenance Type",
                              controller: _maintenanceTypeController,
                              placeholder: "External / 3rd-Party",
                              enabled: false,
                              validator: _req,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildDropdownField(
                              label: "Service Category",
                              value: _selectedServiceCategory,
                              placeholder: "Input",
                              options: _serviceCategoryOptions,
                              onChanged:
                                  (v) => setState(
                                    () => _selectedServiceCategory = v,
                                  ),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Created By (auto) + Date Created (editable)
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: "Created By",
                              controller: _createdByController,
                              placeholder: "Auto-filled",
                              enabled: true,
                              validator: _req,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildDateField(
                              label: "Date Created",
                              selectedDate: _dateCreated,
                              placeholder: "DD / MM / YY",
                              onDateSelected:
                                  (d) => setState(() => _dateCreated = d),
                              enabled: true,
                              requiredField: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Priority + Status
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: "Priority",
                              value: _selectedPriority,
                              placeholder: "Select Priority...",
                              options: _priorityOptions,
                              onChanged:
                                  (v) => setState(() => _selectedPriority = v),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildDropdownField(
                              label: "Status",
                              value: _selectedStatus,
                              placeholder: "Select Status...",
                              options: _statusOptions,
                              onChanged:
                                  (v) => setState(() => _selectedStatus = v),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Service Scope & Description
                      _buildSectionTitle("Service Scope & Description"),
                      const SizedBox(height: 24),

                      _buildDropdownField(
                        label: "Location / Area",
                        value: _selectedLocation,
                        placeholder: "Select Department...",
                        options: _locationOptions,
                        onChanged: (v) => setState(() => _selectedLocation = v),
                        fullWidth: true,
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),

                      _buildTextAreaField(
                        label: "Description",
                        controller: _descriptionController,
                        placeholder: "Enter Description...",
                        validator: _req,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: _buildTextField(
                          label: "Responsible Department",
                          controller: _departmentController,
                          placeholder: "Enter Department",
                          validator: _req,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Contractor Info
                      _buildSectionTitle("Contractor Information"),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: "Contractor (Company) Name",
                              controller: _contractorNameController,
                              placeholder: "Enter Name",
                              validator: _req,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: "Contact Number",
                              controller: _contactNumberController,
                              placeholder: "Input Contact Number",
                              validator: _phoneValidator,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildTextField(
                              label: "Email",
                              controller: _emailController,
                              placeholder: "Input Email",
                              validator: _emailValidator,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Recurrence & Schedule
                      _buildSectionTitle("Recurrence & Schedule"),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: "Recurrence",
                              value: _selectedRecurrence,
                              placeholder: "Input",
                              options: _recurrenceOptions,
                              onChanged: _applyRecurrenceSchedule,
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildDateField(
                              label: "Start Date",
                              selectedDate: _startDate,
                              placeholder: "DD / MM / YY",
                              onDateSelected: _handleStartDateChange,
                              requiredField: true,
                            ),
                          ),
                        ],
                      ),
                      _buildRecurrenceSummary(),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: "Next Due Date",
                              selectedDate: _nextDueDate,
                              placeholder: "DD / MM / YY",
                              onDateSelected:
                                  (d) => setState(() => _nextDueDate = d),
                              requiredField: true,
                              enabled: false,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Service Window",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDateField(
                                        label: "",
                                        selectedDate: _serviceWindowStart,
                                        placeholder: "DD / MM / YY",
                                        onDateSelected:
                                            (d) => setState(
                                              () => _serviceWindowStart = d,
                                            ),
                                        showLabel: false,
                                        enabled: false,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDateField(
                                        label: "",
                                        selectedDate: _serviceWindowEnd,
                                        placeholder: "DD / MM / YY",
                                        onDateSelected:
                                            (d) => setState(
                                              () => _serviceWindowEnd = d,
                                            ),
                                        showLabel: false,
                                        enabled: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Post-Service Assessment Logging
                      _buildSectionTitle("Post-Service Assessment Logging"),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Information",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "These fields will be filled after the 3rd-party service visit is completed",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: "Service Date (Actual)",
                              selectedDate: _serviceDateActual,
                              placeholder: "Auto-generated",
                              onDateSelected:
                                  (d) => setState(() => _serviceDateActual = d),
                              enabled: false, // automated
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildDropdownField(
                              label: "Assessment Received",
                              value: _selectedAssessmentReceived,
                              placeholder: "Input",
                              options: _assessmentOptions,
                              onChanged:
                                  (v) => setState(
                                    () => _selectedAssessmentReceived = v,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: "Logged By",
                              value: _selectedLoggedBy,
                              placeholder: "Auto-filled",
                              options: _loggedByOptions,
                              onChanged: (_) {}, // disabled visually below
                              enabled: false, // automated
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildDateField(
                              label: "Logged Date",
                              selectedDate: _loggedDate,
                              placeholder: "Auto-generated",
                              onDateSelected:
                                  (d) => setState(() => _loggedDate = d),
                              enabled: false, // automated
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextAreaField(
                              label: "Assessment",
                              controller: _assessmentController,
                              placeholder: "Enter Assessment...",
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildTextAreaField(
                              label: "Recommendation",
                              controller: _recommendationController,
                              placeholder: "Enter Recommendation...",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // // Attachments
                      // _buildSectionTitle("Attachments"),
                      // const SizedBox(height: 24),

                      // Container(
                      //   height: 120,
                      //   width: double.infinity,
                      //   decoration: BoxDecoration(
                      //     border: Border.all(
                      //       color: Colors.grey[300]!,
                      //       width: 2,
                      //     ),
                      //     borderRadius: BorderRadius.circular(8),
                      //   ),
                      //   child: Column(
                      //     mainAxisAlignment: MainAxisAlignment.center,
                      //     children: [
                      //       Icon(
                      //         Icons.cloud_upload_outlined,
                      //         size: 32,
                      //         color: Colors.grey[400],
                      //       ),
                      //       const SizedBox(height: 8),
                      //       const Text(
                      //         "Drop files here or click to upload",
                      //         style: TextStyle(
                      //           fontSize: 14,
                      //           color: Colors.black54,
                      //         ),
                      //       ),
                      //       const SizedBox(height: 4),
                      //       Text(
                      //         "PDF, PNG, JPG up to 10MB",
                      //         style: TextStyle(
                      //           fontSize: 12,
                      //           color: Colors.grey[500],
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      // const SizedBox(height: 40),

                      // Notifications
                      _buildSectionTitle("Notifications"),
                      const SizedBox(height: 24),

                      _buildDropdownField(
                        label: "Admin Notifications",
                        value: _selectedAdminNotifications,
                        placeholder: "Before due date",
                        options: _adminNotificationOptions,
                        onChanged:
                            (v) =>
                                setState(() => _selectedAdminNotifications = v),
                        fullWidth: true,
                      ),
                      const SizedBox(height: 40),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _saveDraft,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(
                                  color: Colors.blue,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Save Draft',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 100,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _onNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Actions ----------
  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _onNext() async {
    setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);

    if ((_serviceWindowStart != null && _serviceWindowEnd == null) ||
        (_serviceWindowEnd != null && _serviceWindowStart == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete both Service Window dates.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_serviceWindowStart != null &&
        _serviceWindowEnd != null &&
        _serviceWindowEnd!.isBefore(_serviceWindowStart!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service Window end must be after start.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the highlighted fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_dateCreated == null || _startDate == null || _nextDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select required dates.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String formatDate(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

  final scheduledDateIso = _startDate!.toUtc().toIso8601String();

  final taskData = {
    'task_code': _taskCodeController.text.trim(),
    'task_title': _taskTitleController.text.trim(),
    'task_description': _descriptionController.text.trim(),
    'maintenance_type': 'external',
    'service_category': _selectedServiceCategory,
    'created_by': _createdByController.text.trim(),
    'priority': _selectedPriority ?? 'medium',
    'status': _selectedStatus ?? 'scheduled',
    'location': _selectedLocation ?? '',
    
    // Contractor Information
    'contractor_name': _contractorNameController.text.trim(),
    'contact_person': _contactPersonController.text.trim(),
    'contact_number': _contactNumberController.text.trim(),
    'email': _emailController.text.trim(),
    
    // Scheduling Information
    'recurrence_type': _selectedRecurrence != null
        ? _selectedRecurrence!.toLowerCase()
        : 'none',
    'start_date': formatDate(_startDate!),
    'scheduled_date': scheduledDateIso,
    'next_due_date': formatDate(_nextDueDate!),
    'service_window_start':
      _serviceWindowStart != null ? formatDate(_serviceWindowStart!) : null,
    'service_window_end':
      _serviceWindowEnd != null ? formatDate(_serviceWindowEnd!) : null,
    
    // Assessment and Tracking
    'assessment_received': _selectedAssessmentReceived,
    'logged_by': _selectedLoggedBy,
    'logged_date': _loggedDate != null ? formatDate(_loggedDate!) : null,
    'assessment': _assessmentController.text.trim(),
    'recommendation': _recommendationController.text.trim(),
    
    // Department and Admin
    'department': _departmentController.text.trim(),
    'admin_notification': _selectedAdminNotifications,
    
    // System Fields
    'building_id': 'default_building',
    'task_type': 'external',
    'category': _selectedServiceCategory ?? 'maintenance',
    'assigned_to': _contractorNameController.text.trim(),
    
    // Required Arrays
    'checklist_completed': <Map<String, dynamic>>[],
    'parts_used': <Map<String, dynamic>>[],
    'tools_used': <String>[],
    'photos': <String>[],
  };

    try {
      final result = await _apiService.createMaintenanceTask(taskData);
      final createdTask =
          result['task'] is Map<String, dynamic>
              ? result['task'] as Map<String, dynamic>
              : null;
      final createdId =
          createdTask?['id'] ?? result['id'] ?? result['task_id'];
      print('[v0] External maintenance task created: $createdId');

      if (mounted) {
        context.push(
          '/work/maintenance',
          extra: taskData,
        );
      }
    } catch (e) {
      print('[v0] Error creating external maintenance task: $e');
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

  // ---------- Shared UI helpers ----------
  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
  );

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: enabled ? Colors.white : Colors.grey[50],
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            validator: validator,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon:
                  _isLoadingCode && controller == _taskCodeController
                      ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String placeholder,
    required List<String> options,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
    bool fullWidth = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 48,
          width: fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: enabled ? Colors.white : Colors.grey[50],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            validator: validator,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            dropdownColor: Colors.white,
            items:
                options
                    .map(
                      (opt) => DropdownMenuItem(value: opt, child: Text(opt)),
                    )
                    .toList(),
            onChanged: enabled ? onChanged : null,
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required String placeholder,
    required Function(DateTime) onDateSelected,
    bool enabled = true,
    bool showLabel = true,
    bool requiredField = false,
  }) {
    return FormField<DateTime>(
      validator: (_) {
        if (!requiredField) return null;
        return (selectedDate == null) ? 'Required' : null;
      },
      builder: (state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLabel && label.isNotEmpty) ...[
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(
                  color: hasError ? Colors.red : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(8),
                color: enabled ? Colors.white : Colors.grey[50],
              ),
              child: InkWell(
                onTap:
                    enabled
                        ? () => _selectDate(context, (d) {
                          onDateSelected(d);
                          state.didChange(d);
                        })
                        : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: enabled ? Colors.blue : Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedDate != null
                              ? "${selectedDate.day.toString().padLeft(2, '0')} / ${selectedDate.month.toString().padLeft(2, '0')} / ${selectedDate.year.toString().substring(2)}"
                              : placeholder,
                          style: TextStyle(
                            color:
                                selectedDate != null
                                    ? Colors.black87
                                    : Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Text(
                state.errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTextAreaField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Dispose ----------
  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskCodeController.dispose();
    _createdByController.dispose();
    _descriptionController.dispose();
    _contractorNameController.dispose();
    _contactPersonController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _assessmentController.dispose();
    _recommendationController.dispose();
    _departmentController.dispose();
    _maintenanceTypeController.dispose();
    super.dispose();
  }
}
