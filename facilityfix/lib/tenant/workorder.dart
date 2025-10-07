import 'dart:async';
import 'package:facilityfix/models/cards.dart';
import 'package:facilityfix/tenant/announcement.dart';
import 'package:facilityfix/tenant/chat.dart';
import 'package:facilityfix/tenant/home.dart';
import 'package:facilityfix/tenant/notification.dart';
import 'package:facilityfix/tenant/profile.dart';
import 'package:facilityfix/tenant/request_forms.dart';
import 'package:facilityfix/tenant/view_details.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart';
import 'package:facilityfix/widgets/cards.dart';
import 'package:facilityfix/widgets/helper_models.dart';
import 'package:facilityfix/widgets/modals.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorkOrderPage extends StatefulWidget {
  const WorkOrderPage({super.key});

  @override
  State<WorkOrderPage> createState() => _WorkOrderPageState();
}

class _WorkOrderPageState extends State<WorkOrderPage> {
  // ─────────────── Tabs (by request type) ───────────────
  String _selectedTabLabel = "All";

  // ─────────────── Filters ───────────────
  String _selectedStatus = 'All';
  String _selectedDepartment = 'All'; // mapped as "classification"
  final TextEditingController _searchController = TextEditingController();

  // ─────────────── Sample data (replace with backend) ───────────────
  final List<WorkOrder> _all = [
    WorkOrder(
      title: 'Leaking faucet',
      id: 'CS-2025-005',
      createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
      statusTag: 'Pending',
      departmentTag: 'Plumbing',
      requestTypeTag: 'Concern Slip',
      unitId: 'A 1001',
      staffPhotoUrl: null,
      priorityTag: null,
    ),
    WorkOrder(
      title: 'Leaking faucet',
      id: 'CS-2025-005',
      createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
      statusTag: 'Assigned',
      departmentTag: 'Plumbing',
      requestTypeTag: 'Concern Slip',
      assignedStaff: 'Juan Tamad',
      staffDepartment: 'Plumbing',
      staffPhotoUrl: null,
      unitId: 'A 1001',
      priorityTag: null,
    ),
    WorkOrder(
      title: 'Leaking faucet',
      id: 'CS-2025-030',
      createdAt: DateFormat('MMMM d, yyyy').parse('August 23, 2025'),
      statusTag: 'Done',
      departmentTag: 'Plumbing',
      requestTypeTag: 'Concern Slip',
      assignedStaff: 'Juan Tamad',
      staffDepartment: 'Plumbing',
      staffPhotoUrl: null,
      unitId: 'A 1001',
      priorityTag: 'High',
    ),
    WorkOrder(
      title: 'Leaking faucet',
      id: 'WO-2025-014',
      createdAt: DateFormat('MMMM d, yyyy').parse('August 20, 2025'),
      statusTag: 'Approved',
      departmentTag: 'Plumbing',
      requestTypeTag: 'Work Order',
      unitId: 'A 1001',
      staffPhotoUrl: null,
      priorityTag: 'High',
    ),
    WorkOrder(
      title: 'Leaking faucet',
      id: 'JS-2025-021',
      createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
      statusTag: 'Assigned',
      departmentTag: 'Plumbing',
      requestTypeTag: 'Job Service',
      assignedStaff: 'Juan Tamad',
      staffDepartment: 'Plumbing',
      staffPhotoUrl: null,
      unitId: 'A 1001',
      priorityTag: 'High',
    ),
    WorkOrder(
      title: 'Leaking faucet',
      id: 'JS-2025-031',
      createdAt: DateFormat('MMMM d, yyyy').parse('August 23, 2025'),
      statusTag: 'Done',
      departmentTag: 'Plumbing',
      requestTypeTag: 'Job Service',
      assignedStaff: 'Juan Tamad',
      staffDepartment: 'Plumbing',
      staffPhotoUrl: null,
      unitId: 'A 1001',
      priorityTag: 'High',
    ),
    WorkOrder(
      title: 'Leaking faucet',
      id: 'JS-2025-032',
      createdAt: DateFormat('MMMM d, yyyy').parse('August 23, 2025'),
      statusTag: 'On Hold',
      departmentTag: 'Plumbing',
      requestTypeTag: 'Job Service',
      assignedStaff: 'Juan Tamad',
      staffDepartment: 'Plumbing',
      staffPhotoUrl: null,
      unitId: 'A 1001',
      priorityTag: 'High',
    ),
  ];

  // ===== Refresh =============================================================
  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {});
  }

  // ===== Bottom nav ==========================================================
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

  // ===== Popup to create request ============================================
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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
                            builder: (_) =>
                                const RequestForm(requestType: 'Concern Slip'),
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
                            builder: (_) =>
                                const RequestForm(requestType: 'Job Service'),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.build_outlined),
                      title: const Text('Work Order Permit'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const RequestForm(requestType: 'Work Order'),
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
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';
  String _norm(String? s) => (s ?? '').toLowerCase().trim();

  bool _tabMatchesByRequestType(WorkOrder w) {
    final type = _norm(w.requestTypeTag);
    switch (_norm(_selectedTabLabel)) {
      case 'all':
        return true;
      case 'concern slip':
        return type == 'concern slip';
      case 'job service':
        return type == 'job service';
      case 'work order':
        return type == 'work order';
      default:
        return true;
    }
  }

  bool _statusMatches(WorkOrder w) {
    if (_selectedStatus == 'All') return true;
    return _norm(w.statusTag) == _norm(_selectedStatus);
  }

  bool _departmentMatches(WorkOrder w) {
    if (_selectedDepartment == 'All') return true;
    return _norm(w.departmentTag) == _norm(_selectedDepartment);
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
    ].any((s) => _norm(s).contains(q));
  }

  List<WorkOrder> get _filtered => _all
      .where(_tabMatchesByRequestType)
      .where(_statusMatches)
      .where(_departmentMatches)
      .where(_searchMatches)
      .toList();

  List<WorkOrder> get _filteredSorted {
    final list = List<WorkOrder>.from(_filtered);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<String> get _statusOptions {
    final base =
        _all.where(_tabMatchesByRequestType).where(_departmentMatches).where(_searchMatches);
    final set = <String>{};
    for (final w in base) {
      final s = w.statusTag.trim();
      if (s.isNotEmpty) set.add(s);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  // ✅ Fixed Department filter logic
  List<String> get _deptOptions {
    // predefined departments
    final predefined = {'Maintenance', 'Carpentry', 'Plumbing', 'Electrical', 'Masonry'};

    final base = _all
        .where(_tabMatchesByRequestType)
        .where(_statusMatches)
        .where(_searchMatches);

    final set = <String>{};
    for (final w in base) {
      final d = (w.departmentTag ?? '').trim();
      if (d.isNotEmpty) set.add(d);
    }

    // merge both sets
    final list = {...predefined, ...set}.toList()..sort();
    return ['All', ...list];
  }

  List<TabItem> get _tabs {
    final visible =
        _all.where(_statusMatches).where(_departmentMatches).where(_searchMatches).toList();

    int countFor(String type) =>
        visible.where((w) => _norm(w.requestTypeTag) == _norm(type)).length;

    return [
      TabItem(label: 'All', count: visible.length),
      TabItem(label: 'Concern Slip', count: countFor('concern slip')),
      TabItem(label: 'Job Service', count: countFor('job service')),
      TabItem(label: 'Work Order', count: countFor('work order')),
    ];
  }

  String _routeLabelFor(WorkOrder w) {
    final type = _norm(w.requestTypeTag);
    final status = _norm(w.statusTag);

    switch (type) {
      case 'concern slip':
        if (status == 'pending') return 'concern slip';
        if (status == 'assigned') return 'concern slip assigned';
        if (status == 'assessed') return 'concern slip assessed';
        return 'concern slip';
      case 'job service':
        if (status == 'done' || status == 'assessed' || status == 'closed') {
          return 'job service assessed';
        }
        return 'job service assigned';
      case 'work order':
        return 'work order';
      default:
        return type.isEmpty ? 'concern slip' : type;
    }
  }

  Widget buildCard(WorkOrder r) {
    return RepairCard(
      title: r.title,
      id: r.id,
      createdAt: r.createdAt,
      statusTag: r.statusTag,
      departmentTag: r.departmentTag,
      priorityTag: r.priorityTag,
      unitId: r.unitId ?? '',
      requestTypeTag: r.requestTypeTag,
      assignedStaff: r.assignedStaff,
      staffDepartment: r.staffDepartment,
      onTap: () {
        final routeLabel = _routeLabelFor(r);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewDetailsPage(
              selectedTabLabel: routeLabel,
              requestTypeTag: r.requestTypeTag,
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
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchAndFilterBar(
                      searchController: _searchController,
                      selectedStatus: _selectedStatus,
                      statuses: _statusOptions,
                      selectedClassification: _selectedDepartment,
                      classifications: _deptOptions,
                      onStatusChanged: (status) {
                        setState(() {
                          _selectedStatus = status.trim().isEmpty ? 'All' : status;
                        });
                      },
                      onClassificationChanged: (dept) {
                        setState(() {
                          _selectedDepartment = dept.trim().isEmpty ? 'All' : dept;
                        });
                      },
                      onSearchChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),

                    StatusTabSelector(
                      tabs: _tabs,
                      selectedLabel: _selectedTabLabel,
                      onTabSelected: (label) => setState(() => _selectedTabLabel = label),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Text(
                          'Recent $_selectedTabLabel',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
