import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/widgets/announcement_cards.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementState();
}

class _AnnouncementState extends State<AnnouncementPage> {
  int _selectedIndex = 2;

  final List<Widget> pages = const [
    HomePage(),             // index 0
    WorkOrderPage(),        // index 1
    Placeholder(),          // Placeholder instead of self
    CalendarPage(),         // index 3
    InventoryPage(),        // index 4
  ];

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    // Navigate to the correct page
    Widget destination;
    switch (index) {
      case 0:
        destination = const HomePage();
        break;
      case 1:
        destination = const WorkOrderPage();
        break;
      case 2:
        destination = const AnnouncementPage();
        break;
      case 3:
        destination = const CalendarPage();
        break;
      case 4:
        destination = const InventoryPage();
        break;
      default:
        destination = const HomePage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
