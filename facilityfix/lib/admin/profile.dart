import 'dart:io';
import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/home.dart';
import 'package:facilityfix/admin/notification.dart';
import 'package:facilityfix/admin/workorder.dart';
import 'package:facilityfix/landingpage/splash_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/modals.dart';
import 'package:facilityfix/widgets/profile.dart';
import 'package:facilityfix/widgets/forgotPassword.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/services/profile_service.dart';

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
  final TextEditingController staffDepartmentController =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _profileImageFile;

  // Profile service and loading state
  final ProfileService _profileService = ProfileService();
  Map<String, dynamic>? _profileData;
  bool _isLoadingProfile = true;
  String _errorMessage = '';

  // In-memory persisted profile map (legacy support)
  Map<String, dynamic>? _profileMap;
  String _adminId = '';

  ImageProvider get _profileImageProvider {
    if (_profileImageFile != null) return FileImage(_profileImageFile!);
    
    // Use new profile data first
    if (_profileData != null &&
        _profileData!['photo_url'] != null &&
        _profileData!['photo_url'].toString().isNotEmpty) {
      try {
        return NetworkImage(_profileData!['photo_url'].toString());
      } catch (_) {
        // fallthrough to asset
      }
    }
    
    // Fallback to legacy profile map
    if (_profileMap != null &&
        _profileMap!['photo_url'] != null &&
        _profileMap!['photo_url'].toString().isNotEmpty) {
      try {
        return NetworkImage(_profileMap!['photo_url'].toString());
      } catch (_) {
        // fallthrough to asset
      }
    }
    return const AssetImage('assets/images/profile.png');
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Load user profile using the new ProfileService
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = '';
    });

    try {
      print('[AdminProfile] Loading user profile...');
      
      // Fetch profile using ProfileService
      final profile = await _profileService.getCurrentUserProfile();
      
      if (profile != null) {
        setState(() {
          _profileData = profile;
          _isLoadingProfile = false;
        });
        
        // Update controllers with new data
        _updateControllersFromProfile(profile);
        
        // Also save to legacy profile map for backward compatibility
        _profileMap = Map<String, dynamic>.from(profile);
        
        print('[AdminProfile] Profile loaded successfully');
      } else {
        // Try loading from legacy storage as fallback
        await _loadSavedProfile();
      }
    } catch (e) {
      print('[AdminProfile] Error loading profile: $e');
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoadingProfile = false;
      });
      
      // Try legacy fallback
      await _loadSavedProfile();
    }
  }

  /// Update text controllers from profile data
  void _updateControllersFromProfile(Map<String, dynamic> profile) {
    // Get display name using ProfileService
    final displayName = _profileService.getDisplayName(profile);
    nameController.text = displayName;

    // Get user ID
    _adminId = _profileService.getUserId(profile);

    // Email
    final contactInfo = _profileService.getContactInfo(profile);
    emailController.text = contactInfo['email'] ?? '';

    // Phone number (formatted)
    final phone = contactInfo['phone_number'] ?? contactInfo['phone'] ?? '';
    phoneNumberController.text = _profileService.formatPhoneNumber(phone);

    // Birth date
    final birthDate = profile['birth_date'] ?? profile['birthdate'] ?? '';
    birthDateController.text = _profileService.formatBirthDate(birthDate);

    // Department
    final primaryDept = _profileService.getPrimaryDepartment(profile);
    staffDepartmentController.text = primaryDept;

    // Handle profile image from local storage
    if (profile['photo_path'] != null && profile['photo_path'].toString().isNotEmpty) {
      final candidate = profile['photo_path'].toString();
      try {
        final f = File(candidate);
        if (f.existsSync()) {
          setState(() {
            _profileImageFile = f;
          });
        }
      } catch (_) {}
    }
  }

  // Title-case just the first name
  String _titleCaseFirstOnly(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first;
    final lower = first.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  // Extract phone number without +63 prefix
  String _formatPhoneNumber(String phone) {
    if (phone.startsWith('+63')) {
      return phone.substring(3); // Remove the +63 prefix
    }
    return phone;
  }

  Future<void> _loadSavedProfile() async {
    final saved = await AuthStorage.getProfile();

    // DEBUG: inspect what AuthStorage returns
    print('[AdminProfilePage] AuthStorage.getProfile() => $saved');

    // If no saved profile, leave controllers empty
    if (saved == null) {
      setState(() {
        nameController.text = '';
        emailController.text = '';
        phoneNumberController.text = '';
        birthDateController.text = '';
        staffDepartmentController.text = '';
        _adminId = '';
      });
      return;
    }

    // Ensure we have a mutable map
    _profileMap = Map<String, dynamic>.from(saved);

    // If the saved profile includes a local file path, set it
    if (_profileMap!['photo_path'] != null &&
        _profileMap!['photo_path'].toString().isNotEmpty) {
      final candidate = _profileMap!['photo_path'].toString();
      try {
        final f = File(candidate);
        if (f.existsSync()) _profileImageFile = f;
      } catch (_) {}
    }

    // Helper to try several keys for a value
    String extractFirstNonEmpty(List<String> keys) {
      for (final k in keys) {
        final v = _profileMap![k];
        if (v != null) {
          final s = v.toString().trim();
          if (s.isNotEmpty) return s;
        }
      }
      return '';
    }

    // Candidate key lists for first/last/full name
    final firstCandidates = [
      'first_name',
      'firstName',
      'given_name',
      'givenName',
    ];
    final lastCandidates = [
      'last_name',
      'lastName',
      'family_name',
      'familyName',
    ];
    final fullCandidates = [
      'full_name',
      'fullName',
      'name',
      'displayName',
      'display_name',
    ];

    final firstVal = extractFirstNonEmpty(firstCandidates);
    final lastVal = extractFirstNonEmpty(lastCandidates);
    final fullVal = extractFirstNonEmpty(fullCandidates);

    String fullName = '';

    if (fullVal.isNotEmpty) {
      // Use full_name AS-IS if backend provided it
      fullName = fullVal;
    } else if (firstVal.isNotEmpty || lastVal.isNotEmpty) {
      // Use title-cased first + DB last_name exactly as stored
      final firstPart =
          firstVal.isNotEmpty ? _titleCaseFirstOnly(firstVal) : '';
      final lastPart = lastVal.isNotEmpty ? lastVal.trim() : '';
      fullName =
          [firstPart, lastPart].where((s) => s.isNotEmpty).join(' ').trim();
    } else {
      // fallback to email local-part or user id
      final emailRaw =
          (_profileMap!['email'] ?? _profileMap!['user_email'] ?? '')
              .toString()
              .trim();
      if (emailRaw.isNotEmpty) {
        final at = emailRaw.indexOf('@');
        final local = at > 0 ? emailRaw.substring(0, at) : emailRaw;
        final cleaned = local.replaceAll(RegExp(r'[\._\-]+'), ' ').trim();
        if (cleaned.isNotEmpty) fullName = cleaned;
      }

      if (fullName.isEmpty) {
        final idRaw =
            (_profileMap!['user_id'] ?? _profileMap!['id'] ?? '')
                .toString()
                .trim();
        fullName = idRaw.isNotEmpty ? idRaw : 'User';
      }
    }

    // Fill controllers from saved profile
    nameController.text = fullName;

    // Admin ID (prefer user_id then id)
    _adminId = (_profileMap!['user_id'] ?? _profileMap!['id'] ?? '').toString();

    emailController.text = (_profileMap!['email'] ?? '').toString();

    final phone =
        (_profileMap!['phone_number'] ??
                _profileMap!['phone'] ??
                _profileMap!['phoneNumber'] ??
                '')
            .toString();
    phoneNumberController.text =
        phone.isNotEmpty ? _formatPhoneNumber(phone) : '';

    final bdayRaw =
        (_profileMap!['birthdate'] ??
                _profileMap!['birth_date'] ??
                _profileMap!['birthDate'] ??
                '')
            .toString();
    birthDateController.text =
        bdayRaw.isNotEmpty ? formatPrettyFromString(bdayRaw) : '';

    // For admin, use department-related fields
    staffDepartmentController.text = extractFirstNonEmpty([
      'department',
      'admin_department',
      'role',
      'adminRole',
      'position',
    ]);

    if (mounted) {
      setState(() {});
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
                        // persist path to profile map and save
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
        role: UserRole.admin,
        initialFullName: nameController.text,
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
      // Process the full name to preserve last name exactly
      final entered = updated.fullName.trim();
      String firstPart = '';
      String lastPart = '';

      if (entered.isNotEmpty) {
        final parts = entered.split(RegExp(r'\s+'));
        if (parts.isNotEmpty) {
          firstPart = _titleCaseFirstOnly(parts.first);
          if (parts.length > 1) {
            lastPart = parts.sublist(1).join(' ').trim();
          }
        }
      }

      // Update profile using ProfileService
      final success = await _profileService.updateCurrentUserProfile(
        firstName: firstPart.isNotEmpty ? firstPart : null,
        lastName: lastPart.isNotEmpty ? lastPart : null,
        phoneNumber: updated.contactNumber.isNotEmpty ? updated.contactNumber : null,
        birthDate: updated.birthDate.isNotEmpty ? _normalizeBirthDateForSave(updated.birthDate) : null,
        staffDepartment: updated.staffDepartment?.isNotEmpty == true ? updated.staffDepartment : null,
      );

      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // Reload profile data
        await _loadUserProfile();
        
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
      
      print('[AdminProfile] Error updating profile: $e');
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

  /// Normalize birth date for saving (convert to YYYY-MM-DD format)
  String _normalizeBirthDateForSave(String prettyOrIso) {
    final trimmed = prettyOrIso.trim();
    // If it's already ISO-like (yyyy-mm-dd)
    final isoRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (isoRe.hasMatch(trimmed)) return trimmed;

    // Try parsing with DateTime
    try {
      final dt = DateTime.parse(trimmed);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      // fallback: return trimmed
      return trimmed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Profile',
        leading: const Padding(
          padding: EdgeInsets.only(right: 8),
          child: BackButton(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              );
            },
          ),
          // Add refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserProfile,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingProfile
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading profile...'),
                  ],
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading profile',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadUserProfile,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileInfoWidget(
                          profileImage: _profileImageProvider,
                          fullName: nameController.text.isNotEmpty
                              ? nameController.text
                              : 'User',
                          staffId: _adminId.isNotEmpty
                              ? 'Admin ID: #$_adminId'
                              : 'Admin ID: —',
                          onTap: () => _openPhotoPickerSheet(context),
                        ),
                        const SizedBox(height: 24),

                        // Profile completion indicator
                        if (_profileData != null) ...[
                          _buildProfileCompletionCard(),
                          const SizedBox(height: 24),
                        ],

                        // PERSONAL DETAILS
                        SectionCard(
                          title: 'Personal Details',
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.blueGrey,
                            ),
                            tooltip: 'Edit personal details',
                            onPressed: _openEditAllDetailsSheet,
                          ),
                          child: Column(
                            children: [
                              DetailRow(
                                label: 'Birth Date',
                                value: birthDateController.text.isNotEmpty
                                    ? formatPrettyFromString(
                                        birthDateController.text)
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
                              const SizedBox(height: 10),
                              DetailRow(
                                label: 'Department',
                                value: staffDepartmentController.text.isNotEmpty
                                    ? staffDepartmentController.text
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
                                  // Clear ProfileService cache
                                  _profileService.clearCache();
                                  // Clear saved auth/profile
                                  await AuthStorage.clear();
                                  // Navigate to welcome (clears nav stack)
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SplashScreen(),
                                    ),
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

  /// Build profile completion indicator card
  Widget _buildProfileCompletionCard() {
    final completionPercentage =
        _profileService.getProfileCompletionPercentage(_profileData);
    final isComplete = _profileService.isProfileComplete(_profileData);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isComplete ? Icons.check_circle : Icons.info_outline,
                  color: isComplete ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Profile Completion',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  '${completionPercentage.toInt()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isComplete ? Colors.green : Colors.orange,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isComplete
                  ? 'Your profile is complete!'
                  : 'Complete your profile to access all features',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
