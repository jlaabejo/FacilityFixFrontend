import 'dart:convert';
import 'package:facilityfix/adminweb/widgets/logout_popup.dart';
import 'package:facilityfix/adminweb/widgets/tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../layout/facilityfix_layout.dart';
import '../widgets/delete_popup.dart';
import '../services/api_service_web.dart';
import 'pop_up/inventory_requestdetails_popup.dart';
import '../../services/api_services_mobile.dart' as api_services;
import 'package:facilityfix/utils/inventory_notifier.dart';

class InventoryRequestPage extends StatefulWidget {
  const InventoryRequestPage({super.key});

  @override
  State<InventoryRequestPage> createState() => _InventoryRequestPageState();
}

class _InventoryRequestPageState extends State<InventoryRequestPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _requestItems = [];
  Map<String, String> _inventoryItemNames = {}; // Cache for item names
  bool _isLoading = true;
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;

  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All Status';
  final List<String> _filterOptions = [
    'All Status',
    'Pending',
    'Approved',
    'Rejected',
  ];

  // Sorting
  String _sortColumn = 'requested_date';
  bool _sortAscending = false; // Default to descending (newest first)

  // TODO: Replace with actual building ID from user session
  final String _buildingId = 'default_building_id';

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
    _loadInventoryRequests();
  }

  Future<void> _loadInventoryItems() async {
    try {
      // Fetch ALL inventory items (not filtered by building)
      final token = await api_services.APIService.requireToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/inventory/items'),
        headers: headers,
      );

      print('[v0] Inventory items response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final items = List<Map<String, dynamic>>.from(data['data'] ?? []);
          print('[v0] Number of inventory items: ${items.length}');

          // Build a map of inventory_id -> item_name
          final Map<String, String> itemNames = {};
          for (var item in items) {
            final id = item['id']?.toString() ?? item['_doc_id']?.toString();
            final name =
                item['item_name']?.toString() ?? item['name']?.toString();
            if (id != null && name != null) {
              itemNames[id] = name;
              print('[v0] Cached: $id -> $name');
            }
          }

          print('[v0] Cached ${itemNames.length} item names');
          setState(() {
            _inventoryItemNames = itemNames;
          });
        }
      }
    } catch (e) {
      print('[v0] Error fetching inventory items: $e');
    }
  }

  /// Fetch item name by inventory ID from the API (for items not in cache)
  Future<void> _fetchMissingItemNames() async {
    final missingIds = <String>[];

    // Find all inventory IDs that aren't cached
    for (var request in _requestItems) {
      final inventoryId = request['inventory_id']?.toString();
      if (inventoryId != null &&
          !_inventoryItemNames.containsKey(inventoryId)) {
        missingIds.add(inventoryId);
      }
    }

    if (missingIds.isEmpty) {
      return;
    }

    print('[v0] Fetching ${missingIds.length} missing item names');

    // Fetch each missing item individually
    for (var inventoryId in missingIds) {
      try {
        final response = await _apiService.getInventoryItem(inventoryId);
        if (response['success'] == true && response['data'] != null) {
          final itemData = response['data'];
          final itemName =
              itemData['item_name']?.toString() ??
              itemData['name']?.toString() ??
              'Unknown Item';

          setState(() {
            _inventoryItemNames[inventoryId] = itemName;
          });

          print('[v0] Fetched: $inventoryId -> $itemName');
        }
      } catch (e) {
        print('[v0] Error fetching item $inventoryId: $e');
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadInventoryItems();
    await _loadInventoryRequests();
  }

  Future<void> _loadInventoryRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getInventoryRequests();

      print('[v0] Inventory requests response: $response');

      if (response['success'] == true) {
        final rawData = response['data'] ?? [];
        print('[v0] Number of requests: ${rawData.length}');

        // Debug: Print first item structure if available
        if (rawData.isNotEmpty) {
          print('[v0] First item structure: ${rawData[0]}');
          print('[v0] First item keys: ${(rawData[0] as Map).keys.toList()}');
        }

        // Show ALL inventory requests (no filtering)
        print('[v0] Loaded ${rawData.length} inventory requests');

        setState(() {
          _requestItems = List<Map<String, dynamic>>.from(rawData);
          _isLoading = false;
        });

        // Fetch any missing item names
        await _fetchMissingItemNames();
      } else {
        setState(() {
          _errorMessage = 'Failed to load inventory requests';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[v0] Error fetching inventory requests: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Route mapping helper function
  static String? _getRoutePath(String routeKey) {
    final Map<String, String> pathMap = {
      'dashboard': '/dashboard',
      'user_users': '/user/users',
      'user_scheduling': '/user/scheduling',
      'work_maintenance': '/work/maintenance',
      'work_task_type': '/work/task_type',
      'work_repair': '/work/repair',
      'calendar': '/calendar',
      'inventory_equipment': '/inventory/equipment',
      'inventory_items': '/inventory/items',
      'inventory_request': '/inventory/request',
      'analytics': '/analytics',
      'announcement': '/announcement',
      'settings': '/settings',
      //'logout': '/logout',
    };
    return pathMap[routeKey];
  }

  // Logout functionality
  void _handleLogout(BuildContext context) async {
    print('[DEBUG] _handleLogout called');
    // Ensure we're not already navigating
    if (!mounted) return;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (dialogContext) {
        print('[DEBUG] Dialog builder called');
        return const LogoutPopup();
      },
    );
    print('[DEBUG] Dialog result: $result');
    
    if (result == true && mounted) {
      // Perform logout
      print('[DEBUG] Logging out...');
      context.go('/');
    } else {
      print('[DEBUG] Logout cancelled or dialog dismissed');
    }
  }

  // Column widths for table
  final List<double> _colW = <double>[
    150, // REQUEST ID
    150, // MAINTENANCE ID
    200, // ITEM NAME
    100, // QUANTITY
    120, // DATE
    110, // STATUS
    48, // ACTION
  ];

  // Fixed width cell helper
  Widget _fixedCell(
    int i,
    Widget child, {
    Alignment align = Alignment.centerLeft,
  }) {
    return SizedBox(
      width: _colW[i],
      child: Align(alignment: align, child: child),
    );
  }

  // Text with ellipsis helper
  Text _ellipsis(String s, {TextStyle? style}) => Text(
    s,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    softWrap: false,
    style: style,
  );

  // Action dropdown menu methods
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> item,
    Offset position,
  ) {
    final overlayObj = Overlay.of(context).context.findRenderObject();
    if (overlayObj == null || overlayObj is! RenderBox || !overlayObj.hasSize) return;
    final RenderBox overlay = overlayObj as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                color: Colors.green[600],
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'View Details',
                style: TextStyle(color: Colors.green[600], fontSize: 14),
              ),
            ],
          ),
        ),
        // Show approve/reject options only for pending requests
        if (item['status'] == 'pending' ||
            _normalizeStatus(item['status']) == 'pending') ...[
          PopupMenuItem(
            value: 'approve',
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.blue[600],
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Approve',
                  style: TextStyle(color: Colors.blue[600], fontSize: 14),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'reject',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.red[600], size: 18),
                const SizedBox(width: 12),
                Text(
                  'Reject',
                  style: TextStyle(color: Colors.red[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red[600], size: 18),
              const SizedBox(width: 12),
              Text(
                'Delete',
                style: TextStyle(color: Colors.red[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
    ).then((value) {
      if (value != null) {
        _handleActionSelection(value, item);
      }
    });
  }

  // Handle action selection
  void _handleActionSelection(String action, Map<String, dynamic> item) {
    switch (action) {
      case 'view':
        _viewRequest(item);
        break;
      case 'approve':
        _approveRequest(item);
        break;
      case 'reject':
        _rejectRequest(item);
        break;
      case 'delete':
        _deleteRequest(item);
        break;
    }
  }

  // View request method
  Future<void> _viewRequest(Map<String, dynamic> item) async {
    print('[DEBUG] _viewRequest - Full item data: $item');
    
    // Use formatted_id from backend (INVREQ-YYYY-XXXXX format)
    final requestId = item['formatted_id'] ?? item['_doc_id'] ?? item['id'] ?? 'N/A';
    print('[DEBUG] Request ID: $requestId');
    print('[DEBUG] formatted_id: ${item['formatted_id']}');
    print('[DEBUG] _doc_id: ${item['_doc_id']}');
    print('[DEBUG] id: ${item['id']}');

    // Get item name from cached inventory items
    String itemName = 'Unknown Item';
    final inventoryId = item['inventory_id']?.toString();

    if (inventoryId != null && _inventoryItemNames.containsKey(inventoryId)) {
      // Found in cached inventory items
      itemName = _inventoryItemNames[inventoryId]!;
    } else if (item['item_name'] != null &&
        item['item_name'].toString().isNotEmpty) {
      // Fallback to direct field
      itemName = item['item_name'].toString();
    } else if (inventoryId != null) {
      // Show ID if we have it but no name
      itemName = 'Item $inventoryId';
    }

    // Debug staff department fields
    print('[DEBUG] Staff Department Fields:');
    print('[DEBUG] - staff_department: ${item['staff_department']}');
    print('[DEBUG] - department: ${item['department']}');
    print('[DEBUG] - requester_department: ${item['requester_department']}');
    
    // Debug staff name fields
    print('[DEBUG] Staff Name Fields:');
    print('[DEBUG] - requested_by_name: ${item['requested_by_name']}');
    print('[DEBUG] - requested_by: ${item['requested_by']}');
    print('[DEBUG] - requester_name: ${item['requester_name']}');
    print('[DEBUG] - staff_name: ${item['staff_name']}');

    // Prepare request data for the popup
    final requestData = {
      'requestId': requestId,
      'formatted_id': item['formatted_id'],
      'itemName': itemName,
      'purpose': item['purpose'] ?? 'General',
      'quantityRequested': item['quantity_requested'] ?? 0,
      'quantityApproved': item['quantity_approved'] ?? 0,
      'status': _normalizeStatus(item['status']),
      'requestedBy': item['requested_by_name'] ?? item['requested_by'] ?? item['requester_name'] ?? item['staff_name'] ?? 'Unknown',
      'staffDepartment': item['staff_department'] ?? item['department'] ?? item['requester_department'] ?? 'N/A',
      'requestedDate': _formatDate(item['requested_date']),
      'approvedDate': _formatDate(item['approved_date']),
      'adminNotes': item['admin_notes'] ?? 'No notes',
      'staff_notes': item['staff_notes'] ?? item['purpose'] ?? 'No notes provided',
      'maintenanceTaskId': item['maintenance_task_id'] ?? item['reference_id'],
      // Keep the original item for actions
      '_originalItem': item,
    };
    
    print('[DEBUG] Popup requestData prepared:');
    print('[DEBUG] - requestId: ${requestData['requestId']}');
    print('[DEBUG] - formatted_id: ${requestData['formatted_id']}');
    print('[DEBUG] - staffDepartment: ${requestData['staffDepartment']}');
    print('[DEBUG] - requestedBy: ${requestData['requestedBy']}');

    // Show the details popup and get result
    final result = await InventoryRequestDetailsDialog.show(
      context,
      requestData,
    );

    // Handle the action if user clicked approve or reject
    if (result != null && result['action'] != null) {
      final action = result['action'];
      final originalItem = result['requestData']['_originalItem'];

      if (action == 'approve') {
        await _approveRequest(originalItem);
      } else if (action == 'reject') {
        _rejectRequest(originalItem);
      }
    }
  }

  Future<void> _approveRequest(Map<String, dynamic> item) async {
    try {
      // Use _doc_id as the primary ID from Firestore
      final requestId = item['_doc_id'] ?? item['id'];
      if (requestId == null) {
        throw Exception('Request ID not found');
      }

      // Get inventory item ID and requested quantity for stock validation
      final inventoryId = item['inventory_id']?.toString();
      final quantityRequested =
          (item['quantity_requested'] ?? item['quantity'] ?? 0) as num;

      // Step 1: Check available stock before approval
      if (inventoryId != null && quantityRequested > 0) {
        try {
          // Get current inventory item data
          final itemResp = await _apiService.getInventoryItem(inventoryId);
          if (itemResp['success'] == true && itemResp['data'] is Map) {
            final inventoryData = Map<String, dynamic>.from(itemResp['data']);
            final currentStock =
                (inventoryData['current_stock'] ??
                        inventoryData['quantity_in_stock'] ??
                        0)
                    as num;

            // Calculate reserved stock from all reservations for this item
            int reservedStock = 0;
            try {
              final reservedResp = await _apiService.getInventoryReservations(
                buildingId: _buildingId,
              );
              if (reservedResp['success'] == true &&
                  reservedResp['data'] is List) {
                for (var req in reservedResp['data']) {
                  if (req['inventory_id']?.toString() == inventoryId) {
                    reservedStock += (req['quantity'] ?? 0) as int;
                  }
                }
              }
            } catch (_) {}

            // Calculate available stock (current - reserved)
            final availableStock = currentStock - reservedStock;

            // Check if we have enough stock
            if (availableStock < quantityRequested) {
              if (mounted) {
                // Show error dialog with stock details
                await showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Insufficient Stock'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cannot approve request. Insufficient stock available.',
                            ),
                            const SizedBox(height: 16),
                            Text('Current Stock: $currentStock'),
                            Text('Reserved Stock: $reservedStock'),
                            Text('Available Stock: $availableStock'),
                            Text('Requested Quantity: $quantityRequested'),
                            const SizedBox(height: 8),
                            Text(
                              'Need ${quantityRequested - availableStock} more units.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                );
              }
              return; // Block approval
            }
          }
        } catch (stockCheckError) {
          print('[v0] Error checking stock: $stockCheckError');
          // If stock check fails, show error and block approval
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error checking stock availability: $stockCheckError',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Step 2: Approve the request in the backend (NO stock deduction)
      // Stock will be deducted when staff marks the request as "received"
      await _apiService.approveInventoryRequest(requestId);

      // Reload the list
      _loadInventoryRequests();
      
      // Notify staff views that this request was approved so they can refresh
      try {
        final notifier = InventoryUpdateNotifier();
        final inventoryId = item['inventory_id']?.toString() ?? '';
        notifier.notifyItemUpdated(inventoryId);
      } catch (e) {
        print('[v0] Failed to notify inventory update after approve: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request approved. Staff can now mark as received.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[v0] Error approving request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectRequest(Map<String, dynamic> item) {
    // Use _doc_id as the primary ID from Firestore
    final requestId = item['_doc_id'] ?? item['id'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController reasonController = TextEditingController();

        return AlertDialog(
          title: const Text('Reject Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to reject request $requestId?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for rejection',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  if (requestId == null) {
                    throw Exception('Request ID not found');
                  }

                  await _apiService.denyInventoryRequest(
                    requestId,
                    reasonController.text.isEmpty
                        ? 'Request rejected by admin'
                        : reasonController.text,
                  );
                  // Reload the list
                  _loadInventoryRequests();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Request $requestId rejected'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  // Notify staff views that request was rejected
                  try {
                    final notifier = InventoryUpdateNotifier();
                    final inventoryId = item['inventory_id']?.toString() ?? '';
                    notifier.notifyItemUpdated(inventoryId);
                  } catch (e) {
                    print(
                      '[v0] Failed to notify inventory update after reject: $e',
                    );
                  }
                } catch (e) {
                  print('[v0] Error rejecting request: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error rejecting request: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  void _deleteRequest(Map<String, dynamic> item) {
    // Use _doc_id as the primary ID from Firestore
    final requestId = item['_doc_id'] ?? item['id'];
    showDeleteDialog(
      context,
      itemName: 'Request ${requestId ?? ''}',
      description:
          'Are you sure you want to delete request ${requestId ?? ''}? This will deny the request and cannot be undone.',
    ).then((confirmed) async {
      if (confirmed != true) return;

      try {
        if (requestId == null) throw Exception('Request ID not found');

        await _apiService.denyInventoryRequest(
          requestId,
          'Request deleted by admin',
        );

        // Remove locally and update UI immediately
        if (mounted) {
          setState(() {
            _requestItems.removeWhere((r) {
              final rid = (r['_doc_id'] ?? r['id'])?.toString();
              return rid == requestId.toString();
            });
            _currentPage = 1; // reset to first page when list changes
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Request $requestId deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // Background reload to ensure consistency
        _loadInventoryRequests();
      } catch (e) {
        print('[v0] Error deleting request: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'N/A';
      }
      return DateFormat('MM-dd-yyyy').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  // Normalize status to only pending, approved, rejected
  String _normalizeStatus(String? status) {
    if (status == null) return 'pending';

    final normalized = status.toLowerCase().trim();

    // Map various status values to the three allowed statuses
    switch (normalized) {
      case 'approved':
        return 'approved';
      case 'denied':
      case 'rejected':
        return 'rejected';
      case 'pending':
      default:
        return 'pending';
    }
  }

  // Check if approving this request would cause insufficient stock
  Future<bool> _hasInsufficientStock(Map<String, dynamic> item) async {
    try {
      final inventoryId = item['inventory_id']?.toString();
      final quantityRequested =
          (item['quantity_requested'] ?? item['quantity'] ?? 0) as num;

      if (inventoryId == null || quantityRequested <= 0) return false;

      // Get current inventory item data
      final itemResp = await _apiService.getInventoryItem(inventoryId);
      if (itemResp['success'] == true && itemResp['data'] is Map) {
        final inventoryData = Map<String, dynamic>.from(itemResp['data']);
        final currentStock =
            (inventoryData['current_stock'] ??
                    inventoryData['quantity_in_stock'] ??
                    0)
                as num;

        // Calculate reserved stock from all reservations for this item
        int reservedStock = 0;
        try {
          final reservedResp = await _apiService.getInventoryReservations(
            buildingId: _buildingId,
          );
          if (reservedResp['success'] == true && reservedResp['data'] is List) {
            for (var req in reservedResp['data']) {
              if (req['inventory_id']?.toString() == inventoryId) {
                reservedStock += (req['quantity'] ?? 0) as int;
              }
            }
          }
        } catch (_) {}

        // Calculate available stock (current - reserved)
        final availableStock = currentStock - reservedStock;

        // Return true if insufficient stock
        return availableStock < quantityRequested;
      }
    } catch (e) {
      print('[v0] Error checking stock: $e');
    }
    return false;
  }

  // Format ID with prefix
  String _formatId(dynamic id, String prefix) {
    if (id == null || id.toString().isEmpty) return 'N/A';
    final idStr = id.toString();

    // If already has the full format (e.g., REQ-2025-00001 or MT-2025-00001), return as is
    if (idStr.contains('-') && idStr.split('-').length == 3) {
      return idStr;
    }

    // Extract numeric part from the ID
    final numericId = idStr.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericId.isEmpty) return 'N/A';

    // Pad with leading zeros to make it 5 digits
    final sequenceNumber = numericId.padLeft(5, '0');
    final year = DateTime.now().year;

    // Format as PREFIX-YEAR-XXXXX
    return '$prefix-$year-$sequenceNumber';
  }

  // Filtered requests based on search and filter
  List<Map<String, dynamic>> get _filteredRequests {
    var filtered = List<Map<String, dynamic>>.from(_requestItems);

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      filtered =
          filtered.where((item) {
            // Match against displayed/formatted IDs as well as raw fields
            final rawRequestId =
                (item['_doc_id'] ?? item['id'] ?? '').toString().toLowerCase();
            final rawMaintenanceId =
                (item['maintenance_task_id'] ?? item['reference_id'] ?? '')
                    .toString()
                    .toLowerCase();
            final formattedRequestId =
                _formatId(
                  item['_doc_id'] ?? item['id'],
                  'REQ',
                ).toString().toLowerCase();
            final formattedMaintenanceId =
                _formatId(
                  item['maintenance_task_id'] ?? item['reference_id'],
                  'MT',
                ).toString().toLowerCase();
            final itemName = (item['item_name'] ?? '').toString().toLowerCase();
            final quantity =
                (item['quantity_requested'] ?? '').toString().toLowerCase();

            return rawRequestId.contains(searchLower) ||
                formattedRequestId.contains(searchLower) ||
                rawMaintenanceId.contains(searchLower) ||
                formattedMaintenanceId.contains(searchLower) ||
                itemName.contains(searchLower) ||
                quantity.contains(searchLower);
          }).toList();
    }

    // Apply status filter
    if (_selectedFilter != 'All Status') {
      final filterStatus = _selectedFilter.toLowerCase();
      filtered =
          filtered.where((item) {
            final status = _normalizeStatus(item['status']).toLowerCase();
            return status == filterStatus;
          }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison;

      switch (_sortColumn) {
        case 'requested_date':
        default:
          // Parse dates for proper comparison
          DateTime dateA =
              DateTime.tryParse(a['requested_date']?.toString() ?? '') ??
              DateTime(1970);
          DateTime dateB =
              DateTime.tryParse(b['requested_date']?.toString() ?? '') ??
              DateTime(1970);
          comparison = dateA.compareTo(dateB);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  // Pagination helper methods
  List<Map<String, dynamic>> _getPaginatedRequests() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    final filtered = _filteredRequests;
    if (startIndex >= filtered.length) return [];

    return filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );
  }

  int get _totalPages {
    final filtered = _filteredRequests;
    return filtered.isEmpty ? 1 : (filtered.length / _itemsPerPage).ceil();
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pageButtons = [];

    // Show max 5 page numbers at a time
    int startPage = _currentPage - 2;
    int endPage = _currentPage + 2;

    if (startPage < 1) {
      startPage = 1;
      endPage = 5;
    }

    if (endPage > _totalPages) {
      endPage = _totalPages;
      startPage = _totalPages - 4;
    }

    if (startPage < 1) startPage = 1;

    for (int i = startPage; i <= endPage; i++) {
      pageButtons.add(
        GestureDetector(
          onTap: () => _goToPage(i),
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color:
                  i == _currentPage
                      ? const Color(0xFF1976D2)
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                i.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: i == _currentPage ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return pageButtons;
  }

  // Search functionality
  void _onSearchChanged(String value) {
    setState(() {
      _currentPage = 1; // Reset to first page on search
    });
  }

  // Sorting functionality
  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _currentPage = 1; // Reset to first page on sort
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'inventory_request',
      onNavigate: (routeKey) {
        print('[DEBUG] onNavigate called with routeKey: $routeKey');
        final routePath = _getRoutePath(routeKey);
        if (routePath != null) {
          print('[DEBUG] Navigating to route: $routePath');
          context.go(routePath);
        } else if (routeKey == 'logout') {
          print('[DEBUG] Logout route detected, calling _handleLogout');
          _handleLogout(context);
        } else {
          print('[DEBUG] Unknown routeKey: $routeKey');
        }
      },
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with breadcrumbs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Inventory Management",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Breadcrumb navigation
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => context.go('/dashboard'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Dashboard'),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 16,
                        ),
                        TextButton(
                          onPressed: () => context.go('/inventory/items'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Inventory Management'),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 16,
                        ),
                        TextButton(
                          onPressed: null,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Request'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Search and Filter section
            Row(
              children: [
                // Search Field with white background
                SizedBox(
                  width: 400,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        hintText:
                            "Search",
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Status Filter Dropdown
                IntrinsicWidth(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: _filterOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedFilter = newValue;
                              _currentPage = 1; // Reset to first page on filter change
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Refresh Button
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: _refreshData,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: Colors.blue[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main Content Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table header with title only
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Inventory Request",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        // Export button
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: PopupMenuButton<String>(
                            onSelected: (value) {
                              // TODO: Implement export functionality
                              if (value == 'pdf') {
                                // Export to PDF
                              } else if (value == 'word') {
                                // Export to Word
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  PopupMenuItem(
                                    value: 'pdf',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text('PDF'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'word',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.description,
                                          color: Colors.blue,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Word'),
                                      ],
                                    ),
                                  ),
                                ],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.download,
                                  size: 20,
                                  color: Colors.blue[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Export',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[400]),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadInventoryRequests,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_requestItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: Text(
                          'No inventory requests found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    // Data Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 36,
                        headingRowHeight: 56,
                        dataRowHeight: 64,
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey[50],
                        ),
                        headingTextStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                        dataTextStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        columns: [
                          DataColumn(
                            label: _fixedCell(0, const Text("REQUEST ID")),
                          ),
                          DataColumn(
                            label: _fixedCell(1, const Text("MAINTENANCE ID")),
                          ),
                          DataColumn(
                            label: _fixedCell(2, const Text("ITEM NAME")),
                          ),
                          DataColumn(
                            label: _fixedCell(3, const Text("QUANTITY")),
                          ),
                          DataColumn(
                            label: _fixedCell(
                              4,
                              GestureDetector(
                                onTap: () => _onSort('requested_date'),
                                child: Row(
                                  children: [
                                    const Text("DATE REQUESTED"),
                                    if (_sortColumn == 'requested_date')
                                      Icon(
                                        _sortAscending
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: _fixedCell(5, const Text("STATUS")),
                          ),
                          DataColumn(label: _fixedCell(6, const Text(""))),
                        ],
                        rows:
                            _getPaginatedRequests().map((item) {
                              // Use formatted_id from backend (INVREQ-YYYY-XXXXX format)
                              final requestId = item['formatted_id'] ?? item['_doc_id'] ?? item['id'] ?? 'N/A';
                              final maintenanceId = _formatId(
                                item['maintenance_task_id'] ??
                                    item['reference_id'],
                                'MT',
                              );

                              // Get item name from cached inventory items
                              String itemName = 'Unknown Item';
                              final inventoryId =
                                  item['inventory_id']?.toString();

                              if (inventoryId != null &&
                                  _inventoryItemNames.containsKey(
                                    inventoryId,
                                  )) {
                                // Found in cached inventory items
                                itemName = _inventoryItemNames[inventoryId]!;
                              } else if (item['item_name'] != null &&
                                  item['item_name'].toString().isNotEmpty) {
                                // Fallback to direct field
                                itemName = item['item_name'].toString();
                              } else if (inventoryId != null) {
                                // Show ID if we have it but no name
                                itemName = 'Item $inventoryId';
                              }

                              final quantity =
                                  (item['quantity_requested'] ?? 0).toString();
                              final date = _formatDate(item['requested_date']);
                              final status = _normalizeStatus(item['status']);

                              return DataRow(
                                cells: [
                                  DataCell(
                                    _fixedCell(
                                      0,
                                      _ellipsis(
                                        requestId,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    _fixedCell(
                                      1,
                                      _ellipsis(
                                        maintenanceId,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(_fixedCell(2, _ellipsis(itemName))),
                                  DataCell(
                                    _fixedCell(
                                      3,
                                      // Show warning icon if insufficient stock for pending requests
                                      FutureBuilder<bool>(
                                        future:
                                            (status == 'pending' ||
                                                    status == 'reserved')
                                                ? _hasInsufficientStock(item)
                                                : Future.value(false),
                                        builder: (context, snapshot) {
                                          final hasWarning =
                                              snapshot.data == true;
                                          return Row(
                                            children: [
                                              if (hasWarning)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 4,
                                                      ),
                                                  child: Tooltip(
                                                    message:
                                                        'Insufficient stock available',
                                                    child: Icon(
                                                      Icons
                                                          .warning_amber_rounded,
                                                      color: Colors.orange,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              Flexible(
                                                child: _ellipsis(quantity),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  DataCell(_fixedCell(4, _ellipsis(date))),
                                  DataCell(_fixedCell(5, StatusTag(status))),
                                  DataCell(
                                    _fixedCell(
                                      6,
                                      Builder(
                                        builder: (context) {
                                          return IconButton(
                                            onPressed: () {
                                              final renderObj = context.findRenderObject();
                                              if (renderObj == null || renderObj is! RenderBox || !renderObj.hasSize) return;
                                              final rbx = renderObj as RenderBox;
                                              final position = rbx.localToGlobal(Offset.zero);
                                              // Anchor menu below the icon so it doesn't overlap
                                              final Offset menuPosition =
                                                  position +
                                                  Offset(
                                                    0,
                                                    rbx.size.height + 6,
                                                  );
                                              _showActionMenu(
                                                context,
                                                item,
                                                menuPosition,
                                              );
                                            },
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: Colors.grey[400],
                                              size: 20,
                                            ),
                                          );
                                        },
                                      ),
                                      align: Alignment.center,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[400]),

                  // Pagination section
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _filteredRequests.isEmpty
                              ? "No entries found"
                              : "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage) > _filteredRequests.length ? _filteredRequests.length : _currentPage * _itemsPerPage} of ${_filteredRequests.length} entries",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed:
                                  _currentPage > 1 ? _previousPage : null,
                              icon: Icon(
                                Icons.chevron_left,
                                color:
                                    _currentPage > 1
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                              ),
                            ),
                            ..._buildPageNumbers(),
                            IconButton(
                              onPressed:
                                  _currentPage < _totalPages ? _nextPage : null,
                              icon: Icon(
                                Icons.chevron_right,
                                color:
                                    _currentPage < _totalPages
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
