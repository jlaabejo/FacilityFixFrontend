import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/calendar.dart';
import 'package:facilityfix/admin/home.dart';
import 'package:facilityfix/admin/inventory.dart';
import 'package:facilityfix/admin/workorder.dart';
import 'package:facilityfix/widgets/modals.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/view_details.dart';
import 'package:facilityfix/widgets/buttons.dart' as custom_buttons; // ⬅️ custom buttons
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/config/env.dart';

class InventoryDetails extends StatefulWidget {
  final String selectedTabLabel;
  final String? itemId;  // For inventory items
  final String? requestId;  // For inventory requests

  const InventoryDetails({
    super.key,
    required this.selectedTabLabel,
    this.itemId,
    this.requestId,
  });

  @override
  State<InventoryDetails> createState() => _InventoryDetailsState();
}

class _InventoryDetailsState extends State<InventoryDetails> {
  final int _selectedIndex = 4;
  late final APIService _apiService;

  bool _isLoading = true;
  Map<String, dynamic>? _itemData;
  Map<String, dynamic>? _requestData;
  String? _errorMessage;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  @override
  void initState() {
    super.initState();
    _apiService = APIService(roleOverride: AppRole.admin);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.selectedTabLabel.toLowerCase() == 'inventory details' && widget.itemId != null) {
        // Fetch inventory item
        final data = await _apiService.getInventoryItemById(widget.itemId!);

        if (mounted) {
          setState(() {
            _itemData = data;
            _isLoading = false;
          });
        }
      } else if (widget.selectedTabLabel.toLowerCase() == 'inventory request' && widget.requestId != null) {
        // Fetch inventory request
        final data = await _apiService.getInventoryRequestById(widget.requestId!);

        if (data == null) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Request not found';
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _requestData = data;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'No ID provided';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const CalendarPage(),
      const InventoryPage(),
    ];

    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  bool get _isInventoryDetails =>
      widget.selectedTabLabel.toLowerCase() == 'inventory details';
  bool get _isInventoryRequest =>
      widget.selectedTabLabel.toLowerCase() == 'inventory request';

  // ===== Current item context (from loaded data) =====
  String? get _currentItemName {
    if (_isInventoryDetails && _itemData != null) {
      return _itemData!['item_name'] ?? 'Unknown Item';
    }
    return null;
  }

  String? get _currentItemId {
    if (_isInventoryDetails && _itemData != null) {
      return _itemData!['item_code'] ?? _itemData!['id'] ?? 'N/A';
    }
    return null;
  }

  String? get _currentUnit {
    if (_isInventoryDetails && _itemData != null) {
      return _itemData!['unit_of_measure'] ?? 'pcs';
    }
    return 'pcs';
  }

  // ----- Actions -----
  Future<void> _onRestock() async {
    final result = await showModalBottomSheet<RestockResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RestockBottomSheet(
        itemName: _currentItemName ?? '-',
        itemId: _currentItemId ?? '-',
        unit: _currentUnit ?? 'pcs',
      ),
    );

    if (result != null) {
      // TODO: backend update for restock
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restocked ${result.quantity} ${result.unit}'),
        ),
      );
    }
  }

  Future<void> _onReject() async {
    final result = await showModalBottomSheet<RejectResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RejectBottomSheet(),
    );

    if (result != null) {
      // TODO: backend update for rejection (status, reason, note)
      final note = (result.note == null || result.note!.trim().isEmpty)
          ? ''
          : ' — ${result.note}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request rejected • ${result.reason}$note')),
      );
    }
  }

  void _onAccept() {
    // TODO: backend update for acceptance
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request accepted.')),
    );
  }

  // ----- Sticky bars (no SafeArea bottom to avoid extra padding) -----
  Widget? _buildStickyBar() {
    if (_isInventoryDetails) {
      // Restock Button
      return SafeArea(
        top: false,
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              Expanded(
                child: custom_buttons.FilledButton(
                  label: 'Restock',
                  onPressed: _onRestock,
                  withOuterBorder: false,
                  backgroundColor: const Color(0xFF1570EF),
                  height: 48,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isInventoryRequest) {
      // Reject + Accept
      return SafeArea(
        top: false,
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              Expanded(
                child: custom_buttons.OutlinedPillButton(
                  icon: Icons.delete_outline,
                  label: 'Reject',
                  onPressed: _onReject,
                  height: 44,
                  borderRadius: 24,
                  foregroundColor: Colors.red,
                  borderColor: Colors.red,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: custom_buttons.FilledButton(
                  label: 'Accept',
                  onPressed: _onAccept,
                  withOuterBorder: false,
                  backgroundColor: const Color(0xFF1570EF),
                  height: 48,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return null;
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading details...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
              onPressed: () => _loadData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    switch (widget.selectedTabLabel.toLowerCase()) {
      // Inventory Details
      case 'inventory details':
        if (_itemData == null) {
          return const Center(child: Text("Item not found."));
        }

        final item = _itemData!;
        String formatDate(dynamic date) {
          if (date == null) return 'N/A';
          try {
            final dt = date is DateTime ? date : DateTime.parse(date.toString());
            return '${dt.day.toString().padLeft(2, '0')} / ${dt.month.toString().padLeft(2, '0')} / ${dt.year.toString().substring(2)}';
          } catch (e) {
            return 'N/A';
          }
        }

        return InventoryDetailsScreen(
          // Basic Information
          itemName: item['item_name'] ?? 'Unknown Item',
          itemId: item['item_code'] ?? item['id'] ?? 'N/A',
          status: _getStockStatus(item),
          // Item Details
          dateAdded: formatDate(item['date_added'] ?? item['created_at']),
          classification: item['classification'] ?? item['category'] ?? 'N/A',
          department: item['department'] ?? 'N/A',
          // Stock
          stockStatus: _getStockStatus(item),
          quantity: '${item['current_stock'] ?? 0} ${item['unit_of_measure'] ?? 'pcs'}',
          reorderLevel: '${item['reorder_level'] ?? 0} ${item['unit_of_measure'] ?? 'pcs'}',
          unit: item['unit_of_measure'] ?? 'pcs',
          // Supplier
          supplierName: item['supplier_name'] ?? 'N/A',
          supplierNumber: item['supplier_contact'] ?? 'N/A',
          warrantyUntil: formatDate(item['expiry_date']),
        );

      // Inventory Request
      case 'inventory request':
        if (_requestData == null) {
          return const Center(child: Text("Request not found."));
        }

        final request = _requestData!;
        String formatDate(dynamic date) {
          if (date == null) return 'N/A';
          try {
            final dt = date is DateTime ? date : DateTime.parse(date.toString());
            return '${dt.day.toString().padLeft(2, '0')} / ${dt.month.toString().padLeft(2, '0')} / ${dt.year.toString().substring(2)}';
          } catch (e) {
            return 'N/A';
          }
        }

        return InventoryDetailsScreen(
          // Basic Information
          itemName: request['item_name'] ?? 'Unknown Item',
          itemId: request['_doc_id'] ?? request['id'] ?? 'N/A',
          status: (request['status'] ?? 'pending').toString().toUpperCase(),
          // Request Item
          requestId: request['_doc_id'] ?? request['id'] ?? 'N/A',
          requestQuantity: (request['quantity_requested'] ?? 0).toString(),
          requestUnit: request['unit_of_measure'] ?? 'pcs',
          dateNeeded: formatDate(request['requested_date'] ?? request['created_at']),
          reqLocation: request['location'] ?? 'N/A',
          // Requestor
          staffName: request['requested_by'] ?? 'Unknown',
          staffDepartment: request['department'] ?? 'N/A',
          // Notes
          notes: request['purpose'] ?? request['admin_notes'] ?? 'No notes provided.',
        );

      default:
        return const Center(child: Text("No data found."));
    }
  }

  String _getStockStatus(Map<String, dynamic> item) {
    final currentStock = item['current_stock'] ?? 0;
    final reorderLevel = item['reorder_level'] ?? 0;

    if (currentStock == 0) {
      return 'Out of Stock';
    } else if (currentStock <= reorderLevel) {
      return 'Critical';
    } else {
      return 'In Stock';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sticky = _buildStickyBar();
    final bool hasSticky = sticky != null;
    final bodyInsetBottom = hasSticky ? 120.0 : 24.0; 

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Inventory Management',
        leading: const Padding(
          padding: EdgeInsets.only(right: 8),
          child: BackButton(),
        ),
        showMore: true,
        showHistory: !_isInventoryRequest, // false on the request tab
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, bodyInsetBottom),
          child: _buildTabContent(),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sticky != null) sticky,
          NavBar(
            items: _navItems,
            currentIndex: _selectedIndex,
            onTap: _onTabTapped,
          ),
        ],
      ),
    );
  }
}
