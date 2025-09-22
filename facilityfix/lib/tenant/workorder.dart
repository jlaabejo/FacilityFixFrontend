import 'dart:async';
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
import 'package:facilityfix/services/api_services.dart'; // Import APIService

class WorkOrderPage extends StatefulWidget {
  const WorkOrderPage({super.key});

  @override
  State<WorkOrderPage> createState() => _WorkOrderPageState();
}

class _WorkOrderPageState extends State<WorkOrderPage> {
  // Tabs (by request type)
  String _selectedTabLabel = "All";

  // Filters (Classification removed)
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  List<WorkOrder> _all = [];
  bool _isLoading = true;

  // ===== Refresh =============================================================
  Future<void> _refresh() async {
    await _loadConcernSlips();
  }

  Future<void> _loadConcernSlips() async {
    setState(() => _isLoading = true);

    try {
      final apiService = APIService();
      final concernSlips = await apiService.getTenantConcernSlips();

      if (concernSlips != null && mounted) {
        setState(() {
          // Convert Map data to WorkOrder objects
          _all =
              concernSlips.map<WorkOrder>((data) {
                return WorkOrder(
                  title: data['title'] ?? 'Untitled',
                  requestId: data['id'] ?? '',
                  date: data['created_at'] ?? '',
                  status: data['status'] ?? 'pending',
                  unit: data['location'] ?? '',
                  priority: data['priority'] ?? 'medium',
                  department: data['category'] ?? '',
                  requestType: 'Concern Slip',
                  hasInitialAssessment: false,
                  initialAssigneeName: '',
                  initialAssigneeDepartment: '',
                  hasCompletionAssessment: false,
                  completionAssigneeName: '',
                  completionAssigneeDepartment: '',
                  assignedTo: '',
                  assignedDepartment: '',
                  assignedPhotoUrl: '',
                );
              }).toList();
        });
      }
    } catch (e) {
      print('Error loading concern slips: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      builder:
          (_) => CustomPopup(
            title: 'Create a Request',
            message: 'Would you like to create a new request?',
            primaryText: 'Yes, Continue',
            onPrimaryPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder:
                    (_) => Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'What type of request would you like to create?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
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
                                    builder:
                                        (_) => const RequestForm(
                                          requestType: 'Concern Slip',
                                        ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.design_services_outlined,
                              ),
                              title: const Text('Job Service Request'),
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const RequestForm(
                                          requestType: 'Job Service',
                                        ),
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
                                    builder:
                                        (_) => const RequestForm(
                                          requestType: 'Work Order',
                                        ),
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

  // ===== Filtering logic (classification removed) ============================

  bool _tabMatchesByRequestType(WorkOrder w) {
    final type = (w.requestType ?? '').toLowerCase().trim();
    switch (_selectedTabLabel.toLowerCase()) {
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
    return (w.status).toLowerCase().trim() ==
        _selectedStatus.toLowerCase().trim();
    // You can also normalize status further if needed.
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
      w.requestType ?? '',
    ].any((s) => s.toLowerCase().contains(q));
  }

  List<WorkOrder> get _filtered =>
      _all
          .where(_tabMatchesByRequestType)
          .where(_statusMatches)
          .where(_searchMatches)
          .toList();

  // Sort filtered items by latest date first
  List<WorkOrder> get _filteredSorted {
    final list = List<WorkOrder>.from(_filtered);
    list.sort(
      (a, b) =>
          UiDateParser.parse(b.date).compareTo(UiDateParser.parse(a.date)),
    );
    return list;
  }

  // Dynamic dropdown options (classification removed)
  List<String> get _statusOptions {
    final base = _all.where(_tabMatchesByRequestType).where(_searchMatches);
    final set = <String>{};
    for (final w in base) {
      final s = (w.status).trim();
      if (s.isNotEmpty) set.add(s);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  // Dynamic tab counts (no classification dependency)
  List<TabItem> get _tabs {
    final visible = _all.where(_statusMatches).where(_searchMatches).toList();

    int countFor(String type) =>
        visible
            .where((w) => (w.requestType ?? '').toLowerCase() == type)
            .length;

    return [
      TabItem(label: 'All', count: visible.length),
      TabItem(label: 'Concern Slip', count: countFor('concern slip')),
      TabItem(label: 'Job Service', count: countFor('job service')),
      TabItem(label: 'Work Order', count: countFor('work order')),
    ];
  }

  // ===== Routing helper ======================================================
  String _routeLabelFor(WorkOrder w) {
    final type = (w.requestType ?? '').toLowerCase().trim();
    final status = (w.status).toLowerCase().trim();

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

  // ===== Card builder ========================================================
  Widget buildCard(WorkOrder w) {
    return RepairCard(
      title: w.title,
      requestId: w.requestId,
      reqDate: w.date,
      statusTag: w.status,
      unit: w.unit,
      priority: w.priority,
      departmentTag: w.department,
      hasInitialAssessment: w.hasInitialAssessment,
      initialAssigneeName: w.initialAssigneeName,
      initialAssigneeDepartment: w.initialAssigneeDepartment,
      hasCompletionAssessment: w.hasCompletionAssessment,
      completionAssigneeName: w.completionAssigneeName,
      completionAssigneeDepartment: w.completionAssigneeDepartment,
      assignedTo: w.assignedTo,
      assignedDepartment: w.assignedDepartment,
      // If your RepairCard expects `avatarUrl`, pass assignedPhotoUrl here:
      avatarUrl: w.assignedPhotoUrl,
      requestType: w.requestType,
      onTap: () {
        final routeLabel = _routeLabelFor(w);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ViewDetailsPage(
                  selectedTabLabel: routeLabel,
                  requestType: w.requestType,
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

  // ===== Lifecycle ===========================================================
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadConcernSlips();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===== Helpers =============================================================
  Widget _buildSearchField() {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}), // live search
        decoration: InputDecoration(
          hintText: 'Search by title, ID, status, unit…',
          prefixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF005CE7)),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          isDense: true,
        ),
      ),
    );
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
          child: Stack(
            children: [
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ===== Search + Status (classification removed) =====
                        Row(
                          children: [
                            Expanded(child: _buildSearchField()),
                            const SizedBox(width: 12),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                items:
                                    _statusOptions
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(
                                    () =>
                                        _selectedStatus =
                                            v.trim().isEmpty ? 'All' : v,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tabs: All / Concern Slip / Job Service / Work Order
                        StatusTabSelector(
                          tabs: _tabs,
                          selectedLabel: _selectedTabLabel,
                          onTabSelected:
                              (label) =>
                                  setState(() => _selectedTabLabel = label),
                        ),
                        const SizedBox(height: 20),

                        // Header
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

                        // List
                        Expanded(
                          child:
                              items.isEmpty
                                  ? Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.assignment_outlined,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No ${_selectedTabLabel.toLowerCase()} requests yet',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF374151),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Tap the + button below to create your first request',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: items.length,
                                    separatorBuilder:
                                        (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (_, i) => buildCard(items[i]),
                                  ),
                        ),
                      ],
                    ),
                  ),

              // Add button
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
