import 'dart:async';
import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/calendar.dart';
import 'package:facilityfix/admin/forms/inventory.dart';
import 'package:facilityfix/admin/home.dart';
import 'package:facilityfix/admin/notification.dart';
import 'package:facilityfix/admin/view_details/inventory.dart';
import 'package:facilityfix/admin/workorder.dart';
import 'package:facilityfix/widgets/cards.dart';
import 'package:facilityfix/widgets/pop_up.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/buttons.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  // Tabs
  String selectedTabLabel = "Items";
  List<TabItem> tabs = [
    TabItem(label: 'Items', count: 0),
    TabItem(label: 'Requests', count: 0),
  ];

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  String _selectedClassification = "All"; // All | Electrical | Plumbing | Carpentry

  // Demo data (replace with backend)
  final List<_Item> _allItems = [
    _Item(
      name: 'Galvanized Screw 3mm',
      department: 'Carpentry',
      id: 'MAT-CIV-003',
      stockStatus: 'In Stock',
      quantity: 15,
    ),
    _Item(
      name: 'LED Tube Light 24W',
      department: 'Electrical',
      id: 'EL-LED-024',
      stockStatus: 'Low',
      quantity: 3,
    ),
    _Item(
      name: 'PVC Pipe 1 1/2"',
      department: 'Plumbing',
      id: 'PL-PVC-112',
      stockStatus: 'In Stock',
      quantity: 42,
    ),
  ];

  final List<_Request> _allRequests = [
    _Request(
      name: 'LED Tube Light',
      requestId: 'REQ-2025-001',
      department: 'Electrical',
      status: 'Pending',
    ),
    _Request(
      name: 'Door Hinge Set',
      requestId: 'REQ-2025-010',
      department: 'Carpentry',
      status: 'Approved',
    ),
  ];

  // Debounce for search
  Timer? _debounce;
  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => _onSearchChanged(_searchController.text));
    _recomputeTabCounts();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Filtering logic — keep it centralized
  bool _matchesClassification(String department) {
    if (_selectedClassification == 'All') return true;
    return department.toLowerCase() == _selectedClassification.toLowerCase();
  }

  bool _matchesSearch(String haystack) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return haystack.toLowerCase().contains(q);
  }

  List<_Item> get _filteredItems {
    return _allItems.where((it) {
      final deptMatch = _matchesClassification(it.department);
      final searchMatch = _matchesSearch("${it.name} ${it.id} ${it.department}");
      return deptMatch && searchMatch;
    }).toList();
  }

  List<_Request> get _filteredRequests {
    return _allRequests.where((rq) {
      final deptMatch = _matchesClassification(rq.department);
      final searchMatch = _matchesSearch("${rq.name} ${rq.requestId} ${rq.department} ${rq.status}");
      return deptMatch && searchMatch;
    }).toList();
  }

  void _recomputeTabCounts() {
    final itemsCount = _filteredItems.length;
    final requestsCount = _filteredRequests.length;
    setState(() {
      tabs = [
        TabItem(label: 'Items', count: itemsCount),
        TabItem(label: 'Requests', count: requestsCount),
      ];
    });
  }

  Future<void> _refresh() async {
    // TODO: Load from backend here
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _recomputeTabCounts();
    setState(() {});
  }

  void _onClassificationChanged(String classification) {
    setState(() {
      _selectedClassification = classification;
    });
    _recomputeTabCounts();
  }

  void _showRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CustomPopup(
        title: 'Create Inventory Item',
        message: 'Would you like to create a new inventory item?',
        primaryText: 'Yes',
        onPrimaryPressed: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InventoryForm(requestType: 'Inventory From'),
            ),
          );
        },
        secondaryText: 'Cancel',
        onSecondaryPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildTabContent() {
    if (selectedTabLabel.toLowerCase() == 'items') {
      final list = _filteredItems;
      if (list.isEmpty) {
        return const _EmptyState(title: 'No items found', subtitle: 'Try adjusting search or filters.');
      }
      return ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final it = list[i];
          return InventoryCard(
            itemName: it.name,
            stockStatus: it.stockStatus,
            itemId: it.id,
            department: it.department,
            quantity: it.quantity.toString(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InventoryDetails(selectedTabLabel: 'inventory details'),
                ),
              );
            },
          );
        },
      );
    } else {
      final list = _filteredRequests;
      if (list.isEmpty) {
        return const _EmptyState(title: 'No item found', subtitle: 'Try adjusting search or filters.');
      }
      return ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final rq = list[i];
          return InventoryRequestCard(
            itemName: rq.name,
            requestId: rq.requestId,
            department: rq.department,
            status: rq.status,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InventoryDetails(selectedTabLabel: 'inventory request'),
                ),
              );
            },
          );
        },
      );
    }
  }

  // Navigation bar behavior
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
    if (index != 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep counts in sync on every build
    _recomputeTabCounts();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Inventory',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search & Filter 
                SearchAndFilterBar
                (
                  searchController: _searchController,
                  selectedClassification: _selectedClassification,
                  classifications: const ['All', 'Electrical', 'Plumbing', 'Carpentry'],
                  onSearchChanged: (_) {
                    // search is already debounced in listener; just rebuild
                    setState(() {});
                    _recomputeTabCounts();
                  },
                  onFilterChanged: _onClassificationChanged,
                ),
                const SizedBox(height: 16),

                // Tabs (with live counts)
                StatusTabSelector(
                  tabs: tabs,
                  selectedLabel: selectedTabLabel,
                  onTabSelected: (label) {
                    setState(() => selectedTabLabel = label);
                  },
                ),
                const SizedBox(height: 16),

                Text(
                  selectedTabLabel == 'Items' ? 'Recent Items' : 'Recent Requests',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildTabContent()),
              ],
            ),
          ),
        ),
      ),

      // FAB only on Items tab
      floatingActionButton: selectedTabLabel.toLowerCase() == 'items'
          ? AddButton(onPressed: () => _showRequestDialog(context))
          : null,

      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: 4,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ======= Small helpers / models =======

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Color(0xFF9AA0A6)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF697076))),
          ],
        ),
      ),
    );
  }
}

class _Item {
  final String name;
  final String department; // Electrical | Plumbing | Carpentry | ...
  final String id;
  final String stockStatus; // In Stock | Low | Out
  final int quantity;

  _Item({
    required this.name,
    required this.department,
    required this.id,
    required this.stockStatus,
    required this.quantity,
  });
}

class _Request {
  final String name;
  final String requestId;
  final String department;
  final String status; // Pending | Approved | Rejected

  _Request({
    required this.name,
    required this.requestId,
    required this.department,
    required this.status,
  });
}
