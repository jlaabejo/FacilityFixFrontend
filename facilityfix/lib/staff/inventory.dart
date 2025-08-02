import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/calendar.dart';
import 'package:facilityfix/admin/home.dart';
import 'package:facilityfix/admin/workorder.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:flutter/material.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryState();
}

class _InventoryState extends State<InventoryPage> {
  final int _selectedIndex = 4;

  final List<Widget> pages = const [
    HomePage(),             // index 0
    WorkOrderPage(),        // index 1
    AnnouncementPage(),     // index 2
    CalendarPage(),         // index 3
    Placeholder(),          // Placeholder instead of self
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

      body: const SafeArea(
        child: Center(
          child: Text('Calendar Page'),
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
