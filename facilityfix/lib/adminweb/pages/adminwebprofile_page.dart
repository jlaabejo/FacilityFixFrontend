import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';

class AdminWebProfilePage extends StatefulWidget {
  const AdminWebProfilePage({super.key});

  @override
  State<AdminWebProfilePage> createState() => _AdminWebProfilePageState();
}

class _AdminWebProfilePageState extends State<AdminWebProfilePage> {
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

  // Sample user data - Replace with actual backend data
  Map<String, dynamic> _userData = {
    'firstName': 'Emirhan',
    'lastName': 'Boruch',
    'email': 'emirhanboruch55@gmail.com',
    'phone': '+09 363 398 46',
    'bio': 'Team Manager',
    'role': 'System Administrator',
    'location': 'Leeds, United Kingdom',
    'adminLevel': 'Super Administrator',
    'accountStatus': 'Active',
    'profileType': 'Solo Administrator',
    'systemAccess': [
      'User and Role Management',
      'Calendar',
      'Work Orders'
    ]
  };

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
    _initializeControllers();
  }

  // Initialize text controllers with user data
  void _initializeControllers() {
    _firstNameController.text = _userData['firstName'];
    _lastNameController.text = _userData['lastName'];
    _emailController.text = _userData['email'];
    _phoneController.text = _userData['phone'];
    _bioController.text = _userData['bio'];
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

  // Save profile changes to backend
  void _saveProfileChanges() {
    // TODO: Implement backend API call to save changes
    setState(() {
      _userData['firstName'] = _firstNameController.text;
      _userData['lastName'] = _lastNameController.text;
      _userData['email'] = _emailController.text;
      _userData['phone'] = _phoneController.text;
      _userData['bio'] = _bioController.text;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Handle change password
  void _handleChangePassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController currentPasswordController = TextEditingController();
        final TextEditingController newPasswordController = TextEditingController();
        final TextEditingController confirmPasswordController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Change Password'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement password change API call
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }

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
      currentRoute: 'profile', // You might need to add this route to your layout
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
                        Text(
                          "Dashboard",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Administrator Profile",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Main Content Container
            Container(
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
                                "${_userData['firstName']} ${_userData['lastName']}",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${_userData['role']} • ${_userData['location']}",
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Text(
                            _userData['accountStatus'],
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
                        // Personal Information Section
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
                                "First Name",
                                _userData['firstName'],
                                _firstNameController,
                              ),
                              
                              // Last Name Field
                              _buildInfoField(
                                "Last Name",
                                _userData['lastName'],
                                _lastNameController,
                              ),
                              
                              // Email Field
                              _buildInfoField(
                                "Email address",
                                _userData['email'],
                                _emailController,
                              ),
                              
                              // Phone Field
                              _buildInfoField(
                                "Phone",
                                _userData['phone'],
                                _phoneController,
                              ),
                              
                              // Bio Field
                              _buildInfoField(
                                "Bio",
                                _userData['bio'],
                                _bioController,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 60),
                        
                        // Admin Details Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Admin Details",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Admin Level
                              _buildReadOnlyField(
                                "Admin Level",
                                _userData['adminLevel'],
                              ),
                              
                              // Account Status
                              _buildReadOnlyField(
                                "Account Status",
                                _userData['accountStatus'],
                              ),
                              
                              // Profile Type
                              _buildReadOnlyField(
                                "Profile Type",
                                _userData['profileType'],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // System Access Section
                    const Text(
                      "System Access",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Access List
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _userData['systemAccess'].map<Widget>((access) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                access,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Action Buttons
                    Row(
                      children: [
                        // Change Password Button
                        OutlinedButton.icon(
                          onPressed: _handleChangePassword,
                          icon: const Icon(Icons.lock_outline, size: 18),
                          label: const Text("Change Password"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Edit Profile Button
                        ElevatedButton.icon(
                          onPressed: _handleEditProfile,
                          icon: Icon(
                            _isEditMode ? Icons.save : Icons.edit,
                            size: 18,
                          ),
                          label: Text(_isEditMode ? "Save Profile" : "Edit Profile"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
        ),
      ),
    );
  }

  // Helper method to build editable info fields
  Widget _buildInfoField(String label, String value, TextEditingController controller) {
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
                  decoration: InputDecoration(
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
                      borderSide: const BorderSide(color: Color(0xFF1976D2)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
        ],
      ),
    );
  }

  // Helper method to build read-only fields
  Widget _buildReadOnlyField(String label, String value) {
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}