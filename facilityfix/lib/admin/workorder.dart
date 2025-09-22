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
import 'package:facilityfix/widgets/cards.dart';
import 'package:facilityfix/widgets/helper_models.dart';
import 'package:facilityfix/widgets/modals.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:facilityfix/services/api_services.dart';

class WorkOrderPage extends StatefulWidget {
  const WorkOrderPage({super.key});

  @override
  State<WorkOrderPage> createState() => _WorkOrderPageState();
}

class _WorkOrderPageState extends State<WorkOrderPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTabLabel = 'Repair';
  String _selectedStatus = 'All';

  String _selectedClassification = 'All';
  final List<String> _classificationOptions = const <String>[
    'All',
    'Plumbing',
    'Carpentry',
    'Electrical',
    'Masonry',
    'Maintenance',
  ];

  final Map<String, String> _taskTypeById = {};

  List<WorkOrder> _allWorkOrders = [];
  bool _isLoading = true;
  final APIService _apiService = APIService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadWorkOrders();
  }

  Future<void> _loadWorkOrders() async {
    try {
      setState(() => _isLoading = true);

      final concernSlips = await _apiService.getAllConcernSlips();

      final workOrders =
          concernSlips.map((slip) {
            return WorkOrder(
              title: slip['title'] ?? 'Untitled Request',
              requestId: slip['id'] ?? 'N/A',
              date: _formatDateFromApi(slip['created_at']),
              status: _formatStatusFromApi(slip['status']),
              department: _formatCategoryFromApi(slip['category']),
              requestType: 'Concern Slip',
              unit: slip['unit_id'] ?? 'N/A',
              priority: _formatPriorityFromApi(slip['priority']),
            );
          }).toList();

      setState(() {
        _allWorkOrders = workOrders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading work orders: $e');
      setState(() {
        _isLoading = false;
        _allWorkOrders = [];
      });
    }
  }

  String _formatDateFromApi(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatStatusFromApi(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Done';
      default:
        return 'Pending';
    }
  }

  String _formatCategoryFromApi(String? category) {
    switch (category?.toLowerCase()) {
      case 'plumbing':
        return 'Plumbing';
      case 'electrical':
        return 'Electrical';
      case 'hvac':
        return 'HVAC';
      case 'general':
        return 'Maintenance';
      default:
        return 'Maintenance';
    }
  }

  String _formatPriorityFromApi(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return 'Medium';
    }
  }

  final Map<String, String> _statusOverrideById = {};
  String _statusOf(WorkOrder w) => _statusOverrideById[w.requestId] ?? w.status;

  Future<void> _refresh() async {
    await _loadWorkOrders();
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

  bool _isMaintenanceTask(WorkOrder w) {
    final id = (w.requestId).toUpperCase();
    final tag = (_taskTypeById[w.requestId] ?? '').toLowerCase();
    return id.startsWith('MT-') || tag.contains('maintenance');
  }

  bool _isRepairTask(WorkOrder w) => !_isMaintenanceTask(w);

  bool _tabMatches(WorkOrder w) {
    final tab = _selectedTabLabel.toLowerCase();
    if (tab == 'repair') return _isRepairTask(w);
    return _isMaintenanceTask(w);
  }

  String _detailsLabelFor(WorkOrder w) {
    final type = (w.requestType ?? '').toLowerCase().trim();
    final status = _statusOf(w).toLowerCase().trim();

    bool inSet(Set<String> s) => s.contains(status);

    const doneLike = {
      'done',
      'assessed',
      'closed',
      'approved',
      'completed',
      'finished',
    };
    const assignedLike = {'assigned', 'in progress', 'on hold', 'scheduled'};
    const pendingLike = {'pending'};

    if (_isMaintenanceTask(w)) {
      if (inSet(doneLike)) return 'job service assessed';
      if (inSet(assignedLike)) return 'job service assigned';
      if (inSet(pendingLike)) return 'job service';
      return 'job service assigned';
    }

    if (type.contains('work order')) {
      return 'work order';
    }

    if (type.contains('job service')) {
      if (inSet(doneLike)) return 'job service assessed';
      if (inSet(assignedLike)) return 'job service assigned';
      if (inSet(pendingLike)) return 'job service';
      return 'job service assigned';
    }

    if (type.contains('concern slip')) {
      if (inSet(doneLike)) return 'concern slip assessed';
      if (inSet(assignedLike)) return 'concern slip assigned';
      return 'concern slip';
    }

    return 'job service assigned';
  }

  List<String> get _statusOptions {
    final base = _allWorkOrders
        .where(_tabMatches)
        .where(_searchMatches)
        .where(_classificationMatches);
    final set = <String>{};
    for (final w in base) {
      final s = _statusOf(w).trim();
      if (s.isNotEmpty) set.add(s);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  bool _searchMatches(WorkOrder w) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      w.title,
      w.requestId,
      w.department ?? '',
      w.unit ?? '',
      w.status,
    ].any((s) => s.toLowerCase().contains(q));
  }

  String _classificationOf(WorkOrder w) {
    final dept = (w.department ?? '').trim();
    if (dept.isEmpty) return 'Maintenance';
    switch (dept.toLowerCase()) {
      case 'plumbing':
        return 'Plumbing';
      case 'carpentry':
        return 'Carpentry';
      case 'electrical':
        return 'Electrical';
      case 'masonry':
        return 'Masonry';
      case 'maintenance':
        return 'Maintenance';
      default:
        return dept;
    }
  }

  bool _classificationMatches(WorkOrder w) {
    if (_selectedClassification == 'All') return true;
    return _classificationOf(w) == _selectedClassification;
  }

  bool _statusMatches(WorkOrder w) {
    if (_selectedStatus == 'All') return true;
    return _statusOf(w).toLowerCase() == _selectedStatus.toLowerCase();
  }

  List<WorkOrder> get _filtered =>
      _allWorkOrders
          .where(_tabMatches)
          .where(_searchMatches)
          .where(_classificationMatches)
          .where(_statusMatches)
          .toList();

  List<WorkOrder> get _filteredSorted {
    final list = List<WorkOrder>.from(_filtered);
    list.sort(
      (a, b) =>
          UiDateParser.parse(b.date).compareTo(UiDateParser.parse(a.date)),
    );
    return list;
  }

  List<TabItem> get _tabs {
    final visible = _allWorkOrders.where(_searchMatches).toList();
    return [
      TabItem(label: 'Repair', count: visible.where(_isRepairTask).length),
      TabItem(
        label: 'Maintenance',
        count: visible.where(_isMaintenanceTask).length,
      ),
    ];
  }

  String _fmtListDate(String s) {
    try {
      final parsed = UiDateParser.parse(s);
      return DateFormat('MMM d').format(parsed);
    } catch (_) {
      final dt = DateTime.tryParse(s);
      if (dt != null) return DateFormat('MMM d').format(dt);
      final m = RegExp(r'^\s*[A-Za-z]{3,}\s+\d{1,2}\s*$');
      if (m.hasMatch(s)) return s.trim();
      return s;
    }
  }

  Widget _buildCard(WorkOrder w) {
    final dept = w.department ?? 'Maintenance';
    final prio = w.priority ?? 'Medium';

    if (_isMaintenanceTask(w)) {
      final routeLabel = _detailsLabelFor(w);
      return MaintenanceCard(
        title: w.title,
        requestId: w.requestId,
        unit: w.unit ?? '-',
        date: _fmtListDate(w.date),
        status: _statusOf(w),
        priority: prio,
        department: dept,
        avatarUrl: w.avatarUrl,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => WorkOrderDetailsPage(selectedTabLabel: routeLabel),
            ),
          );
        },
        onChatTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatPage()),
            ),
      );
    }

    final routeLabel = _detailsLabelFor(w);
    return RepairCard(
      title: w.title,
      requestId: w.requestId,
      reqDate: _fmtListDate(w.date),
      statusTag: _statusOf(w),
      unit: w.unit,
      priority: w.priority ?? 'Medium',
      departmentTag: w.department,
      hasInitialAssessment: w.hasInitialAssessment,
      initialAssigneeName: w.initialAssigneeName,
      initialAssigneeDepartment: w.initialAssigneeDepartment,
      hasCompletionAssessment: w.hasCompletionAssessment,
      completionAssigneeName: w.completionAssigneeName,
      completionAssigneeDepartment: w.completionAssigneeDepartment,
      assignedTo: w.assignedTo,
      assignedDepartment: w.assignedDepartment,
      avatarUrl: w.assignedPhotoUrl,
      requestType: w.requestType,
      onTap: () async {
        try {
          final concernSlipData = await _apiService.getConcernSlipById(
            w.requestId,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => WorkOrderDetailsPage(
                    selectedTabLabel: routeLabel,
                    concernSlipData: concernSlipData,
                  ),
            ),
          );
        } catch (e) {
          print('Error fetching concern slip data: $e');
          // Fallback to navigate without data
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => WorkOrderDetailsPage(selectedTabLabel: routeLabel),
            ),
          );
        }
      },
      onChatTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatPage()),
        );
      },
    );
  }

  void _showRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => CustomPopup(
            title: 'Create Maintenance',
            message: 'Would you like to create a new maintenance?',
            primaryText: 'Yes',
            onPrimaryPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => const MaintenanceForm(
                        requestType: 'Basic Information',
                      ),
                ),
              );
            },
            secondaryText: 'Cancel',
            onSecondaryPressed: () => Navigator.of(context).pop(),
          ),
    );
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

                      selectedClassification: _selectedClassification,
                      classifications: _classificationOptions,
                      onClassificationChanged:
                          (v) => setState(() => _selectedClassification = v),

                      selectedStatus: _selectedStatus,
                      statuses: _statusOptions,
                      onStatusChanged: (status) {
                        setState(() {
                          final v = status.trim();
                          _selectedStatus = v.isEmpty ? 'All' : v;
                        });
                      },

                      onSearchChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    StatusTabSelector(
                      tabs: _tabs,
                      selectedLabel: _selectedTabLabel,
                      onTabSelected:
                          (label) => setState(() => _selectedTabLabel = label),
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
                            horizontal: 8,
                            vertical: 2,
                          ),
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
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : items.isEmpty
                              ? const EmptyState()
                              : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: items.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 12),
                                itemBuilder: (_, i) => _buildCard(items[i]),
                              ),
                    ),
                  ],
                ),
              ),

              if (_selectedTabLabel.toLowerCase() == 'maintenance')
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: AddButton(
                    onPressed: () => _showRequestDialog(context),
                  ),
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
