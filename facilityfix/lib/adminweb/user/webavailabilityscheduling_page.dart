import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import 'userwidgets/stat_card_widget.dart';
import 'userwidgets/dayoffrequest_view.dart';

class StaffSchedulingPage extends StatefulWidget {
  const StaffSchedulingPage({super.key});

  @override
  State<StaffSchedulingPage> createState() => _StaffSchedulingPageState();
}

class _StaffSchedulingPageState extends State<StaffSchedulingPage> {
  // ---- Controllers and State Variables ----
  String _selectedView = 'Staff List'; // Toggle between Staff List and Day Off Request
  String _selectedDepartment = 'All Departments';
  String _selectedWeek = 'Current Week';
  String _searchQuery = '';

  // ---- Pagination ----
  int _currentPage = 1;
  final int _itemsPerPage = 7;

  // ---- Sample Data  ----
  // TODO: Replace with actual API calls
  final Map<String, dynamic> _statsData = {
    'totalStaff': 24,
    'availableThisWeek': 18,
    'unavailable': 6,
    'pendingSubmissions': 3,
  };

  // Sample staff members with enhanced data for Staff List view
  List<Map<String, dynamic>> _staffMembers = [
    {
      'id': '1',
      'name': 'Noel Cruz',
      'department': 'HVAC',
      'role': 'Admin',
      'thisWeek': '5/7 days',
      'status': 'Available',
      'nextWeek': 'Submitted',
      'lastUpdated': '2 hours ago',
    },
    {
      'id': '2',
      'name': 'Juan Dela Cruz',
      'department': 'Maintenance',
      'role': 'Staff',
      'thisWeek': '4/7 days',
      'status': 'Available',
      'nextWeek': 'Submitted',
      'lastUpdated': '5 hours ago',
    },
    {
      'id': '3',
      'name': 'Maria Santos',
      'department': 'HVAC',
      'role': 'Staff',
      'thisWeek': '6/7 days',
      'status': 'Available',
      'nextWeek': 'Pending',
      'lastUpdated': '1 day ago',
    },
    {
      'id': '4',
      'name': 'Erika De Guzman',
      'department': 'HVAC',
      'role': 'Staff',
      'thisWeek': '0/7 days',
      'status': 'Unavailable',
      'nextWeek': 'Pending',
      'lastUpdated': '1 day ago',
    },
    {
      'id': '5',
      'name': 'Pedro Reyes',
      'department': 'Maintenance',
      'role': 'Staff',
      'thisWeek': '5/7 days',
      'status': 'Available',
      'nextWeek': 'Submitted',
      'lastUpdated': '3 hours ago',
    },
    {
      'id': '6',
      'name': 'Ana Garcia',
      'department': 'Electrical',
      'role': 'Staff',
      'thisWeek': '5/7 days',
      'status': 'Available',
      'nextWeek': 'Submitted',
      'lastUpdated': '4 hours ago',
    },
    {
      'id': '7',
      'name': 'Carlos Mendoza',
      'department': 'Plumbing',
      'role': 'Staff',
      'thisWeek': '5/7 days',
      'status': 'Available',
      'nextWeek': 'Submitted',
      'lastUpdated': '6 hours ago',
    },
  ];

  // ---- Department List ----
  final List<String> _departments = [
    'All Departments',
    'HVAC',
    'Maintenance',
    'Electrical',
    'Plumbing',
    'Carpentry',
    'Masonry',
  ];

  // ---- Week Filter Options ----
  final List<String> _weekOptions = [
    'Current Week',
    'Next Week',
    'Last Week',
  ];

  // ---- Filtered Staff List ----
  List<Map<String, dynamic>> get _filteredStaff {
    var filtered = _staffMembers;

    // Filter by department
    if (_selectedDepartment != 'All Departments') {
      filtered = filtered
          .where((staff) => staff['department'] == _selectedDepartment)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((staff) =>
              staff['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
              staff['department'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
              staff['role'].toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    // TODO: Fetch staff data from backend
    // _fetchStaffSchedule();
  }

  // ---- Navigation Helper ----
  static String? _getRoutePath(String routeKey) {
      final Map<String, String> pathMap = {
        'dashboard': '/dashboard',
        'user_users': '/user/users',
        // 'user_roles': '/user/roles',
        'user_scheduling': '/user/scheduling',
        'work_maintenance': '/work/maintenance',
        'work_repair': '/work/repair',
        'calendar': '/calendar',
        'inventory_equipment': '/inventory/equipment',
        'inventory_items': '/inventory/items',
        'inventory_request': '/inventory/request',
        'analytics': '/analytics',
        'announcement': '/announcement',
        'settings': '/settings',
        'logout': '/logout',
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

  // ---- Handle Staff Row Click ----
  void _handleStaffClick(Map<String, dynamic> staff) {
    // TODO: Show staff details or edit dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(staff['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Department: ${staff['department']}'),
            Text('Role: ${staff['role']}'),
            Text('This Week: ${staff['thisWeek']}'),
            Text('Status: ${staff['status']}'),
            Text('Next Week: ${staff['nextWeek']}'),
            Text('Last Updated: ${staff['lastUpdated']}'),
            const SizedBox(height: 16),
            const Text(
              'This feature will be implemented with backend integration.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ---- User Actions Menu ----
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> staff,
    Offset position,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final bool isPending = staff['nextWeek'] == 'Pending';

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
        _handleActionSelection(value, staff);
      }
    });
  }

  void _handleActionSelection(String action, Map<String, dynamic> staff) {
    switch (action) {
      case 'view':
        _handleStaffClick(staff);
        break;

      case 'approve':
        // TODO: Implement approve functionality
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved ${staff['name']}\'s availability'),
            backgroundColor: Colors.green,
          ),
        );
        break;

      case 'reject':
        // TODO: Implement reject functionality
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejected ${staff['name']}\'s availability'),
            backgroundColor: Colors.orange,
          ),
        );
        break;

      case 'edit':
        // TODO: Implement edit functionality
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Edit ${staff['name']}\'s availability'),
            backgroundColor: Colors.blue,
          ),
        );
        break;

      case 'delete':
        // TODO: Implement delete functionality
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted ${staff['name']}'),
            backgroundColor: Colors.red,
          ),
        );
        break;
    }
  }

  // ---- Build Status Badge ----
  Widget _buildStatusBadge(String status) {
    final isAvailable = status == 'Available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green[50] : Colors.red[50],
        border: Border.all(
          color: isAvailable ? Colors.green[300]! : Colors.red[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isAvailable ? Colors.green[700] : Colors.red[700],
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  // ---- Build Next Week Badge ----
  Widget _buildNextWeekBadge(String nextWeek) {
    final isSubmitted = nextWeek == 'Submitted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSubmitted ? Colors.green[50] : Colors.orange[50],
        border: Border.all(
          color: isSubmitted ? Colors.green[300]! : Colors.orange[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        nextWeek,
        style: TextStyle(
          color: isSubmitted ? Colors.green[700] : Colors.orange[700],
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  // ---- Build Role Badge ----
  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: role == 'Admin' ? Colors.blue[50] : Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: role == 'Admin' ? Colors.blue[700] : Colors.grey[700],
        ),
      ),
    );
  }

  // ---- Pagination Helper Methods ----
  List<Map<String, dynamic>> _getPaginatedStaff() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    
    final filteredStaff = _filteredStaff;
    if (startIndex >= filteredStaff.length) return [];
    
    return filteredStaff.sublist(
      startIndex,
      endIndex > filteredStaff.length ? filteredStaff.length : endIndex,
    );
  }

  int get _totalPages {
    final filteredStaff = _filteredStaff;
    return filteredStaff.isEmpty ? 1 : (filteredStaff.length / _itemsPerPage).ceil();
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

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'user_scheduling',
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Page Header ----
              const Text(
                'User Management',
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
                    child: const Text('User Management'),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                  TextButton(
                    onPressed: null,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Staff Availability & Scheduling'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ---- Stat Cards Row ----
              Row(
                children: [
                  Expanded(
                    child: StatCardWidget(
                      title: 'TOTAL STAFF',
                      value: _statsData['totalStaff'].toString(),
                      subtitle: 'Active personnel',
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCardWidget(
                      title: 'AVAILABLE THIS WEEK',
                      value: _statsData['availableThisWeek'].toString(),
                      subtitle: '75% of total staff',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCardWidget(
                      title: 'UNAVAILABLE',
                      value: _statsData['unavailable'].toString(),
                      subtitle: 'Out of office',
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCardWidget(
                      title: 'PENDING REQUESTS',
                      value: _statsData['pendingRequests'].toString(),
                      subtitle: 'Day off requests',
                      icon: Icons.access_time,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ---- View Toggle (Staff List / Day Off Request) ----
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewToggleButton('Staff List', _selectedView == 'Staff List'),
                    _buildViewToggleButton('Day Off Request', _selectedView == 'Day Off Request'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ---- Staff List View Content ----
              if (_selectedView == 'Staff List') ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header with Title and Filters
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Staff Availability Overview',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            // Search Field
                            Container(
                              width: 300,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search staff...',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey[500],
                                    size: 20,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Week Filter Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedWeek,
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                  items: _weekOptions.map((String week) {
                                    return DropdownMenuItem<String>(
                                      value: week,
                                      child: Text(
                                        week,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedWeek = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table Header
                      Container(
                        color: Colors.grey[50],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'STAFF MEMBER',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'ROLE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'DEPARTMENT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'THIS WEEK',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'STATUS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'NEXT WEEK',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'LAST UPDATED',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48), // Space for menu icon
                          ],
                        ),
                      ),

                      // Table Body
                      _filteredStaff.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(48),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No staff members found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _getPaginatedStaff().length,
                              itemBuilder: (context, index) {
                                final staff = _getPaginatedStaff()[index];
                                return InkWell(
                                  onTap: () => _handleStaffClick(staff),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Staff Name
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            staff['name'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        // Role
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: _buildRoleBadge(staff['role']),
                                          ),
                                        ),
                                        // Department
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            staff['department'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        // This Week
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            staff['thisWeek'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        // Status
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: _buildStatusBadge(staff['status']),
                                          ),
                                        ),
                                        // Next Week
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: _buildNextWeekBadge(staff['nextWeek']),
                                          ),
                                        ),
                                        // Last Updated
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            staff['lastUpdated'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                        // Menu Icon
                                        Builder(
                                          builder: (BuildContext buttonContext) {
                                            return IconButton(
                                              icon: const Icon(Icons.more_vert),
                                              iconSize: 20,
                                              color: Colors.grey[600],
                                              onPressed: () {
                                                final RenderBox button =
                                                    buttonContext.findRenderObject() as RenderBox;
                                                final position =
                                                    button.localToGlobal(Offset.zero);
                                                _showActionMenu(context, staff, position);
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                      // Footer with Pagination
                      Divider(height: 1, thickness: 1, color: Colors.grey[400]),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _filteredStaff.isEmpty
                                  ? "No staff members found"
                                  : "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage) > _filteredStaff.length ? _filteredStaff.length : _currentPage * _itemsPerPage} of ${_filteredStaff.length} staff members",
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

              // ---- Day Off Request View (Placeholder) ----
              if (_selectedView == 'Day Off Request')
                const DayOffRequestView(),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Build View Toggle Button ----
  Widget _buildViewToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}