import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../popupwidgets/webusers_viewdetails_popup.dart';

class AdminUserPage extends StatefulWidget {
  const AdminUserPage({super.key});

  @override
  State<AdminUserPage> createState() => _AdminUserPageState();
}

class _AdminUserPageState extends State<AdminUserPage> {
  // ---- Controllers and State Variables ----
  final TextEditingController _searchController = TextEditingController();
  String _selectedRoleFilter = 'All Roles';
  String _selectedStatusFilter = 'All Status';
  List<bool> _selectedRows = [];

  // ---- Sample User Data ----
  final List<Map<String, dynamic>> _allUsers = [
    {
      'id': 1,
      'name': 'Noel Cruz',
      'role': 'Admin',
      'department': 'HVAC',
      'status': 'Online',
      'email': 'noel.cruz@facility.com',
      'lastActive': '2 min ago'
    },
    {
      'id': 2,
      'name': 'Juan Dela Cruz',
      'role': 'Staff',
      'department': 'Maintenance',
      'status': 'Offline',
      'email': 'juan.delacruz@facility.com',
      'lastActive': '5 min ago'
    },
    {
      'id': 3,
      'name': 'Erika De Guzman',
      'role': 'Tenant',
      'department': '',
      'status': 'Pending',
      'email': 'erika.deguzman@tenant.com',
      'lastActive': '2 hours ago'
    },
  ];

  // ---- Filtered Users List ----
  List<Map<String, dynamic>> get _filteredUsers {
    return _allUsers.where((user) {
      // Search filter
      bool matchesSearch = _searchController.text.isEmpty ||
          user['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
          user['email'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      
      // Role filter
      bool matchesRole = _selectedRoleFilter == 'All Roles' || user['role'] == _selectedRoleFilter;
      
      // Status filter
      bool matchesStatus = _selectedStatusFilter == 'All Status' || user['status'] == _selectedStatusFilter;
      
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Initialize selection state
    _selectedRows = List.generate(_allUsers.length, (index) => false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---- Navigation Helper ----
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

  // ---- Logout Dialog ----
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

  // ---- Filter Dropdown Builder ----
  Widget _buildFilterDropdown(String label, String value, List<String> options, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text('$label: $option', style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }

  // ---- Role Styles ----
final Map<String, Map<String, Color>> roleStyles = {
  'Admin': {
    'bg': Color(0xFFDDEAFE), // light blue
    'text': Color(0xFF1D4ED8), // dark blue
  },
  'Staff': {
    'bg': Color(0xFFE5E7EB), // light gray
    'text': Color(0xFF374151), // dark gray
  },
  'Tenant': {
    'bg': Color(0xFFFEF9C3), // light yellow
    'text': Color(0xFFB45309), // orange
  },
};

  // ---- Status Styles ----
  final Map<String, Map<String, Color>> statusStyles = {
    'Online': {
      'bg': Color(0xFFD1FAE5), // light green
      'text': Color(0xFF047857), // dark green
    },
    'Offline': {
      'bg': Color(0xFFFEE2E2), // light red
      'text': Color(0xFFB91C1C), // dark red
    },
    'Pending': {
      'bg': Color(0xFFFFEDD5), // light orange
      'text': Color(0xFF9A3412), // dark orange
    },
    'Rejected': {
      'bg': Color(0xFFE5E7EB), // light gray
      'text': Color(0xFF374151), // dark gray
    },
  };

  // ---- Role Badge Widget ----
  Widget _buildRoleBadge(String role) {
    final style = roleStyles[role] ??
        {'bg': Colors.grey.shade200, 'text': Colors.grey.shade700};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style['bg'],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: style['text'],
        ),
      ),
    );
  }

  // ---- Status Badge Widget ----
  Widget _buildStatusBadge(String status) {
    final style = statusStyles[status] ??
        {'bg': Colors.grey.shade200, 'text': Colors.grey.shade700};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style['bg'],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: style['text'],
        ),
      ),
    );
  }

  // ---- User Actions Menu ----
  void _showActionMenu(BuildContext context, Map<String, dynamic> user, Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final bool isPending = user['status'] == 'Pending';

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
              Icon(Icons.visibility_outlined, color: Colors.green[600], size: 18),
              const SizedBox(width: 12),
              Text("View", style: TextStyle(color: Colors.green[600], fontSize: 14)),
            ],
          ),
        ),

        if (isPending) ...[
          PopupMenuItem(
            value: 'approve',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.blue[600], size: 18),
                const SizedBox(width: 12),
                Text("Approve", style: TextStyle(color: Colors.blue[600], fontSize: 14)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'reject',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.orange[600], size: 18),
                const SizedBox(width: 12),
                Text("Reject", style: TextStyle(color: Colors.orange[600], fontSize: 14)),
              ],
            ),
          ),
        ]
        else ...[
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, color: Colors.blue[600], size: 18),
                const SizedBox(width: 12),
                Text("Edit", style: TextStyle(color: Colors.blue[600], fontSize: 14)),
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
              Text("Delete", style: TextStyle(color: Colors.red[600], fontSize: 14)),
            ],
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
    ).then((value) {
      if (value != null) {
        _handleActionSelection(value, user);
      }
    });
  }

  void _handleActionSelection(String action, Map<String, dynamic> user) {
    switch (action) {
      case 'view':
        UserProfileDialog.show(context, user);
        break;

      case 'approve':
        setState(() {
          user['status'] = 'Active';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${user['name']} approved")),
        );
        break;

      case 'reject':
        setState(() {
          user['status'] = 'Rejected'; 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${user['name']} rejected")),
        );
        break;

      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Editing user: ${user['name']}")),
        );
        break;

      case 'delete':
        setState(() {
          //_users.remove(user);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Deleted user: ${user['name']}")),
        );
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;

    return FacilityFixLayout(
      currentRoute: 'user_users',
      onNavigate: (routeKey) {
        final routePath = _getRoutePath(routeKey);
        if (routePath != null) {
          context.go(routePath);
        } else if (routeKey == 'logout') {
          _handleLogout(context);
        }
      },
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Page Header ----
            const Text(
              'User and Role Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // ---- Breadcrumb Navigation ----
            Row(
              children: [
                TextButton(
                  onPressed: () => context.go('/dashboard'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Dashboard'),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                TextButton(
                  onPressed: () => context.go('/user/users'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('User and Role Management'),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                TextButton(
                  onPressed: null,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Users'),
                ),
                
              ],
            ),
            const SizedBox(height: 32),

            // ---- Search and Filter Controls ----
            Row(
              children: [
                // Search Bar
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Role Filter
                _buildFilterDropdown(
                  'Role',
                  _selectedRoleFilter,
                  ['All Roles', 'Admin', 'Staff', 'Tenant'],
                  (value) => setState(() => _selectedRoleFilter = value),
                ),
                const SizedBox(width: 16),

                // Status Filter
                _buildFilterDropdown(
                  'Status',
                  _selectedStatusFilter,
                  ['All Status', 'Online', 'Offline', 'Pending'],
                  (value) => setState(() => _selectedStatusFilter = value),
                ),
                const SizedBox(width: 16),

                // Filter Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Filter',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Export Button
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement export functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export feature coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),

                
              ],
            ),
            const SizedBox(height: 32),

            // ---- Users Table ----
            Flexible(
              fit: FlexFit.loose,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 40), // Checkbox space
                          Expanded(flex: 3, child: Text('USER', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                          Expanded(flex: 2, child: Text('ROLE', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                          Expanded(flex: 2, child: Text('DEPARTMENT', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                          Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                          SizedBox(width: 48), // Actions space
                        ],
                      ),
                    ),

                    // Table Body
                    Flexible(
                      fit: FlexFit.loose,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade100),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Checkbox
                                Checkbox(
                                  value: index < _selectedRows.length ? _selectedRows[index] : false,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (index < _selectedRows.length) {
                                        _selectedRows[index] = value ?? false;
                                      }
                                    });
                                  },
                                ),
                                
                                // User Info
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user['email'],
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Role Badge
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _buildRoleBadge(user['role']),
                                  ),
                                ),

                                // Department
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    user['department'].isEmpty ? '-' : user['department'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),

                                // Status Badge
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _buildStatusBadge(user['status']),
                                  ),
                                ),

                                // Actions Button
                                Builder(
                                  builder: (context) {
                                    return IconButton(
                                      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                      onPressed: () {
                                        final rbx = context.findRenderObject() as RenderBox;
                                        final position = rbx.localToGlobal(Offset.zero);
                                        _showActionMenu(context, user, position);
                                      },
                                    );
                                  },
                                ),

                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Pagination ----
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing 1 to ${filteredUsers.length} of ${filteredUsers.length} entries',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        // TODO: Implement previous page
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '01',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        // TODO: Go to page 2
                      },
                      child: const Text('02'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        // TODO: Implement next page
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}