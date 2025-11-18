import 'package:flutter/material.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/staff/maintenance.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/view_details/invetory_details.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart';
import 'package:facilityfix/widgets/cards.dart';
import 'package:facilityfix/staff/notification.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/config/env.dart';

class InventoryItem {
  final String itemName;
  final String itemId;
  final String department;
  final int quantity;
  final String status; // Stock | Out of Stock | Critical
  final String? description;
  final String? category;
  final double? costPerUnit;
  final int? minimumStock;
  final int? maximumStock;

  const InventoryItem({
    required this.itemName,
    required this.itemId,
    required this.department,
    required this.quantity,
    required this.status,
    this.description,
    this.category,
    this.costPerUnit,
    this.minimumStock,
    this.maximumStock,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    // Convert backend status to display status
    String displayStatus = 'Stock';
    if (json['current_stock'] == 0) {
      displayStatus = 'Out of Stock';
    } else if (json['minimum_stock'] != null && 
               json['current_stock'] <= json['minimum_stock']) {
      displayStatus = 'Critical';
    }

    return InventoryItem(
      itemName: json['item_name'] ?? 'Unknown Item',
      itemId: json['item_code'] ?? json['id'] ?? json['inventory_id'] ?? '',
      department: json['department'] ?? 'Unknown',
      quantity: json['current_stock'] ?? 0,
      status: displayStatus,
      description: json['description'],
      category: json['category'],
      costPerUnit: json['cost_per_unit']?.toDouble(),
      minimumStock: json['minimum_stock'],
      maximumStock: json['maximum_stock'],
    );
  }
}

class InventoryRequest {
  final String itemName;
  final String requestId;
  final String department;
  final String status;
  final int? quantityRequested;
  final String? purpose;
  final String? requestedBy;
  final DateTime? requestDate;
  final String? maintenanceId;

  const InventoryRequest({
    required this.itemName,
    required this.requestId,
    required this.department,
    required this.status,
    this.quantityRequested,
    this.purpose,
    this.requestedBy,
    this.requestDate,
    this.maintenanceId,
  });

  factory InventoryRequest.fromJson(Map<String, dynamic> json) {
    return InventoryRequest(
      itemName: json['item_name'] ?? 'Unknown Item',
      requestId: json['_doc_id'] ?? json['id'] ?? json['inventory_id'] ?? '',
      department: json['department'] ?? 'Unknown',
      status: json['status'] ?? 'pending',
      quantityRequested: json['quantity_requested'],
      purpose: json['purpose'],
      requestedBy: json['assigned_staff_name'] ?? json['staff_name'] ?? 'Unknown',
      requestDate: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      maintenanceId: json['id'] ?? null,
    );
  }
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  // ----- API Service -----
  late final APIService _apiService;

  // ----- Loading & Error States -----
  bool _isLoading = true;
  bool _isLoadingRequests = false;
  String? _errorMessage;

  // ----- API Data -----
  List<InventoryRequest> _requests = [];

  // ----- Tabs -----
  String selectedTabLabel = "Requests";
  final tabs = [
    TabItem(label: 'Requests', count: 1),
  ];

  // ----- Bottom nav -----
  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.build),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  void _onTabTapped(int index) {
    if (index == 5) return; // Already on Inventory page

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WorkOrderPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MaintenancePage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AnnouncementPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CalendarPage()),
        );
        break;
    }
  }

  // ----- Filters -----
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedDepartment = 'All';

  final List<String> _statusOptions = const [
    'All',
    'pending',
    'approved',
    'rejected',
    'received',
  ];

  // ----- Demo data -----
  // Removed hardcoded data - will be loaded from API

  @override
  void initState() {
    super.initState();
    _apiService = APIService(roleOverride: AppRole.staff);
    _loadInitialData();
    _loadUnreadNotifCount();
  }

  int _unreadNotifCount = 0;

  Future<void> _loadUnreadNotifCount() async {
    try {
      final api = APIService(roleOverride: AppRole.staff);
      final count = await api.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadNotifCount = count);
    } catch (e) {
      print('[Staff Inventory] Failed to load unread notification count: $e');
    }
  }

  /// Load initial data when the page starts
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load requests only
      await _loadInventoryRequests();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load inventory data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load inventory items from API (general - not building specific)
  /// Load inventory requests from API - includes general requests and maintenance-assigned requests
  Future<void> _loadInventoryRequests() async {
    if (_isLoadingRequests) return;

    setState(() {
      _isLoadingRequests = true;
    });

    try {
      // Fetch both general requests and maintenance-assigned requests
      final results = await Future.wait([
        _apiService.getInventoryRequests().catchError((e) {
          print('Error loading general requests: $e');
          return <Map<String, dynamic>>[];
        }),
        _apiService.getMyMaintenanceInventoryRequests().catchError((e) {
          print('Error loading maintenance requests: $e');
          return <Map<String, dynamic>>[];
        }),
      ]);

      final generalRequests = results[0];
      final maintenanceRequests = results[1];

      // Combine both lists and remove duplicates based on request ID
      final allRequestsMap = <String, Map<String, dynamic>>{};

      for (var request in generalRequests) {
        final id = request['_doc_id'] ?? request['id'];
        if (id != null) {
          allRequestsMap[id] = request;
        }
      }

      for (var request in maintenanceRequests) {
        final id = request['_doc_id'] ?? request['id'];
        if (id != null) {
          allRequestsMap[id] = request;
        }
      }

      // Enrich with item details
      for (var request in allRequestsMap.values) {
        if (request['inventory_id'] != null) {
          try {
            final itemData = await _apiService.getInventoryItemById(request['inventory_id']);
            if (itemData != null) {
              request['item_name'] = itemData['item_name'];
              request['department'] = itemData['department'];
              request['inventory_id'] = itemData['inventory_id'];
            }
          } catch (e) {
            print('Error loading item details: $e');
          }
        }
      }

      // Enrich with staff names for requested_by UIDs
      for (var request in allRequestsMap.values) {
        if (request['requested_by'] != null && request['requested_by'].toString().isNotEmpty) {
          try {
            final staffData = await _apiService.getStaffById(request['requested_by']);
            if (staffData != null && staffData['name'] != null) {
              request['requested_by_name'] = staffData['name'];
            }
          } catch (e) {
            print('Error loading staff details for ${request['requested_by']}: $e');
          }
        }
      }

      setState(() {
        _requests = allRequestsMap.values
            .map((request) => InventoryRequest.fromJson(request))
            .toList();

        // Update tabs count
        tabs[0] = TabItem(label: 'Requests', count: _requests.length);
      });

      print('DEBUG: Loaded ${_requests.length} total inventory requests (general + maintenance)');
    } catch (e) {
      print('Error loading inventory requests: $e');
      setState(() {
        _errorMessage = 'Failed to load inventory requests: $e';
      });
    } finally {
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  // ===== Filtering =====
  List<InventoryRequest> get _filteredRequests {
    final q = _searchController.text.trim().toLowerCase();
    return _requests.where((r) {
      // Exclude received requests by default unless specifically filtering for them
      if (_selectedStatus == 'All' && r.status.toLowerCase() == 'received') return false;
      if (_selectedStatus != 'All' && r.status != _selectedStatus) return false;
      if (q.isEmpty) return true;
      return [
        r.itemName,
        r.requestId,
        r.department,
        r.status,
      ].any((s) => s.toLowerCase().contains(q));
    }).toList();
  }

  Widget _buildTabContent() {
    switch (selectedTabLabel.toLowerCase()) {
      case 'requests':
        final reqs = _filteredRequests;
        if (reqs.isEmpty) return const Center(child: Text('No requests found.'));
        return ListView.separated(
          itemCount: reqs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = reqs[i];
            return InventoryRequestCard(
              itemName: r.itemName,
              requestId: r.requestId,
              department: r.department,
              status: r.status,
              maintenanceId: r.maintenanceId,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InventoryDetails(
                      selectedTabLabel: 'inventory request',
                      requestId: r.requestId,
                    ),
                  ),
                );
              },
            );
          },
        );

      default:
        return const Center(child: Text('No data.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Inventory Management',
        notificationCount: _unreadNotifCount,
        onNotificationTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationPage()),
          );
          _loadUnreadNotifCount();
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_isLoading)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading inventory data...'),
                  ],
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _loadInitialData(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search + Status + Department filters
                    SearchAndFilterBar(
                      searchController: _searchController,
                      selectedStatus: _selectedStatus,
                      statuses: _statusOptions,
                      selectedClassification: _selectedDepartment,
                      onStatusChanged: (status) {
                        setState(() => _selectedStatus = status.trim().isEmpty ? 'All' : status);
                      },
                      onSearchChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    StatusTabSelector(
                      tabs: tabs,
                      selectedLabel: selectedTabLabel,
                      onTabSelected: (label) => setState(() => selectedTabLabel = label),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Recent Requests',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),

                    Expanded(child: _buildTabContent()),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: 5,
        onTap: _onTabTapped,
      ),
    );
  }
}
