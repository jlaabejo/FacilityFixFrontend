import 'dart:async';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/tenant/announcement.dart';
import 'package:facilityfix/tenant/home.dart';
import 'package:facilityfix/tenant/profile.dart';
import 'package:facilityfix/tenant/repair_management.dart';
import 'package:facilityfix/widgets/buttons.dart' as fx;
import 'package:facilityfix/widgets/forms.dart';
import 'package:facilityfix/widgets/modals.dart'; // CustomPopup
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:facilityfix/utils/ui_format.dart';

class RequestForm extends StatefulWidget {
  /// Allowed: "Concern Slip", "Job Service", "Work Order"
  final String requestType;
  
  /// Optional concern slip ID for linking Job Service to existing concern slip
  final String? concernSlipId;

  /// Optional: Initial data for editing existing requests
  final Map<String, dynamic>? initialData;

  /// Optional: Request ID when editing
  final String? requestId;

  /// Whether this is an edit operation
  final bool isEditing;
  /// If true, the form will return to the caller after successful submit instead
  /// of redirecting to the Repair Request Management page. Callers that want to
  /// handle post-submit navigation (for example to refresh a parent view) can
  /// set this to true.
  final bool returnToCallerOnSuccess;

  const RequestForm({
    super.key, 
    required this.requestType, 
    this.concernSlipId,
    this.initialData,
    this.requestId,
    this.isEditing = false,
    this.returnToCallerOnSuccess = false,
  });

  @override
  State<RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<RequestForm> {
  final int _selectedIndex = 1;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.person),
  ];

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const ProfilePage(),
    ];
    if (index != 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title with info icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF0EA5E9),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Request Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Request type definitions
            const Text(
              'Request Types',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              'Concern Slip',
              'The initial report or request for repair raised by a tenant.',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              'Job Service',
              'An internal maintenance task assigned to in-house staff for inspection or repair.',
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              'Work Order',
              'A permit or request issued for outsourced or external service providers to perform the required work.',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF667085),
            fontFamily: 'Inter',
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ----- Form + validation -----
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false; // <- drives inline error visibility
  bool _isSubmitting = false;
  bool _isLoadingUserData = true;

  // AI categorization results
  String _aiCategory = '';
  String _aiPriority = '';
  bool _isAnalyzing = false;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  final List<String> _requestTypes = const [
    'Air Conditioning',
    'Electrical',
    'Civil/Carpentry',
    'Plumbing',
    'Others',
  ];

  // Date/Time picking for availability range (Mon-Sat, 9am-5pm, only future dates)
  Future<void> _pickAvailabilityRange(TextEditingController controller) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Only allow picking dates after today (not today), and only Mon-Sat
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 1)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
      selectableDayPredicate: (date) {
        // Only allow Monday (1) to Saturday (6)
        return date.weekday >= 1 && date.weekday <= 6 && date.isAfter(today);
      },
    );
    if (pickedDate == null) return;

    // Helper to clamp time to 9:00-17:00
    TimeOfDay _clampToRange(TimeOfDay t) {
      int hour = t.hour;
      int minute = t.minute;
      if (hour < 9) return const TimeOfDay(hour: 9, minute: 0);
      if (hour > 17 || (hour == 17 && minute > 0)) return const TimeOfDay(hour: 17, minute: 0);
      return TimeOfDay(hour: hour, minute: minute);
    }

    // Pick start time (9:00-17:00 only)
    final TimeOfDay? startTimeRaw = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Select start time (9:00 AM - 5:00 PM)',
    );
    if (startTimeRaw == null) return;
    final startTime = _clampToRange(startTimeRaw);
    if (startTime.hour < 9 || startTime.hour > 17) {
      _showSnack('Start time must be between 9:00 AM and 5:00 PM');
      return;
    }

    // Pick end time (must be after start, 9:00-17:00 only)
    final TimeOfDay? endTimeRaw = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (startTime.hour + 2 > 17) ? 17 : startTime.hour + 2, minute: startTime.minute),
      helpText: 'Select end time (9:00 AM - 5:00 PM)',
    );
    if (endTimeRaw == null) return;
    final endTime = _clampToRange(endTimeRaw);
    if (endTime.hour < 9 || endTime.hour > 17) {
      _showSnack('End time must be between 9:00 AM and 5:00 PM');
      return;
    }

    // Validate that end time is after start time
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    if (endMinutes <= startMinutes) {
      _showSnack('End time must be after start time');
      return;
    }

    // Format the range
    final dateStr = DateFormat('MMM d, yyyy').format(pickedDate);
    final startTimeStr = _formatTimeOfDay(startTime);
    final endTimeStr = _formatTimeOfDay(endTime);

    setState(() {
      controller.text = '$dateStr $startTimeStr - $endTimeStr';
      // Recompute inline errors after picking a date
      _formKey.currentState?.validate();
    });
  }

  // Date/Time picking for single date/time (for other forms)
  Future<void> _pickDateTimeInto(TextEditingController controller) async {
    final now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (pickedTime == null) return;

    final dt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      controller.text = DateFormat('MMM d, yyyy h:mm a').format(dt);
      // Recompute inline errors after picking a date
      _formKey.currentState?.validate();
    });
  }

  // Date picking only (for Work Order Valid From/To)
  Future<void> _pickDateOnly(TextEditingController controller) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Only allow selecting Monday (1) to Saturday (6) and no past dates
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: today.isAfter(DateTime(2020)) ? today : DateTime(2020),
      firstDate: today,
      lastDate: DateTime(2100),
      selectableDayPredicate: (date) {
        return date.weekday >= DateTime.monday && date.weekday <= DateTime.saturday;
      },
    );
    if (pickedDate == null) return;

    setState(() {
      controller.text = DateFormat('MMM d, yyyy').format(pickedDate);
      // Recompute inline errors after picking a date
      _formKey.currentState?.validate();
    });
  }

  // Helper method to format TimeOfDay
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : hour;
    return '$displayHour:$minute $period';
  }

  // Controllers
  final TextEditingController reqIdController = TextEditingController();
  final TextEditingController dateRequestedController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController availabilityController = TextEditingController();
  final TextEditingController permitIdController = TextEditingController();
  final TextEditingController validFromController = TextEditingController();
  final TextEditingController validToController = TextEditingController();
  final TextEditingController contractorNameController = TextEditingController();
  final TextEditingController contractorNumberController = TextEditingController();
  final TextEditingController contractorEmailController = TextEditingController();
  final TextEditingController othersRequestTypeController = TextEditingController();

  // Local state
  String _requestTypeValue = ''; // dropdown selection for work order type
  bool _hasContractors = false; // list not empty?
  List<Map<String, String>> _contractors = []; // Store contractor list
  PlatformFile? selectedFile;
  List<PlatformFile> _attachments = []; // Store selected attachments

  @override
  void initState() {
    super.initState();
    _loadUserDataAndGenerateId();

    // Listen to description changes for AI categorization (only for Concern Slip)
    if (widget.requestType == 'Concern Slip') {
      descriptionController.addListener(_onDescriptionChanged);
      titleController.addListener(_onDescriptionChanged);
    }
  }

  void _onDescriptionChanged() {
    // Debounce AI analysis
    Timer(const Duration(milliseconds: 1000), () {
      if (mounted &&
          (titleController.text.trim().isNotEmpty ||
              descriptionController.text.trim().isNotEmpty)) {
        _analyzeWithAI();
      }
    });
  }

  Future<void> _analyzeWithAI() async {
    if (_isAnalyzing) return;

    setState(() => _isAnalyzing = true);

    try {
      final combinedText =
          '${descriptionController.text.trim()}';
      if (combinedText.trim().isEmpty) return;

      print('[AI] Analyzing: $combinedText');

      // Use API service for AI analysis
      final apiService = APIService();
      final result = await apiService.analyzeConcernWithAI(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _aiCategory = result['cat_argmax'] ?? 'General';
          _aiPriority = result['urg_argmax'] ?? 'Medium';
        });
        print('[AI] Category: $_aiCategory, Priority: $_aiPriority');
      }
    } catch (e) {
      print('[AI] Analysis error: $e');
      // Fallback to local analysis
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _loadUserDataAndGenerateId() async {
    setState(() => _isLoadingUserData = true);

    try {
      // If editing, use initial data
      if (widget.isEditing && widget.initialData != null) {
        final data = widget.initialData!;
        
        // Pre-fill all fields with existing data
        reqIdController.text = data['formatted_id'] ?? widget.requestId ?? data['id'] ?? '';
        
        if (data['created_at'] != null) {
          try {
            final createdAt = DateTime.parse(data['created_at']);
            dateRequestedController.text = DateFormat('MMM d, yyyy h:mm a').format(createdAt);
          } catch (e) {
            dateRequestedController.text = data['created_at'];
          }
        }
        
        unitController.text = data['unit_id'] ?? '';
        nameController.text = data['requested_by'] ?? data['reported_by_name'] ?? '';
        titleController.text = data['title'] ?? '';
        descriptionController.text = data['description'] ?? '';
        availabilityController.text = data['schedule_availability'] ?? '';
        
        // Work Order specific fields
        if (widget.requestType == 'Work Order') {
          permitIdController.text = data['formatted_id'] ?? data['id'] ?? '';
          contractorNameController.text = data['contractor_name'] ?? '';
          contractorNumberController.text = data['contractor_number'] ?? '';
          contractorEmailController.text = data['contractor_email'] ?? '';
          
          if (data['work_schedule_from'] != null) {
            try {
              final from = DateTime.parse(data['work_schedule_from']);
              validFromController.text = DateFormat('MMM d, yyyy h:mm a').format(from);
            } catch (e) {
              validFromController.text = data['work_schedule_from'];
            }
          }
          
          if (data['work_schedule_to'] != null) {
            try {
              final to = DateTime.parse(data['work_schedule_to']);
              validToController.text = DateFormat('MMM d, yyyy h:mm a').format(to);
            } catch (e) {
              validToController.text = data['work_schedule_to'];
            }
          }
        }
        
        // Set request type for dropdowns
        _requestTypeValue = data['category'] ?? data['department_tag'] ?? '';
        
        setState(() => _isLoadingUserData = false);
        return;
      }
      
      // Original logic for creating new requests
      // Generate auto-incrementing ID based on request type
      final now = DateTime.now();
      final year = now.year;

      final apiService = APIService();
      String formattedId;

      try {
        switch (widget.requestType) {
          case 'Concern Slip':
            formattedId = await apiService.getNextConcernSlipId();
            break;
          case 'Job Service':
            formattedId = await apiService.getNextJobServiceId();
            break;
          case 'Work Order':
            formattedId = await apiService.getNextWorkOrderId();
            break;
          default:
            formattedId = 'REQ-$year-00001';
        }
      } catch (e) {
        print('Error getting next ID from backend: $e');
        // Fallback ID generation
        final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
        final prefix = widget.requestType == 'Concern Slip'
            ? 'CS'
            : widget.requestType == 'Job Service'
                ? 'JS'
                : 'WP';
        formattedId = '$prefix-$year-${dayOfYear.toString().padLeft(5, '0')}';
      }

      // Set date requested (formatted as fullDate)
      dateRequestedController.text = UiDateUtils.fullDate(now);
      reqIdController.text = formattedId;

      // Load user profile data
      final profile = await AuthStorage.getProfile();
      if (profile != null) {
        // Populate user information
        final firstName = profile['first_name'] ?? '';
        final lastName = profile['last_name'] ?? '';
        final fullName = '$firstName $lastName'.trim();

        nameController.text = fullName.isNotEmpty ? fullName : 'User';

        // Format building and unit
        final buildingUnit = profile['building_unit'] ?? '';
        unitController.text =
            buildingUnit.isNotEmpty ? buildingUnit : 'Tower A - Unit 10B';
      } else {
        // Fallback values
        nameController.text = 'John Doe';
        unitController.text = 'Tower A - Unit 10B';
      }

      // For Work Order -> permit
      permitIdController.text =
          'PERMIT-${now.year}${now.month.toString().padLeft(2, '0')}-0012';
    } catch (e) {
      print('Error loading user data: $e');
      // Set fallback values
      final now = DateTime.now();
      final prefix =
          widget.requestType == 'Concern Slip'
              ? 'CS'
              : widget.requestType == 'Job Service'
              ? 'JS'
              : 'WP';
      reqIdController.text = '$prefix-${now.year}-00001';
      dateRequestedController.text = UiDateUtils.fullDate(now);
      nameController.text = 'John Doe';
      unitController.text = 'Tower A - Unit 10B';
    } finally {
      if (mounted) {
        setState(() => _isLoadingUserData = false);
      }
    }
  }

  @override
  void dispose() {
    reqIdController.dispose();
    dateRequestedController.dispose();
    unitController.dispose();
    nameController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    availabilityController.dispose();
    permitIdController.dispose();
    validFromController.dispose();
    validToController.dispose();
    contractorNameController.dispose();
    contractorNumberController.dispose();
    contractorEmailController.dispose();
    othersRequestTypeController.dispose();
    super.dispose();
  }

  // ----- Success dialog sending user to Work Order Management -----
  void _showRequestDialog(BuildContext context, String? formattedId) {
    showDialog(
      context: context,
      builder:
          (_) => CustomPopup(
            title: 'Success',
            message:
                'Your ${widget.requestType.toLowerCase()} ${formattedId != null ? '($formattedId)' : ''} has been submitted successfully and is now listed under Repair Request Management.',
            primaryText: 'Go to Repair Request Management',
            onPrimaryPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const WorkOrderPage()),
              );
            },
          ),
    );
  }

  // ----- Parsing + inline error helpers -----
  DateTime? _parseDT(String value) {
    try {
      // Try date-time format first
      return DateFormat('MMM d, yyyy h:mm a').parseStrict(value);
    } catch (_) {
      try {
        // Try date-only format
        return DateFormat('MMM d, yyyy').parseStrict(value);
      } catch (_) {
        return null;
      }
    }
  }

  // Parse and validate availability time range
  bool _isValidAvailabilityRange(String value) {
    if (value.trim().isEmpty) return false;
    
    try {
      // Expected format: "MMM d, yyyy h:mm AM - h:mm PM"
      // Example: "Oct 12, 2025 9:00 AM - 11:00 AM"
      
      final parts = value.split(' - ');
      if (parts.length != 2) return false;
      
      final startPart = parts[0].trim();
      final endPart = parts[1].trim();
      
      // Extract date from start part
      final dateMatch = RegExp(r'^([A-Za-z]+ \d{1,2}, \d{4})').firstMatch(startPart);
      if (dateMatch == null) return false;
      
      final dateStr = dateMatch.group(1)!;
      
      // Extract time from start part
      final startTimeStr = startPart.substring(dateStr.length).trim();
      final endTimeStr = endPart.trim();
      
      // Validate time format (h:mm AM/PM)
      final timeRegex = RegExp(r'^\d{1,2}:\d{2}\s?(AM|PM)$', caseSensitive: false);
      if (!timeRegex.hasMatch(startTimeStr) || !timeRegex.hasMatch(endTimeStr)) {
        return false;
      }
      
      return true;
    } catch (_) {
      return false;
    }
  }

  // Parse availability range into start and end DateTime objects
  Map<String, DateTime?> _parseAvailabilityRange(String value) {
    try {
      final parts = value.split(' - ');
      if (parts.length != 2) return {'start': null, 'end': null};
      
      final startPart = parts[0].trim();
      final endPart = parts[1].trim();
      
      // Extract date from start part
      final dateMatch = RegExp(r'^([A-Za-z]+ \d{1,2}, \d{4})').firstMatch(startPart);
      if (dateMatch == null) return {'start': null, 'end': null};
      
      final dateStr = dateMatch.group(1)!;
      final startTimeStr = startPart.substring(dateStr.length).trim();
      final endTimeStr = endPart.trim();
      
      // Parse the date
      final date = DateFormat('MMM d, yyyy').parse(dateStr);
      
      // Parse start time
      final startTime = DateFormat('h:mm a').parse(startTimeStr);
      final startDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        startTime.hour,
        startTime.minute,
      );
      
      // Parse end time (same date)
      final endTime = DateFormat('h:mm a').parse(endTimeStr);
      final endDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        endTime.hour,
        endTime.minute,
      );
      
      return {'start': startDateTime, 'end': endDateTime};
    } catch (e) {
      print('Error parsing availability range: $e');
      return {'start': null, 'end': null};
    }
  }

  // Concern Slip errors
  String? _errCS(String key) {
    if (!_submitted) return null;
    switch (key) {
      case 'title':
        return titleController.text.trim().isEmpty
            ? 'Task title is required.'
            : null;
      case 'desc':
        return descriptionController.text.trim().isEmpty
            ? 'Description is required.'
            : null;
      case 'avail':
        if (availabilityController.text.trim().isEmpty)
          return 'Availability is required.';
        return !_isValidAvailabilityRange(availabilityController.text.trim())
            ? 'Invalid time range format. Use: Date StartTime - EndTime'
            : null;
      default:
        return null;
    }
  }

  // Job Service errors
  String? _errJS(String key) {
    if (!_submitted) return null;
    switch (key) {
      case 'notes':
        // Notes are optional for Job Service
        return null;
      case 'avail':
        if (availabilityController.text.trim().isEmpty)
          return 'Availability is required.';
        return !_isValidAvailabilityRange(availabilityController.text.trim())
            ? 'Invalid time range format. Use: Date StartTime - EndTime'
            : null;
      default:
        return null;
    }
  }

  // Work Order errors
  String? _errWO(String key) {
    if (!_submitted) return null;
    switch (key) {
      case 'type':
        if (_requestTypeValue.trim().isEmpty) {
          return 'Request type is required.';
        }
        if (_requestTypeValue.toLowerCase() == 'others' && othersRequestTypeController.text.trim().isEmpty) {
          return 'Please specify the request type.';
        }
        return null;
      case 'from':
        if (validFromController.text.trim().isEmpty)
          return 'Start date is required.';
        final dt = _parseDT(validFromController.text.trim());
        if (dt == null) return 'Invalid date.';
        if (dt.weekday < 1 || dt.weekday > 6) return 'Date must be Monday to Saturday.';
        return null;
      case 'to':
        if (validToController.text.trim().isEmpty) return 'End date is required.';
        final from = _parseDT(validFromController.text.trim());
        final to = _parseDT(validToController.text.trim());
        if (to == null) return 'Invalid date.';
        if (from != null && !to.isAfter(from))
          return 'End date must be later than start date.';
        if (to.weekday < 1 || to.weekday > 6) return 'Date must be Monday to Saturday.';
        return null;
      case 'contractors':
        if (!_hasContractors) return 'Please add at least one contractor/personnel.';
        if (_contractors.length > 3) return 'Maximum of 3 contractors allowed.';
        return null;
      default:
        return null;
    }
  }

  // Phone number validation
  String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your contact number.';
    }
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return 'Input must be a number. Please check for any letters or special symbols.';
    }
    if (!(cleaned.length == 10 || cleaned.length == 11)) {
      return 'Must contain 10 digits (excluding the initial \'0\' for domestic calls or the +63 country code).';
    }
    if (!(RegExp(r'^(09\d{9}|9\d{9})$').hasMatch(cleaned))) {
      return "Must follow 09XX-XXX-YYYY (11 digits total with '0') or 9XX-XXX-YYYY (10 digits without '0').\nInvalid phone number format. Mobile numbers must be 10 digits";
    }
    return null;
  }

  // Email validation
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!value.contains('@')) {
      return "Invalid email format. Missing '@' symbol";
    }
    if (value.length > 254) {
      return 'Email is too long. Must be less than 254 characters.';
    }
    if (RegExp(r'[\s,;:/\\\[\]{}()<>]').hasMatch(value)) {
      return 'Invalid character found in the email address.';
    }
    if (!RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$').hasMatch(value)) {
      return 'Invalid email address format.';
    }
    return null;
  }

  bool _hasAnyErrorForType(String type) {
    switch (type) {
      case 'Concern Slip':
        return _errCS('title') != null ||
            _errCS('desc') != null ||
            _errCS('avail') != null;
      case 'Job Service':
        // Only availability is required; notes are optional
        return _errJS('avail') != null;
      case 'Work Order':
        return _errWO('type') != null ||
            _errWO('from') != null ||
            _errWO('to') != null ||
            _errWO('contractors') != null;
      default:
        return true;
    }
  }

  Future<void> _onSubmit() async {
    // Mark as submitted so errorText becomes visible
    setState(() => _submitted = true);

    // Also run any internal validators the custom fields may have
    _formKey.currentState?.validate();

    final type = widget.requestType.trim();
    if (_hasAnyErrorForType(type)) {
      _showSnack('Please correct the highlighted fields.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiService = APIService();
      Map<String, dynamic> result;

      // Handle editing existing requests
      if (widget.isEditing && widget.requestId != null) {
        if (type == 'Concern Slip') {
          print('[SUBMIT] Updating concern slip...');
          
          result = await apiService.updateConcernSlip(
            concernSlipId: widget.requestId!,
            scheduleAvailability: availabilityController.text.trim(),
          );
          
          result['success'] = true;
        } else if (type == 'Job Service') {
          print('[SUBMIT] Updating job service...');
          
          result = await apiService.updateJobService(
            jobServiceId: widget.requestId!,
            scheduleAvailability: availabilityController.text.trim(),
          );
          
          result['success'] = true;
        } else if (type == 'Work Order') {
          print('[SUBMIT] Updating work order...');
          
          result = await apiService.updateWorkOrder(
            workOrderId: widget.requestId!,
            contractorName: contractorNameController.text.trim(),
            contractorNumber: contractorNumberController.text.trim(),
            contractorEmail: contractorEmailController.text.trim(),
            workScheduleFrom: validFromController.text.trim(),
            workScheduleTo: validToController.text.trim(),
          );
          
          result['success'] = true;
        } else {
          throw Exception('Unknown request type: $type');
        }

        if (result['success'] == true) {
          print('[SUBMIT] Update successful');
          _showSnack('$type updated successfully');
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          _showSnack('Failed to update $type. Please try again.');
        }
        return;
      }

      // Original submit logic for creating new requests
      if (type == 'Concern Slip') {
        print('[SUBMIT] Submitting concern slip to Firebase...');

        result = await apiService.submitConcernSlip(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          location: unitController.text.trim(),
          category:
              _aiCategory.isNotEmpty ? _aiCategory.toLowerCase() : '',
          priority:
              _aiPriority.isNotEmpty ? _aiPriority.toLowerCase() : '',
          unitId: unitController.text.trim(),
          scheduleAvailability: availabilityController.text.trim(),
          attachments: _attachments,
        );
      } else if (type == 'Job Service') {
        print('[SUBMIT] Submitting job service to Firebase...');

        // Parse the availability range to get structured start/end times
        final availabilityText = availabilityController.text.trim();
        final parsedTimes = _parseAvailabilityRange(availabilityText);

        result = await apiService.submitJobService(
          notes: descriptionController.text.trim().isNotEmpty 
              ? descriptionController.text.trim() 
              : null,
          location: unitController.text.trim(),
          unitId: unitController.text.trim(),
          scheduleAvailability: availabilityText,
          startTime: parsedTimes['start'],
          endTime: parsedTimes['end'],
          concernSlipId: widget.concernSlipId,
        );
        // If this job service is linked to a concern slip, update the
        // concern slip to record the resolution type and schedule so the
        // tenant/staff lists show "Pending JS" appropriately.
        if (result['success'] == true && widget.concernSlipId != null && widget.concernSlipId!.isNotEmpty) {
          try {
            await apiService.updateConcernSlip(
              concernSlipId: widget.concernSlipId!,
              scheduleAvailability: availabilityText.isNotEmpty ? availabilityText : null,
              resolutionType: 'job_service',
              status: 'pending',
            );
          } catch (e) {
            print('[SUBMIT] Warning: failed to update concern slip after creating job service: $e');
          }
        }
      } else if (type == 'Work Order') {
        print('[SUBMIT] Submitting work order to Firebase...');

        result = await apiService.submitWorkOrder(
          requestType: _requestTypeValue,
          validFrom: validFromController.text.trim(),
          validTo: validToController.text.trim(),
          contractors: _contractors,
          location: unitController.text.trim(),
          unitId: unitController.text.trim(),
          concernSlipId: widget.concernSlipId,  // Pass the concern slip ID if available
        );
        // If linked to a concern slip, update the concern slip to reflect
        // that a work order has been requested (Pending WOP). Use the
        // validFrom/validTo as schedule availability where available.
        if (result['success'] == true && widget.concernSlipId != null && widget.concernSlipId!.isNotEmpty) {
          try {
            final schedule = (validFromController.text.trim().isNotEmpty || validToController.text.trim().isNotEmpty)
                ? '${validFromController.text.trim()} - ${validToController.text.trim()}'
                : null;
            await apiService.updateConcernSlip(
              concernSlipId: widget.concernSlipId!,
              scheduleAvailability: schedule,
              resolutionType: 'work_permit',
              status: 'pending',
            );
          } catch (e) {
            print('[SUBMIT] Warning: failed to update concern slip after creating work order: $e');
          }
        }
      } else {
        throw Exception('Unknown request type: $type');
      }

      if (result['success'] == true) {
        print('[SUBMIT] Success: ${result['formatted_id']}');
        // If caller requested to handle navigation, return to caller so it
        // can refresh or navigate as needed. Otherwise keep existing
        // behavior of showing the success dialog and redirecting to the
        // Repair Request Management page.
        if (widget.returnToCallerOnSuccess) {
          // Normalize the returned payload so callers have a stable shape.
          // resource_type: 'job_service'|'work_order'|'concern_slip'
          // resource_id: the primary id string (id, job_service_id, work_order_id, or formatted_id)
          final String resourceType = (type == 'Job Service')
              ? 'job_service'
              : (type == 'Work Order')
                  ? 'work_order'
                  : 'concern_slip';

          String? resourceId;
          // Prefer explicit keys if present
          resourceId = result['job_service_id']?.toString()
              ?? result['work_order_id']?.toString()
              ?? result['id']?.toString()
              ?? result['formatted_id']?.toString();

          final canonical = {
            'resource_type': resourceType,
            'resource_id': resourceId ?? '',
            'raw': result,
          };

          Navigator.pop(context, canonical);
        } else {
          _showRequestDialog(context, result['formatted_id']);
        }
      } else {
        _showSnack('Failed to submit $type. Please try again.');
      }
    } catch (e) {
      print('[SUBMIT] Error: $e');
      _showSnack('Error submitting request: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildAIInsights() {
    if (widget.requestType != 'Concern Slip') return const SizedBox.shrink();
    if (_aiCategory.isEmpty && _aiPriority.isEmpty && !_isAnalyzing) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        border: Border.all(color: const Color(0xFF0EA5E9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFF0EA5E9), size: 16),
              const SizedBox(width: 8),
              const Text(
                'AI Analysis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0EA5E9),
                ),
              ),
              if (_isAnalyzing) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0EA5E9),
                  ),
                ),
              ],
            ],
          ),
          if (_aiCategory.isNotEmpty || _aiPriority.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (_aiCategory.isNotEmpty)
              Text(
                'Detected Category: $_aiCategory',
                style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
              ),
            if (_aiPriority.isNotEmpty)
              Text(
                'Suggested Priority: $_aiPriority',
                style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
              ),
          ],
        ],
      ),
    );
  }

  // ----- UI sections -----
  List<Widget> getFormFields() {
    if (_isLoadingUserData) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(48.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }

    switch (widget.requestType) {
      case 'Concern Slip':
        return [
          const Text('Detail Information', style: TextStyle(fontSize: 20)),
          const Text(
            'Enter Detail Information',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            'Basic Information',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputField(
                label: 'Request Id',
                controller: reqIdController,
                hintText: 'Auto-generated',
                isRequired: true,
                readOnly: true,
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Date Requested',
                controller: dateRequestedController,
                hintText: 'Auto-filled',
                isRequired: true,
                readOnly: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.date_range),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Building & Unit No.',
                controller: unitController,
                hintText: 'Auto-filled from profile',
                isRequired: true,
                readOnly: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.apartment),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Name',
                controller: nameController,
                hintText: 'Auto-filled from profile',
                isRequired: true,
                readOnly: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Request Details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              InputField(
                label: 'Task Title',
                controller: titleController,
                hintText: 'Enter Task Title',
                isRequired: true,
                readOnly: widget.isEditing, // Read-only when editing
                errorText: _errCS('title'),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Description',
                controller: descriptionController,
                hintText: 'Enter task description (will be analyzed by our AI)',
                isRequired: true,
                maxLines: 4,
                readOnly: widget.isEditing, // Read-only when editing
                errorText: _errCS('desc'),
              ),
              _buildAIInsights(),
              InputField(
                label: 'Schedule Availability',
                controller: availabilityController,
                hintText: 'Select date and time range (e.g., 9:00 AM - 11:00 AM)',
                isRequired: true,
                onTap: () => _pickAvailabilityRange(availabilityController),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.access_time),
                ),
                errorText: _errCS('avail'),
              ),
              const SizedBox(height: 8),
              FileAttachmentPicker(
                label: 'Upload Attachment',
                onChanged: (files) {
                  setState(() {
                    _attachments = files;
                  });
                },
              ),
            ],
          ),
        ];

      case 'Job Service':
        return [
          const Text('Detail Information', style: TextStyle(fontSize: 20)),
          const Text(
            'Enter Detail Information',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            'Basic Information',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputField(
                label: 'Request Id',
                controller: reqIdController,
                hintText: 'Auto-generated',
                isRequired: true,
                readOnly: true,
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Date Requested',
                controller: dateRequestedController,
                hintText: 'Auto-filled',
                isRequired: true,
                readOnly: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.date_range),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Building & Unit No.',
                controller: unitController,
                hintText: 'Auto-filled from profile',
                isRequired: true,
                readOnly: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.apartment),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Name',
                controller: nameController,
                hintText: 'Auto-filled from profile',
                isRequired: true,
                readOnly: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Request Details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              InputField(
                label: 'Notes',
                controller: descriptionController,
                hintText: 'Enter additional notes',
                // Notes are optional for Job Service
                isRequired: false,
                maxLines: 4,
              ),
              InputField(
                label: 'Schedule Availability',
                controller: availabilityController,
                hintText: 'Select date and time range (e.g., 9:00 AM - 11:00 AM)',
                isRequired: true,
                onTap: () => _pickAvailabilityRange(availabilityController),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.access_time),
                ),
                errorText: _errJS('avail'),
              ),
              const SizedBox(height: 8),
              FileAttachmentPicker(
                label: 'Upload Attachment',
                onChanged: (files) {
                  setState(() {
                    _attachments = files;
                  });
                },
              ),
            ],
          ),
        ];

      case 'Work Order':
        return [
          const Text('Permit Validation', style: TextStyle(fontSize: 20)),
          const Text(
            'Enter Detail Information',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            'Basic Information',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputField(
                label: 'Request Id',
                controller: reqIdController,
                hintText: 'Auto-generated',
                isRequired: true,
                readOnly: true,
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Date Requested',
                controller: dateRequestedController,
                hintText: 'Auto-filled',
                isRequired: true,
                readOnly: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.date_range),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Building & Unit No.',
                controller: unitController,
                hintText: 'Auto-filled from profile',
                isRequired: true,
                readOnly: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.apartment),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Name',
                controller: nameController,
                hintText: 'Auto-filled from profile',
                isRequired: true,
                readOnly: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Permit Validation',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              // Request Type (dropdown w/ required message)
              DropdownField<String>(
                label: 'Work Order Type',
                value: _requestTypeValue.isEmpty ? null : _requestTypeValue,
                items: _requestTypes,
                onChanged: (v) {
                  setState(() {
                    _requestTypeValue = v ?? '';
                    // Clear others field when not "Others"
                    if (v?.toLowerCase() != 'others') {
                      othersRequestTypeController.clear();
                    }
                  });
                  _formKey.currentState?.validate();
                },
                isRequired: _submitted, // only show built-in error after submit
                requiredMessage: 'Work order type is required.',
                hintText: 'Select work order type',
                isDense: true, // Match InputField height
              ),
              // Show "Others" text field when "Others" is selected
              if (_requestTypeValue.toLowerCase() == 'others') ...[
                const SizedBox(height: 8),
                InputField(
                  label: 'Specify Work Order Type',
                  controller: othersRequestTypeController,
                  hintText: 'Enter work order type details',
                  isRequired: true,
                  errorText: _submitted && othersRequestTypeController.text.trim().isEmpty
                      ? 'Please specify the work order type'
                      : null,
                ),
              ],
              // Also show our explicit errorText slot if your DropdownField supports it:
              if (_errWO('type') != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    _errWO('type')!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 8),

              // Valid From / Valid To (two-up row, blue calendar icon) with inline errors
                Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                  'Schedule Date',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                  children: [
                    Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDateOnly(validFromController),
                      child: AbsorbPointer(
                      child: InputField(
                        label: 'Valid From',
                        controller: validFromController,
                        hintText: 'Select date',
                        isRequired: true,
                        suffixIcon: const Icon(
                        Icons.calendar_today_rounded,
                        size: 20,
                        color: Color(0xFF005CE7),
                        ),
                        errorText: _errWO('from'),
                      ),
                      ),
                    ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDateOnly(validToController),
                      child: AbsorbPointer(
                      child: InputField(
                        label: 'Valid To',
                        controller: validToController,
                        hintText: 'Select date',
                        isRequired: true,
                        suffixIcon: const Icon(
                        Icons.calendar_today_rounded,
                        size: 20,
                        color: Color(0xFF005CE7),
                        ),
                        errorText: _errWO('to'),
                      ),
                      ),
                    ),
                    ),
                  ],
                  ),
                ],
                ),
                InputField(
                label: 'Notes',
                controller: descriptionController,
                hintText: 'Enter additional notes',
                isRequired: false,
                maxLines: 4,
                ),
              const SizedBox(height: 8),

                // Contractors/Personnel section (stacked vertically)
                const Text(
                  'List of Contractors/Personnel',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                // Name / Company
                InputField(
                  label: 'Name/Company',
                  controller: contractorNameController,
                  hintText: 'Enter name or company',
                  isRequired: true,
                ),
                const SizedBox(height: 8),
                // Contact Number
                InputField(
                  label: 'Contact Number',
                  controller: contractorNumberController,
                  hintText: '09XXXXXXXXX',
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                  errorText: _submitted
                    ? validatePhoneNumber(contractorNumberController.text)
                    : null,
                ),
                const SizedBox(height: 8),
                // Email
                InputField(
                  label: 'Email',
                  controller: contractorEmailController,
                  hintText: 'Optional',
                  isRequired: false,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _submitted
                    ? validateEmail(contractorEmailController.text)
                    : null,
                ),
                const SizedBox(height: 8),
                // Add button (aligned to the right)
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005CE7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    ),
                    onPressed: () {
                    final name = contractorNameController.text.trim();
                    final number = contractorNumberController.text.trim();
                    final email = contractorEmailController.text.trim();

                    final phoneError = validatePhoneNumber(number);
                    final emailError = validateEmail(email);

                    // Prevent adding more than 3 contractors
                    if (_contractors.length >= 3) {
                      setState(() {
                        _submitted = true;
                      });
                      _showSnack('You can only add up to 3 contractors.');
                      return;
                    }

                    if (name.isEmpty ||
                      phoneError != null ||
                      (email.isNotEmpty && emailError != null)) {
                      setState(() {
                      _submitted = true;
                      });
                      _showSnack('Please enter valid contractor details.');
                      return;
                    }

                    setState(() {
                      _contractors.add({
                      'name': name,
                      'contact_number': number,
                      'email': email,
                      });
                      _hasContractors = _contractors.isNotEmpty;
                      contractorNameController.clear();
                      contractorNumberController.clear();
                      contractorEmailController.clear();
                    });
                    },
                    child: const Icon(Icons.add, size: 20),
                  ),
                  ),
                ),
                if (_errWO('contractors') != null)
                  Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    _errWO('contractors')!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  ),
                const SizedBox(height: 12),
                // List of added contractors
                Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _contractors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final c = entry.value;
                  return Chip(
                  label: Text(
                    '${c['name']} - ${c['contact_number']}${c['email'] != null && c['email']!.isNotEmpty ? ' - ' + c['email']! : ''}',
                    style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF344054),
                    fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: const Color(0xFFF2F4F7),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  deleteIconColor: const Color(0xFF667085),
                  shape: const StadiumBorder(
                    side: BorderSide(color: Color(0xFFE4E7EC)),
                  ),
                  onDeleted: () {
                    setState(() {
                    _contractors.removeAt(index);
                    _hasContractors = _contractors.isNotEmpty;
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  );
                }).toList(),
              ),
            ],
          ),
        ];

      default:
        // Graceful fallback: show a helpful message instead of a hard error.
        return [
          const SizedBox(height: 16),
          Text(
            'Unsupported form: "${widget.requestType}". Please go back and choose a valid request type.',
            style: const TextStyle(color: Colors.red),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.requestType) {
      'Concern Slip' => 'New Concern Slip',
      'Job Service' => 'New Job Service',
      'Work Order' => 'New Work Order Permit',
      _ => 'New Request',
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: title,
        leading: const BackButton(),
        actions: [
          if (!widget.isEditing)
            IconButton(
              icon: const Icon(Icons.info_outline, color: Color(0xFF0EA5E9)),
              onPressed: _showInfoSheet,
              tooltip: 'Request Information',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 120,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [...getFormFields(), const SizedBox(height: 24)],
            ),
          ),
        ),
      ),
      // Sticky action + NavBar
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: fx.FilledButton(
                  label: _isSubmitting 
                      ? (widget.isEditing ? 'Updating...' : 'Submitting...') 
                      : (widget.isEditing ? 'Update Request' : 'Create Task'),
                  backgroundColor: const Color(0xFF005CE7),
                  withOuterBorder: false,
                  elevation: 0,
                  onPressed: _isSubmitting ? () {} : _onSubmit,
                ),
              ),
            ),
          ),
          NavBar(
            items: _navItems,
            currentIndex: _selectedIndex,
            onTap: _onTabTapped,
          ),
        ],
      ),
    );
  }
}
