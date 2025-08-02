import 'package:facilityfix/tenant/announcement.dart';
import 'package:facilityfix/tenant/home.dart';
import 'package:facilityfix/tenant/profile.dart';
import 'package:facilityfix/tenant/workorder.dart';
import 'package:facilityfix/widgets/view_details.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';

class ViewDetailsPage extends StatefulWidget {
  const ViewDetailsPage({super.key});

  @override
  State<ViewDetailsPage> createState() => _ViewDetailsPageState();
}

class _ViewDetailsPageState extends State<ViewDetailsPage> {
  int _selectedIndex = 1;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.person),
  ];

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const Profile(),
    ];

    if (index != 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
              child: const BackButton(),
            ),
            Text('View Details'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              RequestDetailsScreen(
                title: "Leaking Faucet",
                requestId: "REQ-2025-00123",
                classification: "Plumbing",
                date: "August 2, 2025",
                requestType: "Repair",
                unit: "A 1001",
                description: "Hi, I’d like to report a clogged drainage issue in the bathroom of my unit. The water is draining very slowly, and it’s starting to back up onto the floor. I’ve already tried using a plunger but it didn’t help. It’s been like this since yesterday and is getting worse. Please send someone to check and fix it as soon as possible. Thank you!",
                priority: "High",
                assigneeName: "Juan Dela Cruz",
                assigneeRole: "Plumber",
                attachments: [
                  "https://via.placeholder.com/140x80.png?text=Leak+1",
                  "https://via.placeholder.com/140x80.png?text=Leak+2",
                ],
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
