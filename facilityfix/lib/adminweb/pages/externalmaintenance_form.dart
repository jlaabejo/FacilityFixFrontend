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

  // For consistent field heights
  static const double _kFieldHeight = 48;

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
  final TextEditingController _otherLocationController = TextEditingController();
  final TextEditingController _otherServiceCategoryController = TextEditingController();
  final TextEditingController _estimatedDurationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _nextDueDateController = TextEditingController();

  // ---------- State (dropdowns/dates) ----------
  String? _selectedServiceCategory;
  DateTime? _dateCreated;
  String? _selectedPriority;
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
  bool _isOtherLocation = false;
  bool _isOtherServiceCategory = false;

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
    'Other',
  ];
  final List<String> _priorityOptions = ['Low', 'Medium', 'High'];
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
    'Other',
  ];
  final List<String> _assessmentOptions = ['Yes', 'No', 'Pending'];
  final List<String> _loggedByOptions = [
    'Auto-filled',
    'Manual Entry',
    'System Generated',
  ];

  DateTime _calculateNextDueDate(DateTime base, String frequency) {
    switch (frequency) {
      case 'Daily':
        return base.add(const Duration(days: 1));
      case 'Weekly':
        return base.add(const Duration(days: 7));
      case 'Monthly':
        return _addMonths(base, 1);
      case 'Quarterly':
        return _addMonths(base, 3);
      case 'Annually':
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

  // Auto-generate notifications based on task duration
  void _updateNotifications() {
    if (_startDate == null) return;
    
    final now = DateTime.now();
    final daysUntilStart = _startDate!.difference(now).inDays;
    
    // Auto-generate notification schedule based on time until task
    List<String> notifications = [];
    
    if (daysUntilStart >= 30) {
      notifications.add('1 month before');
    }
    if (daysUntilStart >= 7) {
      notifications.add('1 week before');
    }
    if (daysUntilStart >= 5) {
      notifications.add('5 days before');
    }
    if (daysUntilStart >= 3) {
      notifications.add('3 days before');
    }
    if (daysUntilStart >= 1) {
      notifications.add('1 day before');
    }
    
    setState(() {
      if (notifications.isNotEmpty) {
        _selectedAdminNotifications = notifications.join(', ');
      } else {
        _selectedAdminNotifications = 'On due date';
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

  void _handleRecurrenceChange(String? value) {
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
      _startDateController.text = _formatDateYYYYMMDD(baseStart);
      _nextDueDateController.text = _formatDateYYYYMMDD(nextDue);
      _updateNotifications(); // Auto-update notifications
    });
  }

  void _handleStartDateChange(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);

    setState(() {
      _startDate = normalized;
      _startDateController.text = _formatDateYYYYMMDD(normalized);
      
      if (_selectedRecurrence != null) {
        final nextDue = _calculateNextDueDate(normalized, _selectedRecurrence!);
        _nextDueDate = nextDue;
        _nextDueDateController.text = _formatDateYYYYMMDD(nextDue);
      }
      _updateNotifications(); // Auto-update notifications
    });
  }

  String _formatDateYYYYMMDD(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate({
    required DateTime initial,
    required Function(DateTime) onPick,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) onPick(picked);
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
    _dateCreated = DateTime.now(); // prefill but user can change
    _selectedAssessmentReceived = 'No'; // Auto-set to "No" when task is created

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
                  "Work Orders",
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
                      child: const Text('Work Orders'),
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
                      child: const Text('Maintenance Tasks'),
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
                    color: Colors.black.withOpacity(0.05),
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
                      _buildSectionHeader(
                        "Basic Information",
                        "General details about the maintenance task",
                      ),
                      const SizedBox(height: 24),

                      // Task Title + Task Code
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: "Task Title",
                              controller: _taskTitleController,
                              placeholder: "Enter Task Title",
                              validator: _req,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildTextField(
                              label: "Task Code",
                              controller: _taskCodeController,
                              placeholder: "Auto-generated",
                              enabled: false,
                              validator: _req,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Created By + Date Created
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: "Created By",
                              controller: _createdByController,
                              placeholder: "Auto-filled",
                              enabled: false,
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

                      // Priority only (Status auto-set to "New")
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
                          const Expanded(child: SizedBox()), // Empty space on right
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),
                      const SizedBox(height: 32),

                      // Task Scope & Description
                      _buildSectionHeader(
                        "Task Scope & Description",
                        "Detailed description of what needs to be done",
                      ),
                      const SizedBox(height: 24),

                      // Location/Area on left, Service Category on right
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: "Location / Area",
                              value: _selectedLocation,
                              placeholder: "Select Location...",
                              options: _locationOptions,
                              onChanged: (v) {
                                setState(() {
                                  _selectedLocation = v;
                                  _isOtherLocation = (v == 'Other');
                                  if (!_isOtherLocation) {
                                    _otherLocationController.clear();
                                  }
                                });
                              },
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildDropdownField(
                              label: "Service Category",
                              value: _selectedServiceCategory,
                              placeholder: "Select Category...",
                              options: _serviceCategoryOptions,
                              onChanged: (v) {
                                setState(() {
                                  _selectedServiceCategory = v;
                                  _isOtherServiceCategory = (v == 'Other');
                                  if (!_isOtherServiceCategory) {
                                    _otherServiceCategoryController.clear();
                                  }
                                });
                              },
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      
                      // Show custom location input if "Other" is selected
                      if (_isOtherLocation) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Specify Location',
                                controller: _otherLocationController,
                                placeholder: 'Enter custom location...',
                                validator: _req,
                              ),
                            ),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      ],
                      
                      // Show custom service category input if "Other" is selected
                      if (_isOtherServiceCategory) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: SizedBox()),
                            Expanded(
                              child: _buildTextField(
                                label: 'Specify Service Category',
                                controller: _otherServiceCategoryController,
                                placeholder: 'Enter custom category...',
                                validator: _req,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

                      _buildTextAreaField(
                        label: "Description",
                        controller: _descriptionController,
                        placeholder: "Enter Description...",
                        validator: _req,
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),
                      const SizedBox(height: 32),

                      // Contractor Info
                      _buildSectionHeader(
                        "Contractor Information",
                        "Details of the external contractor assigned to this task or a company",
                      ),
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
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),
                      const SizedBox(height: 32),

                      // Recurrence & Schedule
                      _buildSectionHeader(
                        "Recurrence & Schedule",
                        "Define when and how often this maintenance task occurs",
                      ),
                      const SizedBox(height: 24),

                      // Row 1: Recurrence and Estimated Duration
                      Row(
                        children: [
                          // Recurrence
                          Expanded(
                            child: _buildDropdownField(
                              label: 'Recurrence Frequency',
                              value: _selectedRecurrence,
                              placeholder: 'Select frequency...',
                              options: const [
                                'Daily',
                                'Weekly',
                                'Monthly',
                                'Quarterly',
                                'Annually',
                              ],
                              onChanged: _handleRecurrenceChange,
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Estimated Duration
                          Expanded(
                            child: _buildTextField(
                              label: 'Estimated Duration',
                              controller: _estimatedDurationController,
                              placeholder: 'e.g., 3 hrs / 45 mins',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Row 2: Start Date and Next Due Date
                      Row(
                        children: [
                          // Start Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Start Date'),
                                Container(
                                  height: _kFieldHeight,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextFormField(
                                    controller: _startDateController,
                                    validator: _req,
                                    readOnly: true,
                                    onTap: () => _pickDate(
                                      initial: _startDate ?? DateTime.now(),
                                      onPick: _handleStartDateChange,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'YYYY-MM-DD',
                                      hintStyle: TextStyle(color: Colors.grey[240], fontSize: 14),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      suffixIcon: const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Next Due Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Next Due Date'),
                                Container(
                                  height: _kFieldHeight,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[50],
                                  ),
                                  child: TextFormField(
                                    controller: _nextDueDateController,
                                    validator: _req,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: 'YYYY-MM-DD',
                                      hintStyle: TextStyle(color: Colors.grey[240], fontSize: 14),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      suffixIcon: const Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      _buildRecurrenceSummary(),
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),
                      const SizedBox(height: 32),

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
                      const SizedBox(height: 32),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _onCancel,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                  fontSize: 15,
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
  void _onCancel() {
    context.go('/work/maintenance');
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
    if (_dateCreated == null || _startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select required dates.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get actual location (use Other input if selected)
    final actualLocation = _isOtherLocation 
        ? _otherLocationController.text.trim()
        : (_selectedLocation ?? '');
    
    // Get actual service category (use Other input if selected)
    final actualServiceCategory = _isOtherServiceCategory 
        ? _otherServiceCategoryController.text.trim()
        : (_selectedServiceCategory ?? '');

    String formatDate(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

  final scheduledDateIso = _startDate!.toUtc().toIso8601String();

  final taskData = {
    'task_code': _taskCodeController.text.trim(),
    'task_title': _taskTitleController.text.trim(),
    'task_description': _descriptionController.text.trim(),
    'maintenance_type': 'external',
    'service_category': actualServiceCategory,
    'created_by': _createdByController.text.trim(),
    'priority': _selectedPriority ?? 'medium',
    'status': 'New', // Auto-set to "New" for external maintenance
    'location': actualLocation,
    
    // Contractor Information
    'contractor_name': _contractorNameController.text.trim(),
    'contact_person': _contactPersonController.text.trim(),
    'contact_number': _contactNumberController.text.trim(),
    'email': _emailController.text.trim(),
    
    // Scheduling Information
    'recurrence_type': _selectedRecurrence?.toLowerCase() ?? 'none',
    'start_date': formatDate(_startDate!),
    'scheduled_date': scheduledDateIso,
    'next_due_date': _nextDueDate != null ? formatDate(_nextDueDate!) : null,
    'estimated_duration': _estimatedDurationController.text.trim(),
    
    // Assessment and Tracking
    'assessment_received': _selectedAssessmentReceived,
    'logged_by': _selectedLoggedBy,
    'logged_date': _loggedDate != null ? formatDate(_loggedDate!) : null,
    'assessment': _assessmentController.text.trim(),
    'recommendation': _recommendationController.text.trim(),
    
    // Admin Notifications (Auto-generated from start date)
    'admin_notification': _selectedAdminNotifications,
    
    // System Fields
    'building_id': 'default_building',
    'task_type': 'external',
    'category': actualServiceCategory,
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
  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
  );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400]),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      borderSide: const BorderSide(color: Colors.blue),
    ),
  );

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
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
        _fieldLabel(label),
        SizedBox(
          height: _kFieldHeight,
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            validator: validator,
            decoration: _decoration(placeholder).copyWith(
              filled: !enabled,
              fillColor: enabled ? Colors.white : Colors.grey[50],
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
        if (label.isNotEmpty) _fieldLabel(label),
        SizedBox(
          height: _kFieldHeight,
          width: fullWidth ? double.infinity : null,
          child: DropdownButtonFormField<String>(
            value: value,
            validator: validator,
            decoration: _decoration(placeholder).copyWith(
              filled: !enabled,
              fillColor: enabled ? Colors.white : Colors.grey[50],
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
            if (showLabel && label.isNotEmpty) _fieldLabel(label),
            SizedBox(
              height: _kFieldHeight,
              child: InkWell(
                onTap:
                    enabled
                        ? () => _selectDate(context, (d) {
                          onDateSelected(d);
                          state.didChange(d);
                        })
                        : null,
                child: InputDecorator(
                  decoration: _decoration(placeholder).copyWith(
                    filled: !enabled,
                    fillColor: enabled ? Colors.white : Colors.grey[50],
                    errorText: hasError ? state.errorText : null,
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
        _fieldLabel(label),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: 5,
          decoration: _decoration(placeholder),
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
    _otherLocationController.dispose();
    _otherServiceCategoryController.dispose();
    _estimatedDurationController.dispose();
    _startDateController.dispose();
    _nextDueDateController.dispose();
    super.dispose();
  }
}
