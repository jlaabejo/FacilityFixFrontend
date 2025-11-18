import 'package:facilityfix/adminweb/widgets/logout_popup.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../layout/facilityfix_layout.dart';
import '../services/api_service.dart';
import '../../services/auth_storage.dart';

class EditAnnouncementPage extends StatefulWidget {
  final String announcementId;

  const EditAnnouncementPage({super.key, required this.announcementId});

  @override
  State<EditAnnouncementPage> createState() => _EditAnnouncementPageState();
}

class _EditAnnouncementPageState extends State<EditAnnouncementPage> {
  final ApiService _apiService = ApiService();

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  // Form state variables
  String? _selectedAudience;
  String? _selectedType;
  String? _selectedLocation;
  List<File> _attachedFiles = [];
  // Custom 'Others' inputs (copied from CreateAnnouncementPage)
  final TextEditingController _customTypeController = TextEditingController();
  final TextEditingController _customLocationController =
      TextEditingController();
  bool _showCustomType = false;
  bool _showCustomLocation = false;

  // Loading and error states
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _announcementId;

  // Dropdown options
  final List<String> _audienceOptions = ['Tenant', 'Staff', 'All'];

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

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  // Auth initialization method
  Future<void> _initializeAuth() async {
    try {
      // Get stored token from AuthStorage
      final token = await AuthStorage.getToken();

      if (token != null && token.isNotEmpty) {
        print('[Edit] Auth token loaded from storage');

        // Get user profile for additional info if needed
        final profile = await AuthStorage.getProfile();
        if (profile != null) {
          print('[Edit] User profile loaded: ${profile['email']}');
        }

        // Load announcement data
        await _loadAnnouncementData();
      } else {
        throw Exception('No authentication token found. Please login again.');
      }
    } catch (e) {
      print('[Edit] Error initializing auth: $e');
      setState(() {
        _errorMessage = 'Authentication error: $e';
        _isLoading = false;
      });
    }
  }

  // Load existing announcement data
  Future<void> _loadAnnouncementData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('[Edit] Fetching announcement: ${widget.announcementId}');

      final response = await _apiService.getAnnouncement(widget.announcementId);

      print('[Edit] Loaded announcement data: $response');

      setState(() {
  // Populate form fields
  _titleController.text = response['title'] ?? '';
  _announcementId = response['formatted_id'] ?? response['announcement']?['formatted_id'] ?? response['id'] ?? response['announcement']?['id'] ?? widget.announcementId;
        _detailsController.text = response['content'] ?? '';

        // Set audience
        final audience = response['audience']?.toString().toLowerCase();
        if (audience == 'tenant' || audience == 'tenants') {
          _selectedAudience = 'Tenant';
        } else if (audience == 'staff') {
          _selectedAudience = 'Staff';
        } else {
          _selectedAudience = 'All';
        }

        // Set type (if backend value isn't in our known list, treat it as 'Others')
        final backendType = response['type']?.toString();
        final knownTypeValues =
            _typeOptions.map((t) => t['value'] as String).toList();
        if (backendType != null &&
            backendType.isNotEmpty &&
            !knownTypeValues.contains(backendType)) {
          _selectedType = 'Others';
          _showCustomType = true;
          _customTypeController.text = backendType;
        } else {
          _selectedType = backendType ?? 'General Announcement';
          _showCustomType = _selectedType == 'Others';
        }

        // Set location (handle unknown location as 'Others')
        final backendLocation = response['location_affected']?.toString();
        if (backendLocation != null &&
            backendLocation.isNotEmpty &&
            !_locationOptions.contains(backendLocation)) {
          _selectedLocation = 'Others';
          _showCustomLocation = true;
          _customLocationController.text = backendLocation;
        } else {
          _selectedLocation = backendLocation;
          _showCustomLocation = _selectedLocation == 'Others';
        }

        // Set schedule dates if available (using correct backend field names)
        if (response['scheduled_publish_date'] != null) {
          _startDateController.text = _formatDate(
            response['scheduled_publish_date'],
          );
        }
        if (response['expiry_date'] != null) {
          _endDateController.text = _formatDate(response['expiry_date']);
        }

        _isLoading = false;
      });
    } catch (e) {
      print('[Edit] Error loading announcement: $e');
  setState(() {
        _errorMessage = 'Failed to load announcement: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';

    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return '';
      }

      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      print('[Edit] Error formatting date: $e');
      return '';
    }
  }

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
void _handleLogout(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return const LogoutPopup();
    },
  );

  if (result == true) {
    context.go('/');
  }
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
    // If 'Others' is selected for type, require the custom input to be filled
    if (_selectedType == null ||
        (_selectedType == 'Others' &&
            _customTypeController.text.trim().isEmpty)) {
      _showErrorSnackBar('Please select a type');
      return false;
    }
    if (_detailsController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter announcement details');
      return false;
    }
    return true;
  }

  // Show error snackbar with minimalist aesthetically pleasing styling
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
        margin: EdgeInsets.only(
          left: 24,
          bottom: 24,
          right: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        elevation: 2,
      ),
    );
  }

  // Show success snackbar with minimalist aesthetically pleasing styling
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
        margin: EdgeInsets.only(
          left: 24,
          bottom: 24,
          right: MediaQuery.of(context).size.width * 0.7,
        ),
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

  // Submit form - update announcement
  void _submitForm() async {
    if (!_validateForm()) return;

    setState(() {
      _isSaving = true;
    });

    final finalType =
        _showCustomType && _customTypeController.text.trim().isNotEmpty
            ? _customTypeController.text.trim()
            : _selectedType ?? 'General Announcement';

    final finalLocation =
        _showCustomLocation && _customLocationController.text.trim().isNotEmpty
            ? _customLocationController.text.trim()
            : _selectedLocation;

    final updateData = {
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
      'notify_changes': true, // Notify users about the update
    };

    try {
      print('[Edit] Updating announcement with data: $updateData');

      final response = await _apiService.updateAnnouncement(
        widget.announcementId,
        updateData,
      );

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        _showSuccessSnackBar(
          'Announcement updated successfully! ID: ${response['formatted_id'] ?? widget.announcementId}',
        );

        // Navigate back to announcement list after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/announcement');
          }
        });
      }
    } catch (e) {
      print('[Edit] Error updating announcement: $e');

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        _showErrorSnackBar('Failed to update announcement: $e');
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
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/announcement'),
                      child: const Text('Back to Announcements'),
                    ),
                  ],
                ),
              )
              : LayoutBuilder(
                builder: (context, constraints) {
                  final hasBoundedHeight = constraints.hasBoundedHeight;

                  final content = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "Announcement",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => context.go('/dashboard'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                child: const Text('Edit'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Main Form Container
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ===== Basic Information =====
                              _buildSectionHeader(
                                'Basic Information',
                                'General details about the announcement',
                              ),
                              const SizedBox(height: 24),

                              // Title
                              // Title + Announcement ID (read-only)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _fieldLabel("Title"),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.white,
                                          ),
                                          child: TextField(
                                            controller: _titleController,
                                            decoration: InputDecoration(
                                              hintText: "e.g., Scheduled Water Interruption",
                                              hintStyle: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 14,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _fieldLabel("Announcement ID"),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: 48,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey[300]!),
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.grey[50],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                _announcementId ?? 'N/A',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _fieldLabel("Audience"),
                                        Container(
                                          height: 48,
                                          child:
                                              DropdownButtonFormField<String>(
                                                value: _selectedAudience,
                                                decoration: _decoration(
                                                  "Select recipients...",
                                                ),
                                                isExpanded: true,
                                                items:
                                                    _audienceOptions.map((
                                                      audience,
                                                    ) {
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _fieldLabel("Announcement Type"),
                                        Container(
                                          height: 48,
                                          child: DropdownButtonFormField<
                                            String
                                          >(
                                            value: _selectedType,
                                            decoration: _decoration(
                                              "Select type...",
                                            ),
                                            isExpanded: true,
                                            items:
                                                _typeOptions.map((type) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value:
                                                        type['value'] as String,
                                                    child: Text(
                                                      type['label'] as String,
                                                    ),
                                                  );
                                                }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedType = value;
                                                _showCustomType =
                                                    value == 'Others';
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
                                        decoration: _decoration(
                                          "Enter custom type...",
                                        ),
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
                                decoration: _decoration(
                                  "Enter the full announcement details...",
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Divider(
                                color: Color(0xFFE2E8F0),
                                height: 1,
                                thickness: 1,
                              ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _fieldLabel(
                                          "Location Affected (Optional)",
                                        ),
                                        DropdownButtonFormField<String>(
                                          value: _selectedLocation,
                                          decoration: _decoration(
                                            "Select location...",
                                          ),
                                          items: [
                                            const DropdownMenuItem(
                                              value: null,
                                              child: Text("None"),
                                            ),
                                            ..._locationOptions.map(
                                              (loc) => DropdownMenuItem(
                                                value: loc,
                                                child: Text(loc),
                                              ),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedLocation = value;
                                              _showCustomLocation =
                                                  value == 'Others';
                                              if (!_showCustomLocation) {
                                                _customLocationController
                                                    .clear();
                                              }
                                            });
                                          },
                                        ),
                                        if (_showCustomLocation) ...[
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller:
                                                _customLocationController,
                                            decoration: _decoration(
                                              "Enter custom location...",
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  // Schedule
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _fieldLabel("Schedule Visibility"),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller:
                                                    _startDateController,
                                                readOnly: true,
                                                decoration: _decoration(
                                                  "DD / MM / YY",
                                                ).copyWith(
                                                  suffixIcon: Icon(
                                                    Icons.calendar_today,
                                                    color: Colors.grey[600],
                                                    size: 20,
                                                  ),
                                                ),
                                                onTap:
                                                    () => _selectDate(
                                                      _startDateController,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _endDateController,
                                                readOnly: true,
                                                decoration: _decoration(
                                                  "DD / MM / YY",
                                                ).copyWith(
                                                  suffixIcon: Icon(
                                                    Icons.calendar_today,
                                                    color: Colors.grey[600],
                                                    size: 20,
                                                  ),
                                                ),
                                                onTap:
                                                    () => _selectDate(
                                                      _endDateController,
                                                    ),
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

                              // Attachments
                              Text(
                                "Attachments (Optional)",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
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
                                ...List.generate(_attachedFiles.length, (
                                  index,
                                ) {
                                  final file = _attachedFiles[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
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
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
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
                              const SizedBox(height: 24),

                              // Bottom Actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed:
                                        () => context.go('/announcement'),
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
                                    onPressed: _isSaving ? null : _submitForm,
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
                                    child:
                                        _isSaving
                                            ? const SizedBox(
                                              width: 80,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    "Saving...",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            : const Text(
                                              "Save",
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
                        ),
                      ),
                    ],
                  );

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
                            : content,
                  );
                },
              ),
    );
  }
}
