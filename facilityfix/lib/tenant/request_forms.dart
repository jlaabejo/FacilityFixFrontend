import 'dart:async';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/tenant/announcement.dart';
import 'package:facilityfix/tenant/home.dart';
import 'package:facilityfix/tenant/profile.dart';
import 'package:facilityfix/tenant/workorder.dart';
import 'package:facilityfix/widgets/buttons.dart' as fx;
import 'package:facilityfix/widgets/forms.dart';
import 'package:facilityfix/widgets/modals.dart'; // CustomPopup
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:intl/intl.dart';

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

  const RequestForm({
    super.key, 
    required this.requestType, 
    this.concernSlipId,
    this.initialData,
    this.requestId,
    this.isEditing = false,
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
              'The initial report or request for repair or maintenance raised by a tenant or staff.',
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

  // Date/Time picking for availability range
  Future<void> _pickAvailabilityRange(TextEditingController controller) async {
    final now = DateTime.now();

    // Pick the date first
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    // Pick start time
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      helpText: 'Select start time',
    );
    if (startTime == null) return;

    // Pick end time
    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (startTime.hour + 2) % 24, // Default to 2 hours later
        minute: startTime.minute,
      ),
      helpText: 'Select end time',
    );
    if (endTime == null) return;

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

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
  final TextEditingController contractorCompanyController = TextEditingController();
  final TextEditingController entryEquipmentsController = TextEditingController();
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
          contractorCompanyController.text = data['contractor_company'] ?? '';
          
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
          
          // Handle entry equipments
          if (data['entry_equipments'] != null) {
            if (data['entry_equipments'] is List) {
              entryEquipmentsController.text = (data['entry_equipments'] as List).join(', ');
            } else if (data['entry_equipments'] is String) {
              entryEquipmentsController.text = data['entry_equipments'];
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

      // Set date requested
      dateRequestedController.text = DateFormat(
        'MMM d, yyyy h:mm a',
      ).format(now);
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
      dateRequestedController.text = DateFormat(
        'MMM d, yyyy h:mm a',
      ).format(now);
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
    contractorCompanyController.dispose();
    entryEquipmentsController.dispose();
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
                'Your ${widget.requestType.toLowerCase()} ${formattedId != null ? '($formattedId)' : ''} has been submitted successfully and is now listed under Work Order Management.',
            primaryText: 'Go to Work Orders',
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
        // If "Others" is selected, check if the text field is filled
        if (_requestTypeValue.toLowerCase() == 'others' &&
            othersRequestTypeController.text.trim().isEmpty) {
          return 'Please specify the request type.';
        }
        return null;
      case 'from':
        if (validFromController.text.trim().isEmpty)
          return 'Start date is required.';
        return _parseDT(validFromController.text.trim()) == null
            ? 'Invalid date.'
            : null;
      case 'to':
        if (validToController.text.trim().isEmpty) return 'End date is required.';
        final from = _parseDT(validFromController.text.trim());
        final to = _parseDT(validToController.text.trim());
        if (to == null) return 'Invalid date.';
        if (from != null && !to.isAfter(from))
          return 'End date must be later than start date.';
        return null;
      case 'contractors':
        return !_hasContractors
            ? 'Please add at least one contractor/personnel.'
            : null;
      default:
        return null;
    }
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
          
          // Parse entry equipments from comma-separated string
          final equipments = entryEquipmentsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          
          result = await apiService.updateWorkOrder(
            workOrderId: widget.requestId!,
            contractorName: contractorNameController.text.trim(),
            contractorNumber: contractorNumberController.text.trim(),
            contractorCompany: contractorCompanyController.text.trim(),
            workScheduleFrom: validFromController.text.trim(),
            workScheduleTo: validToController.text.trim(),
            entryEquipments: equipments,
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
              _aiCategory.isNotEmpty ? _aiCategory.toLowerCase() : 'general',
          priority:
              _aiPriority.isNotEmpty ? _aiPriority.toLowerCase() : 'medium',
          unitId: unitController.text.trim(),
          scheduleAvailability: availabilityController.text.trim(),
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
      } else {
        throw Exception('Unknown request type: $type');
      }

      if (result['success'] == true) {
        print('[SUBMIT] Success: ${result['formatted_id']}');
        _showRequestDialog(context, result['formatted_id']);
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
                label: 'Availability',
                controller: availabilityController,
                hintText: 'Select date and time range (e.g., 9:00 AM - 11:00 AM)',
                isRequired: true,
                readOnly: true,
                onTap: () => _pickAvailabilityRange(availabilityController), // Always allow picking availability
                errorText: _errCS('avail'),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.access_time),
                ),
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
                label: 'Availability',
                controller: availabilityController,
                hintText: 'Select date and time range (e.g., 9:00 AM - 11:00 AM)',
                isRequired: true,
                readOnly: true,
                onTap: () => _pickAvailabilityRange(availabilityController),
                errorText: _errJS('avail'),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.access_time),
                ),
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
                label: 'Request Type',
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
                requiredMessage: 'Request type is required.',
                hintText: 'Select request type',
                isDense: true, // Match InputField height
              ),
              // Show "Others" text field when "Others" is selected
              if (_requestTypeValue.toLowerCase() == 'others') ...[
                const SizedBox(height: 8),
                InputField(
                  label: 'Specify Request Type',
                  controller: othersRequestTypeController,
                  hintText: 'Enter request type details',
                  isRequired: true,
                  errorText: _submitted && othersRequestTypeController.text.trim().isEmpty
                      ? 'Please specify the request type'
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
              const SizedBox(height: 8),

              const Text(
                'List of Contractors/Personnel',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              MultiContractorInputField(
                isRequired: true,
                onChanged: (contractorList) {
                  setState(() {
                    _hasContractors = contractorList.isNotEmpty;
                    _contractors = contractorList;
                  });
                },
              ),
              if (_errWO('contractors') != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    _errWO('contractors')!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
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
