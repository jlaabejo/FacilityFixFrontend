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
import 'package:facilityfix/widgets/view_details.dart';
import 'package:facilityfix/widgets/forms.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart' as fx;
import 'package:facilityfix/widgets/modals.dart';

class StaffConcernSlipDetailPage extends StatefulWidget {
  final String concernSlipId;

  const StaffConcernSlipDetailPage({super.key, required this.concernSlipId});

  @override
  State<StaffConcernSlipDetailPage> createState() =>
      _StaffConcernSlipDetailPageState();
}

class _StaffConcernSlipDetailPageState
    extends State<StaffConcernSlipDetailPage> {
  int _selectedIndex = 1;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _concernSlipData;

  // Assessment form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateAssessedController = TextEditingController();
  final TextEditingController _assessmentController = TextEditingController();
  final TextEditingController _recommendationController = TextEditingController();

  // Form state
  String? _assessmentError;
  String? _recommendationError;
  bool _isSubmitting = false;
  bool _showAssessmentForm = false; // Toggle to show/hide form
  String _selectedResolutionType = 'work_order'; // Default to work_order

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  @override
  void initState() {
    super.initState();
    _loadConcernSlipData();
    _initializeFormFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateAssessedController.dispose();
    _assessmentController.dispose();
    _recommendationController.dispose();
    super.dispose();
  }

  Future<void> _initializeFormFields() async {
    // Load user profile data
    final profile = await AuthStorage.getProfile();
    
    if (profile != null && mounted) {
      final firstName = profile['first_name'] ?? '';
      final lastName = profile['last_name'] ?? '';
      final fullName = '$firstName $lastName'.trim();
      
      setState(() {
        _nameController.text = fullName.isNotEmpty ? fullName : 'Staff Member';
      });
    }
    
    // Set current date/time
    final now = DateTime.now();
    _dateAssessedController.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _loadConcernSlipData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Use staff role for API service
      final apiService = APIService(roleOverride: AppRole.staff);
      final data = await apiService.getConcernSlipById(widget.concernSlipId);

      if (mounted) {
        setState(() {
          _concernSlipData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

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

  bool _validateAssessmentFields() {
    String? assessErr;
    String? recErr;

    if (_assessmentController.text.trim().isEmpty) {
      assessErr = 'Assessment is required';
    }
    if (_recommendationController.text.trim().isEmpty) {
      recErr = 'Recommendation is required';
    }

    setState(() {
      _assessmentError = assessErr;
      _recommendationError = recErr;
    });

    return assessErr == null && recErr == null;
  }

  Future<void> _submitAssessment() async {
    if (!_validateAssessmentFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Use staff role for API service
      final apiService = APIService(roleOverride: AppRole.staff);
      
      // Get auth token
      final token = await AuthStorage.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }
      
      // Prepare request body
      final body = {
        'assessment': _assessmentController.text.trim(),
        'recommendation': _recommendationController.text.trim(),
        'resolution_type': _selectedResolutionType,
        'attachments': [], // TODO: Add attachment support
      };
      
      // Submit assessment with proper body using HTTP PATCH
      final response = await http.patch(
        Uri.parse('${apiService.baseUrl}/concern-slips/${widget.concernSlipId}/submit-assessment'),
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
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (_) => CustomPopup(
            title: 'Success',
            message: 'Your assessment has been submitted successfully and is now recorded.',
            primaryText: 'OK',
            onPrimaryPressed: () {
              Navigator.of(context).pop();
              // Refresh the concern slip data
              _loadConcernSlipData();
              // Hide the form
              setState(() => _showAssessmentForm = false);
            },
          ),
        );
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

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  Widget _buildInlineAssessmentForm() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assessment & Recommendation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B1D21),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() => _showAssessmentForm = false);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Concern Slip Info Card
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
                    'ID: ${_concernSlipData!['formatted_id'] ?? _concernSlipData!['id'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Title: ${_concernSlipData!['title'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Location: ${_concernSlipData!['location'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Basic Information
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            InputField(
              label: 'Full Name',
              controller: _nameController,
              hintText: 'Auto-filled',
              isRequired: true,
              readOnly: true,
            ),
            InputField(
              label: 'Date Assessed',
              controller: _dateAssessedController,
              hintText: 'Auto-filled',
              isRequired: true,
              readOnly: true,
            ),

            const SizedBox(height: 16),
            const Text(
              'Assessment and Recommendation',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            InputField(
              label: 'Assessment',
              controller: _assessmentController,
              hintText: 'Enter your assessment of the issue',
              isRequired: true,
              maxLines: 4,
              errorText: _assessmentError,
            ),
            const SizedBox(height: 8),
            InputField(
              label: 'Recommendation',
              controller: _recommendationController,
              hintText: 'Enter your recommendation',
              isRequired: true,
              maxLines: 4,
              errorText: _recommendationError,
            ),

            const SizedBox(height: 16),
            const Text(
              'Resolution Type',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
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
                                const Text(
                                  'Work Order',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'For repairs requiring external contractors',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
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
                                const Text(
                                  'Job Service',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'For repairs handled by internal staff',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF667085)),
                                ),
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

            const SizedBox(height: 16),
            const Text(
              'Attachment',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const FileAttachmentPicker(label: 'Upload Attachment'),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
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
                  : fx.FilledButton(
                      label: 'Submit Assessment',
                      backgroundColor: const Color(0xFF005CE7),
                      textColor: Colors.white,
                      withOuterBorder: false,
                      onPressed: _submitAssessment,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: const BackButton(),
        title: 'Concern Slip Details',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading concern slip',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 24),
                      fx.FilledButton(
                        label: 'Retry',
                        backgroundColor: const Color(0xFF005CE7),
                        textColor: Colors.white,
                        onPressed: _loadConcernSlipData,
                      ),
                    ],
                  ),
                )
              : _concernSlipData == null
                  ? const Center(child: Text('No data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          // Display the concern slip details
                          ConcernSlipDetails(
                            id: _concernSlipData!['formatted_id'] ??
                                _concernSlipData!['id'] ??
                                '',
                            createdAt: _parseDateTime(
                                    _concernSlipData!['created_at']) ??
                                DateTime.now(),
                            updatedAt:
                                _parseDateTime(_concernSlipData!['updated_at']),
                            departmentTag: _concernSlipData!['category'],
                            requestTypeTag:
                                _concernSlipData!['request_type'] ??
                                    'Concern Slip',
                            priority: _concernSlipData!['priority'],
                            statusTag: _concernSlipData!['status'] ?? 'pending',
                            resolutionType:
                                _concernSlipData!['resolution_type'],
                            requestedBy: _concernSlipData!['reported_by'] ?? '',
                            unitId: _concernSlipData!['unit_id'] ?? '',
                            scheduleAvailability:
                                _concernSlipData!['schedule_availability'],
                            title: _concernSlipData!['title'] ?? 'Untitled',
                            description:
                                _concernSlipData!['description'] ?? '',
                            attachments: _parseStringList(
                                _concernSlipData!['attachments']),
                            assignedStaff: _concernSlipData!['assigned_to'],
                            staffDepartment:
                                _concernSlipData!['staff_department'],
                            assessedAt:
                                _parseDateTime(_concernSlipData!['assessed_at']),
                            assessment: _concernSlipData!['staff_assessment'],
                            staffAttachments: _parseStringList(
                                _concernSlipData!['staff_attachments']),
                          ),
                          
                          // Show assessment form inline if staff is assigned and no assessment yet
                          if (_concernSlipData!['assigned_to'] != null &&
                              _concernSlipData!['staff_assessment'] == null &&
                              _showAssessmentForm)
                            _buildInlineAssessmentForm(),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show assessment button if staff is assigned and no assessment yet
          if (_concernSlipData != null &&
              _concernSlipData!['assigned_to'] != null &&
              _concernSlipData!['staff_assessment'] == null &&
              !_showAssessmentForm)
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
                    label: 'Fill Assessment Form',
                    backgroundColor: const Color(0xFF005CE7),
                    textColor: Colors.white,
                    withOuterBorder: false,
                    onPressed: () {
                      setState(() => _showAssessmentForm = true);
                    },
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
