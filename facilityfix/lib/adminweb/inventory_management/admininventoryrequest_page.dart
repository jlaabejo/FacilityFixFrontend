import 'dart:convert';
import 'package:facilityfix/adminweb/widgets/tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../layout/facilityfix_layout.dart';
import '../widgets/delete_popup.dart';
import '../services/api_service.dart';
import 'pop_up/inventory_requestdetails_popup.dart';
import '../../services/api_services.dart' as api_services;

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
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Pending', 'Approved', 'Rejected'];
  
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
            final name = item['item_name']?.toString() ?? item['name']?.toString();
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
      if (inventoryId != null && !_inventoryItemNames.containsKey(inventoryId)) {
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
          final itemName = itemData['item_name']?.toString() ??
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

  Future<void> _loadInventoryRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getInventoryRequests(
        buildingId: _buildingId,
      );

      print('[v0] Inventory requests response: $response');

      if (response['success'] == true) {
        final rawData = response['data'] ?? [];
        print('[v0] Number of requests: ${rawData.length}');

        // Debug: Print first item structure if available
        if (rawData.isNotEmpty) {
          print('[v0] First item structure: ${rawData[0]}');
          print('[v0] First item keys: ${(rawData[0] as Map).keys.toList()}');
        }

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
  String? _getRoutePath(String routeKey) {
    final Map<String, String> pathMap = {
      'dashboard': '/dashboard',
      'user_users': '/user/users',
      'user_roles': '/user/roles',
      'work_maintenance': '/work/maintenance',
      'work_repair': '/work/repair',
      'calendar': '/calendar',
      'inventory_items': '/inventory/items',
      'inventory_request': '/inventory/request',
      'analytics': '/analytics',
      'announcement': '/announcement',
      'settings': '/settings',
    };
    return pathMap[routeKey];
  }

  // Logout functionality
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
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
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

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
        if (item['status'] == 'pending' || _normalizeStatus(item['status']) == 'pending') ...[
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
    final requestId = item['_doc_id'] ?? item['id'] ?? 'N/A';
    
    // Get item name from cached inventory items
    String itemName = 'Unknown Item';
    final inventoryId = item['inventory_id']?.toString();
    
    if (inventoryId != null && _inventoryItemNames.containsKey(inventoryId)) {
      // Found in cached inventory items
      itemName = _inventoryItemNames[inventoryId]!;
    } else if (item['item_name'] != null && item['item_name'].toString().isNotEmpty) {
      // Fallback to direct field
      itemName = item['item_name'].toString();
    } else if (inventoryId != null) {
      // Show ID if we have it but no name
      itemName = 'Item $inventoryId';
    }
    
    // Prepare request data for the popup
    final requestData = {
      'requestId': requestId,
      'itemName': itemName,
      'purpose': item['purpose'] ?? 'General',
      'quantityRequested': item['quantity_requested'] ?? 0,
      'quantityApproved': item['quantity_approved'] ?? 0,
      'status': _normalizeStatus(item['status']),
      'requestedBy': item['requested_by'] ?? 'Unknown',
      'staffDepartment': item['staff_department'] ?? 'N/A',
      'requestedDate': _formatDate(item['requested_date']),
      'approvedDate': _formatDate(item['approved_date']),
      'adminNotes': item['admin_notes'] ?? 'No notes',
      'maintenanceTaskId': item['maintenance_task_id'] ?? item['reference_id'],
      // Keep the original item for actions
      '_originalItem': item,
    };

    // Show the details popup and get result
    final result = await InventoryRequestDetailsDialog.show(context, requestData);
    
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

      // Check if this is a reserved request (from maintenance)
      final status = (item['status'] ?? 'pending').toString().toLowerCase();
      final isReserved = status == 'reserved';
      final maintenanceTaskId = item['maintenance_task_id'] ?? item['reference_id'];

      // Get inventory item ID and requested quantity
      final inventoryId = item['inventory_id']?.toString();
      final quantityRequested = (item['quantity_requested'] ?? item['quantity'] ?? 0) as num;
      
      if (isReserved) {
        // Reserved items (from maintenance) should NOT be approved via this flow
        // They are automatically "allocated" when maintenance is scheduled
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reserved items cannot be approved. They are allocated for maintenance tasks.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Step 1: Check available stock before approval
      if (inventoryId != null && quantityRequested > 0) {
        try {
          // Get current inventory item data
          final itemResp = await _apiService.getInventoryItem(inventoryId);
          if (itemResp['success'] == true && itemResp['data'] is Map) {
            final inventoryData = Map<String, dynamic>.from(itemResp['data']);
            final currentStock = (inventoryData['current_stock'] ?? inventoryData['quantity_in_stock'] ?? 0) as num;
            
            // Calculate reserved stock from all reserved requests for this item
            int reservedStock = 0;
            try {
              final reservedResp = await _apiService.getInventoryRequests(
                buildingId: _buildingId,
                status: 'reserved',
              );
              if (reservedResp['success'] == true && reservedResp['data'] is List) {
                for (var req in reservedResp['data']) {
                  if (req['inventory_id']?.toString() == inventoryId) {
                    reservedStock += (req['quantity_requested'] ?? req['quantity'] ?? 0) as int;
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
                  builder: (context) => AlertDialog(
                    title: const Text('Insufficient Stock'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cannot approve request. Insufficient stock available.'),
                        const SizedBox(height: 16),
                        Text('Current Stock: $currentStock'),
                        Text('Reserved Stock: $reservedStock'),
                        Text('Available Stock: $availableStock'),
                        Text('Requested Quantity: $quantityRequested'),
                        const SizedBox(height: 8),
                        Text(
                          'Need ${quantityRequested - availableStock} more units.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
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
                content: Text('Error checking stock availability: $stockCheckError'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
      
      // Step 2: Approve the request in the backend
      await _apiService.approveInventoryRequest(requestId);

      // Step 3: Deduct stock from the inventory item
      if (inventoryId != null && quantityRequested > 0) {
        try {
          // Get current inventory item data again (in case it changed)
          final itemResp = await _apiService.getInventoryItem(inventoryId);
          if (itemResp['success'] == true && itemResp['data'] is Map) {
            final inventoryData = Map<String, dynamic>.from(itemResp['data']);
            final currentStock = (inventoryData['current_stock'] ?? inventoryData['quantity_in_stock'] ?? 0) as num;
            
            // Calculate new stock (deduct the approved quantity)
            final newStock = (currentStock - quantityRequested).toInt();

            // Update the inventory item with new stock
            await _apiService.updateInventoryItem(inventoryId, {
              'current_stock': newStock,
              'quantity_in_stock': newStock,
            });
            
            print('[v0] Stock deducted: $inventoryId, Old: $currentStock, New: $newStock');
          }
        } catch (stockError) {
          print('[v0] Error deducting stock: $stockError');
          // Request was approved, but stock deduction failed - log but don't fail the whole operation
        }
      }

      // Reload the list
      _loadInventoryRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request $requestId approved and stock deducted'),
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
      description: 'Are you sure you want to delete request ${requestId ?? ''}? This will deny the request and cannot be undone.',
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
      case 'fulfilled':
      case 'completed':
      case 'approved':
        return 'approved';
      case 'denied':
      case 'rejected':
        return 'rejected';
      case 'reserved':
        return 'reserved';
      case 'pending':
      default:
        return 'pending';
    }
  }

  // Check if approving this request would cause insufficient stock
  Future<bool> _hasInsufficientStock(Map<String, dynamic> item) async {
    try {
      final inventoryId = item['inventory_id']?.toString();
      final quantityRequested = (item['quantity_requested'] ?? item['quantity'] ?? 0) as num;
      
      if (inventoryId == null || quantityRequested <= 0) return false;

      // Get current inventory item data
      final itemResp = await _apiService.getInventoryItem(inventoryId);
      if (itemResp['success'] == true && itemResp['data'] is Map) {
        final inventoryData = Map<String, dynamic>.from(itemResp['data']);
        final currentStock = (inventoryData['current_stock'] ?? inventoryData['quantity_in_stock'] ?? 0) as num;
        
        // Calculate reserved stock from all reserved requests for this item
        int reservedStock = 0;
        try {
          final reservedResp = await _apiService.getInventoryRequests(
            buildingId: _buildingId,
            status: 'reserved',
          );
          if (reservedResp['success'] == true && reservedResp['data'] is List) {
            for (var req in reservedResp['data']) {
              if (req['inventory_id']?.toString() == inventoryId) {
                reservedStock += (req['quantity_requested'] ?? req['quantity'] ?? 0) as int;
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
      filtered = filtered.where((item) {
        // Match against displayed/formatted IDs as well as raw fields
        final rawRequestId = (item['_doc_id'] ?? item['id'] ?? '').toString().toLowerCase();
        final rawMaintenanceId = (item['maintenance_task_id'] ?? item['reference_id'] ?? '').toString().toLowerCase();
        final formattedRequestId = _formatId(item['_doc_id'] ?? item['id'], 'REQ').toString().toLowerCase();
        final formattedMaintenanceId = _formatId(item['maintenance_task_id'] ?? item['reference_id'], 'MT').toString().toLowerCase();
        final itemName = (item['item_name'] ?? '').toString().toLowerCase();
        final quantity = (item['quantity_requested'] ?? '').toString().toLowerCase();

        return rawRequestId.contains(searchLower) ||
               formattedRequestId.contains(searchLower) ||
               rawMaintenanceId.contains(searchLower) ||
               formattedMaintenanceId.contains(searchLower) ||
               itemName.contains(searchLower) ||
               quantity.contains(searchLower);
      }).toList();
    }
    
    // Apply status filter
    if (_selectedFilter != 'All') {
      final filterStatus = _selectedFilter.toLowerCase();
      filtered = filtered.where((item) {
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
          DateTime dateA = DateTime.tryParse(a['requested_date']?.toString() ?? '') ?? DateTime(1970);
          DateTime dateB = DateTime.tryParse(b['requested_date']?.toString() ?? '') ?? DateTime(1970);
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
              color: i == _currentPage ? const Color(0xFF1976D2) : Colors.grey[100],
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

  // Filter functionality
  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _currentPage = 1; // Reset to first page on filter change
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
        final routePath = _getRoutePath(routeKey);
        if (routePath != null) {
          context.go(routePath);
        } else if (routeKey == 'logout') {
          _handleLogout(context);
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
                  // Table header with search and filter
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
                        // Search and Filter section
                        Row(
                          children: [
                            // Search field
                            Container(
                              width: 240,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  suffixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey[500],
                                    size: 20,
                                  ),
                                  hintText: "Search",
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Refresh Button
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: InkWell(
                                onTap: _loadInventoryRequests,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh_rounded, size: 20, color: Colors.blue[600]),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Filter button
                            PopupMenuButton<String>(
                              initialValue: _selectedFilter,
                              onSelected: _onFilterChanged,
                              itemBuilder: (context) => _filterOptions.map((filter) {
                                return PopupMenuItem(
                                  value: filter,
                                  child: Text(filter),
                                );
                              }).toList(),
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tune,
                                      color: Colors.grey[600],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Filter",
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                              // Use _doc_id as the primary ID from Firestore
                              final requestId = _formatId(item['_doc_id'] ?? item['id'], 'REQ');
                              final maintenanceId = _formatId(
                                item['maintenance_task_id'] ?? item['reference_id'],
                                'MT',
                              );
                              
                              // Get item name from cached inventory items
                              String itemName = 'Unknown Item';
                              final inventoryId = item['inventory_id']?.toString();

                              if (inventoryId != null && _inventoryItemNames.containsKey(inventoryId)) {
                                // Found in cached inventory items
                                itemName = _inventoryItemNames[inventoryId]!;
                              } else if (item['item_name'] != null && item['item_name'].toString().isNotEmpty) {
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
                                        future: (status == 'pending' || status == 'reserved') 
                                            ? _hasInsufficientStock(item)
                                            : Future.value(false),
                                        builder: (context, snapshot) {
                                          final hasWarning = snapshot.data == true;
                                          return Row(
                                            children: [
                                              if (hasWarning)
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 4),
                                                  child: Tooltip(
                                                    message: 'Insufficient stock available',
                                                    child: Icon(
                                                      Icons.warning_amber_rounded,
                                                      color: Colors.orange,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              Flexible(child: _ellipsis(quantity)),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  DataCell(_fixedCell(4, _ellipsis(date))),
                                  DataCell(
                                    _fixedCell(5, StatusTag(status: status)),
                                  ),
                                  DataCell(
                                    _fixedCell(
                                      6,
                                      Builder(
                                        builder: (context) {
                                          return IconButton(
                                            onPressed: () {
                                              final rbx =
                                                  context.findRenderObject()
                                                      as RenderBox;
                                              final position = rbx
                                                  .localToGlobal(Offset.zero);
                                              _showActionMenu(
                                                context,
                                                item,
                                                position,
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
                              onPressed: _currentPage > 1 ? _previousPage : null,
                              icon: Icon(
                                Icons.chevron_left,
                                color: _currentPage > 1 ? Colors.grey[600] : Colors.grey[400],
                              ),
                            ),
                            ..._buildPageNumbers(),
                            IconButton(
                              onPressed: _currentPage < _totalPages ? _nextPage : null,
                              icon: Icon(
                                Icons.chevron_right,
                                color: _currentPage < _totalPages ? Colors.grey[600] : Colors.grey[400],
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
  