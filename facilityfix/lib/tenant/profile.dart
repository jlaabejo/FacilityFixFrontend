// lib/tenant/profile.dart
import 'dart:io';
import 'package:facilityfix/landingpage/welcomepage.dart';
import 'package:facilityfix/tenant/notification.dart';
import 'package:facilityfix/widgets/profile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:facilityfix/tenant/announcement.dart';
import 'package:facilityfix/tenant/home.dart';
import 'package:facilityfix/tenant/workorder.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/modals.dart';
import 'package:facilityfix/widgets/forgotPassword.dart';

// NEW: auth storage
import 'package:facilityfix/services/auth_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 3;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.person),
  ];

  // Controllers (page-level; live as long as this page)
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController buildingUnitNoController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _profileImageFile;

  // Keep an in-memory profile map so we can persist updates
  Map<String, dynamic>? _profileMap;

  // Tenant id (user_id) to display as Tenant ID
  String _tenantId = '';

  ImageProvider get _profileImageProvider {
    if (_profileImageFile != null) return FileImage(_profileImageFile!);
    // If profile map has a network photo_url, attempt NetworkImage fallback:
    if (_profileMap != null && _profileMap!['photo_url'] != null && _profileMap!['photo_url'].toString().isNotEmpty) {
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
    _loadSavedProfile();
  }

  // Title-case just the first name (preserve DB last_name exactly)
  String _titleCaseFirstOnly(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first;
    final lower = first.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  // ---------- REPLACED: loader that preserves DB last_name ----------
  Future<void> _loadSavedProfile() async {
    final saved = await AuthStorage.getProfile();

    // DEBUG: inspect what AuthStorage returns — remove once confirmed correct.
    print('[ProfilePage] AuthStorage.getProfile() => $saved');

    // If no saved profile, leave controllers empty (no demo prefill)
    if (saved == null) {
      nameController.text = '';
      emailController.text = '';
      phoneNumberController.text = '';
      birthDateController.text = '';
      buildingUnitNoController.text = '';
      _tenantId = '';
      if (!mounted) return;
      setState(() {});
      return;
    }

    // Ensure we have a mutable map
    _profileMap = Map<String, dynamic>.from(saved);

    // If the saved profile includes a local file path, set it
    if (_profileMap!['photo_path'] != null && _profileMap!['photo_path'].toString().isNotEmpty) {
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
    final firstCandidates = ['first_name', 'firstName', 'given_name', 'givenName'];
    final lastCandidates  = ['last_name', 'lastName', 'family_name', 'familyName'];
    final fullCandidates  = ['full_name', 'fullName', 'name', 'displayName', 'display_name'];

    final firstVal = extractFirstNonEmpty(firstCandidates);
    final lastVal  = extractFirstNonEmpty(lastCandidates);
    final fullVal  = extractFirstNonEmpty(fullCandidates);

    String fullName = '';

    if (fullVal.isNotEmpty) {
      // Use full_name AS-IS if backend provided it
      fullName = fullVal;
    } else if (firstVal.isNotEmpty || lastVal.isNotEmpty) {
      // Use title-cased first + DB last_name exactly as stored
      final firstPart = firstVal.isNotEmpty ? _titleCaseFirstOnly(firstVal) : '';
      final lastPart = lastVal.isNotEmpty ? lastVal.trim() : '';
      fullName = [firstPart, lastPart].where((s) => s.isNotEmpty).join(' ').trim();
    } else {
      // fallback to email local-part (nicer form) or user id
      final emailRaw = (_profileMap!['email'] ?? _profileMap!['user_email'] ?? '').toString().trim();
      if (emailRaw.isNotEmpty) {
        final at = emailRaw.indexOf('@');
        final local = at > 0 ? emailRaw.substring(0, at) : emailRaw;
        final cleaned = local.replaceAll(RegExp(r'[\._\-]+'), ' ').trim();
        if (cleaned.isNotEmpty) fullName = cleaned;
      }

      if (fullName.isEmpty) {
        final idRaw = (_profileMap!['user_id'] ?? _profileMap!['id'] ?? '').toString().trim();
        fullName = idRaw.isNotEmpty ? idRaw : 'User';
      }
    }

    // Fill controllers from saved profile, preserving UI formatting
    nameController.text = fullName;

    // Tenant ID (prefer user_id then id)
    _tenantId = (_profileMap!['user_id'] ?? _profileMap!['id'] ?? '').toString();

    emailController.text = (_profileMap!['email'] ?? '').toString();
    final phone = (_profileMap!['phone_number'] ?? _profileMap!['phone'] ?? _profileMap!['phoneNumber'] ?? '').toString();
    phoneNumberController.text = phone.isNotEmpty ? phone : '+63 ';
    final bdayRaw = (_profileMap!['birthdate'] ?? _profileMap!['birth_date'] ?? _profileMap!['birthDate'] ?? '').toString();
    birthDateController.text = bdayRaw.isNotEmpty ? formatPrettyFromString(bdayRaw) : '';
    buildingUnitNoController.text = (_profileMap!['building_unit'] ?? _profileMap!['buildingUnit'] ?? _profileMap!['unit'] ?? '').toString();

    if (!mounted) return;
    setState(() {});
  }
  // ---------- END REPLACED ----------

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    birthDateController.dispose();
    buildingUnitNoController.dispose();
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
        role: UserRole.tenant,
        initialFullName: nameController.text,
        initialBirthDate: birthDateController.text,
        initialUserEmail: emailController.text,
        initialContactNumber: phoneNumberController.text,
        initialBuildingUnitNo: buildingUnitNoController.text, // optional
      ),
    );

    if (updated == null || !mounted) return;

    // If the user typed a full name in the modal, we will try to preserve the last name exactly as entered.
    // Title-case the first name only.
    final entered = updated.fullName.trim();
    String firstPart = '';
    String lastPart = '';

    if (entered.isNotEmpty) {
      final parts = entered.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        firstPart = _titleCaseFirstOnly(parts.first);
        if (parts.length > 1) {
          lastPart = parts.sublist(1).join(' ').trim(); // preserve exact last name casing/spacing user entered
        }
      }
    }

    final titleCasedFull = [if (firstPart.isNotEmpty) firstPart, if (lastPart.isNotEmpty) lastPart].join(' ').trim();

    setState(() {
      nameController.text           = titleCasedFull;
      birthDateController.text      = formatPrettyFromString(updated.birthDate);
      buildingUnitNoController.text = updated.buildingUnitNo ?? '';
      emailController.text          = updated.userEmail;
      phoneNumberController.text    = updated.contactNumber;
    });

    // Merge updated fields into persisted profile map and save
    _profileMap = {
      ...?_profileMap,
      'first_name': firstPart,
      'last_name': lastPart,
      'email': updated.userEmail,
      'phone_number': updated.contactNumber,
      // save raw birthdate (store as YYYY-MM-DD if modal returns that)
      'birthdate': _normalizeBirthDateForSave(updated.birthDate),
      // store building/unit as a single string (preserve what modal returns)
      'building_unit': updated.buildingUnitNo ?? _profileMap?['building_unit'] ?? '',
      // ensure we don't clobber user_id if present
      'user_id': _profileMap?['user_id'] ?? _tenantId,
    };

    // Try to also extract building_id and unit_id if modal returned a parsable string like
    // "Building A • Unit 1001" or "Bldg A • Unit 1001" or "A 1001" or "A • 1001"
    final parsed = _parseBuildingUnit(updated.buildingUnitNo ?? '');
    if (parsed != null) {
      _profileMap = {
        ...?_profileMap,
        'building_id': parsed['building_id'],
        'unit_id': parsed['unit_id'],
      };
    }

    // Save tenant id if not already present
    if ((_profileMap?['user_id'] ?? '').toString().isEmpty && _tenantId.isNotEmpty) {
      _profileMap = {...?_profileMap, 'user_id': _tenantId};
    }

    await AuthStorage.saveProfile(_profileMap ?? {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  Map<String, String>? _parseBuildingUnit(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    // Common patterns:
    // "Building A • Unit 1001" or "Bldg A • Unit 1001"
    final regex1 = RegExp(r'(?i)(?:building|bldg)\s*[:]?\s*([^\s•,]+).*?(?:unit)\s*[:]?\s*([^\s•,]+)');
    final m1 = regex1.firstMatch(s);
    if (m1 != null) {
      return {'building_id': m1.group(1) ?? '', 'unit_id': m1.group(2) ?? ''};
    }

    // "A • 1001" or "A - 1001" or "A 1001"
    final regex2 = RegExp(r'^([A-Za-z0-9\-]+)[\s\-\•]+([A-Za-z0-9\-]+)$');
    final m2 = regex2.firstMatch(s);
    if (m2 != null) {
      return {'building_id': m2.group(1) ?? '', 'unit_id': m2.group(2) ?? ''};
    }

    // fallback: cannot parse
    return null;
  }

  String _extractFirstName(String full) {
    final parts = full.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  String _extractLastName(String full) {
    final parts = full.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  /// If the modal returns a pretty date like "Aug 14, 1999" or "1999-08-14",
  /// attempt to normalize to YYYY-MM-DD for saving. If unable, return original.
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
        ],
        leading: Row(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileInfoWidget(
                profileImage: _profileImageProvider,
                fullName: nameController.text,
                staffId: _tenantId.isNotEmpty ? 'Tenant ID: #$_tenantId' : 'Tenant ID: —',
                onTap: () => _openPhotoPickerSheet(context),
              ),
              const SizedBox(height: 24),

              // PERSONAL DETAILS — display-only
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
                      value: formatPrettyFromString(birthDateController.text),
                    ),
                    const SizedBox(height: 10),
                    DetailRow(
                      label: 'Building Unit No',
                      value: buildingUnitNoController.text.isEmpty
                          ? '—'
                          : buildingUnitNoController.text,
                    ),
                    const SizedBox(height: 10),
                    DetailRow(label: 'Email', value: emailController.text),
                    const SizedBox(height: 10),
                    DetailRow(label: 'Contact Number', value: phoneNumberController.text),
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
                        // Clear saved auth/profile
                        await AuthStorage.clear();
                        // Navigate to welcome (clears nav stack)
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const WelcomePage()),
                          (route) => false,
                        );
                      },
                      secondaryText: 'No',
                      onSecondaryPressed: () => Navigator.of(context).pop(),
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
