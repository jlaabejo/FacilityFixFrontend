import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/widgets/tag.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/view_details.dart';

class InventoryDetails extends StatefulWidget {
  final String selectedTabLabel; 

  const InventoryDetails({
    super.key,
    required this.selectedTabLabel,
  });

  @override
  State<InventoryDetails> createState() => _InventoryDetailsState();
}

class _InventoryDetailsState extends State<InventoryDetails> {
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
      case 'inventory details':
        return InventoryDetailsScreen(
          itemName: 'Galvanized Screw 3mm',
          sku: 'MAT-CIV-003',
          headerBadge: const Tag(
            label: 'High Turnover',
            bg: Color(0xFFFFD6D0),
            fg: Color(0xFFEF4444),
            fontSize: 12,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          dateAdded: 'Automated',
          classification: 'Materials',
          brandName: '-',
          department: 'Civil/Carpentry',
          stockStatus: 'In Stock',
          quantityInStock: '150 pcs',
          reorderLevel: '50 pcs',
          unit: 'pcs',
          supplier: 'Screw Incop.', 
          warrantyUntil: 'DD / MM / YY',
        );

      case 'inventory request':
        return InventoryRequestDetailsScreen(
          itemName: 'LED Tube Light',
          requestId: 'REQ-2025-001',
          headerBadge: StatusTag(status: 'Pending'),
          requestedDate: 'Automated',
          requestedBy: 'Juan Dela Cruz',
          department: 'Maintenance',
          neededBy: '2025-08-20',
          location: 'Lobby',
          classification: 'Lighting',
          quantity: '5',
          unit: 'pcs',
          notes: 'Replace flickering lights near elevator lobby.',
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
        leading: Row(
          children: const [
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: BackButton(),
            ),
            Text('View Details'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildTabContent(), // Display selected tab content
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
