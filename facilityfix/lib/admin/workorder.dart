// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/calendar.dart';
import 'package:facilityfix/admin/chat.dart';
import 'package:facilityfix/admin/home.dart';
import 'package:facilityfix/admin/inventory.dart';
import 'package:facilityfix/admin/notification.dart';
import 'package:facilityfix/admin/view_details/workorder_details.dart';
import 'package:facilityfix/models/cards.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/adminweb/services/api_service.dart' as admin_api;
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart';
import 'package:facilityfix/widgets/cards.dart'; // RepairCard, MaintenanceCard, SearchAndFilterBar, StatusTabSelector, EmptyState
import 'package:facilityfix/widgets/helper_models.dart'; // WorkOrder, UiDateParser, TabItem
import 'package:flutter/material.dart';

/// Canonical departments (Admin can see 'All')
const List<String> kDepartments = <String>[
  'All',
  'Maintenance',
  'Carpentry',
  'Plumbing',
  'Electrical',
  'Masonry',
];

/// Staff-only Work Order page
/// - Admin default: staffDepartment = 'All'
/// - Search + Status + Department filters
/// - Two tabs: Repair Task / Maintenance Task
class WorkOrderPage extends StatefulWidget {
  /// Staff department. This page will ONLY show items from this department unless 'All'.
  final String staffDepartment;

  const WorkOrderPage({
    super.key,
    this.staffDepartment = 'All', // Admin default
  });

  @override
  State<WorkOrderPage> createState() => _WorkOrderPageState();
}

class _WorkOrderPageState extends State<WorkOrderPage> {
  // Tabs (by maintenance/repair classification)
  String _selectedTabLabel = 'Repair Task';

  // Filters
  String _selectedStatus = 'All';
  String _selectedDepartment = 'All';
  final TextEditingController _searchController = TextEditingController();

  // Dynamic data from API
  List<WorkOrder> _allRequests = [];
  List<WorkOrder> _jobServices = [];
  List<WorkOrder> _maintenanceTasks = [];
  bool _isLoading = true;

  // ───────────────── helpers ─────────────────
  static const List<String> _months = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';
  String _norm(String? s) => (s ?? '').toLowerCase().trim();

  @override
  void initState() {
    super.initState();
    _selectedDepartment = widget.staffDepartment; // reflect entry context
    _searchController.addListener(() => setState(() {}));
    _loadAllData();
  }

  // ===== Data Loading =======================================================
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final apiService = APIService();
      final adminApiService = admin_api.ApiService();
      
      // Fetch concern slips (separate from job services)
      final concernSlips = await apiService.getAllTenantRequests();
      
      // Fetch job services from dedicated endpoint
      final jobServices = await adminApiService.getAllJobServices();
      
      // Fetch maintenance tasks
      final maintenanceTasks = await apiService.getAllMaintenance();

      if (mounted) {
        setState(() {
          // Process concern slips into WorkOrder objects
          _allRequests = concernSlips
              .where((request) => request['request_type'] != 'Job Service') // Exclude job services from concern slips
              .map((request) => _processRequestToWorkOrder(request))
              .toList();
          
          // Process job services into WorkOrder objects
          _jobServices = jobServices
              .map((jobService) => _processJobServiceToWorkOrder(jobService))
              .toList();
          
          // Process maintenance tasks into WorkOrder objects
          _maintenanceTasks = maintenanceTasks
              .map((task) => _processMaintenanceToWorkOrder(task))
              .toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading work order data: $e');
      if (mounted) {
        setState(() {
          _allRequests = [];
          _jobServices = [];
          _maintenanceTasks = [];
          _isLoading = false;
          _isLoading = false;
        });
      }
    }
  }

  WorkOrder _processRequestToWorkOrder(Map<String, dynamic> request) {
    return WorkOrder(
      title: request['title'] ?? 'Untitled Request',
      id: request['formatted_id'] ?? request['id'] ?? 'N/A',
      createdAt: _parseDate(request['created_at']),
      statusTag: _capitalizeStatus(request['status'] ?? 'pending'),
      departmentTag: _mapCategoryToDepartment(request['category']), // AI-generated category
      requestTypeTag: request['request_type'] ?? 'Concern Slip',
      unitId: request['unit_id'] ?? 'N/A',
      priorityTag: _capitalizePriority(request['priority']), // AI-generated priority
      assignedStaff: request['assigned_to'] ?? request['assigned_staff'],
      staffDepartment: _mapCategoryToDepartment(request['category']),
      staffPhotoUrl: 'assets/images/avatar.png',
    );
  }

  WorkOrder _processMaintenanceToWorkOrder(Map<String, dynamic> task) {
    return WorkOrder(
      title: task['task_title'] ?? task['title'] ?? 'Maintenance Task',
      id: task['formatted_id'] ?? task['id'] ?? 'N/A',
      createdAt: _parseDate(task['scheduled_date'] ?? task['created_at']),
      statusTag: _capitalizeStatus(task['status'] ?? 'scheduled'),
      departmentTag: _mapCategoryToDepartment(task['category'] ?? task['department']),
      requestTypeTag: 'Maintenance',
      unitId: task['location'] ?? 'N/A',
      priorityTag: _capitalizePriority(task['priority']),
      assignedStaff: task['assigned_staff'] ?? task['assigned_to'],
      staffDepartment: _mapCategoryToDepartment(task['category'] ?? task['department']),
      staffPhotoUrl: 'assets/images/avatar.png',
    );
  }

  WorkOrder _processJobServiceToWorkOrder(Map<String, dynamic> jobService) {
    return WorkOrder(
      title: jobService['title'] ?? 'Job Service Request',
      id: jobService['formatted_id'] ?? jobService['id'] ?? 'N/A',
      createdAt: _parseDate(jobService['created_at'] ?? jobService['submitted_at']),
      statusTag: _capitalizeStatus(jobService['status'] ?? 'pending'),
      departmentTag: _mapCategoryToDepartment(jobService['category']),
      requestTypeTag: 'Job Service',
      unitId: jobService['unit_id'] ?? jobService['location'] ?? 'N/A',
      priorityTag: _capitalizePriority(jobService['priority']),
      assignedStaff: jobService['assigned_to'] ?? jobService['assigned_staff'],
      staffDepartment: _mapCategoryToDepartment(jobService['category']),
      staffPhotoUrl: 'assets/images/avatar.png',
    );
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    
    return DateTime.now();
  }

  String _capitalizeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'assessed':
        return 'Assessed';
      case 'completed':
        return 'Completed';
      case 'scheduled':
        return 'Scheduled';
      case 'done':
        return 'Done';
      case 'on_hold':
        return 'On Hold';
      default:
        return status;
    }
  }

  String _capitalizePriority(String? priority) {
    if (priority == null) return 'Medium';
    
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return 'Medium';
    }
  }

  String _mapCategoryToDepartment(String? category) {
    if (category == null) return 'General';
    
    switch (category.toLowerCase()) {
      case 'electrical':
        return 'Electrical';
      case 'plumbing':
        return 'Plumbing';
      case 'hvac':
        return 'HVAC';
      case 'carpentry':
        return 'Carpentry';
      case 'maintenance':
        return 'Maintenance';
      case 'masonry':
        return 'Masonry';
      default:
        return 'General';
    }
  }

  // Map request id → details tab (routing classification only).
  final Map<String, String> _taskTypeById = const {
    'CS-2025-001': 'repair detail',
    'CS-2025-002': 'repair detail',
    'JS-2025-031': 'repair detail',
    'JS-2025-032': 'repair detail',
    'JS-2025-033': 'repair detail',
    'MT-P-2025-011': 'maintenance detail',
    'MT-P-2025-012': 'maintenance detail',
  };

  // Optional status override (e.g., if something moves On Hold → In Progress)
  final Map<String, String> _statusOverrideById = {};
  String _statusOf(WorkOrder w) => _statusOverrideById[w.id] ?? w.statusTag;

  // ===== Refresh =============================================================
  Future<void> _refresh() async {
    await _loadAllData();
  }

  // ===== Bottom nav ==========================================================
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

  // ===== Classification (Repair vs Maintenance) & Filters ====================

  /// True if a work order is a maintenance item based on request type or routing map.
  bool _isMaintenanceTask(WorkOrder w) =>
      w.requestTypeTag == 'Maintenance' ||
      (_taskTypeById[w.id]?.toLowerCase() ?? 'repair detail') == 'maintenance detail';

  /// True if a work order is a repair item.
  bool _isRepairTask(WorkOrder w) => !_isMaintenanceTask(w);

  /// Tab predicate
  bool _tabMatches(WorkOrder w) {
    final tab = _norm(_selectedTabLabel);
    if (tab == 'repair task') return _isRepairTask(w);
    return _isMaintenanceTask(w); // 'Maintenance Task'
  }

  /// Enforce department filter:
  /// - If a UI department is selected (not All) → use it.
  /// - Else, lock to staffDepartment unless it's All.
  bool _departmentAllowed(WorkOrder w) {
    final dep = _norm(w.departmentTag);
    final staff = _norm(widget.staffDepartment);
    final selectedDept = _norm(_selectedDepartment);

    if (selectedDept.isNotEmpty && selectedDept != 'all') {
      return dep == selectedDept;
    }
    if (staff == 'all' || staff.isEmpty) return true;
    return dep == staff;
  }

  /// Allow item if it matches the currently selected status.
  bool _statusAllowed(WorkOrder w) {
    final sel = _norm(_selectedStatus);
    if (sel == 'all' || sel.isEmpty) return true;
    return _norm(_statusOf(w)) == sel;
  }

  /// Text search over several fields.
  bool _searchMatches(WorkOrder w) {
    final q = _norm(_searchController.text);
    if (q.isEmpty) return true;

    final dateText = shortDate(w.createdAt); // make DateTime searchable

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

  /// Get combined list of all work orders (concern slips + job services + maintenance)
  List<WorkOrder> get _allWorkOrders => [..._allRequests, ..._jobServices, ..._maintenanceTasks];

  /// Items after applying department → status → tab → search.
  List<WorkOrder> get _filtered => _allWorkOrders
      .where(_departmentAllowed)
      .where(_statusAllowed)
      .where(_tabMatches)
      .where(_searchMatches)
      .toList();

  /// Sort by createdAt (latest first).
  List<WorkOrder> get _filteredSorted {
    final list = List<WorkOrder>.from(_filtered);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first
    return list;
  }

  /// Tabs with counts (within dept + search scope; status-agnostic).
  List<TabItem> get _tabs {
    final visible = _allWorkOrders.where(_departmentAllowed).where(_searchMatches).toList();
    final repairCount = visible.where(_isRepairTask).length;
    final maintenanceCount = visible.where(_isMaintenanceTask).length;

    return [
      TabItem(label: 'Repair Task', count: repairCount),
      TabItem(label: 'Maintenance Task', count: maintenanceCount),
    ];
  }

  /// Status filter options available. Always includes 'All'.
  List<String> get _statusOptions {
    final set = <String>{};
    for (final w in _allWorkOrders) {
      final s = w.statusTag.trim();
      if (s.isNotEmpty) set.add(s);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  /// Department options (fixed list).
  List<String> get _deptOptions => kDepartments;

  /// Maps a WorkOrder to the exact detail label that WorkOrderDetails expects.
  String _routeLabelFor(WorkOrder w) {
    final status = _norm(_statusOf(w));
    final type = _norm(w.requestTypeTag);

    // Maintenance items (based on _taskTypeById)
    if (_isMaintenanceTask(w) || _norm(w.departmentTag) == 'maintenance') {
      if (status == 'scheduled') return 'maintenance detail';
      if (status == 'done' || status == 'assessed' || status == 'closed') {
        return 'maintenance assessed';
      }
      return 'maintenance detail';
    }

    // Repairs (tenant-originated)
    if (type == 'concern slip') {
      if (status == 'assigned') return 'concern slip assigned';
      if (status == 'assessed' || status == 'done' || status == 'closed') {
        return 'concern slip assessed';
      }
      return 'concern slip assigned';
    }

    if (type == 'job service') {
      if (status == 'on hold') return 'job service on hold';
      if (status == 'done' || status == 'assessed' || status == 'closed') {
        return 'job service assessed';
      }
      return 'job service assigned';
    }

    // Unknown type → safest fallback
    return 'concern slip assigned';
  }

  /// Centralized navigation on tap
  void _openDetails(WorkOrder w) {
    final label = _routeLabelFor(w);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkOrderDetailsPage(selectedTabLabel: label),
        settings: RouteSettings(name: 'workorder_details/${w.id}'),
      ),
    );
  }

  // Cards (Maintenance & Repair) — keep UI but map unified fields
  Widget buildCard(WorkOrder w) {
    final isMaint = _isMaintenanceTask(w) || _norm(w.departmentTag) == 'maintenance';

    final Widget inner = isMaint
        ? MaintenanceCard(
            title: w.title,
            id: w.id,
            createdAt: w.createdAt,
            statusTag: w.statusTag,
            departmentTag: w.departmentTag,
            priority: w.priorityTag,
            location: w.unitId ?? '',
            requestTypeTag: w.requestTypeTag,

            // Assignment / avatar
            assignedStaff: w.assignedStaff,
            staffDepartment: w.staffDepartment,
            staffPhotoUrl: w.staffPhotoUrl,

            onTap: () => _openDetails(w), // pass through
            onChatTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatPage()),
              );
            },
          )
        : RepairCard(
            title: w.title,
            id: w.id,
            createdAt: w.createdAt,
            statusTag: w.statusTag,
            departmentTag: w.departmentTag,
            priorityTag: w.priorityTag,
            unitId: w.unitId ?? '',
            requestTypeTag: w.requestTypeTag,

            // Assignment / avatar
            assignedStaff: w.assignedStaff,
            staffDepartment: w.staffDepartment,
            // staffPhotoUrl: w.staffPhotoUrl,

            onTap: () => _openDetails(w), // pass through
            onChatTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatPage()),
              );
            },
          );

    // Hard wrap with a Material+InkWell to guarantee taps even if inner card doesn't use onTap.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetails(w),
        child: inner,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===== UI ==================================================================
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search + Status + Department filters
                      SearchAndFilterBar(
                        searchController: _searchController,
                        selectedStatus: _selectedStatus,
                        statuses: _statusOptions,
                        selectedClassification: _selectedDepartment, // using department as classification
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

                      // Tabs
                      StatusTabSelector(
                        tabs: _tabs,
                        selectedLabel: _selectedTabLabel,
                        onTabSelected: (label) => setState(() => _selectedTabLabel = label),
                      ),
                      const SizedBox(height: 20),

                      // Header with count
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