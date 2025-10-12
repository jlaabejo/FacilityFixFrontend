import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../popupwidgets/webforgotpassword_popup.dart';
import '../../services/profile_service.dart';

class AdminWebProfilePage extends StatefulWidget {
  const AdminWebProfilePage({super.key});

  @override
  State<AdminWebProfilePage> createState() => _AdminWebProfilePageState();
}

class _AdminWebProfilePageState extends State<AdminWebProfilePage> {
  final ProfileService _profileService = ProfileService();
  
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

  // Profile data - will be loaded from backend
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  // Text controllers for form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // Edit mode toggle
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Load user profile from backend
  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final profile = await _profileService.getCurrentUserProfile();
      
      setState(() {
        _userData = profile;
        _isLoading = false;
      });

      _updateControllersFromProfile();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load profile: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update text controllers with user data
  void _updateControllersFromProfile() {
    if (_userData != null) {
      _firstNameController.text = _userData!['first_name'] ?? '';
      _lastNameController.text = _userData!['last_name'] ?? '';
      _emailController.text = _userData!['email'] ?? '';
      _phoneController.text = _userData!['phone_number'] ?? '';
      _bioController.text = _userData!['staff_department'] ?? '';
    }
  }

  // Handle edit profile button
  void _handleEditProfile() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
    
    if (!_isEditMode) {
      // Save changes - TODO: Implement backend API call
      _saveProfileChanges();
    }
  }

  // Save profile changes with validation
  Future<void> _saveProfileChanges() async {
    if (_userData == null) return;

    setState(() {
      _validationErrors['firstName'] =
          _firstNameController.text.trim().isEmpty ? 'First name is required' : null;

      _validationErrors['lastName'] =
          _lastNameController.text.trim().isEmpty ? 'Last name is required' : null;

      _validationErrors['email'] =
          !_emailController.text.contains('@') ? 'Invalid email address' : null;

      _validationErrors['phone'] =
          _phoneController.text.trim().isEmpty ? 'Phone number is required' : null;

      _validationErrors['department'] =
          _bioController.text.trim().isEmpty ? 'Department is required' : null;
    });

    // Stop if any errors exist
    if (_validationErrors.values.any((error) => error != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors before saving'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Update profile via ProfileService
      final success = await _profileService.updateCurrentUserProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        staffDepartment: _bioController.text.trim(),
      );

      if (success) {
        // Reload profile to get updated data
        await _loadUserProfile();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle change password
  void _handleChangePassword() {
    ForgotPasswordDialog.show(context);
  }

  // Track validation errors for each field
  final Map<String, String?> _validationErrors = {
    'firstName': null,
    'lastName': null,
    'email': null,
    'phone': null,
    'department': null,
  };

  bool isFirstNameValid = true;
  bool isLastNameValid = true;
  bool isEmailValid = true;
  bool isPhoneValid = true;
  bool isDepartmentValid = true;


  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'profile', 
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
            // Header Section with breadcrumbs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Breadcrumb and title section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Administrator Profile",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Breadcrumb navigation
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => context.go('/dashboard'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Dashboard'),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                        TextButton(
                          onPressed: null,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Profile'),
                        ),
                        
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Main Content Container
            _isLoading ? _buildLoadingWidget() : _buildProfileContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_userData == null) {
      return Center(
        child: Column(
          children: [
            const Text('Failed to load profile data'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
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
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Section
            const Text(
              "System Administrator",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // Profile Info Row
            Row(
              children: [
                // Profile Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 24),
                
                // Profile Name and Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_userData!['first_name'] ?? ''} ${_userData!['last_name'] ?? ''}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_userData!['role'] ?? 'Administrator'}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Text(
                    _userData!['status'] ?? 'Active',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 14, // bigger font
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Content Row - Personal Information and Admin Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Personal Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // First Name Field
                      _buildInfoField(
                        label: "First Name",
                        value: _userData!["first_name"] ?? "",
                        controller: _firstNameController,
                        isValid: isFirstNameValid,
                        setValid: (v) => isFirstNameValid = v,
                      ),

                      // Last Name Field
                      _buildInfoField(
                        label: "Last Name",
                        value: _userData!["last_name"] ?? "",
                        controller: _lastNameController,
                        isValid: isLastNameValid,
                        setValid: (v) => isLastNameValid = v,
                      ),

                      // Phone Field
                      _buildInfoField(
                        label: "Phone",
                        value: _userData!["phone_number"] ?? "",
                        controller: _phoneController,
                        isValid: isPhoneValid,
                        setValid: (v) => isPhoneValid = v,
                        isPhone: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 60),

                // Right Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email Field
                      _buildInfoField(
                        label: "Email",
                        value: _userData!["email"] ?? "",
                        controller: _emailController,
                        isValid: isEmailValid,
                        setValid: (v) => isEmailValid = v,
                        isEmail: true,
                      ),

                      // Department Field (was Bio)
                      _buildInfoField(
                        label: "Department",
                        value: _userData!["staff_department"] ?? "",
                        controller: _bioController,
                        isValid: isDepartmentValid,
                        setValid: (v) => isDepartmentValid = v,
                      ),
                      
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Action Buttons
            Row(
              children: [
                // Change Password Button
                OutlinedButton.icon(
                  onPressed: _handleChangePassword,
                  icon: const Icon(Icons.lock_outline, size: 20),
                  label: const Text(
                    "Change Password",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Edit Profile Button
                ElevatedButton.icon(
                  onPressed: _handleEditProfile,
                  icon: Icon(
                    _isEditMode ? Icons.save : Icons.edit,
                    size: 20,
                  ),
                  label: Text(
                    _isEditMode ? "Save Profile" : "Edit Profile",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build editable info fields
  Widget _buildInfoField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isValid,
    required Function(bool) setValid,
    bool isEmail = false,
    bool isPhone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _isEditMode
              ? TextField(
                  controller: controller,
                  keyboardType: isEmail
                      ? TextInputType.emailAddress
                      : isPhone
                          ? TextInputType.phone
                          : TextInputType.text,
                  decoration: InputDecoration(
                    hintText: "Enter $label",
                    prefixIcon: Icon(
                      isEmail
                          ? Icons.email_outlined
                          : isPhone
                              ? Icons.phone
                              : Icons.text_fields,
                      color: isValid ? Colors.grey[500] : Colors.red,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: isValid ? Colors.grey[300]! : Colors.red),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: isValid ? Colors.grey[300]! : Colors.red),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: isValid ? const Color(0xFF1976D2) : Colors.red,
                          width: 2),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (val) {
                    // live validation
                    if (val.trim().isEmpty) {
                      setValid(false);
                    } else {
                      if (isEmail) {
                        setValid(RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(val));
                      } else {
                        setValid(true);
                      }
                    }
                    setState(() {});
                  },
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
          if (!isValid)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                "Please enter a valid $label",
                style: TextStyle(fontSize: 12, color: Colors.red[600]),
              ),
            ),
        ],
      ),
    );
  }
}