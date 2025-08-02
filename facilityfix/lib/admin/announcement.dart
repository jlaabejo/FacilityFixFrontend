
import 'package:facilityfix/admin/calendar.dart';
import 'package:facilityfix/admin/forms.dart';

import 'package:facilityfix/admin/home.dart';
import 'package:facilityfix/admin/inventory.dart';
import 'package:facilityfix/admin/workorder.dart';
import 'package:facilityfix/widgets/announcement_cards.dart';
import 'package:facilityfix/widgets/buttons.dart';
import 'package:facilityfix/widgets/pop_up.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementState();
}

class _AnnouncementState extends State<AnnouncementPage> {
  int _selectedIndex = 2;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const CalendarPage(),
      const InventoryPage(),
    ];

    if (index != 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }
  
  void _showRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => CustomPopup(
        title: 'Create an Announcement',
        message: 'Would you like to create a new announcement?',
        primaryText: 'Yes',
        onPrimaryPressed: () {
          Navigator.of(dialogContext).pop(); // use dialogContext, not context
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const AddForm(requestType: 'Maintenance Task'),
            ),
          );
        },
        secondaryText: 'Cancel',
        onSecondaryPressed: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: const Text('Announcement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notification tap
            },
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            
            // Latest Announcement Section
            AnnouncementCard(
              title: 'Utility Interruption',
              datePosted: '3 hours ago',
              details: 'Temporary shutdown in pipelines for maintenance cleaning.',
              classification: 'utility',
              onViewPressed: () {
                // Navigate to announcement details
              },
            ),
            // Add Button
            Positioned(
              bottom: 24,
              right: 24,
              child: AddButton(onPressed: () => _showRequestDialog(context)),
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
