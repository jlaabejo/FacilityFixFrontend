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
import 'package:facilityfix/widgets/forms.dart';
import 'package:facilityfix/widgets/pop_up.dart';

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

  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _profileImageFile;

  // Provide profile image (default placeholder if none selected)
  ImageProvider get _profileImageProvider {
    if (_profileImageFile != null) {
      return FileImage(_profileImageFile!);
    }
    return const AssetImage('assets/images/profile.png');
  }

  // Bottom navigation tab handler
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

  // Modal bottom sheet for photo upload
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
              // Drag handle
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
              // Upload from gallery
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Upload from gallery'),
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    allowMultiple: false,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final file = File(result.files.first.path!);
                    setState(() => _profileImageFile = file);
                  }
                  if (context.mounted) Navigator.pop(ctx);
                },
              ),
              // Take a photo
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () async {
                  final XFile? photo =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    final file = File(photo.path);
                    setState(() => _profileImageFile = file);
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

  @override
  void initState() {
    super.initState();
    emailController.text = 'erika.deguzman@example.com';
    phoneNumberController.text = '+63 912 345 6789';
    passwordController.text = '••••••••';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
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
              // Profile avatar with edit badge
              ProfileInfoWidget(
                profileImage: _profileImageProvider,
                name: 'Erika De Guzman',
                staffId: 'Tenant ID: #T12345',
                onTap: () => _openPhotoPickerSheet(context),
              ),

              const SizedBox(height: 24),

              // Personal Details card with edit icon in header
              SectionCard(
                title: 'Personal Details',
                trailing: IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                  onPressed: () {
                    // TODO: Implement edit personal details logic
                  },
                ),
                child: Column(
                  children: [
                    InputField(
                      label: 'Email',
                      controller: emailController,
                      hintText: 'Auto-filled',
                      isRequired: true,
                      readOnly: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.mail),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InputField(
                      label: 'Phone Number',
                      controller: phoneNumberController,
                      hintText: 'Auto-filled',
                      isRequired: true,
                      readOnly: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 10),
                    PasswordInputField(
                      label: 'Password',
                      controller: passwordController,
                      hintText: 'Auto-filled',
                      isRequired: true,
                      readOnly: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.lock),
                      ),
                    ),
                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password flow
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(fontSize: 13, color: Colors.blue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Settings card
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

              // Logout
              LogoutButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CustomPopup(
                      title: 'Confirm Logout',
                      message: 'Are you sure you want to logout?',
                      primaryText: 'Yes',
                      onPrimaryPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WelcomePage(),
                          ),
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
