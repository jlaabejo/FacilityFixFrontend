import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../layout/facilityfix_layout.dart';
import '../services/api_service.dart';

class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({super.key});

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final ApiService _apiService = ApiService();

  // Form controllers for backend integration
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  // Form state variables
  String? _selectedAudience;
  String? _selectedType;
  String? _selectedLocation;
  bool _pinToDashboard = false;
  List<File> _attachedFiles = [];
  
  // Additional controllers for "Others" options
  final TextEditingController _customTypeController = TextEditingController();
  final TextEditingController _customLocationController = TextEditingController();
  bool _showCustomType = false;
  bool _showCustomLocation = false;

  // Dropdown options
  final List<String> _audienceOptions = ['Tenants', 'Staff', 'All'];

  final List<Map<String, dynamic>> _typeOptions = [
    {
      'value': 'Scheduled Maintenance',
      'label': 'Scheduled Maintenance',
      'icon': Icons.build,
      'color': Colors.green,
    },
    {
      'value': 'Utility Interruption',
      'label': 'Utility Interruption',
      'icon': Icons.water_drop,
      'color': Colors.blue,
    },
    {
      'value': 'Safety Inspection',
      'label': 'Safety Inspection',
      'icon': Icons.warning,
      'color': Colors.orange,
    },
    {
      'value': 'Power Outage',
      'label': 'Power Outage',
      'icon': Icons.power_off,
      'color': Colors.grey[700],
    },
    {
      'value': 'General Announcement',
      'label': 'General Announcement',
      'icon': Icons.campaign,
      'color': Colors.orange,
    },
    {
      'value': 'Pest Control',
      'label': 'Pest Control',
      'icon': Icons.pest_control,
      'color': Colors.orange,
    },
    {
      'value': 'Others',
      'label': 'Others',
      'icon': Icons.more_horiz,
      'color': Colors.grey[600],
    },
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
    'Others',
  ];

  // Route mapping helper function
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

  // Logout functionality
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
        );
      },
    );
  }

  // File picker functionality
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result != null) {
        setState(() {
          _attachedFiles.addAll(
            result.paths
                .where((path) => path != null)
                .map((path) => File(path!))
                .toList(),
          );
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking files: $e');
    }
  }

  // Remove file functionality
  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  // Date picker functionality
  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        controller.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  // Form validation
  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a title');
      return false;
    }
    if (_selectedAudience == null) {
      _showErrorSnackBar('Please select an audience');
      return false;
    }
    if (_selectedType == null) {
      _showErrorSnackBar('Please select a type');
      return false;
    }
    if (_detailsController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter announcement details');
      return false;
    }
    return true;
  }

  // Error scnackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(left: 24, bottom: 24, right: MediaQuery.of(context).size.width * 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        elevation: 2,
      ),
    );
  }

  // Ssuccess snackbar 
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF66BB6A),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(left: 24, bottom: 24, right: MediaQuery.of(context).size.width * 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        elevation: 2,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => context.go('/announcement'),
        ),
      ),
    );
  }

  // Convert DD/MM/YYYY date format to ISO 8601 format for backend
  String? _convertDateToISO(String dateString) {
    try {
      // Parse the date from DD/MM/YYYY format
      final parts = dateString.split('/');
      if (parts.length != 3) return null;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      final dateTime = DateTime(year, month, day);
      return dateTime.toIso8601String();
    } catch (e) {
      print('[v0] Error converting date to ISO: $e');
      return null;
    }
  }

  // Submit form - ready for backend integration
  void _submitForm() async {
    if (!_validateForm()) return;

    // Determine final type and location values
    final finalType = _showCustomType && _customTypeController.text.trim().isNotEmpty
        ? _customTypeController.text.trim()
        : _selectedType ?? 'General Announcement';
        
    final finalLocation = _showCustomLocation && _customLocationController.text.trim().isNotEmpty
        ? _customLocationController.text.trim()
        : _selectedLocation;

    final announcementData = {
      'title': _titleController.text.trim(),
      'content': _detailsController.text.trim(),
      'type': finalType,
      'audience': _selectedAudience?.toLowerCase() ?? 'all',
      'location_affected': finalLocation,
      'scheduled_publish_date':
          _startDateController.text.isNotEmpty
              ? _convertDateToISO(_startDateController.text)
              : null,
      'expiry_date':
          _endDateController.text.isNotEmpty 
              ? _convertDateToISO(_endDateController.text) 
              : null,
      'is_pinned': _pinToDashboard,
      'is_published': true, // Publish immediately
      'building_id': 'building_001', // TODO: Get from user session
      'created_by': 'admin_user', // TODO: Get from user session
    };

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await _apiService.createAnnouncement(announcementData);

      print('[v0] Create announcement response: $response');

      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        final formattedId = response['formatted_id'] ??
                           response['announcement']?['formatted_id'] ??
                           response['id'] ??
                           response['announcement']?['id'] ??
                           'Unknown';

        print('[v0] Success! Announcement ID: $formattedId');

        _showSuccessSnackBar(
          'Announcement created successfully! ID: $formattedId',
        );

        // Navigate back to announcement list after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/announcement');
          }
        });
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        _showErrorSnackBar('Failed to create announcement: $e');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _customTypeController.dispose();
    _customLocationController.dispose();
    super.dispose();
  }

  // UI Helper Methods
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

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'announcement',
      onNavigate: (routeKey) {
        final routePath = _getRoutePath(routeKey);
        if (routePath != null) {
          context.go(routePath);
        } else if (routeKey == 'logout') {
          _handleLogout(context);
        }
      },
      // Important: let THIS be the only scroll view at this level.
      // Important: this entire "body:" replaces the current one
      body: LayoutBuilder(
        builder: (context, constraints) {
          final hasBoundedHeight = constraints.hasBoundedHeight;

          // Build the actual page content once,(optionally) wrap it with a ConstrainedBox
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // shrink-wrap vertically
            children: [
              // ===== Header Section with breadcrumbs =====
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Announcement",
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
                        onPressed: () => context.go('/announcement'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Announcement'),
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
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ===== Main Form Container (no inner scroll view) =====
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // shrink-wrap vertically
                    children: [
                      // ===== Basic Information =====
                      _buildSectionHeader(
                        'Basic Information',
                        'General details about the announcement',
                      ),
                      const SizedBox(height: 24),
                      // ===== Title =====
                      _fieldLabel("Title"),
                      TextFormField(
                        controller: _titleController,
                        decoration: _decoration("e.g., Scheduled Water Interruption"),
                      ),
                      const SizedBox(height: 24),

                      // ===== Audience & Type =====
                      // First row: audience input and type dropdown aligned
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Audience
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel("Audience"),
                                Container(
                                  height: 48,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedAudience,
                                    decoration: _decoration("Select recipients..."),
                                    isExpanded: true,
                                    items: _audienceOptions.map((audience) {
                                      return DropdownMenuItem(
                                        value: audience,
                                        child: Text(audience),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedAudience = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Type
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel("Announcement Type"),
                                Container(
                                  height: 48,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedType,
                                    decoration: _decoration("Select type..."),
                                    isExpanded: true,
                                    items: _typeOptions.map((type) {
                                      return DropdownMenuItem<String>(
                                        value: type['value'] as String,
                                        child: Text(type['label'] as String),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedType = value;
                                        _showCustomType = value == 'Others';
                                        if (!_showCustomType) {
                                          _customTypeController.clear();
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Second row: optional custom type input aligned under Type column
                      if (_showCustomType) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // empty left column to keep alignment under Type
                            Expanded(child: const SizedBox()),
                            const SizedBox(width: 24),
                            Expanded(
                              child: TextFormField(
                                controller: _customTypeController,
                                decoration: _decoration("Enter custom type..."),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

                      // ===== Post Details =====
                      _fieldLabel("Announcement Details"),
                      TextFormField(
                        controller: _detailsController,
                        maxLines: 8,
                        decoration: _decoration("Enter the full announcement details..."),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),
                      const SizedBox(height: 32),
                      // ===== Task Scope & Description =====
                      _buildSectionHeader(
                        'Task Scope & Description',
                        'Detailed description of what needs to be done',
                      ),
                      const SizedBox(height: 24),

                      // ===== Location + Schedule =====
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel("Location Affected (Optional)"),
                                DropdownButtonFormField<String>(
                                  value: _selectedLocation,
                                  decoration: _decoration("Select location..."),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text("None"),
                                    ),
                                    ..._locationOptions.map((loc) => DropdownMenuItem(
                                      value: loc,
                                      child: Text(loc),
                                    )),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedLocation = value;
                                      _showCustomLocation = value == 'Others';
                                      if (!_showCustomLocation) {
                                        _customLocationController.clear();
                                      }
                                    });
                                  },
                                ),
                                if (_showCustomLocation) ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _customLocationController,
                                    decoration: _decoration("Enter custom location..."),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Schedule
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel("Schedule Visibility"),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _startDateController,
                                        readOnly: true,
                                        decoration: _decoration("DD / MM / YY").copyWith(
                                          suffixIcon: Icon(
                                            Icons.calendar_today,
                                            color: Colors.grey[600],
                                            size: 20,
                                          ),
                                        ),
                                        onTap: () => _selectDate(_startDateController),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _endDateController,
                                        readOnly: true,
                                        decoration: _decoration("DD / MM / YY").copyWith(
                                          suffixIcon: Icon(
                                            Icons.calendar_today,
                                            color: Colors.grey[600],
                                            size: 20,
                                          ),
                                        ),
                                        onTap: () => _selectDate(_endDateController),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Start date → Expiry Date",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ===== Attachments =====
                      _fieldLabel("Attachments (Optional)"),
                      GestureDetector(
                        onTap: _pickFiles,
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 32,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Drop files here or click to upload",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "PDF, PNG, JPG up to 10MB",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_attachedFiles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...List.generate(_attachedFiles.length, (index) {
                          final file = _attachedFiles[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    file.path
                                        .split(Platform.pathSeparator)
                                        .last,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeFile(index),
                                  icon: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 8),

                      // Bottom row: Pin control on the left; actions (Cancel/Publish) on the right
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Pin control (left)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  "Pin to Dashboard",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: _pinToDashboard,
                                  onChanged: (value) => setState(() => _pinToDashboard = value),
                                ),
                              ],
                            ),
                          ),

                          // Actions (right)
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => context.go('/announcement'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "Publish",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Keep visible at top",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

          // Only ONE scroll view. If parent has a finite height, it we stretch to it.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child:
                hasBoundedHeight
                    ? ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: content,
                    )
                    : content, // if unbounded, don't force a minHeight
          );
        },
      ),
    );
  }
}
