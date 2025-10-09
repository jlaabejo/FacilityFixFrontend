import 'dart:async';
import 'package:facilityfix/tenant/home.dart';
import 'package:facilityfix/tenant/notification.dart';
import 'package:facilityfix/tenant/profile.dart';
import 'package:facilityfix/tenant/workorder.dart';
import 'package:facilityfix/widgets/buttons.dart';
import 'package:facilityfix/widgets/cards.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/helper_models.dart';
import 'package:flutter/material.dart';

import '../staff/view_details/announcement_details.dart';

/// Simple data model for the list (avoids mixing widgets & data).
class AnnouncementItem {
  final String id;
  final String title;
  final String announcementType; // e.g. "utility interruption"
  final DateTime createdAt;
  final bool isRead;

  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.announcementType,
    required this.createdAt,
    required this.isRead,
  });

  AnnouncementItem copyWith({
    String? id,
    String? title,
    String? announcementType,
    String? classification,
    String? details,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AnnouncementItem(
      id: id ?? this.id,
      title: title ?? this.title,
      announcementType: announcementType ?? this.announcementType,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  int _selectedIndex = 2;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.person),
  ];


  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const ProfilePage(),
    ];
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }


  // ===== Search, classification & read-status filters =====
  final TextEditingController _searchController = TextEditingController();

  // Classification (announcement categories)
  String _selectedClassification = "All";
  final List<String> _classifications = const [
    'All',
    'Utility Interruption',
    'Power Outage',
    'Pest Control',
    'General Maintenance',
  ];

  // Status filter
  String _selectedStatus = 'All';
  final List<String> _statuses = const ['All', 'Unread', 'Read', 'Recent'];
  AnnStatusFilter _statusFilter = AnnStatusFilter.all;

  AnnStatusFilter _toFilter(String s) {
    switch (s.toLowerCase()) {
      case 'unread':
        return AnnStatusFilter.unread;
      case 'read':
        return AnnStatusFilter.read;
      case 'recent':
        return AnnStatusFilter.recent;
      default:
        return AnnStatusFilter.all;
    }
  }

  // ===== Demo data (replace with backend) =====
  final List<AnnouncementItem> _all = [
    AnnouncementItem(
      id: 'ANN-2025-0011',
      title: 'Utility Interruption',
      announcementType: 'utility interruption',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: false, 
    ),
    AnnouncementItem(
      id: 'ANN-2025-0012',
      title: 'Power Outage',
      announcementType: 'power outage',
      createdAt: DateTime.now().subtract(const Duration(hours: 27)),
      isRead: true,
    ),
    AnnouncementItem(
      id: 'ANN-2025-0013',
      title: 'General Maintenance',
      announcementType: 'general maintenance',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isRead: false,
    ),
    AnnouncementItem(
      id: 'ANN-2025-0014',
      title: 'Pest Control',
      announcementType: 'pest control',
      createdAt: DateTime.now().subtract(const Duration(days: 11)),
      isRead: true,
    ),
  ];

  // ===== Debounce for search =====
  Timer? _debounce;
  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => _onSearchChanged(_searchController.text));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ===== Filtering logic =====
  bool _isRecent(DateTime dt) => DateTime.now().difference(dt).inDays <= 7;

  bool _matchesClassification(String classification) {
    if (_selectedClassification == 'All') return true;
    return classification.toLowerCase() == _selectedClassification.toLowerCase();
  }

  bool _matchesSearch(String haystack) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return haystack.toLowerCase().contains(q);
  }

  bool _matchesStatus(AnnouncementItem a) {
    switch (_statusFilter) {
      case AnnStatusFilter.all:
        return true;
      case AnnStatusFilter.unread:
        return !a.isRead;
      case AnnStatusFilter.read:
        return a.isRead;
      case AnnStatusFilter.recent:
        return _isRecent(a.createdAt);
    }
  }

  List<AnnouncementItem> get _filteredAnnouncements {
    return _all.where((a) {
      final classMatch = _matchesClassification(a.announcementType);
      final searchMatch = _matchesSearch("${a.title} ${a.announcementType}");
      final statusMatch = _matchesStatus(a);
      return classMatch && searchMatch && statusMatch;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _refresh() async {
    // TODO: replace with backend fetch
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {});
  }

  String headerTitle() {
    switch (_statusFilter) {
      case AnnStatusFilter.all:
        return 'All Announcements';
      case AnnStatusFilter.unread:
        return 'Unread Announcements';
      case AnnStatusFilter.read:
        return 'Read Announcements';
      case AnnStatusFilter.recent:
        return 'Recent Announcements';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredAnnouncements;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Announcement',
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========== TOP BAR: Search + Classification + Status ==========
                SearchAndFilterBar(
                  searchController: _searchController,

                  // Classification (turns on the tune icon & bottom sheet)
                  selectedClassification: _selectedClassification,
                  classifications: _classifications,
                  onClassificationChanged: (v) =>
                      setState(() => _selectedClassification = v),

                  // Status (required by SearchAndFilterBar)
                  selectedStatus: _selectedStatus,
                  statuses: _statuses,
                  onStatusChanged: (v) => setState(() {
                    _selectedStatus = v;
                    _statusFilter = _toFilter(v);
                  }),

                  // Optional: react to search typing/submit
                  onSearchChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Text(
                  headerTitle(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // ======================== LIST ================================
                Expanded(
                  child: items.isEmpty
                      ? const EmptyState()
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final a = items[i];

                            return Opacity(
                              opacity: a.isRead ? 0.85 : 1,
                              child: Stack(
                                children: [
                                  AnnouncementCard(
                                    id: a.id,
                                    title: a.title,
                                    announcementType: a.announcementType,
                                    createdAt: a.createdAt, // DateTime ✅
                                    isRead: a.isRead,
                                    onTap: () {
                                      // mark as read on view
                                      final idx = _all.indexWhere((x) => x.id == a.id);
                                      if (idx != -1 && !_all[idx].isRead) {
                                        setState(() => _all[idx] =
                                            _all[idx].copyWith(isRead: true));
                                      }

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const AnnouncementDetailsPage(),
                                        ),
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
      ),
      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
