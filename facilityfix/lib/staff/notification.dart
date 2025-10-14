import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/cards.dart';
import 'package:facilityfix/models/notification_models.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/config/env.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final int _selectedIndex = 3;
  final APIService _apiService = APIService(roleOverride: AppRole.staff);
  bool _isLoading = false;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  // Filter: All or Unread
  NotifFilter _filter = NotifFilter.all;

  // Use enhanced notifications list instead of sample data
  List<EnhancedNotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      print('[Staff Notifications] Loading notifications...');
      final notificationsJson = await _apiService.getNotifications(
        unreadOnly: _filter == NotifFilter.unread,
        limit: 50,
      );
      print('[Staff Notifications] Received ${notificationsJson.length} notifications');
      
      final notifications = notificationsJson
          .map((json) => EnhancedNotificationItem.fromJson(json))
          .toList();
      
      setState(() {
        _notifications = notifications;
      });
      print('[Staff Notifications] Successfully loaded ${notifications.length} notifications');
    } catch (e) {
      print('[Staff Notifications] Error loading notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadNotifications();
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

  // ===== Grouping & Formatting =====

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isYesterday(DateTime d) {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return d.year == y.year && d.month == y.month && d.day == y.day;
  }

  // Build a flat list with section headers inserted
  List<ListEntry> _buildSectioned() {
    final List<EnhancedNotificationItem> src = _notifications
        .where((n) => _filter == NotifFilter.all ? true : !n.isRead)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final entries = <ListEntry>[];

    // Group
    bool addedToday = false;
    bool addedYesterday = false;
    bool addedEarlier = false;

    for (final n in src) {
      if (_isToday(n.createdAt) && !addedToday) {
        entries.add(ListHeader('Today'));
        addedToday = true;
      } else if (_isYesterday(n.createdAt) && !addedYesterday) {
        entries.add(ListHeader('Yesterday'));
        addedYesterday = true;
      } else if (!(_isToday(n.createdAt) || _isYesterday(n.createdAt)) && !addedEarlier) {
        entries.add(ListHeader('Earlier'));
        addedEarlier = true;
      }
      entries.add(EnhancedListItem(n));
    }

    if (entries.isEmpty) {
      entries.add(ListHeader(_filter == NotifFilter.unread ? 'No unread notifications' : 'No notifications'));
    }

    return entries;
  }

  Future<void> _markAllAsRead() async {
    try {
      final unreadIds = _notifications
          .where((n) => !n.isRead)
          .map((n) => n.id)
          .toList();
      
      if (unreadIds.isNotEmpty) {
        await _apiService.markNotificationsAsRead(unreadIds);
        await _loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark all as read: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(EnhancedNotificationItem notification) async {
    if (!notification.isRead) {
      try {
        await _apiService.markNotificationAsRead(notification.id);
        await _loadNotifications();
      } catch (e) {
        // Silently handle error for individual marking
      }
    }
  }

  Future<void> _deleteNotification(EnhancedNotificationItem notification) async {
    try {
      await _apiService.deleteNotification(notification.id);
      await _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete notification: $e')),
        );
      }
    }
  }

  bool get _hasUnread => _notifications.any((n) => !n.isRead);

  Widget _leadingIcon(EnhancedNotificationItem n) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: n.iconBackgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(n.typeIcon, color: n.iconColor, size: 22),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF005CE7) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF005CE7) : const Color(0xFFE4E7EC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF667085),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildSectioned();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Notifications',
        leading: const Row(
          children: [
            BackButton(),
            SizedBox(width: 8),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _hasUnread ? _markAllAsRead : null,
            style: TextButton.styleFrom(
              foregroundColor: _hasUnread ? const Color(0xFF005CE7) : const Color(0xFF98A2B3),
            ),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Mark all read'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segmented filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _buildFilterChip(
                    'All',
                    _filter == NotifFilter.all,
                    () async {
                      setState(() => _filter = NotifFilter.all);
                      await _loadNotifications();
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Unread',
                    _filter == NotifFilter.unread,
                    () async {
                      setState(() => _filter = NotifFilter.unread);
                      await _loadNotifications();
                    },
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      if (entry is ListHeader) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text(
                            entry.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF667085),
                              letterSpacing: 0.3,
                            ),
                          ),
                        );
                      }

                      final item = (entry as EnhancedListItem).data;

                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDECEC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete_outline, color: Color(0xFFE84545)),
                        ),
                        onDismissed: (_) {
                          _deleteNotification(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification deleted')),
                          );
                        },
                        child: NotificationMessageCard(
                          title: item.title,
                          message: item.message,
                          timeLabel: item.timeAgo,
                          isUnread: !item.isRead,
                          leading: _leadingIcon(item),
                          onTap: () async {
                            // Mark as read
                            await _markAsRead(item);

                            // Navigate based on notification type
                            if (item.notificationType.contains('announcement')) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AnnouncementPage()),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const WorkOrderPage()),
                              );
                            }
                          },
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: entries.length,
                  ),
                ),
              ),
          ],
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
