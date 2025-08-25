import 'dart:async';
import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/calendar.dart';
import 'package:facilityfix/admin/chat.dart';
import 'package:facilityfix/admin/home.dart';
import 'package:facilityfix/admin/inventory.dart';
import 'package:facilityfix/admin/forms/maintenance_task.dart';
import 'package:facilityfix/admin/notification.dart';
import 'package:facilityfix/admin/view_details/workorder_details.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart';
import 'package:facilityfix/widgets/cards.dart';         // RepairCard, MaintenanceCard, SearchAndFilterBar, StatusTabSelector, EmptyState
import 'package:facilityfix/widgets/helper_models.dart'; // WorkOrder, UiDateParser, TabItem
import 'package:facilityfix/widgets/pop_up.dart';
import 'package:flutter/material.dart';

class WorkOrderPage extends StatefulWidget {
  const WorkOrderPage({super.key});

  @override
  State<WorkOrderPage> createState() => _WorkOrderPageState();
}

class _WorkOrderPageState extends State<WorkOrderPage> {
  String _selectedDepartment = 'All';
  String _selectedTabLabel = 'Repair';
  final TextEditingController _searchController = TextEditingController();

  /// Classifier:
  /// - For PM/MT IDs → "maintenance"
  /// - For REQ-* IDs → repair subtype (keep original casing!)
  final Map<String, String> _taskTypeById = {
    // maintenance
    'PM-2025-020': 'maintenance',
    'PM-GEN-LIGHT-001': 'maintenance',
    'PM-GEN-001': 'maintenance',
    'PM-SAF-004': 'maintenance',
    'MT-5356': 'maintenance',

    // repair (subtypes — preserve display casing)
    'REQ-001': 'Concern Slip',
    'REQ-002': 'Assessed Concern Slip', 
    'REQ-003': 'Job Service',
    'REQ-004': 'Work Order Permit',
    'REQ-006': 'Concern Slip',
  };

  // ==== SAMPLE DATA ==========================================================
  final List<WorkOrder> _all = [
    WorkOrder(
      title: 'Fix Sink',
      requestId: 'REQ-001',
      date: 'Sept 26',
      status: 'In Progress',
      department: 'Maintenance',
      requestType: 'Concern Slip',
      unit: 'A 1001',
      priority: 'Medium',
      showAvatar: false,
    ),
    // assessed concern slip
    WorkOrder(
      title: 'Leaking Faucet (CR-3)',
      requestId: 'REQ-002',
      date: 'Sept 25',
      status: 'In Progress',
      department: 'Plumbing',
      requestType: 'Assessed Concern Slip',
      unit: 'B 203',
      priority: 'High',
      showAvatar: true,
    ),
    // job service request
    WorkOrder(
      title: 'Door Latch Misaligned',
      requestId: 'REQ-003',
      date: 'Sept 24',
      status: 'In Progress',
      department: 'Civil/Carpentry',
      requestType: 'Job Service',
      unit: 'Tower C · 10F',
      priority: 'Low',
      showAvatar: true,
    ),
    // work order permit
    WorkOrder(
      title: 'Power Outlet Not Working',
      requestId: 'REQ-004',
      date: 'Sept 22',
      status: 'Pending',
      department: 'Electrical',
      requestType: 'Work Order Permit',
      unit: 'A 908',
      priority: 'Medium',
      showAvatar: false,
    ),
    WorkOrder(
      title: 'Clogged Drainage',
      requestId: 'REQ-006',
      date: 'Sept 18',
      status: 'In Progress',
      department: 'Plumbing',
      requestType: 'Concern Slip',
      unit: 'B 102',
      priority: 'Medium',
      showAvatar: false,
    ),

    // Maintenance
    WorkOrder(
      title: 'Pest Control',
      requestId: 'MT-5356',
      date: 'Jul 27',
      status: 'Scheduled',
      department: 'Pest Control',
      unit: 'Lobby',
      priority: 'High',
      showAvatar: true,
    ),
    WorkOrder(
      title: 'Pump Room Inspection',
      requestId: 'PM-2025-020',
      date: 'Aug 15',
      status: 'Scheduled',
      department: 'Maintenance',
      unit: 'B2 Pump Room',
      priority: 'Medium',
      showAvatar: true,
    ),
    WorkOrder(
      title: 'Lobby Light Check',
      requestId: 'PM-GEN-LIGHT-001',
      date: 'Jul 30',
      status: 'In Progress',
      department: 'Maintenance',
      unit: 'Lobby',
      priority: 'Low',
      showAvatar: false,
    ),
    WorkOrder(
      title: 'Generator Test',
      requestId: 'PM-GEN-001',
      date: 'Sept 26',
      status: 'Done',
      department: 'Electrical',
      unit: 'Genset Room',
      priority: 'Low',
      showAvatar: false,
    ),
    WorkOrder(
      title: 'Fire Extinguisher Audit',
      requestId: 'PM-SAF-004',
      date: 'Sept 10',
      status: 'In Progress',
      department: 'Safety',
      unit: 'All Floors',
      priority: 'High',
      showAvatar: false,
    ),
  ];

  final Map<String, String> _statusOverrideById = {};
  String _statusOf(WorkOrder w) => _statusOverrideById[w.requestId] ?? w.status;

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {});
  }

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
    if (index != 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  bool _isMaintenanceTask(WorkOrder w) =>
      (_taskTypeById[w.requestId]?.toLowerCase() ?? 'repair') == 'maintenance';
  bool _isRepairTask(WorkOrder w) => !_isMaintenanceTask(w);

  bool _tabMatches(WorkOrder w) {
    final tab = _selectedTabLabel.toLowerCase();
    if (tab == 'repair') return _isRepairTask(w);
    return _isMaintenanceTask(w);
  }

  String _selectedLabelFor(WorkOrder w) {
    if (_isMaintenanceTask(w)) return 'Maintenance';
    // preserve original casing for routing
    return _taskTypeById[w.requestId] ?? 'Concern Slip';
    // With REQ-002 mapped to "Assessed Concern Slip",
    // the details page will hit the right case branch.
  }

  // ===== Filtering =====
  List<String> get _departmentOptions {
    final set = <String>{};
    for (final w in _all) {
      final d = (w.department ?? '').trim();
      if (d.isNotEmpty) set.add(d);
    }
    return ['All', ...set.toList()..sort()];
  }

  bool _departmentAllowed(WorkOrder w) {
    if (_selectedDepartment == 'All') return true;
    return (w.department ?? '').toLowerCase() == _selectedDepartment.toLowerCase();
  }

  bool _searchMatches(WorkOrder w) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [w.title, w.requestId, w.department ?? '', w.unit ?? '', w.status]
        .any((s) => s.toLowerCase().contains(q));
  }

  List<WorkOrder> get _filtered =>
      _all.where(_departmentAllowed).where(_tabMatches).where(_searchMatches).toList();

  List<WorkOrder> get _filteredSorted {
    final list = List<WorkOrder>.from(_filtered);
    list.sort((a, b) => UiDateParser.parse(b.date).compareTo(UiDateParser.parse(a.date)));
    return list;
  }

  List<TabItem> get _tabs {
    final visible = _all.where(_departmentAllowed).where(_searchMatches).toList();
    return [
      TabItem(label: 'Repair', count: visible.where(_isRepairTask).length),
      TabItem(label: 'Maintenance', count: visible.where(_isMaintenanceTask).length),
    ];
  }

  // Card builder
  Widget _buildCard(WorkOrder w) {
    final dept = w.department ?? 'General Maintenance';
    final prio = w.priority ?? 'Medium';

    if (_isMaintenanceTask(w)) {
      return MaintenanceCard(
        title: w.title,
        requestId: w.requestId,
        unit: w.unit ?? '-',
        date: w.date,
        status: _statusOf(w),
        priority: prio,
        department: dept,
        showAvatar: w.showAvatar,
        avatarUrl: w.avatarAsset,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const WorkOrderDetailsPage(selectedTabLabel: 'Maintenance'),
            ),
          );
        },
        onChatTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage())),
      );
    }

    // Repair card
    return RepairCard(
      title: w.title,
      requestId: w.requestId,
      date: w.date,
      status: _statusOf(w),
      unit: (w.unit ?? '—'),
      priority: (w.priority ?? 'Medium'),
      requestType: (_taskTypeById[w.requestId] ?? 'Concern Slip'),
      department: (w.department ?? 'General Maintenance'),
      showAvatar: (w.showAvatar == true) && (w.avatarAsset != null && w.avatarAsset!.isNotEmpty),
      avatarUrl: w.avatarAsset ?? '',
      onTap: () {
        final selectedLabel = _selectedLabelFor(w); // keep display casing
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkOrderDetailsPage(selectedTabLabel: selectedLabel),
          ),
        );
      },
      onChatTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage())),
    );
  }

  void _showRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CustomPopup(
        title: 'Create Maintenance',
        message: 'Would you like to create a new maintenance?',
        primaryText: 'Yes',
        onPrimaryPressed: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MaintenanceForm(requestType: 'Basic Information'),
            ),
          );
        },
        secondaryText: 'Cancel',
        onSecondaryPressed: () => Navigator.of(context).pop(),
      ),
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
    final items = _filteredSorted;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Work Order Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage()));
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
                    // Search + Department filter
                    SearchAndFilterBar(
                      searchController: _searchController,
                      selectedClassification: _selectedDepartment,
                      classifications: _departmentOptions,
                      onSearchChanged: (_) => setState(() {}),
                      onFilterChanged: (value) => setState(() => _selectedDepartment = value),
                    ),
                    const SizedBox(height: 16),

                    // Tabs
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
                              itemBuilder: (_, i) => _buildCard(items[i]),
                            ),
                    ),
                  ],
                ),
              ),

              // FAB only for Maintenance tab
              if (_selectedTabLabel.toLowerCase() == 'maintenance')
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
