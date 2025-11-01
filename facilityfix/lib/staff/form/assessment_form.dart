import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:facilityfix/config/env.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/widgets/buttons.dart'; // FilledButton
import 'package:facilityfix/widgets/forms.dart';   // InputField, FileAttachmentPicker
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/modals.dart';  // <-- CustomPopup
import 'package:flutter/material.dart' hide FilledButton;

enum AssessmentFormMode { concernSlip, jobServiceCompletion, maintenanceTask }

class AssessmentForm extends StatefulWidget {
  /// The concern slip ID to submit assessment for
  final String? concernSlipId;
  
  /// The concern slip data to pre-fill form fields
  final Map<String, dynamic>? concernSlipData;
  
  /// Optional context string for where the assessment is coming from (e.g., a WO title or id)
  final String? requestType;
  /// Which variant of the assessment form to show
  final AssessmentFormMode mode;
  /// Optional override for submission endpoint. If provided, this URL will be used instead of inferred endpoints.
  final String? submitUrl;

  const AssessmentForm({
    super.key,
    this.concernSlipId,
    this.concernSlipData,
    this.requestType,
    this.mode = AssessmentFormMode.concernSlip,
    this.submitUrl,
  });

  @override
  State<AssessmentForm> createState() => _AssessmentFormState();
}

class _AssessmentFormState extends State<AssessmentForm> {
  // Highlight Work tab for staff
  final int _selectedIndex = 1;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const CalendarPage(),
      const InventoryPage(),
    ];
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  // -------- Controllers --------
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateAssessedController = TextEditingController();
  final TextEditingController assessmentController = TextEditingController();

  // -------- Error states --------
  String? _assessmentError;
  bool _isSubmitting = false;
  // Resolution type (only relevant for concernSlip mode) - default to job_service
  String? _selectedResolutionType = 'job_service';

  @override
  void initState() {
    super.initState();
    _loadUserDataAndInitialize();
  }

  Future<void> _loadUserDataAndInitialize() async {
    // Load user profile data from AuthStorage
    final profile = await AuthStorage.getProfile();
    
    if (profile != null && mounted) {
      final firstName = profile['first_name'] ?? '';
      final lastName = profile['last_name'] ?? '';
      final fullName = '$firstName $lastName'.trim();
      
      setState(() {
        nameController.text = fullName.isNotEmpty ? fullName : 'Staff Member';
      });
    }
    
    // Set current date/time
    final now = DateTime.now();
    dateAssessedController.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    nameController.dispose();
    dateAssessedController.dispose();
    assessmentController.dispose();
    super.dispose();
  }

  // 🔹 Success dialog
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CustomPopup(
        title: 'Success',
        message:
            'Your assessment has been submitted successfully and is now recorded under Repair Tasks.',
        primaryText: 'Go to Repair Task',
        onPrimaryPressed: () {
          Navigator.of(context).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WorkOrderPage()),
          );
        },
      ),
    );
  }

  bool _validateFields() {
    String? assessErr;

    if (assessmentController.text.trim().isEmpty) {
      assessErr = 'Assessment is required';
    }
    setState(() {
      _assessmentError = assessErr;
    });

    return assessErr == null;
  }

  Future<void> _submit() async {
    if (!_validateFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the highlighted fields.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check if we have a concern slip ID
    if (widget.concernSlipId == null || widget.concernSlipId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No concern slip ID provided'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Use staff role for API service to get baseUrl
      final apiService = APIService(roleOverride: AppRole.staff);
      
      // Get auth token
      final token = await AuthStorage.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }
      
      // Prepare request body based on mode
      final Map<String, dynamic> body = {
        'assessment': assessmentController.text.trim(),
        'attachments': [],
      };

      // Determine endpoint and add mode-specific fields
      final String endpoint;
      
      if (widget.submitUrl != null && widget.submitUrl!.isNotEmpty) {
        // Use custom endpoint if provided
        endpoint = widget.submitUrl!;
        if (widget.mode == AssessmentFormMode.concernSlip) {
          body['resolution_type'] = _selectedResolutionType;
        }
      } else {
        // Use default endpoints based on mode
        switch (widget.mode) {
          case AssessmentFormMode.concernSlip:
            endpoint = '/concern-slips/${widget.concernSlipId}/submit-assessment';
            body['resolution_type'] = _selectedResolutionType;
            break;
          case AssessmentFormMode.jobServiceCompletion:
            // Job service completion uses job-services endpoint
            endpoint = '/job-services/${widget.concernSlipId}/complete';
            break;
          case AssessmentFormMode.maintenanceTask:
            // Maintenance task uses maintenance-tasks endpoint
            endpoint = '/maintenance-tasks/${widget.concernSlipId}/complete';
            break;
        }
      }

      // Submit assessment with HTTP PATCH
      final response = await http.patch(
        Uri.parse('${apiService.baseUrl}$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to submit assessment: ${response.body}');
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit assessment: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = (widget.requestType != null && widget.requestType!.trim().isNotEmpty)
        ? 'for ${widget.requestType}'
        : widget.concernSlipData != null
            ? 'for ${widget.concernSlipData!['formatted_id'] ?? widget.concernSlipData!['id'] ?? ''}'
            : '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: const BackButton(),
        title: 'Assessment',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header varies slightly by mode
                const Text('Detail Information', style: TextStyle(fontSize: 20)),
                Text(
                  widget.mode == AssessmentFormMode.concernSlip
                      ? 'Enter Detail Information $subtitle'
                      : (widget.mode == AssessmentFormMode.jobServiceCompletion
                          ? 'Complete Job Service Assessment $subtitle'
                          : 'Maintenance Task Assessment $subtitle'),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Show concern slip context if available
                if (widget.concernSlipData != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Concern Slip Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ID: ${widget.concernSlipData!['formatted_id'] ?? widget.concernSlipData!['id'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Title: ${widget.concernSlipData!['title'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Location: ${widget.concernSlipData!['location'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text('Basic Information',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                // Name and date are only shown for the full concern-slip flow
                if (widget.mode == AssessmentFormMode.concernSlip) ...[
                  InputField(
                    label: 'Full Name',
                    controller: nameController,
                    hintText: 'Auto-filled',
                    isRequired: true,
                    readOnly: true,
                  ),
                  InputField(
                    label: 'Date Assessed',
                    controller: dateAssessedController,
                    hintText: 'Auto-filled',
                    isRequired: true,
                    readOnly: true,
                  ),
                ],

                const SizedBox(height: 16),
                // Title differs slightly when recommendation is not required
                Text(
                  widget.mode == AssessmentFormMode.concernSlip
                      ? 'Assessment and Resolution'
                      : 'Assessment',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                InputField(
                  label: 'Assessment',
                  controller: assessmentController,
                  hintText: widget.mode == AssessmentFormMode.concernSlip
                      ? 'Enter assessment'
                      : 'Enter assessment and/or completion notes',
                  isRequired: true,
                  maxLines: 4,
                  errorText: _assessmentError,
                ),

                // Resolution Type only for concern slip flow
                if (widget.mode == AssessmentFormMode.concernSlip) ...[
                  const SizedBox(height: 8),
                  const Text('Resolution Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Job Service FIRST
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedResolutionType = 'job_service';
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'job_service',
                                  groupValue: _selectedResolutionType,
                                  activeColor: const Color(0xFF005CE7),
                                  onChanged: (String? value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedResolutionType = value;
                                      });
                                    }
                                  },
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Job Service', style: TextStyle(fontSize: 14)),
                                      const SizedBox(height: 2),
                                      const Text('For repairs handled by internal staff',
                                          style: TextStyle(fontSize: 12, color: Color(0xFF667085))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        // Work Order Permit SECOND
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedResolutionType = 'work_order';
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'work_order',
                                  groupValue: _selectedResolutionType,
                                  activeColor: const Color(0xFF005CE7),
                                  onChanged: (String? value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedResolutionType = value;
                                      });
                                    }
                                  },
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Work Order Permit', style: TextStyle(fontSize: 14)),
                                      const SizedBox(height: 2),
                                      const Text('For repairs requiring external contractors',
                                          style: TextStyle(fontSize: 12, color: Color(0xFF667085))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                const Text('Attachment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const FileAttachmentPicker(label: 'Upload Attachment'),
              ],
            ),
          ),
        ),
      ),

      // ✅ Sticky bottom button + NavBar
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
                child: _isSubmitting
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF005CE7),
                            ),
                          ),
                        ),
                      )
                    : FilledButton(
                        label: 'Submit Assessment',
                        backgroundColor: const Color(0xFF005CE7),
                        textColor: Colors.white,
                        withOuterBorder: false,
                        onPressed: _submit,
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
