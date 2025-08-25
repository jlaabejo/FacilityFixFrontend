import 'dart:async';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/chat.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/notification.dart';
import 'package:facilityfix/staff/view_details/details_maintenanceForm.dart';
import 'package:facilityfix/staff/view_details/details_repairForm.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart';
import 'package:facilityfix/widgets/cards.dart';         // RepairCard, MaintenanceTaskCard, SearchAndFilterBar, StatusTabSelector, EmptyState
import 'package:facilityfix/widgets/helper_models.dart'; // WorkOrder, UiDateParser, TabItem
import 'package:flutter/material.dart';

class WorkOrderPage extends StatefulWidget {
  const WorkOrderPage({super.key});

  @override
  State<WorkOrderPage> createState() => _WorkOrderPageState();
}

class _WorkOrderPageState extends State<WorkOrderPage> {
  /// Staff department. All visible/acceptable tasks MUST match this.
  static const String staffDepartment = 'Maintenance';

  /// Default selected tab.
  String _selectedTabLabel = 'Repair Task';

  /// Search box controller.
  final TextEditingController _searchController = TextEditingController();

  /// Map the requestId to the task “kind” (who created it).
  /// - "repair" = tenant (RepairCard)
  /// - "maintenance" = admin (MaintenanceTaskCard)
  final Map<String, String> _taskTypeById = {
    'REQ-2025-014': 'maintenance',
    'PM-2025-020': 'maintenance',
    'PM-GEN-LIGHT-001': 'maintenance',
    'PM-GEN-001': 'maintenance',
    'REQ-2025-005': 'repair',
    'CS-2025-00321': 'repair',
  };

  // ==== SAMPLE DATA ==========================================================
  final List<WorkOrder> _all = [
    WorkOrder(
      title: 'AC not cooling',
      requestId: 'REQ-2025-014',
      date: 'Aug 3',
      status: 'In Progress',
      department: 'Maintenance',
      unit: 'A 1001',
      priority: 'High',
    ),
    WorkOrder(
      title: 'Monthly Pump Check',
      requestId: 'PM-2025-020',
      date: 'Aug 15',
      status: 'Scheduled',
      department: 'Maintenance',
      unit: 'B2 Pump Room',
      priority: 'Medium',
    ),
    WorkOrder(
      title: 'Light Inspection',
      requestId: 'PM-GEN-LIGHT-001',
      date: 'Jul 30',
      status: 'In Progress',
      department: 'Maintenance',
      unit: 'Lobby',
      priority: 'Low',
    ),
    WorkOrder(
      title: 'Generator Test',
      requestId: 'PM-GEN-001',
      date: 'Sept 26',
      status: 'Done',
      department: 'Maintenance',
      unit: 'Genset Room',
      priority: 'Low',
    ),
    // Tenant-created (repair)
    WorkOrder(
      title: 'Leaky faucet in CR-3',
      requestId: 'REQ-2025-005',
      date: 'Aug 22',
      status: 'In Progress',
      department: 'Maintenance',
      unit: 'Unit 3B · Tower A',
      priority: 'High',
    ),
    WorkOrder(
      title: 'Flickering lights',
      requestId: 'CS-2025-00321',
      date: 'Aug 18',
      status: 'Pending',
      department: 'Maintenance',
      unit: 'Unit 7C',
      priority: 'Medium',
    ),
  ];

  // NEW: Local overrides for status + optional hold reason
  final Map<String, String> _statusOverrideById = {};

  String _statusOf(WorkOrder w) => _statusOverrideById[w.requestId] ?? w.status;

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

  // ── Helpers: task kind by request id ───────────────────────────────────────
  bool _isMaintenanceTask(WorkOrder w) =>
      (_taskTypeById[w.requestId]?.toLowerCase() ?? 'repair') == 'maintenance';

  bool _isRepairTask(WorkOrder w) => !_isMaintenanceTask(w);

  bool _tabMatches(WorkOrder w) {
    final tab = _selectedTabLabel.toLowerCase();
    if (tab == 'repair task') return _isRepairTask(w);
    return _isMaintenanceTask(w);
  }

  // ===== Filtering ===========================================================
  bool _departmentAllowed(WorkOrder w) =>
      (w.department ?? '').toLowerCase() == staffDepartment.toLowerCase();

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
    return _all
        .where(_departmentAllowed)
        .where(_tabMatches)
        .where(_searchMatches)
        .toList();
  }

  // Latest date first
  List<WorkOrder> get _filteredSorted {
    final list = List<WorkOrder>.from(_filtered);
    list.sort((a, b) => UiDateParser.parse(b.date).compareTo(UiDateParser.parse(a.date)));
    return list;
  }

  // Two tabs (counts within department)
  List<TabItem> get _tabs {
    final visible = _all.where(_departmentAllowed).where(_searchMatches).toList();
    final repairCount = visible.where(_isRepairTask).length;
    final maintenanceCount = visible.where(_isMaintenanceTask).length;

    return [
      TabItem(label: 'Repair Task', count: repairCount),
      TabItem(label: 'Maintenance Task', count: maintenanceCount),
    ];
  }

  // Card builder: Maintenance → MaintenanceTaskCard, Repair → RepairCard
  Widget buildCard(WorkOrder w) {
    const forcedDept = staffDepartment;

    if (_isMaintenanceTask(w)) {
      return MaintenanceCard(
        title: w.title,
        requestId: w.requestId,
        unit: w.unit ?? '-',
        date: w.date,
        status: _statusOf(w),       // override-aware
        priority: w.priority ?? 'Medium',
        department: forcedDept,             // show staff department
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MaintenanceDetails(selectedTabLabel: 'view detail',)),
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

    // Tenant → RepairCard (with On Hold support)
    return RepairCard(
      title: w.title,
      requestId: w.requestId,
      date: w.date,
      status: _statusOf(w),                 // override-aware
      unit: w.unit,
      priority: w.priority,
      department: forcedDept,
      showAvatar: w.showAvatar,
      avatarUrl: w.avatarAsset,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RepairDetails(selectedTabLabel: 'view detail')),
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
                // Search + department locked to staff scope
                SearchAndFilterBar(
                  searchController: _searchController,
                  selectedClassification: staffDepartment,
                  classifications: const [staffDepartment],
                  onSearchChanged: (_) => setState(() {}),
                  onFilterChanged: (_) {},
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

/// Result model returned from the bottom sheet
class HoldResult {
  final String reason;
  final String? note;
  const HoldResult({required this.reason, this.note});
}

/// Bottom sheet UI to collect "On Hold" reason + optional note
class HoldBottomSheet extends StatefulWidget {
  const HoldBottomSheet({super.key});

  @override
  State<HoldBottomSheet> createState() => _HoldBottomSheetState();
}

class _HoldBottomSheetState extends State<HoldBottomSheet> {
  String _selected = 'Waiting for materials';
  final TextEditingController _note = TextEditingController();

  final _reasons = const <String>[
    'Waiting for materials',
    'Tenant unavailable',
    'Rescheduled',
    'Awaiting approval',
    'Weather constraints',
    'Other',
  ];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Put Request On Hold',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              // Reasons
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _reasons.map((r) {
                    final selected = r == _selected;
                    return ChoiceChip(
                      label: Text(r),
                      selected: selected,
                      onSelected: (_) => setState(() => _selected = r),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // Optional note
              TextField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'Add extra details…',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          HoldResult(reason: _selected, note: _note.text),
                        );
                      },
                      child: const Text('Confirm Hold'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
