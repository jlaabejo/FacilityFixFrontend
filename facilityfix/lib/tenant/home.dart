import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/widgets/modals.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/tenant/announcement.dart';
import 'package:facilityfix/tenant/notification.dart';
import 'package:facilityfix/tenant/profile.dart';
import 'package:facilityfix/tenant/workorder.dart';
import 'package:facilityfix/widgets/cards.dart';
import 'package:facilityfix/widgets/helper_models.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/tenant/view_details.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  // runtime user fields (defaults)
  String _userName = 'User';
  String _unitLabel = '—';

  List<Map<String, dynamic>> _allRequests = [];
  int _activeRequestsCount = 0;
  int _doneRequestsCount = 0;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.person),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAllRequests();
  }

  Future<void> _loadAllRequests() async {
    try {
      final apiService = APIService();
      final allRequests = await apiService.getAllTenantRequests();

      if (allRequests.isNotEmpty && mounted) {
        setState(() {
          _allRequests = allRequests;

          _activeRequestsCount =
              allRequests
                  .where(
                    (data) =>
                        (data['status'] ?? '').toString().toLowerCase() !=
                            'done' &&
                        (data['status'] ?? '').toString().toLowerCase() !=
                            'completed' &&
                        (data['status'] ?? '').toString().toLowerCase() !=
                            'closed',
                  )
                  .length;

          _doneRequestsCount =
              allRequests
                  .where(
                    (data) =>
                        (data['status'] ?? '').toString().toLowerCase() ==
                            'done' ||
                        (data['status'] ?? '').toString().toLowerCase() ==
                            'completed' ||
                        (data['status'] ?? '').toString().toLowerCase() ==
                            'closed',
                  )
                  .length;
        });
      }
    } catch (e) {
      print('Error loading all requests: $e');
    }
  }

  // Capitalize first name only
  String _titleCaseFirstOnly(String input) {
    final s = input.trim();
    if (s.isEmpty) return s;
    final firstWord = s.split(RegExp(r'\s+')).first;
    final lower = firstWord.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Try to fetch from backend first
      final apiService = APIService();
      final profileData = await apiService.getUserProfile();

      if (profileData != null) {
        await AuthStorage.saveProfile(profileData);
        _updateUIFromProfile(profileData);
      } else {
        final localProfile = await AuthStorage.getProfile();
        if (localProfile != null) {
          _updateUIFromProfile(localProfile);
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      final localProfile = await AuthStorage.getProfile();
      if (localProfile != null) {
        _updateUIFromProfile(localProfile);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateUIFromProfile(Map<String, dynamic> profile) {
    // ---- Name ----
    String firstName = '';
    final firstRaw = (profile['first_name'] ?? '').toString().trim();

    if (firstRaw.isNotEmpty) {
      firstName = _titleCaseFirstOnly(firstRaw);
    } else {
      final fullName = (profile['full_name'] ?? '').toString().trim();
      if (fullName.isNotEmpty) {
        firstName = _titleCaseFirstOnly(fullName);
      }
    }

    // ---- Building Unit (snake_case only, no formatting) ----
    final buildingUnit = (profile['building_unit'] ?? '').toString().trim();
    final formattedUnit = buildingUnit.isNotEmpty ? buildingUnit : '—';

    if (mounted) {
      setState(() {
        _userName = firstName.isNotEmpty ? firstName : 'User';
        _unitLabel = formattedUnit; // ✅ show raw building_unit only
      });
    }
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        if (_selectedIndex != 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
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
          MaterialPageRoute(builder: (_) => const AnnouncementPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        ).then((_) {
          _loadUserData();
        });
        break;
    }

    setState(() => _selectedIndex = index);
  }

  Future<void> _refresh() async {
    await _loadUserData();
    await _loadAllRequests();
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    // Determine the request type and format accordingly
    final requestType = request['request_type'] ?? 'Concern Slip';
    final status = request['status'] ?? 'pending';
    final priority = request['priority'] ?? 'medium';

    // Format the ID based on request type
    String displayId = request['formatted_id'] ?? request['id'] ?? '';
    if (displayId.isEmpty) {
      switch (requestType.toLowerCase()) {
        case 'concern slip':
          displayId = 'CS-${request['id'] ?? ''}';
          break;
        case 'job service':
          displayId = 'JS-${request['id'] ?? ''}';
          break;
        case 'work order':
          displayId = 'WO-${request['id'] ?? ''}';
          break;
        default:
          displayId = request['id'] ?? '';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          final concernSlipId = request['id'] ?? '';
          if (concernSlipId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => TenantConcernSlipDetailPage(
                      concernSlipId: concernSlipId,
                    ),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request['title'] ?? 'Untitled Request',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B1D21),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatStatus(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'ID: $displayId',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatPriority(priority),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _getPriorityColor(priority),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatDate(request['created_at'] ?? ''),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getRequestTypeColor(requestType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    requestType,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _getRequestTypeColor(requestType),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
      case 'done':
        return 'Done';
      case 'approved':
        return 'Approved';
      case 'denied':
        return 'Denied';
      case 'on_hold':
        return 'On Hold';
      default:
        return status;
    }
  }

  String _formatPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      case 'critical':
        return 'Critical';
      default:
        return priority;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF79009);
      case 'assigned':
      case 'in_progress':
        return const Color(0xFF2563EB);
      case 'done':
      case 'completed':
        return const Color(0xFF24D164);
      case 'approved':
        return const Color(0xFF24D164);
      case 'denied':
        return const Color(0xFFDC2626);
      case 'on_hold':
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFF667085);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'critical':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF667085);
    }
  }

  Color _getRequestTypeColor(String requestType) {
    switch (requestType.toLowerCase()) {
      case 'concern slip':
        return const Color(0xFF7C3AED);
      case 'job service':
        return const Color(0xFF0891B2);
      case 'work order':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF667085);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _userName.isNotEmpty ? _userName : 'User';
    final displayUnit = _unitLabel.isNotEmpty ? _unitLabel : '—';

    final recentRequests = _allRequests.take(3).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Home',
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
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: 'Hello, ',
                                style: const TextStyle(
                                  color: Color(0xFF1B1D21),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                                children: [
                                  TextSpan(
                                    text: displayName,
                                    style: const TextStyle(
                                      color: Color(0xFF101828),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayUnit,
                              style: const TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: StatusCard(
                                title: 'Active Request',
                                count: '$_activeRequestsCount',
                                icon: Icons.settings_outlined,
                                iconColor: const Color(0xFFF79009),
                                backgroundColor: const Color(0xFFFFFAEB),
                                borderColor: const Color(0xFFF79009),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatusCard(
                                title: 'Done',
                                count: '$_doneRequestsCount',
                                icon: Icons.check_circle_rounded,
                                iconColor: const Color(0xFF24D164),
                                backgroundColor: const Color(0xFFF0FDF4),
                                borderColor: const Color(0xFF24D164),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Recent Requests
                        SectionHeader(
                          title: 'Recent Requests',
                          actionLabel: 'View all',
                          onActionTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const WorkOrderPage(),
                                ),
                              ),
                        ),
                        const SizedBox(height: 12),

                        recentRequests.isEmpty
                            ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 48,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No recent requests',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Your submitted requests will appear here',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                            : Column(
                              children:
                                  recentRequests
                                      .map(
                                        (request) => _buildRequestCard(request),
                                      )
                                      .toList(),
                            ),
                        const SizedBox(height: 24),

                        // Latest Announcement
                        SectionHeader(
                          title: 'Latest Announcement',
                          actionLabel: 'View all',
                          onActionTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AnnouncementPage(),
                                ),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.announcement_outlined,
                                size: 48,
                                color: Color(0xFF9CA3AF),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No announcements',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Building announcements will appear here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
