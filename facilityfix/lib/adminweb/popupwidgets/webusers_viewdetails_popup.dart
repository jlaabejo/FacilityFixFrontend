import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../popupwidgets/webforgotpassword_popup.dart';

class UserProfileDialog extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserProfileDialog({
    super.key,
    required this.user,
  });

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();

  // Static method to show the dialog
  static void show(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return UserProfileDialog(user: user);
      },
    );
  }
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  bool isEditMode = false;
  
  // Controllers for editable fields
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController contactController;
  late TextEditingController birthDateController;
  late TextEditingController departmentController;

  bool isNameValid = true;
  bool isEmailValid = true;
  bool isContactValid = true;
  bool isBirthDateValid = true;
  bool isDepartmentValid = true;

  bool _validateInputs() {
    setState(() {
      isNameValid = nameController.text.trim().isNotEmpty;
      isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(emailController.text.trim());
      isContactValid = contactController.text.trim().isNotEmpty;
      isBirthDateValid = birthDateController.text.trim().isNotEmpty;
      isDepartmentValid = departmentController.text.trim().isNotEmpty;
    });

    return isNameValid &&
        isEmailValid &&
        isContactValid &&
        isBirthDateValid &&
        isDepartmentValid;
  }

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    nameController = TextEditingController(text: widget.user['name'] ?? '');
    emailController = TextEditingController(text: widget.user['email'] ?? '');
    contactController = TextEditingController(text: widget.user['contactNumber'] ?? '');
    birthDateController = TextEditingController(text: widget.user['birthDate'] ?? '');
    departmentController = TextEditingController(text: widget.user['department'] ?? '');
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    nameController.dispose();
    emailController.dispose();
    contactController.dispose();
    birthDateController.dispose();
    departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: const BoxConstraints(
          maxWidth: 700,
          maxHeight: 700,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section
            _buildHeader(context),

            // Content Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image Section
                    _buildProfileImage(),
                    const SizedBox(height: 24),

                    // Name Section
                    _buildNameSection(),
                    const SizedBox(height: 8),

                    // Staff ID Section (Read-only)
                    _buildStaffIdSection(),
                    const SizedBox(height: 32),

                    // Personal Details Section
                    _buildPersonalDetailsSection(),
                  ],
                ),
              ),
            ),

            // Footer Section
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // Header with title, edit toggle, and close button
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 32, right: 24, top: 24, bottom: 16),
      child: Row(
        children: [
          const Text(
            'User Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          // Edit toggle button
          IconButton(
            onPressed: () => _toggleEditMode(),
            icon: Icon(
              isEditMode ? Icons.save : Icons.edit,
              color: isEditMode ? Colors.green[600] : Colors.blue[600],
              size: 24,
            ),
            tooltip: isEditMode ? 'Save Changes' : 'Edit Profile',
          ),
          const SizedBox(width: 8),
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.grey,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Profile image with camera icon for editing
  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blue[200]!,
              width: 3,
            ),
          ),
          child: CircleAvatar(
            radius: 58,
            backgroundColor: Colors.grey[100],
            backgroundImage: widget.user['profileImage'] != null
                ? NetworkImage(widget.user['profileImage'])
                : null,
            child: widget.user['profileImage'] == null
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey[400],
                  )
                : null,
          ),
        ),
        if (isEditMode)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blue[600],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                onPressed: () => _changeProfileImage(),
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
      ],
    );
  }

  // Name section with editing capability
  Widget _buildNameSection() {
    return isEditMode
        ? SizedBox(
            width: 300,
            child: TextFormField(
              controller: nameController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter name',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          )
        : Text(
            widget.user['name'] ?? 'No Name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          );
  }

  // Staff ID section (always read-only)
  Widget _buildStaffIdSection() {
    return Text(
      'Staff ID: ${widget.user['staffId'] ?? 'N/A'}',
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Personal details section with all editable fields
  Widget _buildPersonalDetailsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title with edit icon
          Row(
            children: [
              const Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (isEditMode)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.edit_note,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Birth Date field
          _buildDetailField(
            'Birth Date',
            birthDateController,
            widget.user['birthDate'] ?? 'Not specified',
            isDate: true,
          ),
          const SizedBox(height: 20),

          // Staff Department field
          _buildDetailField(
            'Staff Department',
            departmentController,
            widget.user['department'] ?? 'Not specified',
          ),
          const SizedBox(height: 20),

          // Email field
          _buildDetailField(
            'Email',
            emailController,
            widget.user['email'] ?? 'Not specified',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),

          // Contact Number field
          _buildDetailField(
            'Contact Number',
            contactController,
            widget.user['contactNumber'] ?? 'Not specified',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),

          // Forgot Password link
          _buildForgotPasswordSection(),
        ],
      ),
    );
  }

  // Individual detail field with edit/view modes
  Widget _buildDetailField(
    String label,
    TextEditingController controller,
    String displayValue, {
    bool isDate = false,
    TextInputType? keyboardType,
  }) {
    // Pick the right validation flag for this field
    bool isValid = true;
    Function(bool)? setValid;

    if (label == "Email") {
      isValid = isEmailValid;
      setValid = (v) => isEmailValid = v;
    } else if (label == "Contact Number") {
      isValid = isContactValid;
      setValid = (v) => isContactValid = v;
    } else if (label == "Birth Date") {
      isValid = isBirthDateValid;
      setValid = (v) => isBirthDateValid = v;
    } else if (label == "Staff Department") {
      isValid = isDepartmentValid;
      setValid = (v) => isDepartmentValid = v;
    } else if (label == "Name") {
      isValid = isNameValid;
      setValid = (v) => isNameValid = v;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        if (isEditMode)
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: isDate,
            onTap: isDate ? () => _selectDate(controller) : null,
            onChanged: (val) {
              if (setValid != null) {
                if (val.trim().isEmpty) {
                  setValid(false);
                } else if (label == "Email") {
                  setValid(RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(val));
                } else {
                  setValid(true);
                }
                setState(() {});
              }
            },
            decoration: InputDecoration(
              hintText: 'Enter $label',
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isValid ? Colors.grey[300]! : Colors.red,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isValid ? Colors.grey[300]! : Colors.red,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isValid ? const Color(0xFF1976D2) : Colors.red,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              suffixIcon: isDate
                  ? const Icon(Icons.calendar_today, size: 20)
                  : null,
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              displayValue,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        if (isEditMode && !isValid)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              "Please enter a valid $label",
              style: TextStyle(fontSize: 12, color: Colors.red[600]),
            ),
          ),
      ],
    );
  }


  // Forgot password section
  Widget _buildForgotPasswordSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Password Settings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _forgotPassword(),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[600],
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Footer with action buttons
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isEditMode) ...[
            // Cancel button (only in edit mode)
            OutlinedButton(
              onPressed: () => _cancelEdit(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
            // Save button (only in edit mode)
            ElevatedButton(
              onPressed: () => _saveChanges(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 0,
              ),
              child: const Text('Save Changes'),
            ),
          ] else ...[
            // Close button (only in view mode)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 0,
              ),
              child: const Text('Close'),
            ),
          ],
        ],
      ),
    );
  }

  // Event handlers and utility methods

  // Toggle between edit and view modes
  void _toggleEditMode() {
    if (isEditMode) {
      _saveChanges();
    } else {
      setState(() {
        isEditMode = true;
      });
    }
  }

  // Cancel editing and revert changes
  void _cancelEdit() {
    setState(() {
      isEditMode = false;
      // Reset controllers to original values
      nameController.text = widget.user['name'] ?? '';
      emailController.text = widget.user['email'] ?? '';
      contactController.text = widget.user['contactNumber'] ?? '';
      birthDateController.text = widget.user['birthDate'] ?? '';
      departmentController.text = widget.user['department'] ?? '';
    });
  }

  // Save changes to backend
  void _saveChanges() async {
    // Validate first
    if (!_validateInputs()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors before saving'),
          backgroundColor: Colors.red,
        ),
      );
      return; 
    }

    try {
      Map<String, dynamic> updatedUser = {
        'id': widget.user['id'],
        'staffId': widget.user['staffId'],
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'contactNumber': contactController.text.trim(),
        'birthDate': birthDateController.text.trim(),
        'department': departmentController.text.trim(),
        'profileImage': widget.user['profileImage'],
      };

      await _updateUserProfile(updatedUser);

      setState(() {
        isEditMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Date picker for birth date
  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      controller.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
    }
  }

  // Change profile image
  void _changeProfileImage() {
    // TODO: Implement image picker functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile image change coming soon...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Forgot password handler
  void _forgotPassword() {
    ForgotPasswordDialog.show(context);
  }

  // Backend API methods (implement these according to your backend)

  // Update user profile in backend
  Future<void> _updateUserProfile(Map<String, dynamic> updatedUser) async {
    // TODO: Implement API call to update user profile
    try {
      // Example API call structure:
      // await UserService.updateProfile(updatedUser);
      print('Updating user profile: $updatedUser');
      
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update the original user data for display
      widget.user.addAll(updatedUser);
      
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }
}