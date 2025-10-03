import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';

class InventoryRequestPage extends StatefulWidget {
  const InventoryRequestPage({super.key});

  @override
  State<InventoryRequestPage> createState() => _InventoryRequestPageState();
}

class _InventoryRequestPageState extends State<InventoryRequestPage> {
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

  // Sample inventory request data - modified for request structure
  final List<Map<String, dynamic>> _requestItems = [
    {
      'requestId': 'EQ-001',
      'itemName': 'LED Tube Light',
      'itemType': 'Electrical Supply',
      'quantity': '10',
      'date': '07-21-2026',
      'status': 'Pending',
    },
    {
      'requestId': 'REQ-002',
      'itemName': 'PVC Pipe 4 inch',
      'itemType': 'Plumbing Supply',
      'quantity': '5',
      'date': '07-20-2026',
      'status': 'Approved',
    },
    {
      'requestId': 'REQ-003',
      'itemName': 'Safety Helmet',
      'itemType': 'Safety Equipment',
      'quantity': '3',
      'date': '07-19-2026',
      'status': 'Rejected',
    },
    {
      'requestId': 'REQ-004',
      'itemName': 'Galvanized Screw 5mm',
      'itemType': 'Hardware',
      'quantity': '50',
      'date': '07-18-2026',
      'status': 'Completed',
    },
  ];

  // Column widths for table 
  final List<double> _colW = <double>[
    150, // REQUEST ID
    200, // ITEM NAME
    180, // ITEM TYPE
    100, // QUANTITY
    120, // DATE
    120, // STATUS
    48,  // ACTION
  ];

  // Fixed width cell helper
  Widget _fixedCell(int i, Widget child, {Alignment align = Alignment.centerLeft}) {
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
  void _showActionMenu(BuildContext context, Map<String, dynamic> item, Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
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
                style: TextStyle(
                  color: Colors.green[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        // Show approve/reject options only for pending requests
        if (item['status'] == 'Pending') ...[
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
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'reject',
            child: Row(
              children: [
                Icon(
                  Icons.cancel_outlined,
                  color: Colors.red[600],
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Reject',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.red[600],
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
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
  void _viewRequest(Map<String, dynamic> item) {
    context.go('/inventory/request/${item['requestId']}');
  }

  // Approve request method
  void _approveRequest(Map<String, dynamic> item) {
    setState(() {
      final index = _requestItems.indexWhere((req) => req['requestId'] == item['requestId']);
      if (index != -1) {
        _requestItems[index]['status'] = 'Approved';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request ${item['requestId']} approved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Reject request method
  void _rejectRequest(Map<String, dynamic> item) {
    setState(() {
      final index = _requestItems.indexWhere((req) => req['requestId'] == item['requestId']);
      if (index != -1) {
        _requestItems[index]['status'] = 'Rejected';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request ${item['requestId']} rejected'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Delete request method
  void _deleteRequest(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Request'),
          content: Text('Are you sure you want to delete request ${item['requestId']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Remove request from list
                setState(() {
                  _requestItems.removeWhere((req) => req['requestId'] == item['requestId']);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request ${item['requestId']} deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
                        const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                        TextButton(
                          onPressed: () => context.go('/inventory/items'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Inventory Management'),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
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
                            // Filter button
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey[400],
                  ),

                  // Data Table 
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 30,
                      headingRowHeight: 56,
                      dataRowHeight: 64,
                      headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
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
                        DataColumn(label: _fixedCell(0, const Text("REQUEST ID"))),
                        DataColumn(label: _fixedCell(1, const Text("ITEM NAME"))),
                        DataColumn(label: _fixedCell(2, const Text("ITEM TYPE"))),
                        DataColumn(label: _fixedCell(3, const Text("QUANTITY"))),
                        DataColumn(label: _fixedCell(4, const Text("DATE"))),
                        DataColumn(label: _fixedCell(5, const Text("STATUS"))),
                        DataColumn(label: _fixedCell(6, const Text(""))),
                      ],
                      rows: _requestItems.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(_fixedCell(0, _ellipsis(
                              item['requestId'],
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            ))),
                            DataCell(_fixedCell(1, _ellipsis(item['itemName']))),
                            DataCell(_fixedCell(2, _ellipsis(
                              item['itemType'],
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ))),
                            DataCell(_fixedCell(3, _ellipsis(item['quantity']))),
                            DataCell(_fixedCell(4, _ellipsis(item['date']))),
                            DataCell(_fixedCell(5, _buildStatusChip(item['status']))),
                            DataCell(_fixedCell(6,
                            Builder(builder: (context) {
                              return IconButton(
                                onPressed: () {
                                  final rbx = context.findRenderObject() as RenderBox;
                                  final position = rbx.localToGlobal(Offset.zero);
                                  _showActionMenu(context, item, position);
                                },
                                icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                              );
                            }),
                          align: Alignment.center,
                        )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey[400],
                  ),

                  // Pagination section 
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Showing 1 to 2 of 2 entries",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: null,
                              icon: Icon(
                                Icons.chevron_left,
                                color: Colors.grey[400],
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Text(
                                  "01",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  "02",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.chevron_right,
                                color: Colors.grey[600],
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

  // Status chip widget 
  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    
    switch (status) {
      case 'Pending':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        break;
      case 'Approved':
        bgColor = const Color(0xFFE8F5E8);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'Rejected':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        break;
      case 'Completed':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}