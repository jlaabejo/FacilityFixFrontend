import 'dart:async';
import 'package:facilityfix/tenant/announcement.dart';
import 'package:facilityfix/tenant/chat.dart';
import 'package:facilityfix/tenant/home.dart';
import 'package:facilityfix/tenant/notification.dart';
import 'package:facilityfix/tenant/profile.dart';
import 'package:facilityfix/tenant/reminder.dart';
import 'package:facilityfix/tenant/request_forms.dart';
import 'package:facilityfix/tenant/view_details.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart';
import 'package:facilityfix/widgets/cards.dart';
import 'package:facilityfix/widgets/helper_models.dart'; 
import 'package:facilityfix/widgets/pop_up.dart';
import 'package:flutter/material.dart';

class WorkOrderPage extends StatefulWidget {
  const WorkOrderPage({super.key});

  @override
  State<WorkOrderPage> createState() => _WorkOrderPageState();
}

class _WorkOrderPageState extends State<WorkOrderPage> {
  // Tabs
  String _selectedTabLabel = "All";

  // Filters
  String _selectedClassification = "All"; // department filter
  final TextEditingController _searchController = TextEditingController();

  // Sample data (replace with backend)
  final List<WorkOrder> _all = [
    WorkOrder(
      title: "Clogged Drainage",
      requestId: "CS-2025-00321",
      date: "Jul 12",
      status: "Pending",
      department: "Plumbing",
      priority: "High",
    ),
    WorkOrder(
      title: "Broken Light",
      requestId: "REQ-2025-010",
      date: "Sept 28", // "Sep" and "Sept" both supported
      status: "In Progress",
      department: "Electrical",
      showAvatar: true,
      avatarAsset: 'assets/images/avatar.png',
    ),
    WorkOrder(
      title: "Fixed Door Lock",
      requestId: "REQ-2025-005",
      date: "Sept 26",
      status: "Done",
      department: "Civil/Carpentry",
      showAvatar: true,
    ),
    WorkOrder(
      title: "AC not cooling",
      requestId: "REQ-2025-014",
      date: "Aug 3",
      status: "In Progress",
      department: "Maintenance",
      showAvatar: true,
    ),
    WorkOrder(
      title: "Leak under sink",
      requestId: "REQ-2025-020",
      date: "Aug 15",
      status: "Pending",
      department: "Plumbing",
      priority: "Medium",
    ),
  ];

  // Refresh
  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {});
  }

  // Bottom nav
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
      const ProfilePage(),
    ];
    if (index != 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  // Popup flow to create request
  void _showRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CustomPopup(
        title: 'Create a Request',
        message: 'Would you like to create a new request?',
        primaryText: 'Yes, Continue',
        onPrimaryPressed: () {
          Navigator.of(context).pop();
          showDialog(
            context: context,
            builder: (_) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'What type of request would you like to create?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: const Text('Concern Slip'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RequestForm(requestType: 'Concern Slip'),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.build_outlined),
                      title: const Text('Work Order Request'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReminderPage(requestType: 'work order permit'),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.design_services_outlined),
                      title: const Text('Job Service Request'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReminderPage(requestType: 'job service permit'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        secondaryText: 'Cancel',
        onSecondaryPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  // ===== Filtering logic =====================================================

  bool statusMatches(WorkOrder w) {
    switch (_selectedTabLabel.toLowerCase()) {
      case 'all':
        return true;
      case 'pending':
        return w.status.toLowerCase() == 'pending';       // ✅ fixed
      case 'in progress':
        return w.status.toLowerCase() == 'in progress';
      case 'done':
        return w.status.toLowerCase() == 'done';
      default:
        return true;
    }
  }

  bool _departmentMatches(WorkOrder w) {
    if (_selectedClassification == 'All') return true;
    return (w.department ?? '').toLowerCase() == _selectedClassification.toLowerCase();
  }

  bool _searchMatches(WorkOrder w) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      w.title,
      w.requestId,
      w.department ?? '',
      w.unit ?? '',
      w.status
    ].any((s) => s.toLowerCase().contains(q));
  }

  List<WorkOrder> get _filtered {
    return _all.where((w) => statusMatches(w) && _departmentMatches(w) && _searchMatches(w)).toList();
  }

  // Sort filtered items by LATEST date first using UiDateParser (descending)
  List<WorkOrder> get _filteredSorted {
    final list = List<WorkOrder>.from(_filtered);
    list.sort((a, b) => UiDateParser.parse(b.date).compareTo(UiDateParser.parse(a.date)));
    return list;
  }

  // Dynamic tab counts (respect current department/search filters)
  List<TabItem> get _tabs {
    final all = _all.where((w) => _departmentMatches(w) && _searchMatches(w)).toList();
    final pending    = all.where((w) => w.status.toLowerCase() == 'pending').length;
    final inProgress = all.where((w) => w.status.toLowerCase() == 'in progress').length;
    final done       = all.where((w) => w.status.toLowerCase() == 'done').length;

    return [
      TabItem(label: 'All',         count: all.length),
      TabItem(label: 'Pending',     count: pending),
      TabItem(label: 'In Progress', count: inProgress),
      TabItem(label: 'Done',        count: done),
    ];
  }

  // Card builder
  Widget buildCard(WorkOrder w) {
    return RepairCard(
      title: w.title,
      requestId: w.requestId,
      date: w.date,
      status: w.status,
      unit: w.unit,
      priority: w.priority,
      department: w.department,     
      showAvatar: w.showAvatar,     
      avatarUrl: w.avatarAsset,     
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ViewDetailsPage(selectedTabLabel: 'repair detail'),
          ),
        );
      },
      onChatTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatPage()),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredSorted; // latest first

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Work Order Management',
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
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search + Filter
                    SearchAndFilterBar(
                      searchController: _searchController,
                      selectedClassification: _selectedClassification,
                      classifications: const ['All', 'Electrical', 'Plumbing', 'Civil/Carpentry', 'Maintenance'],
                      onSearchChanged: (_) => setState(() {}),
                      onFilterChanged: (classification) {
                        setState(() => _selectedClassification = classification);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Status Tabs (dynamic counts)
                    StatusTabSelector(
                      tabs: _tabs,
                      selectedLabel: _selectedTabLabel,
                      onTabSelected: (label) => setState(() => _selectedTabLabel = label),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      children: [
                        const Text(
                          'Recent Requests',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${items.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475467),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List
                    Expanded(
                      child: items.isEmpty
                          ? const EmptyState()
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) => buildCard(items[i]),
                            ),
                    ),
                  ],
                ),
              ),

              // Add button (floating within padding)
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
        currentIndex: 1,
        onTap: _onTabTapped,
      ),
    );
  }
}
