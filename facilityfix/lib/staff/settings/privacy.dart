
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/maintenance_task.dart';
import 'package:facilityfix/staff/repair_task.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  final int _selectedIndex = 0;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.build),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const RepairTaskPage(),
      const MaintenanceTaskPage(),
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

  Widget _buildTabContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Privacy Policy',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Last updated: November 28, 2025',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 18),
          const Text(
            '1. Introduction',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'FacilityFix ("we", "us", or "our") is committed to protecting the privacy of our users. This Privacy Policy explains how we collect, use, disclose, and safeguard your personal information when you use our services. By using our services, you consent to the collection and use of information in accordance with this policy.',
          ),
          const SizedBox(height: 16),
          const Text(
            '2. Information We Collect',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'We may collect the following types of information: account information (name, email, contact), usage data, device data, location (if enabled), and any information you submit through forms or support requests. We only collect the minimum data necessary to provide and improve our services.',
          ),
          const SizedBox(height: 16),
          const Text(
            '3. How We Use Your Information',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your information is used to support and operate the app, respond to requests, provide notifications, improve our products, and comply with legal obligations. We do not sell personal data to third parties.',
          ),
          const SizedBox(height: 16),
          const Text(
            '4. Sharing and Disclosure',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'We may share information with third-party service providers who perform services on our behalf (e.g., analytics, hosting), or where required by law. We require such providers to use your data only for the purposes we specify.',
          ),
          const SizedBox(height: 16),
          const Text(
            '5. Your Rights',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Depending on your location, you may have certain rights regarding your personal data, including access, correction, or deletion. Contact our support for privacy-related requests.',
          ),
          const SizedBox(height: 16),
          const Text(
            '6. Security',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'We use reasonable administrative, technical and physical controls to protect your data. However, no system can guarantee absolute security.',
          ),
          const SizedBox(height: 16),
          const Text(
            '7. Contact Us',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'If you have any questions about this policy or wish to exercise your privacy rights, please contact the FacilityFix support team via the app or your account representative.'
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Privacy Policy',
        leading: Row(
          children: const [
            BackButton(),
            SizedBox(width: 8),
          ],
        ),
      ),
      body: SafeArea(
        child: _buildTabContent(),
      ),
      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
