import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import 'pop_up/webusers_viewdetails_popup.dart';
import '../services/api_service.dart';
import '../widgets/tags.dart';

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
  bool _selectAll = false;

  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _allUsers = [];
  
  // Pagination - Max 10 items per page
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // ---- Filtered Users List ----
  List<Map<String, dynamic>> get _filteredUsers {
    return _allUsers.where((user) {
      // Search filter - search by name, email, and user ID
      bool matchesSearch =
          _searchController.text.isEmpty ||
          user['name'].toString().toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          user['email'].toString().toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          user['id'].toString().toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );

      // Role filter
      bool matchesRole =
          _selectedRoleFilter == 'All Roles' ||
          user['role'] == _selectedRoleFilter;

      // Status filter
      bool matchesStatus =
          _selectedStatusFilter == 'All Status' ||
          user['status'] == _selectedStatusFilter;

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('[AdminUserPage] Fetching users from backend...');
      final users = await _apiService.getUsers();

      print('[AdminUserPage] Received ${users.length} users from backend');

      // Map backend response to frontend format
      final mappedUsers = users.map((user) {
        try {
          // Determine status display text
          String statusDisplay = _mapStatus(user['status'] ?? 'active');

          // Build full name
          String fullName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
          if (fullName.isEmpty) {
            fullName = user['email'] ?? user['user_id'] ?? 'Unknown User';
          }

          // Determine role display text
          String roleDisplay = _capitalizeRole(user['role'] ?? 'tenant');

          // Get department with better fallback handling
          String department = user['department'] ?? 
                             user['staff_department'] ?? 
                             user['building_unit'] ?? '';
          
          // If no department but has departments list, use first one
          if (department.isEmpty) {
            final departments = user['departments'] ?? user['staff_departments'];
            if (departments is List && departments.isNotEmpty) {
              department = departments[0].toString();
            }
          }

          return {
            'id': user['user_id'] ?? user['id'] ?? 'unknown-${DateTime.now().millisecondsSinceEpoch}',
            'name': fullName,
            'role': roleDisplay,
            'department': department,
            'status': statusDisplay,
            'email': user['email'] ?? '',
            'lastActive': _formatLastActive(user['updated_at']),
            // Store original data for detail view
            '_raw': user,
          };
        } catch (e) {
          print('[AdminUserPage] Error mapping user ${user['id'] ?? 'unknown'}: $e');
          // Return a minimal user object to prevent crashes
          return {
            'id': user['user_id'] ?? user['id'] ?? 'error-${DateTime.now().millisecondsSinceEpoch}',
            'name': user['email'] ?? 'Error Loading User',
            'role': 'Tenant',
            'department': '',
            'status': 'Offline',
            'email': user['email'] ?? '',
            'lastActive': 'Unknown',
            '_raw': user,
          };
        }
      }).toList();

      setState(() {
        _allUsers = mappedUsers;
        _selectedRows = List.generate(_allUsers.length, (index) => false);
        _isLoading = false;
      });

      print('[AdminUserPage] Successfully loaded ${_allUsers.length} users');
      
      // Show success feedback for user
      if (mounted && _allUsers.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${_allUsers.length} users successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('[AdminUserPage] Error fetching users: $e');
      setState(() {
        _errorMessage = _getDetailedErrorMessage(e);
        _isLoading = false;
      });
      
      // Show error feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: ${_getSimpleErrorMessage(e)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchUsers,
            ),
          ),
        );
      }
    }
  }

  String _getDetailedErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'Network connection error. Please check your internet connection and try again.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. The server may be busy. Please try again.';
    } else if (error.toString().contains('401')) {
      return 'Authentication failed. Please log in again.';
    } else if (error.toString().contains('403')) {
      return 'Access denied. You may not have permission to view users.';
    } else if (error.toString().contains('404')) {
      return 'Users endpoint not found. The server may be misconfigured.';
    } else if (error.toString().contains('500')) {
      return 'Server error. Please try again later or contact support.';
    } else {
      return 'Failed to load users: ${error.toString()}';
    }
  }

  String _getSimpleErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'Network error';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timed out';
    } else if (error.toString().contains('401')) {
      return 'Authentication failed';
    } else if (error.toString().contains('403')) {
      return 'Access denied';
    } else {
      return 'Server error';
    }
  }

  String _mapStatus(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'active':
        return 'Online';
      case 'inactive':
        return 'Offline';
      case 'suspended':
        return 'Pending';
      default:
        return 'Offline';
    }
  }

  String _capitalizeRole(String role) {
    if (role.isEmpty) return 'Tenant';
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

  String _formatLastActive(dynamic updatedAt) {
    if (updatedAt == null) return 'Never';

    try {
      DateTime date;
      if (updatedAt is String) {
        date = DateTime.parse(updatedAt);
      } else if (updatedAt is DateTime) {
        date = updatedAt;
      } else {
        return 'Unknown';
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return 'Unknown';
    }
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
  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
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
          items:
              options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    '$label: $option',
                    style: const TextStyle(fontSize: 14),
                  ),
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
    final style =
        roleStyles[role] ??
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
    final style =
        statusStyles[status] ??
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
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> user,
    Offset position,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

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
              Icon(
                Icons.visibility_outlined,
                color: Colors.green[600],
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                "View",
                style: TextStyle(color: Colors.green[600], fontSize: 14),
              ),
            ],
          ),
        ),

        if (isPending) ...[
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
                  "Approve",
                  style: TextStyle(color: Colors.blue[600], fontSize: 14),
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
                  color: Colors.orange[600],
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  "Reject",
                  style: TextStyle(color: Colors.orange[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ] else ...[
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, color: Colors.blue[600], size: 18),
                const SizedBox(width: 12),
                Text(
                  "Edit",
                  style: TextStyle(color: Colors.blue[600], fontSize: 14),
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
                "Delete",
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
        _handleActionSelection(value, user);
      }
    });
  }

  void _handleActionSelection(String action, Map<String, dynamic> user) {
    switch (action) {
      case 'view':
        _viewUser(user);
        break;

      case 'approve':
        _updateUserStatus(user, 'active', 'Online');
        break;

      case 'reject':
        _updateUserStatus(user, 'suspended', 'Rejected');
        break;

      case 'edit':
        _editUser(user);
        break;

      case 'delete':
        _deleteUser(user);
        break;
    }
  }

  Future<void> _viewUser(Map<String, dynamic> user) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return UserProfileDialog(user: user);
      },
    );
    
    // If user was updated or deleted, refresh the list
    if (result != null) {
      if (result['deleted'] == true) {
        // Show deletion confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _fetchUsers();
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return UserProfileDialog(user: user);
      },
    );
    
    // If user was updated or deleted, refresh the list
    if (result != null) {
      if (result['deleted'] == true) {
        // Show deletion confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _fetchUsers();
    }
  }

  Future<void> _updateUserStatus(
    Map<String, dynamic> user,
    String backendStatus,
    String displayStatus,
  ) async {
    final userId = user['id'];
    final originalStatus = user['status'];
    
    try {
      print('[AdminUserPage] Updating user $userId status to $backendStatus');

      // Optimistically update the UI
      setState(() {
        user['status'] = displayStatus;
      });

      // Show loading feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text("Updating ${user['name']} status..."),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      await _apiService.updateUserStatus(userId, backendStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("${user['name']} status updated to $displayStatus"),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('[AdminUserPage] Error updating user status: $e');
      
      // Revert the optimistic update
      if (mounted) {
        setState(() {
          user['status'] = originalStatus; // Revert to original status
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("Failed to update user status: ${_getSimpleErrorMessage(e)}"),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _updateUserStatus(user, backendStatus, displayStatus),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete the following user?',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'] ?? 'No email',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Role: ${user['role'] ?? 'Unknown'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete User'),
            ),
          ],
        );
      },
    );

    // If user didn't confirm, exit early
    if (confirmed != true) return;

    try {
      final userId = user['id'];
      print('[AdminUserPage] Deleting user $userId');

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _apiService.deleteUser(userId, permanent: false);

      // Close loading indicator
      Navigator.of(context).pop();

      // Refresh the user list
      await _fetchUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Successfully deleted user: ${user['name']}"),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Implement undo functionality if needed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Undo functionality not yet implemented'),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      print('[AdminUserPage] Error deleting user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete user: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _deleteUser(user),
            ),
          ),
        );
      }
    }
  }

  // Column widths for fixed table layout
  final List<double> _colW = <double>[
    50,  // CHECKBOX
    100, // USER ID
    250, // USER NAME
    120, // ROLE
    150, // DEPARTMENT/UNIT
    80,  // ACTION
  ];

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

  Text _ellipsis(String s, {TextStyle? style}) => Text(
    s,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    softWrap: false,
    style: style,
  );

  // Pagination helper methods
  List<Map<String, dynamic>> _getPaginatedUsers() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    
    final filteredUsers = _filteredUsers;
    if (startIndex >= filteredUsers.length) return [];
    
    return filteredUsers.sublist(
      startIndex,
      endIndex > filteredUsers.length ? filteredUsers.length : endIndex,
    );
  }

  int get _totalPages {
    final filteredUsers = _filteredUsers;
    return filteredUsers.isEmpty ? 1 : (filteredUsers.length / _itemsPerPage).ceil();
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  // Get list of selected users
  List<Map<String, dynamic>> _getSelectedUsers() {
    List<Map<String, dynamic>> selectedUsers = [];
    final paginatedUsers = _getPaginatedUsers();
    for (int i = 0; i < paginatedUsers.length; i++) {
      final globalIndex = _filteredUsers.indexOf(paginatedUsers[i]);
      if (globalIndex != -1 && globalIndex < _selectedRows.length && _selectedRows[globalIndex]) {
        selectedUsers.add(paginatedUsers[i]);
      }
    }
    return selectedUsers;
  }

  // Toggle select all (only for current page)
  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      final paginatedUsers = _getPaginatedUsers();
      for (var user in paginatedUsers) {
        final index = _filteredUsers.indexOf(user);
        if (index != -1 && index < _selectedRows.length) {
          _selectedRows[index] = _selectAll;
        }
      }
    });
  }

  // Bulk delete selected users
  Future<void> _bulkDeleteUsers() async {
    final selectedUsers = _getSelectedUsers();
    
    if (selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No users selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Users'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete ${selectedUsers.length} user(s)?'),
            const SizedBox(height: 12),
            Text(
              'Users to be deleted:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: selectedUsers.map((user) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${user['name']} (${user['email']})',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Deleting users...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Delete users one by one
    int successCount = 0;
    int failureCount = 0;
    List<String> failedUsers = [];

    for (var user in selectedUsers) {
      try {
        await _apiService.deleteUser(user['id'], permanent: true);
        successCount++;
      } catch (e) {
        failureCount++;
        failedUsers.add(user['name']);
      }
    }

    // Close loading dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    // Refresh the user list
    await _fetchUsers();

    // Reset selections
    setState(() {
      _selectAll = false;
      _selectedRows = List.generate(_allUsers.length, (index) => false);
    });

    // Show result
    if (mounted) {
      if (failureCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deleted $successCount user(s)'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deleted $successCount user(s), $failureCount failed'),
                if (failedUsers.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Failed: ${failedUsers.join(", ")}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
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
                        hintText: "Search by name, email, or user ID",
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6.5,
                        ),
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

                // Refresh Button
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    onTap: _fetchUsers,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, size: 20, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Refresh',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Delete Selected Button (only show if users are selected)
                if (_getSelectedUsers().isNotEmpty)
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      onTap: _bulkDeleteUsers,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Delete Selected (${_getSelectedUsers().length})',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // ---- Users Table ----
            Container(
              height: 650,
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
                  // Table Header
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Users",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[400]),

                  // Data Table
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                        color: Colors.red[600],
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _fetchUsers,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : _filteredUsers.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No Users Found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'There are currently no users to display.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        columnSpacing: 70,
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
                                            label: _fixedCell(
                                              0,
                                              Checkbox(
                                                value: _selectAll,
                                                onChanged: _toggleSelectAll,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: _fixedCell(1, const Text("USER ID")),
                                          ),
                                          DataColumn(
                                            label: _fixedCell(2, const Text("USER NAME")),
                                          ),
                                          DataColumn(
                                            label: _fixedCell(3, const Text("ROLE")),
                                          ),
                                          DataColumn(
                                            label: _fixedCell(4, const Text("DEPARTMENT/UNIT")),
                                          ),
                                          DataColumn(
                                            label: _fixedCell(5, const Text("")),
                                          ),
                                        ],
                                        rows: _getPaginatedUsers().map((user) {
                                          final index = _filteredUsers.indexOf(user);
                                          return DataRow(
                                            cells: [
                                              // Checkbox
                                              DataCell(
                                                _fixedCell(
                                                  0,
                                                  Checkbox(
                                                    value: index < _selectedRows.length
                                                        ? _selectedRows[index]
                                                        : false,
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        if (index < _selectedRows.length) {
                                                          _selectedRows[index] = value ?? false;
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ),
                                              // User ID
                                              DataCell(
                                                _fixedCell(
                                                  1,
                                                  _ellipsis(
                                                    user['id'],
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[700],
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // User Name
                                              DataCell(
                                                _fixedCell(
                                                  2,
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      _ellipsis(
                                                        user['name'],
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      _ellipsis(
                                                        user['email'],
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Role
                                              DataCell(
                                                _fixedCell(
                                                  3,
                                                  _buildRoleBadge(user['role']),
                                                ),
                                              ),
                                              // Department
                                              DataCell(
                                                _fixedCell(
                                                  4,
                                                  user['department'].isEmpty
                                                      ? const Text('-')
                                                      : DepartmentTag(user['department']),
                                                ),
                                              ),
                                              // Action
                                              DataCell(
                                                _fixedCell(
                                                  5,
                                                  Builder(
                                                    builder: (context) {
                                                      return IconButton(
                                                        onPressed: () {
                                                          final rbx = context.findRenderObject() as RenderBox;
                                                          final position = rbx.localToGlobal(Offset.zero);
                                                          _showActionMenu(context, user, position);
                                                        },
                                                        icon: Icon(
                                                          Icons.more_vert,
                                                          color: Colors.grey[400],
                                                          size: 20,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  align: Alignment.centerLeft,
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[400]),

                  // Pagination Section
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _filteredUsers.isEmpty
                              ? "No entries found"
                              : "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage) > _filteredUsers.length ? _filteredUsers.length : _currentPage * _itemsPerPage} of ${_filteredUsers.length} entries",
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
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