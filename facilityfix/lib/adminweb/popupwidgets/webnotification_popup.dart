import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class NotificationDialog extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final VoidCallback? onRefresh; // Added refresh callback

  const NotificationDialog({
    super.key,
    required this.notifications,
    this.onRefresh, // Added refresh callback
  });

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();

  // Static method to show the notification dialog
  static void show(
    BuildContext context,
    List<Map<String, dynamic>> notifications, {
    VoidCallback? onRefresh, // Added refresh callback
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return NotificationDialog(
          notifications: notifications,
          onRefresh: onRefresh, // Pass refresh callback
        );
      },
    );
  }
}

class _NotificationDialogState extends State<NotificationDialog> {
  bool _isLoading = false;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _localNotifications = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _localNotifications = List.from(widget.notifications);
    _refreshNotifications();
  }

  Future<void> _refreshNotifications() async {
    if (_isLoading || _isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().getNotifications(limit: 50);
      
      // The backend returns a List directly
      List<dynamic> notificationsList;
      if (response is List) {
        notificationsList = response;
      } else {
        // Fallback for unexpected response format
        notificationsList = [];
        print('[NotificationDialog] Unexpected response format: ${response.runtimeType}');
      }

      final transformedNotifications = notificationsList.map((notif) {
        return {
          'id': notif['id'],
          'type': notif['notification_type'] ?? 'system',
          'title': notif['title'] ?? 'Notification',
          'message': notif['message'] ?? '',
          'timestamp': notif['created_at'] ?? DateTime.now().toIso8601String(),
          'isRead': notif['is_read'] ?? false,
          'relatedId': notif['related_entity_id'],
          'related_entity_type': notif['related_entity_type'],
          'action_url': notif['action_url'],
          'priority': notif['priority'] ?? 'normal',
          'isUrgent': notif['is_urgent'] ?? false,
          'notificationType': notif['notification_type'] ?? 'system',
          'department': notif['department'],
          'buildingId': notif['building_id'],
        };
      }).toList();

      setState(() {
        _localNotifications = transformedNotifications;
        _isRefreshing = false;
      });

      // Trigger parent refresh
      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
        _errorMessage = 'Failed to load notifications: ${e.toString()}';
      });
      print('[NotificationDialog] Error refreshing notifications: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      alignment: Alignment.topRight, // Position at top-right
      insetPadding: const EdgeInsets.only(top: 60, right: 20, left: 20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section
            _buildHeader(context),

            // Error message display
            if (_errorMessage != null) _buildErrorMessage(),

            // Notifications List
            Flexible(
              child: _isRefreshing
                  ? _buildLoadingState()
                  : _localNotifications.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationsList(),
            ),

            // Footer Section (optional settings or clear all)
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // Header with title and close button
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          // Refresh button
          IconButton(
            onPressed: _isRefreshing ? null : _refreshNotifications,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh, color: Colors.grey[600], size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Refresh notifications',
          ),
          const SizedBox(width: 8),
          // Settings button (optional)
          IconButton(
            onPressed: () => _openNotificationSettings(),
            icon: Icon(Icons.settings, color: Colors.grey[600], size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Notification settings',
          ),
          const SizedBox(width: 8),
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  // Error message display
  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[700],
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _errorMessage = null),
            icon: Icon(Icons.close, size: 16, color: Colors.red[700]),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Loading state
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Notifications list builder
  Widget _buildNotificationsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children:
            _localNotifications.map((notification) {
              return _buildNotificationItem(notification);
            }).toList(),
      ),
    );
  }

  // Individual notification item
  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final message = notification['message'] ?? 'No message';
    // Show more lines for all messages to avoid ellipsis
    final maxLines = 4; // Increased from 2 to show more content

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color:
            notification['isRead'] == false
                ? Colors.blue[50]
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon/avatar
              _buildNotificationIcon(notification['type']),
              const SizedBox(width: 12),

              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and timestamp row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? 'Notification',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  notification['isRead'] == false
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          _formatTimestamp(notification['timestamp']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Notification message - expands for long messages
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Action buttons (dismiss, more options)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[500], size: 16),
                padding: EdgeInsets.zero,
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'mark_read',
                        child: Text(
                          notification['isRead'] == false
                              ? 'Mark as read'
                              : 'Mark as unread',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'dismiss',
                        child: Text('Dismiss'),
                      ),
                    ],
                onSelected:
                    (value) => _handleNotificationAction(notification, value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Notification type icon builder
  Widget _buildNotificationIcon(String? type) {
    Color bgColor;
    Color iconColor;
    IconData icon;

    switch (type?.toLowerCase()) {
      case 'concern_slip_submitted':
        bgColor = Colors.blue[100]!;
        iconColor = Colors.blue[700]!;
        icon = Icons.assignment_turned_in;
        break;
      case 'concern_slip_assigned':
        bgColor = Colors.orange[100]!;
        iconColor = Colors.orange[700]!;
        icon = Icons.assignment_ind;
        break;
      case 'concern_slip_completed':
        bgColor = Colors.green[100]!;
        iconColor = Colors.green[700]!;
        icon = Icons.check_circle_outline;
        break;
      case 'concern_slip_resolved':
        bgColor = Colors.green[100]!;
        iconColor = Colors.green[700]!;
        icon = Icons.check_circle;
        break;
      case 'maintenance':
        bgColor = Colors.orange[100]!;
        iconColor = Colors.orange[700]!;
        icon = Icons.build;
        break;
      case 'repair':
        bgColor = Colors.red[100]!;
        iconColor = Colors.red[700]!;
        icon = Icons.handyman;
        break;
      case 'inspection':
        bgColor = Colors.blue[100]!;
        iconColor = Colors.blue[700]!;
        icon = Icons.checklist;
        break;
      case 'announcement':
        bgColor = Colors.green[100]!;
        iconColor = Colors.green[700]!;
        icon = Icons.campaign;
        break;
      case 'user_registered':
        bgColor = Colors.indigo[100]!;
        iconColor = Colors.indigo[700]!;
        icon = Icons.person_add;
        break;
      case 'work_order_created':
        bgColor = Colors.cyan[100]!;
        iconColor = Colors.cyan[700]!;
        icon = Icons.work_outline;
        break;
      case 'work_order_assigned':
        bgColor = Colors.amber[100]!;
        iconColor = Colors.amber[700]!;
        icon = Icons.engineering;
        break;
      case 'work_order_completed':
        bgColor = Colors.teal[100]!;
        iconColor = Colors.teal[700]!;
        icon = Icons.task_alt;
        break;
      case 'inventory_low_stock':
        bgColor = Colors.orange[100]!;
        iconColor = Colors.orange[700]!;
        icon = Icons.inventory_2_outlined;
        break;
      case 'inventory_out_of_stock':
        bgColor = Colors.red[100]!;
        iconColor = Colors.red[700]!;
        icon = Icons.warning_amber;
        break;
      case 'system':
        bgColor = Colors.purple[100]!;
        iconColor = Colors.purple[700]!;
        icon = Icons.settings;
        break;
      case 'urgent':
        bgColor = Colors.red[100]!;
        iconColor = Colors.red[700]!;
        icon = Icons.priority_high;
        break;
      case 'escalation':
      case 'priority_escalated':
        bgColor = Colors.red[100]!;
        iconColor = Colors.red[700]!;
        icon = Icons.trending_up;
        break;
      default:
        bgColor = Colors.cyan[100]!;
        iconColor = Colors.cyan[700]!;
        icon = Icons.campaign_outlined;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }

  // Empty state when no notifications
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, color: Colors.grey[400], size: 48),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Footer section with actions
  Widget _buildFooter(BuildContext context) {
    if (_localNotifications.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Mark all as read',
              style: TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _clearAllNotifications,
            child: Text(
              'Clear all',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  // Format timestamp for display
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';

    try {
      DateTime dateTime = DateTime.parse(timestamp);
      DateTime now = DateTime.now();
      Duration difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return timestamp;
    }
  }

  // Handle notification tap - navigate to relevant screen or show details
  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Navigate to relevant screen based on notification type
    final notificationType = notification['type']?.toLowerCase() ?? '';
    final relatedId = notification['relatedId'] ?? '';
    final notificationId = notification['id'];

    print('[NOTIF_TAP] notificationType: $notificationType');
    print('[NOTIF_TAP] Full notification: $notification');

    // Determine the route based on notification type and related entity
    String? targetRoute;
    
    switch (notificationType) {
      // Concern Slip related notifications
      case 'concern_slip_submitted':
      case 'concern_slip_assigned':
      case 'concern_slip_assessed':
      case 'concern_slip_evaluated':
      case 'concern_slip_resolution_set':
      case 'concern_slip_returned':
        if (relatedId.isNotEmpty) {
          targetRoute = '/work/repair';
        }
        break;
      
      // Job Service notifications
      case 'job_service_received':
      case 'job_service_completed':
        if (relatedId.isNotEmpty) {
          targetRoute = '/adminweb/pages/adminrepair_js_page';
        }
        break;
      
      // Work Order notifications
      case 'work_order_created':
      case 'work_order_assigned':
      case 'work_order_completed':
        if (relatedId.isNotEmpty) {
          targetRoute = '/adminweb/pages/adminrepair_wop_page';
        }
        break;
      
      // Priority escalated - check related_entity_type to route to correct page
      case 'priority_escalated':
      case 'escalation':
        final entityType = notification['related_entity_type']?.toString().toLowerCase() ?? '';
        print('[ESCALATION] Routing based on related_entity_type: $entityType');
        
        if (entityType.contains('concern_slip') || entityType == 'concern_slips') {
          print('[ESCALATION] → Routing to CONCERN SLIP page');
          targetRoute = '/work/repair';
        } else if (entityType.contains('job_service') || entityType == 'job_services') {
          print('[ESCALATION] → Routing to JOB SERVICE page');
          targetRoute = '/adminweb/pages/adminrepair_js_page';
        } else if (entityType.contains('work_order') || entityType == 'work_order_permits') {
          print('[ESCALATION] → Routing to WORK ORDER page');
          targetRoute = '/adminweb/pages/adminrepair_wop_page';
        } else {
          print('[ESCALATION] → Unknown entity type: "$entityType" - going to DASHBOARD');
          targetRoute = '/dashboard';
        }
        break;
      
      // Maintenance notifications
      case 'maintenance':
        targetRoute = '/work/maintenance';
        break;
      
      // Announcement notifications
      case 'announcement':
      case 'announcement_published':
        print('[ANNOUNCEMENT_TAP] Navigate to announcement: $relatedId');
        targetRoute = '/announcement';
        break;
      
      default:
        // Default: go to dashboard
        print('[NOTIF] Type "$notificationType" - going to DASHBOARD');
        targetRoute = '/dashboard';
    }

    print('[NOTIF_TAP] targetRoute: $targetRoute');

    // Close the popup and navigate
    Navigator.of(context).pop();
    
    if (targetRoute != null) {
      context.go(targetRoute);
    }

    // Mark as read AFTER navigation (silent background operation)
    Future.delayed(const Duration(milliseconds: 100), () {
      _markNotificationAsRead(notificationId);
    });
  }

  // Handle notification context menu actions
  void _handleNotificationAction(
    Map<String, dynamic> notification,
    String action,
  ) {
    switch (action) {
      case 'mark_read':
        _toggleNotificationReadStatus(notification);
        break;
      case 'dismiss':
        _dismissNotification(notification['id']);
        break;
    }
  }

  // Open notification settings
  void _openNotificationSettings() {
    Navigator.of(context).pop();
    // TODO: Navigate to notification settings page
    print('Open notification settings');
  }

  // Mark all notifications as read
  void _markAllAsRead() async {
    final unreadIds =
        _localNotifications
            .where((n) => n['isRead'] == false)
            .map((n) => n['id'] as String)
            .toList();

    if (unreadIds.isEmpty) return;

    try {
      await ApiService().markNotificationsAsRead(unreadIds);

      setState(() {
        for (var notification in _localNotifications) {
          notification['isRead'] = true;
        }
      });

      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[v0] Error marking all as read: $e');
      setState(() {
        _errorMessage = 'Failed to mark notifications as read: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark notifications as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Clear all notifications
  void _clearAllNotifications() async {
    if (_localNotifications.isEmpty) return;

    try {
      // Delete all notifications via API
      for (var notification in _localNotifications) {
        await ApiService().deleteNotification(notification['id']);
      }

      setState(() {
        _localNotifications.clear();
      });

      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      print('[v0] Error clearing notifications: $e');
      setState(() {
        _errorMessage = 'Failed to clear notifications: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Toggle notification read status
  void _toggleNotificationReadStatus(Map<String, dynamic> notification) async {
    final newReadStatus = !(notification['isRead'] ?? false);

    try {
      if (newReadStatus) {
        await ApiService().markNotificationsAsRead([notification['id']]);
      }

      setState(() {
        notification['isRead'] = newReadStatus;
      });

      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    } catch (e) {
      print('[v0] Error toggling notification read status: $e');
    }
  }

  // Mark single notification as read (silent operation, no refresh callback)
  void _markNotificationAsRead(String id) async {
    try {
      await ApiService().markNotificationsAsRead([id]);
      // Silent operation - don't call widget.onRefresh() to avoid setState on disposed widget
    } catch (e) {
      print('[v0] Error marking notification as read: $e');
    }
  }

  // Dismiss notification
  void _dismissNotification(String id) async {
    try {
      await ApiService().deleteNotification(id);

      setState(() {
        _localNotifications.removeWhere((notif) => notif['id'] == id);
      });

      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    } catch (e) {
      print('[v0] Error deleting notification: $e');
      setState(() {
        _errorMessage = 'Failed to delete notification: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
