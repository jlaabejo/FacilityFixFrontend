import 'dart:async';
import 'package:facilityfix/models/cards.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart' hide WorkOrder;
import 'package:facilityfix/staff/chat.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/notification.dart';
import 'package:facilityfix/staff/view_details/workorder.dart'
    show WorkOrderDetails, WorkOrderDetailsPage;
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart';
import 'package:facilityfix/widgets/cards.dart';
import 'package:facilityfix/widgets/helper_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorkOrderPage extends StatefulWidget {
  final String staffDepartment;

  const WorkOrderPage({
    super.key,
    this.staffDepartment = 'Plumbing',
  });

  @override
  State<WorkOrderPage> createState() => _WorkOrderPageState();
}

class _WorkOrderPageState extends State<WorkOrderPage> {
  String _selectedTabLabel = 'Repair Task';
  String _selectedStatus = 'All';
  String _selectedPriority = 'All';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, String> _taskTypeById = const {
    'CS-2025-001': 'repair detail',
    'CS-2025-002': 'repair detail',
    'JS-2025-031': 'repair detail',
    'JS-2025-032': 'repair detail',
    'JS-2025-033': 'repair detail',
    'MT-P-2025-011': 'maintenance detail',
    'MT-P-2025-012': 'maintenance detail',
  };

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';
  String _norm(String? s) => (s ?? '').toLowerCase().trim();

  final List<WorkOrder> _all = [
    WorkOrder(
      title: 'Leaking faucet',
      id: 'CS-2025-001',
      createdAt: DateFormat('MMMM d, yyyy').parse('August 25, 2025'),
      statusTag: 'Assigned',
      departmentTag: 'Plumbing',
      requestTypeTag: 'Concern Slip',
      unitId: 'A 1001',
      priorityTag: 'High',
      assignedStaff: 'Juan Dela Cruz',
      staffDepartment: 'Plumbing',
      staffPhotoUrl: 'assets/images/avatar.png',
    ),
    WorkOrder(
      title: 'Leaking faucet',
      id: 'CS-2025-002',
      createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
      statusTag: 'Done',
      departmentTag: 'Plumbing',
      requestTypeTag: 'Concern Slip',
      unitId: 'A 1001',
      priorityTag: 'High',
      assignedStaff: 'Juan Dela Cruz',
      staffDepartment: 'Plumbing',
      staffPhotoUrl: 'assets/images/avatar.png',
    ),
    WorkOrder(
      title: 'Leaking faucet',
      id: 'JS-2025-031',
      createdAt: DateFormat('MMMM d, yyyy').parse('August 21, 2025'),
      statusTag: 'Assigned',
      departmentTag: 'Plumbing',
      requestTypeTag: 'Job Service',
      unitId: 'A 1001',
      priorityTag: 'High',
      assignedStaff: 'Juan Dela Cruz',
      staffDepartment: 'Plumbing',
      staffPhotoUrl: 'assets/images/avatar.png',
    ),
    WorkOrder(
      title: 'Quarterly Pipe Inspection',
      id: 'MT-P-2025-011',
      createdAt: DateFormat('MMMM d, yyyy').parse('August 30, 2025'),
      statusTag: 'Scheduled',
      departmentTag: 'Plumbing',
      requestTypeTag: 'Work Order',
      unitId: 'Tower A - 5th Floor',
      priorityTag: 'Medium',
      assignedStaff: 'Juan Dela Cruz',
      staffDepartment: 'Plumbing',
      staffPhotoUrl: 'assets/images/avatar.png',
    ),
  ];

  final Map<String, String> _statusOverrideById = {};
  String _statusOf(WorkOrder w) => _statusOverrideById[w.id] ?? w.statusTag;

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
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
      WorkOrderPage(staffDepartment: widget.staffDepartment),
      const AnnouncementPage(),
      const CalendarPage(),
      const InventoryPage(),
    ];
    if (index != 1) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destinations[index],
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  bool _isMaintenanceTask(WorkOrder w) =>
      (_taskTypeById[w.id]?.toLowerCase() ?? 'repair detail') ==
      'maintenance detail';
  bool _isRepairTask(WorkOrder w) => !_isMaintenanceTask(w);

  bool _tabMatches(WorkOrder w) {
    final tab = _norm(_selectedTabLabel);
    if (tab == 'repair task') return _isRepairTask(w);
    return _isMaintenanceTask(w);
  }

  bool _departmentAllowed(WorkOrder w) {
    final dep = _norm(w.departmentTag);
    final staff = _norm(widget.staffDepartment);
    if (staff == 'all' || staff.isEmpty) return true;
    return dep == staff;
  }

  bool _statusAllowed(WorkOrder w) {
    final sel = _norm(_selectedStatus);
    if (sel == 'all' || sel.isEmpty) return true;
    return _norm(_statusOf(w)) == sel;
  }

  bool _priorityAllowed(WorkOrder w) {
    final sel = _norm(_selectedPriority);
    if (sel == 'all' || sel.isEmpty) return true;
    return _norm(w.priorityTag ?? '') == sel;
  }

  bool _searchMatches(WorkOrder w) {
    final q = _norm(_searchController.text);
    if (q.isEmpty) return true;
    final dateText = shortDate(w.createdAt);
    return <String>[
      w.title,
      w.id,
      w.departmentTag ?? '',
      w.unitId ?? '',
      w.statusTag,
      w.requestTypeTag,
      dateText,
      w.priorityTag ?? '',
    ].any((s) => _norm(s).contains(q));
  }

  List<WorkOrder> get _filtered => _all
      .where(_departmentAllowed)
      .where(_tabMatches)
      .where(_statusAllowed)
      .where(_priorityAllowed)
      .where(_searchMatches)
      .toList();

  List<WorkOrder> get _filteredSorted {
    final list = List<WorkOrder>.from(_filtered);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<TabItem> get _tabs {
    final visible = _all.where(_departmentAllowed).where(_searchMatches).toList();
    final repairCount = visible.where(_isRepairTask).length;
    final maintenanceCount = visible.where(_isMaintenanceTask).length;

    return [
      TabItem(label: 'Repair Task', count: repairCount),
      TabItem(label: 'Maintenance Task', count: maintenanceCount),
    ];
  }

  /// ✅ Fixed filters for both tabs
  final List<String> _statusOptions = [
    'All', 'Pending', 'Assigned', 'Scheduled', 'On Hold'
  ];

  final List<String> _priorityOptions = [
    'All', 'High', 'Medium', 'Low'
  ];

  String _routeLabelFor(WorkOrder w) {
    final status = _norm(_statusOf(w));
    final type = _norm(w.requestTypeTag);
    if (_isMaintenanceTask(w)) {
      if (status == 'scheduled') return 'maintenance task scheduled';
      if (status == 'done' || status == 'assessed' || status == 'closed') {
        return 'maintenance task assessed';
      }
      return 'maintenance task scheduled';
    }
    if (type == 'concern slip') {
      if (status == 'assigned') return 'concern slip assigned';
      if (status == 'assessed' || status == 'done' || status == 'closed') {
        return 'concern slip assessed';
      }
      return 'concern slip assigned';
    }
    if (type == 'job service') {
      if (status == 'done' || status == 'assessed' || status == 'closed') {
        return 'job service assessed';
      }
      return 'job service assigned';
    }
    return 'concern slip assigned';
  }

  Widget buildCard(WorkOrder w) {
    if (_isMaintenanceTask(w)) {
      return MaintenanceCard(
        title: w.title,
        id: w.id,
        createdAt: w.createdAt,
        statusTag: w.statusTag,
        departmentTag: w.departmentTag,
        priority: w.priorityTag,
        location: w.unitId ?? '',
        requestTypeTag: w.requestTypeTag,
        assignedStaff: w.assignedStaff,
        staffDepartment: w.staffDepartment,
        staffPhotoUrl: w.staffPhotoUrl,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkOrderDetailsPage(
                selectedTabLabel: _routeLabelFor(w),
              ),
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

    return RepairCard(
      title: w.title,
      id: w.id,
      createdAt: w.createdAt,
      statusTag: w.statusTag,
      departmentTag: w.departmentTag,
      priorityTag: w.priorityTag,
      unitId: w.unitId ?? '',
      requestTypeTag: w.requestTypeTag,
      assignedStaff: w.assignedStaff,
      staffDepartment: w.staffDepartment,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkOrderDetailsPage(
              selectedTabLabel: _routeLabelFor(w),
            ),
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
    final items = _filteredSorted;
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchAndFilterBar(
                  searchController: _searchController,
                  selectedStatus: _selectedStatus,
                  statuses: _statusOptions,
                  selectedClassification: _selectedPriority,
                  classifications: _priorityOptions,
                  onStatusChanged: (status) {
                    setState(() {
                      _selectedStatus = status.trim().isEmpty ? 'All' : status;
                    });
                  },
                  onClassificationChanged: (prio) {
                    setState(() {
                      _selectedPriority = prio.trim().isEmpty ? 'All' : prio;
                    });
                  },
                  onSearchChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                StatusTabSelector(
                  tabs: _tabs,
                  selectedLabel: _selectedTabLabel,
                  onTabSelected: (label) =>
                      setState(() => _selectedTabLabel = label),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Recent Requests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
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
                Expanded(
                  child: items.isEmpty
                      ? const EmptyState()
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => buildCard(items[i]),
                        ),
                ),
              ],
            ),
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
