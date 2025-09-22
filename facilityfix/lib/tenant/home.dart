import 'package:facilityfix/services/api_services.dart';
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

  List<Map<String, dynamic>> _concernSlips = [];
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
    _loadConcernSlips();
  }

  Future<void> _loadConcernSlips() async {
    try {
      final apiService = APIService();
      final concernSlips = await apiService.getTenantConcernSlips();

      if (concernSlips != null && mounted) {
        setState(() {
          _concernSlips = concernSlips;

          _activeRequestsCount =
              concernSlips
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
              concernSlips
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
      print('Error loading concern slips: $e');
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
        // Save to local storage
        await AuthStorage.saveProfile(profileData);
        _updateUIFromProfile(profileData);
      } else {
        // Fallback to local storage if backend fails
        final localProfile = await AuthStorage.getProfile();
        if (localProfile != null) {
          _updateUIFromProfile(localProfile);
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Fallback to local storage
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
    // Extract first name
    String firstName = '';

    // Try different possible keys for first name
    final firstRaw =
        (profile['first_name'] ?? profile['firstName'] ?? '').toString().trim();

    if (firstRaw.isNotEmpty) {
      firstName = _titleCaseFirstOnly(firstRaw);
    } else {
      // Fallback: extract from full name
      final fullName =
          (profile['full_name'] ?? profile['fullName'] ?? '').toString().trim();

      if (fullName.isNotEmpty) {
        firstName = _titleCaseFirstOnly(fullName);
      }
    }

    // Extract building and unit information - STRICT PATTERN ONLY
    String buildingId = (profile['building_id'] ?? '').toString().trim();
    String unitId = (profile['unit_id'] ?? '').toString().trim();

    // If building/unit IDs are empty, try to parse from building_unit field
    // USING STRICT PATTERN: "Building A • Unit 1001"
    if (buildingId.isEmpty || unitId.isEmpty) {
      final buildingUnit = (profile['building_unit'] ?? '').toString().trim();

      if (buildingUnit.isNotEmpty) {
        final parsed = _parseStrictBuildingUnit(buildingUnit);
        if (parsed != null) {
          buildingId =
              buildingId.isEmpty ? parsed['building'] ?? '' : buildingId;
          unitId = unitId.isEmpty ? parsed['unit'] ?? '' : unitId;
        }
      }
    }

    // Format the display text - STRICT PATTERN ONLY
    String formattedUnit = '—';
    if (buildingId.isNotEmpty && unitId.isNotEmpty) {
      formattedUnit = 'Building $buildingId • Unit $unitId';
    }

    if (mounted) {
      setState(() {
        _userName = firstName.isNotEmpty ? firstName : 'User';
        _unitLabel = formattedUnit;
      });
    }
  }

  // STRICT PATTERN PARSING: Only accept "Building A • Unit 1001"
  Map<String, String>? _parseStrictBuildingUnit(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    // Strict pattern: "Building A • Unit 1001"
    final regex = RegExp(
      r'^Building\s+([A-Za-z0-9]+)\s+•\s+Unit\s+([A-Za-z0-9]+)$',
    );
    final match = regex.firstMatch(s);

    if (match != null) {
      return {
        'building': (match.group(1) ?? '').trim(),
        'unit': (match.group(2) ?? '').trim(),
      };
    }

    return null;
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    // Handle navigation based on index
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
          // Refresh data when returning from profile page
          _loadUserData();
        });
        break;
    }

    setState(() => _selectedIndex = index);
  }

  Future<void> _refresh() async {
    await _loadUserData();
    await _loadConcernSlips();
  }

  Widget _buildConcernSlipCard(Map<String, dynamic> concernSlip) {
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ViewDetailsPage(
                    selectedTabLabel: 'concern slip',
                    requestType: 'Concern Slip',
                  ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    concernSlip['title'] ?? 'Untitled',
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
                    color: _getStatusColor(
                      concernSlip['status'] ?? '',
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    concernSlip['status'] ?? 'pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(concernSlip['status'] ?? ''),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${concernSlip['id'] ?? ''}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
            ),
            const SizedBox(height: 4),
            Text(
              concernSlip['created_at'] ?? '',
              style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF79009);
      case 'assigned':
      case 'in progress':
        return const Color(0xFF2563EB);
      case 'done':
      case 'completed':
        return const Color(0xFF24D164);
      default:
        return const Color(0xFF667085);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _userName.isNotEmpty ? _userName : 'User';
    final displayUnit = _unitLabel.isNotEmpty ? _unitLabel : '—';

    final recentConcernSlips = _concernSlips.take(3).toList();

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

                        recentConcernSlips.isEmpty
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
                                  recentConcernSlips
                                      .map((cs) => _buildConcernSlipCard(cs))
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
