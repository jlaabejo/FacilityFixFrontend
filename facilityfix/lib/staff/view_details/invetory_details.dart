import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/view_details.dart';
import 'package:facilityfix/widgets/modals.dart'; // <-- CustomPopup
import 'package:facilityfix/widgets/buttons.dart'
    as custom_buttons; // <-- FilledButton lives here
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
  final int _selectedIndex = 5;
  late final APIService _apiService;
  
  bool _isLoading = true;
  Map<String, dynamic>? _itemData;
  Map<String, dynamic>? _requestData;
  String? _errorMessage;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.build),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  @override
  void initState() {
    super.initState();
    _apiService = APIService(roleOverride: AppRole.staff);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('DEBUG: Loading data for tab: ${widget.selectedTabLabel}');
      print('DEBUG: Item ID: ${widget.itemId}');
      print('DEBUG: Request ID: ${widget.requestId}');

      if (widget.selectedTabLabel.toLowerCase() == 'inventory details' && widget.itemId != null) {
        // Fetch inventory item
        print('DEBUG: Fetching inventory item with ID: ${widget.itemId}');
        final data = await _apiService.getInventoryItemById(widget.itemId!);
        print('DEBUG: Inventory item data received: $data');

        if (mounted) {
          setState(() {
            _itemData = data;
            _isLoading = false;
          });
        }
      } else if (widget.selectedTabLabel.toLowerCase() == 'inventory request' && widget.requestId != null) {
        // Fetch inventory request
        print('DEBUG: Fetching inventory request with ID: ${widget.requestId}');
        final data = await _apiService.getInventoryRequestById(widget.requestId!);
        print('DEBUG: Inventory request data received: $data');

        if (data == null) {
          print('DEBUG: Request data is null, setting error message');
          if (mounted) {
            setState(() {
              _errorMessage = 'Request not found with ID: ${widget.requestId}';
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
        // No ID provided
        print('DEBUG: No ID provided for ${widget.selectedTabLabel}');
        if (mounted) {
          setState(() {
            _errorMessage = 'No ID provided';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('ERROR: Error loading inventory details: $e');
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

  // ───────────────────────────────────────────────────────────
  // Success dialog -> Announcements
  // ───────────────────────────────────────────────────────────
  void _showRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CustomPopup(
        title: 'Success',
        message:
            'Your item request has been submitted successfully and is now listed under Inventory Management.',
        primaryText: 'Go to Inventory Management',
        onPrimaryPressed: () {
          Navigator.of(context).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const InventoryPage()),
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // Modal: Request Item (quantity, date needed, optional notes)
  // ───────────────────────────────────────────────────────────
  Future<void> _openRequestItemSheet({
    required String itemName,
    required String itemId,
    required String defaultUnit,
  }) async {
    final formKey = GlobalKey<FormState>();
    final qtyCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime? neededDate;

    Future<void> pickDate() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now, // can't be in the past
        lastDate: DateTime(now.year + 3),
      );
      if (picked != null) {
        setState(() {
          neededDate = DateTime(picked.year, picked.month, picked.day);
        });
      }
    }

    String formatDate(DateTime d) {
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec',
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const Text(
                    'Request Item',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$itemName • $itemId',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475467),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quantity
                  const Text(
                    'Quantity',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter quantity',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return 'Quantity is required';
                            final n = int.tryParse(s);
                            if (n == null || n <= 0) {
                              return 'Enter a positive whole number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          defaultUnit,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475467),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Date Needed
                  const Text(
                    'Date Needed',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: pickDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Select date',
                          suffixIcon: const Icon(Icons.calendar_today_rounded),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (_) {
                          if (neededDate == null) return 'Date needed is required';
                          final now = DateTime.now();
                          final dd = DateTime(
                            neededDate!.year, neededDate!.month, neededDate!.day,
                          );
                          final today = DateTime(now.year, now.month, now.day);
                          if (dd.isBefore(today)) {
                            return 'Date cannot be in the past';
                          }
                          return null;
                        },
                        controller: TextEditingController(
                          text: neededDate == null ? '' : formatDate(neededDate!),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Notes (Optional)
                  const Text(
                    'Notes (optional)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: notesCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Add any remarks for this request',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Submit button
                  custom_buttons.FilledButton(
                    label: 'Submit Request',
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        final payload = {
                          'itemId': itemId,
                          'itemName': itemName,
                          'quantity': int.parse(qtyCtrl.text.trim()),
                          'unit': defaultUnit,
                          'dateNeeded': neededDate!.toIso8601String(),
                          'notes': notesCtrl.text.trim().isEmpty
                              ? null
                              : notesCtrl.text.trim(),
                          'requestedAt': DateTime.now().toIso8601String(),
                          'requestedBy': 'Current User', // TODO: bind to auth
                          'status': 'Pending',
                        };

                        Navigator.of(ctx).pop(); // close sheet
                        // Show success dialog and route to Announcements
                        _showRequestDialog(context);
                      }
                    },
                    height: 48,
                    borderRadius: 12,
                    backgroundColor: const Color(0xFF005CE7), // primary blue
                    withOuterBorder: false, // <-- remove outer border line
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Content (without the button; button is sticky in bottomNavigationBar)
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
          notes: request['justification'] ?? request['admin_notes'] ?? 'No notes provided.',
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

  // Sticky button builder (only for Inventory Details tab)
  Widget _buildStickyRequestBar() {
    // Use actual item data if available, otherwise use defaults
    final itemName = _itemData?['item_name'] ?? 'Unknown Item';
    final itemId = _itemData?['item_code'] ?? _itemData?['id'] ?? 'N/A';
    final defaultUnit = _itemData?['unit_of_measure'] ?? 'pcs';

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: custom_buttons.FilledButton(
            label: 'Request Item',
            onPressed: () {
              if (_itemData != null) {
                _openRequestItemSheet(
                  itemName: itemName,
                  itemId: itemId,
                  defaultUnit: defaultUnit,
                );
              }
            },
            borderRadius: 12,
            backgroundColor: const Color(0xFF005CE7), // primary blue
            withOuterBorder: false, // <-- remove outer border line
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Enough bottom padding so content never hides behind the sticky bar + nav
    const contentBottomPadding = 140.0;

    final lowerTab = widget.selectedTabLabel.toLowerCase();
    final showSticky = lowerTab == 'inventory details';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'View Details',
        leading: const Padding(
          padding: EdgeInsets.only(right: 8),
          child: BackButton(),
        ),
        showMore: true,
        showHistory: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, contentBottomPadding),
          child: _buildTabContent(),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSticky) _buildStickyRequestBar(),
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
