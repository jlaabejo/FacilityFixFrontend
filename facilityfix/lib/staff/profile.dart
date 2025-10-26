// lib/staff/profile.dart
import 'dart:io';
import 'package:facilityfix/landingpage/splash_screen.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/notification.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/modals.dart';
import 'package:facilityfix/widgets/profile.dart';
import 'package:facilityfix/widgets/forgotPassword.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/services/profile_service.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 0;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController staffDepartmentController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _profileImageFile;

  // Profile service for API calls
  final ProfileService _profileService = ProfileService();

  // In-memory persisted profile map
  Map<String, dynamic>? _profileMap;
  String _staffId = '';
  String _fullName = 'User';

  ImageProvider? get _profileImageProvider {
    if (_profileImageFile != null) return FileImage(_profileImageFile!);
    if (_profileMap != null &&
        _profileMap!['photo_url'] != null &&
        _profileMap!['photo_url'].toString().isNotEmpty) {
      try {
        return NetworkImage(_profileMap!['photo_url'].toString());
      } catch (_) {}
    }
    return null; // Return null to show initials
  }

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
  }

  Future<void> _loadSavedProfile() async {
    final saved = await AuthStorage.getProfile();
    print('[StaffProfilePage] Raw saved data: $saved');

    if (saved == null) {
      setState(() {
        _fullName = 'User';
        emailController.text = '';
        phoneNumberController.text = '';
        birthDateController.text = '';
        staffDepartmentController.text = '';
        _staffId = '';
      });
      return;
    }

    _profileMap = Map<String, dynamic>.from(saved);

    print('Available keys in saved profile: ${_profileMap!.keys.toList()}');

    // Use full_name if first/last missing
    final firstName = (_profileMap!['first_name'] ?? '').toString();
    final lastName = (_profileMap!['last_name'] ?? '').toString();
    final fullNameFromKey = (_profileMap!['full_name'] ?? '').toString();
    final email = (_profileMap!['email'] ?? '').toString();
    final phone = (_profileMap!['phone_number'] ?? '').toString();
    final staffDept = (_profileMap!['staff_department'] ?? '').toString();
    final staffId = (_profileMap!['staff_id'] ?? _profileMap!['id'] ?? '').toString();
    final birthDate = (_profileMap!['birthdate'] ?? _profileMap!['birth_date'] ?? '').toString();
    
    // Construct full name with fallback
    final fullName = (('$firstName $lastName').trim().isNotEmpty)
        ? '$firstName $lastName'.trim()
        : fullNameFromKey.trim();

    print('Extracted data: fullName=$fullName, email=$email, phone=$phone, '
          'staff_department=$staffDept, staffId=$staffId, birthDate=$birthDate');

    setState(() {
      _fullName = fullName.isNotEmpty ? fullName : 'User';
      emailController.text = email;
      phoneNumberController.text = phone;
      staffDepartmentController.text = staffDept;
      _staffId = staffId;
      birthDateController.text =
          birthDate.isNotEmpty ? _formatBirthDateForDisplay(birthDate) : '';
    });
  }

  String _formatBirthDateForDisplay(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateString)) {
        final date = DateTime.parse(dateString);
        return DateFormat('MMM dd, yyyy').format(date);
      }
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    birthDateController.dispose();
    staffDepartmentController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const ProfilePage(),
    ];
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  Future<void> _openPhotoPickerSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Change profile photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Upload from gallery'),
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    allowMultiple: false,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final path = result.files.first.path;
                    if (path != null) {
                      final file = File(path);
                      setState(() {
                        _profileImageFile = file;
                        _profileMap = {...?_profileMap, 'photo_path': path};
                        AuthStorage.saveProfile(_profileMap ?? {});
                      });
                    }
                  }
                  if (context.mounted) Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () async {
                  final XFile? photo = await _picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (photo != null) {
                    final file = File(photo.path);
                    setState(() {
                      _profileImageFile = file;
                      _profileMap = {...?_profileMap, 'photo_path': photo.path};
                      AuthStorage.saveProfile(_profileMap ?? {});
                    });
                  }
                  if (context.mounted) Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openForgotPasswordEmail() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ForgotPasswordEmailModal(),
    );
  }

  Future<void> _openEditAllDetailsSheet() async {
    final updated = await showModalBottomSheet<EditedProfileData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditProfileModal(
        role: UserRole.staff,
        initialFullName: _fullName,
        initialBirthDate: birthDateController.text,
        initialUserEmail: emailController.text,
        initialContactNumber: phoneNumberController.text,
        initialStaffDepartment: staffDepartmentController.text,
      ),
    );

    if (updated == null || !mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final parts = updated.fullName.trim().split(RegExp(r'\s+'));
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      // Update profile using ProfileService to call backend API
      final success = await _profileService.updateCurrentUserProfile(
        firstName: firstName.isNotEmpty ? firstName : null,
        lastName: lastName.isNotEmpty ? lastName : null,
        phoneNumber: updated.contactNumber.isNotEmpty ? updated.contactNumber : null,
        birthDate: updated.birthDate.isNotEmpty ? _normalizeBirthDateForSave(updated.birthDate) : null,
        staffDepartment: updated.staffDepartment,
      );

      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // Update local state and storage
        setState(() {
          _fullName = updated.fullName;
          emailController.text = updated.userEmail;
          phoneNumberController.text = updated.contactNumber;
          staffDepartmentController.text =
              updated.staffDepartment ?? staffDepartmentController.text;
          birthDateController.text = updated.birthDate.isNotEmpty
              ? _formatBirthDateForDisplay(updated.birthDate)
              : '';
        });

        _profileMap = {
          ...?_profileMap,
          'first_name': firstName,
          'last_name': lastName,
          'email': updated.userEmail,
          'phone_number': updated.contactNumber,
          'staff_department': updated.staffDepartment ?? _profileMap?['staff_department'],
          'birthdate': _normalizeBirthDateForSave(updated.birthDate),
          'birth_date': _normalizeBirthDateForSave(updated.birthDate),
        };

        await AuthStorage.saveProfile(_profileMap ?? {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();

      print('[StaffProfile] Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _normalizeBirthDateForSave(String prettyOrIso) {
    final trimmed = prettyOrIso.trim();
    final isoRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (isoRe.hasMatch(trimmed)) return trimmed;
    try {
      final dt = DateTime.parse(trimmed);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return trimmed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'View Details',
        leading: const Padding(
          padding: EdgeInsets.only(right: 8),
          child: BackButton(),
        ),
        showMore: true,
        showHistory: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileInfoWidget(
                profileImage: _profileImageProvider,
                fullName: _fullName,
                staffId:
                    _staffId.isNotEmpty ? 'Staff ID: #$_staffId' : 'Staff ID: —',
                onTap: () => _openPhotoPickerSheet(context),
              ),
              const SizedBox(height: 24),
              SectionCard(
                title: 'Personal Details',
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                  tooltip: 'Edit personal details',
                  onPressed: _openEditAllDetailsSheet,
                ),
                child: Column(
                  children: [
                    DetailRow(
                      label: 'Birth Date',
                      value: birthDateController.text.isNotEmpty
                          ? birthDateController.text
                          : '—',
                    ),
                    const SizedBox(height: 10),
                    DetailRow(
                      label: 'Staff Department',
                      value: staffDepartmentController.text.isNotEmpty
                          ? staffDepartmentController.text
                          : '—',
                    ),
                    const SizedBox(height: 10),
                    DetailRow(
                      label: 'Email',
                      value: emailController.text.isNotEmpty
                          ? emailController.text
                          : '—',
                    ),
                    const SizedBox(height: 10),
                    DetailRow(
                      label: 'Contact Number',
                      value: phoneNumberController.text.isNotEmpty
                          ? phoneNumberController.text
                          : '—',
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _openForgotPasswordEmail,
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF005CE7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: 'Settings',
                child: Column(
                  children: [
                    SettingsOption(
                      text: 'Notifications',
                      icon: Icons.notifications,
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    SettingsOption(
                      text: 'Privacy & Security',
                      icon: Icons.lock,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LogoutButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CustomPopup(
                      title: 'Confirm Logout',
                      message: 'Are you sure you want to logout?',
                      primaryText: 'Yes',
                      onPrimaryPressed: () async {
                        Navigator.of(context).pop();
                        await AuthStorage.clear();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SplashScreen()),
                          (route) => false,
                        );
                      },
                      secondaryText: 'No',
                      onSecondaryPressed: () =>
                          Navigator.of(context).pop(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
