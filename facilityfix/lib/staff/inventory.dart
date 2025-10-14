import 'package:facilityfix/staff/form/inventory_form.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/staff/maintenance.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/profile.dart';
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
      itemId: json['item_code'] ?? json['id'] ?? '',
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

  const InventoryRequest({
    required this.itemName,
    required this.requestId,
    required this.department,
    required this.status,
    this.quantityRequested,
    this.purpose,
    this.requestedBy,
    this.requestDate,
  });

  factory InventoryRequest.fromJson(Map<String, dynamic> json) {
    return InventoryRequest(
      itemName: json['item_name'] ?? 'Unknown Item',
      requestId: json['id'] ?? '',
      department: json['department'] ?? 'Unknown',
      status: json['status'] ?? 'pending',
      quantityRequested: json['quantity_requested'],
      purpose: json['purpose'],
      requestedBy: json['requested_by'],
      requestDate: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
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
  bool _isLoadingItems = false;
  bool _isLoadingRequests = false;
  String? _errorMessage;

  // ----- API Data -----
  List<InventoryItem> _items = [];
  List<InventoryRequest> _requests = [];

  // ----- Tabs -----
  String selectedTabLabel = "Items";
  final tabs = [
    TabItem(label: 'Items', count: 1),
    TabItem(label: 'Requests', count: 1),
  ];

  // ----- Bottom nav -----
  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.build),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.inventory),
  ];

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const MaintenancePage(),
      const AnnouncementPage(),
      const InventoryPage(),
      const ProfilePage(),
    ];
    if (index != 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  // ----- Filters -----
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedDepartment = 'All';

  final List<String> _statusOptions = const [
    'All',
    'In Stock',
    'Out of Stock',
    'Critical',
  ];
  final List<String> _deptOptions = const [
    'All',
    'Plumbing',
    'Carpentry',
    'Electrical',
    'Masonry',
    'Maintenance',
  ];

  // ----- Demo data -----
  // Removed hardcoded data - will be loaded from API

  @override
  void initState() {
    super.initState();
    _apiService = APIService(roleOverride: AppRole.staff);
    _loadInitialData();
  }

  /// Load initial data when the page starts
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load both items and requests directly without building filtering
      await Future.wait([
        _loadInventoryItems(),
        _loadInventoryRequests(),
      ]);
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
  Future<void> _loadInventoryItems() async {
    if (_isLoadingItems) return;
    
    setState(() {
      _isLoadingItems = true;
    });

    try {
      // Use the new general inventory endpoint
      final response = await _apiService.getAllInventoryItems(
        includeInactive: false,
      );

      if (response['success'] == true && response['data'] is List) {
        final itemsData = List<Map<String, dynamic>>.from(response['data']);
        setState(() {
          _items = itemsData.map((item) => InventoryItem.fromJson(item)).toList();
          
          // Update tabs count
          tabs[0] = TabItem(label: 'Items', count: _items.length);
        });
      } else {
        throw Exception(response['detail'] ?? 'Unknown error');
      }
    } catch (e) {
      print('Error loading inventory items: $e');
      setState(() {
        _errorMessage = 'Failed to load inventory items: $e';
      });
    } finally {
      setState(() {
        _isLoadingItems = false;
      });
    }
  }

  /// Load inventory requests from API (general - no building filter)
  Future<void> _loadInventoryRequests() async {
    if (_isLoadingRequests) return;
    
    setState(() {
      _isLoadingRequests = true;
    });

    try {
      // Call the general requests endpoint without building filter
      final requestsData = await _apiService.getInventoryRequests();

      setState(() {
        _requests = requestsData.map((request) => InventoryRequest.fromJson(request)).toList();
        
        // Update tabs count
        tabs[1] = TabItem(label: 'Requests', count: _requests.length);
      });
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
  bool _statusAllowed(InventoryItem it) {
    if (_selectedStatus == 'All') return true;
    return it.status == _selectedStatus;
  }

  bool _deptAllowed(InventoryItem it) {
    if (_selectedDepartment == 'All') return true;
    return it.department == _selectedDepartment;
  }

  bool _searchMatchesItem(InventoryItem it) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      it.itemName,
      it.itemId,
      it.department,
      it.status,
      it.quantity.toString(),
    ].any((s) => s.toLowerCase().contains(q));
  }

  List<InventoryItem> get _filteredItems {
    final list = _items.where(_statusAllowed).where(_deptAllowed).where(_searchMatchesItem).toList();
    list.sort((a, b) => a.quantity.compareTo(b.quantity)); // sort lower → upper
    return list;
  }

  List<InventoryRequest> get _filteredRequests {
    final q = _searchController.text.trim().toLowerCase();
    return _requests.where((r) {
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
      case 'items':
        final items = _filteredItems;
        if (items.isEmpty) return const Center(child: Text('No items found.'));
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final it = items[i];
            return InventoryCard(
              itemName: it.itemName,
              stockStatus: it.status,
              itemId: it.itemId,
              department: it.department,
              quantityInStock: it.quantity.toString(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InventoryDetails(
                      selectedTabLabel: 'inventory details',
                      itemId: it.itemId,
                    ),
                  ),
                );
              },
            );
          },
        );

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
    final isRequestsTab = selectedTabLabel.toLowerCase() == 'requests';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Inventory Management',
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
          // IconButton(
          //   icon: const Icon(Icons.refresh),
          //   onPressed: () => _loadInitialData(),
          // ),
        ],
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
                      classifications: _deptOptions,
                      onStatusChanged: (status) {
                        setState(() => _selectedStatus = status.trim().isEmpty ? 'All' : status);
                      },
                      onClassificationChanged: (dept) {
                        setState(() => _selectedDepartment = dept.trim().isEmpty ? 'All' : dept);
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
                      selectedTabLabel.toLowerCase() == 'items' ? 'Recent Items' : 'Recent Requests',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),

                    Expanded(child: _buildTabContent()),
                  ],
                ),
              ),

            // ✅ Direct to InventoryForm on Add
            if (isRequestsTab && !_isLoading)
              Positioned(
                bottom: 24,
                right: 24,
                child: AddButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InventoryForm(
                          requestType: 'Basic Information', // start at Basic Info
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: 4,
        onTap: _onTabTapped,
      ),
    );
  }
}
