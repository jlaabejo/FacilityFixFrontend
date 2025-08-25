import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/calendar.dart';
import 'package:facilityfix/admin/home.dart';
import 'package:facilityfix/admin/inventory.dart';
import 'package:facilityfix/admin/workorder.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/view_details.dart';

class FullDetails extends StatefulWidget {
  final String selectedTabLabel;

  const FullDetails({
    super.key,
    required this.selectedTabLabel,
  });

  @override
  State<FullDetails> createState() => _FullDetailsState();
}

class _FullDetailsState extends State<FullDetails> {
  int _selectedIndex = 1;

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

    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  Widget _buildTabContent() {
    switch (widget.selectedTabLabel.toLowerCase()) {
      // After assigning from a Concern Slip
      case 'concern slip assign staff':
        return RepairDetailsScreen(
          // Basic Information
          title: "Leaking Faucet",
          requestId: "REQ-2025-00123",
          statusTag: 'Assigned',
          date: "August 2, 2025",
          requestType: "Concern Slip",

          // Tenant / Requester Details
          requestedBy: "Erika De Guzman",
          unit: "A 1001",
          scheduleAvailability: 'August 19, 2025',

          // Request Details
          priority: "High",
          department: "Plumbing",
          description:
              "Hi, I’d like to report a clogged drainage issue in the bathroom...",

          // Assigned To
          assignedTo: "Juan Dela Cruz",
          assignedRole: "Plumber",

          attachments: const [
            "assets/images/upload1.png",
            "assets/images/upload2.png",
          ],
        );

      // Job Service full details
      case 'job service full details':
        return RepairDetailsScreen(
          // Basic Information
          title: "Leaking Faucet",
          requestId: "REQ-2025-00123",
          statusTag: 'Pending',
          date: "August 2, 2025",
          requestType: "Repair",

          // Tenant / Requester Details
          requestedBy: "Erika De Guzman",
          unit: "A 1001",
          scheduleAvailability: 'August 19, 2025',

          // Request Details
          priority: "High",
          department: "Plumbing",
          description:
              "Hi, I’d like to report a clogged drainage issue in the bathroom...",

          // Assessed by
          assigneeName: "Juan Dela Cruz",
          assigneeRole: "Plumber",
          assessment:
              'Inspecting all ceilings lights and emergency lighting. Check for flickering, burnt bulbs, and exposed wiring.',
          recommendation: 'Clear clogged drainage pipe.',

          // Assigned to
          assignedTo: "Juan Dela Cruz",
          assignedRole: "Plumber",
          assignedSchedule: 'August 19, 2025',

          attachments: const [
            "assets/images/upload1.png",
            "assets/images/upload2.png",
          ],
        );

      // Work Order Permit full details (accept both spellings)
      case 'work order permit full details':
      case 'work order permit details':
        return RepairDetailsScreen(
          // Basic Information
          title: "Leaking Faucet",
          requestId: "REQ-2025-00123",
          statusTag: 'Pending',
          date: "August 2, 2025",
          requestType: "Repair",

          // Tenant / Requester Details
          requestedBy: "Erika De Guzman",
          unit: "A 1001",
          scheduleAvailability: 'August 19, 2025',

          // Request Details
          priority: "High",
          department: "Plumbing",
          description:
              "Hi, I’d like to report a clogged drainage issue in the bathroom...",

          // Assessed by
          assigneeName: "Juan Dela Cruz",
          assigneeRole: "Plumber",

          assessment:
              'Inspecting all ceilings lights and emergency lighting. Check for flickering, burnt bulbs, and exposed wiring.',
          recommendation: 'Clear clogged drainage pipe.',

          attachments: const [
            "assets/images/upload1.png",
            "assets/images/upload2.png",
          ],

          // Permit details
          accountType: 'Air conditioning',
          permitId: 'PM-GEN-AC-001',
          issueDate: 'June 15, 2025',
          expirationDate: 'June 15, 2026',
          instructions: 'Ensure all safety protocols are followed during maintenance.',

          // Contractor profile
          contractorName: 'john doe',
          contractorCompany: 'Doe Enterprises',
          contractorPhone: '09171234567',
        );

      default:
        return const Center(child: Text("No requests found."));
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildTabContent(),
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
