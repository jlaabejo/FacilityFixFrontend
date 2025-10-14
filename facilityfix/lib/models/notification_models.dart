import 'package:flutter/material.dart';

/// Enhanced notification model to match backend notification structure
class EnhancedNotificationItem {
  final String id;
  final String notificationType;
  final String recipientId;
  final String? senderId;
  final String title;
  final String message;
  final String? description;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final String? buildingId;
  final String? department;
  final String priority;
  final bool isUrgent;
  final DateTime? expiresAt;
  final List<String> channels;
  final String deliveryStatus;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final String? failedReason;
  final String? actionUrl;
  final String? actionLabel;
  final bool requiresAction;
  final bool actionTaken;
  final DateTime? actionTakenAt;
  final Map<String, dynamic>? customData;
  final List<String> tags;
  final String? groupKey;
  final String? batchId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EnhancedNotificationItem({
    required this.id,
    required this.notificationType,
    required this.recipientId,
    this.senderId,
    required this.title,
    required this.message,
    this.description,
    this.relatedEntityType,
    this.relatedEntityId,
    this.buildingId,
    this.department,
    this.priority = 'normal',
    this.isUrgent = false,
    this.expiresAt,
    this.channels = const [],
    this.deliveryStatus = 'pending',
    this.isRead = false,
    this.readAt,
    this.deliveredAt,
    this.failedReason,
    this.actionUrl,
    this.actionLabel,
    this.requiresAction = false,
    this.actionTaken = false,
    this.actionTakenAt,
    this.customData,
    this.tags = const [],
    this.groupKey,
    this.batchId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory method to create from backend JSON response
  factory EnhancedNotificationItem.fromJson(Map<String, dynamic> json) {
    return EnhancedNotificationItem(
      id: json['id']?.toString() ?? '',
      notificationType: json['notification_type']?.toString() ?? '',
      recipientId: json['recipient_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      description: json['description']?.toString(),
      relatedEntityType: json['related_entity_type']?.toString(),
      relatedEntityId: json['related_entity_id']?.toString(),
      buildingId: json['building_id']?.toString(),
      department: json['department']?.toString(),
      priority: json['priority']?.toString() ?? 'normal',
      isUrgent: json['is_urgent'] ?? false,
      expiresAt: json['expires_at'] != null 
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      channels: json['channels'] != null 
          ? List<String>.from(json['channels']) 
          : [],
      deliveryStatus: json['delivery_status']?.toString() ?? 'pending',
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null 
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      deliveredAt: json['delivered_at'] != null 
          ? DateTime.tryParse(json['delivered_at'].toString())
          : null,
      failedReason: json['failed_reason']?.toString(),
      actionUrl: json['action_url']?.toString(),
      actionLabel: json['action_label']?.toString(),
      requiresAction: json['requires_action'] ?? false,
      actionTaken: json['action_taken'] ?? false,
      actionTakenAt: json['action_taken_at'] != null 
          ? DateTime.tryParse(json['action_taken_at'].toString())
          : null,
      customData: json['custom_data'] as Map<String, dynamic>?,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) 
          : [],
      groupKey: json['group_key']?.toString(),
      batchId: json['batch_id']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notification_type': notificationType,
      'recipient_id': recipientId,
      if (senderId != null) 'sender_id': senderId,
      'title': title,
      'message': message,
      if (description != null) 'description': description,
      if (relatedEntityType != null) 'related_entity_type': relatedEntityType,
      if (relatedEntityId != null) 'related_entity_id': relatedEntityId,
      if (buildingId != null) 'building_id': buildingId,
      if (department != null) 'department': department,
      'priority': priority,
      'is_urgent': isUrgent,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      'channels': channels,
      'delivery_status': deliveryStatus,
      'is_read': isRead,
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
      if (deliveredAt != null) 'delivered_at': deliveredAt!.toIso8601String(),
      if (failedReason != null) 'failed_reason': failedReason,
      if (actionUrl != null) 'action_url': actionUrl,
      if (actionLabel != null) 'action_label': actionLabel,
      'requires_action': requiresAction,
      'action_taken': actionTaken,
      if (actionTakenAt != null) 'action_taken_at': actionTakenAt!.toIso8601String(),
      if (customData != null) 'custom_data': customData,
      'tags': tags,
      if (groupKey != null) 'group_key': groupKey,
      if (batchId != null) 'batch_id': batchId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with new values
  EnhancedNotificationItem copyWith({
    String? id,
    String? notificationType,
    String? recipientId,
    String? senderId,
    String? title,
    String? message,
    String? description,
    String? relatedEntityType,
    String? relatedEntityId,
    String? buildingId,
    String? department,
    String? priority,
    bool? isUrgent,
    DateTime? expiresAt,
    List<String>? channels,
    String? deliveryStatus,
    bool? isRead,
    DateTime? readAt,
    DateTime? deliveredAt,
    String? failedReason,
    String? actionUrl,
    String? actionLabel,
    bool? requiresAction,
    bool? actionTaken,
    DateTime? actionTakenAt,
    Map<String, dynamic>? customData,
    List<String>? tags,
    String? groupKey,
    String? batchId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EnhancedNotificationItem(
      id: id ?? this.id,
      notificationType: notificationType ?? this.notificationType,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      title: title ?? this.title,
      message: message ?? this.message,
      description: description ?? this.description,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      buildingId: buildingId ?? this.buildingId,
      department: department ?? this.department,
      priority: priority ?? this.priority,
      isUrgent: isUrgent ?? this.isUrgent,
      expiresAt: expiresAt ?? this.expiresAt,
      channels: channels ?? this.channels,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      failedReason: failedReason ?? this.failedReason,
      actionUrl: actionUrl ?? this.actionUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      requiresAction: requiresAction ?? this.requiresAction,
      actionTaken: actionTaken ?? this.actionTaken,
      actionTakenAt: actionTakenAt ?? this.actionTakenAt,
      customData: customData ?? this.customData,
      tags: tags ?? this.tags,
      groupKey: groupKey ?? this.groupKey,
      batchId: batchId ?? this.batchId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get priority color based on priority level
  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626); // Red
      case 'urgent':
        return const Color(0xFFEA580C); // Orange
      case 'high':
        return const Color(0xFFCA8A04); // Yellow/Amber
      case 'normal':
        return const Color(0xFF059669); // Green
      case 'low':
        return const Color(0xFF0891B2); // Cyan
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  /// Get icon based on notification type
  IconData get typeIcon {
    switch (notificationType.toLowerCase()) {
      // Concern Slip notifications
      case 'concern_slip_submitted':
        return Icons.assignment_outlined;
      case 'concern_slip_assigned':
        return Icons.assignment_ind_outlined;
      case 'concern_slip_assessed':
        return Icons.check_circle_outline;
      case 'concern_slip_evaluated':
        return Icons.verified_outlined;
      case 'concern_slip_resolution_set':
        return Icons.settings_outlined;
      case 'concern_slip_returned':
        return Icons.assignment_return_outlined;

      // Work Order notifications
      case 'work_order_submitted':
        return Icons.work_outline;
      case 'work_order_assigned':
        return Icons.person_add_outlined;
      case 'work_order_schedule_updated':
        return Icons.schedule_outlined;
      case 'work_order_canceled':
        return Icons.cancel_outlined;

      // Job Service notifications
      case 'job_service_received':
        return Icons.handyman_outlined;
      case 'job_service_completed':
        return Icons.task_alt_outlined;

      // Permit notifications
      case 'permit_created':
        return Icons.description_outlined;
      case 'permit_approved':
        return Icons.verified_user_outlined;
      case 'permit_rejected':
        return Icons.block_outlined;
      case 'permit_expiring':
        return Icons.access_time_outlined;

      // Maintenance notifications
      case 'maintenance_task_assigned':
        return Icons.build_outlined;
      case 'maintenance_overdue':
        return Icons.warning_outlined;
      case 'maintenance_completed':
        return Icons.done_all_outlined;

      // Inventory notifications
      case 'inventory_low_stock':
      case 'inventory_critical_stock':
        return Icons.inventory_2_outlined;
      case 'inventory_restocked':
        return Icons.add_box_outlined;
      case 'inventory_request_submitted':
        return Icons.shopping_cart_outlined;
      case 'inventory_request_ready':
        return Icons.local_shipping_outlined;

      // Announcement notifications
      case 'announcement_published':
        return Icons.campaign_outlined;
      case 'announcement_updated':
        return Icons.edit_notifications_outlined;
      case 'announcement_reminder':
        return Icons.notifications_active_outlined;

      // User management notifications
      case 'user_invited':
        return Icons.person_add_alt_outlined;
      case 'user_approved':
        return Icons.how_to_reg_outlined;

      // System notifications
      case 'system_maintenance':
        return Icons.settings_system_daydream_outlined;
      case 'escalation':
        return Icons.priority_high_outlined;

      default:
        return Icons.notifications_outlined;
    }
  }

  /// Get background color for icon based on notification type
  Color get iconBackgroundColor {
    switch (notificationType.toLowerCase()) {
      // Concern Slip - Blue variants
      case 'concern_slip_submitted':
      case 'concern_slip_assigned':
      case 'concern_slip_evaluated':
      case 'concern_slip_resolution_set':
      case 'concern_slip_returned':
        return const Color(0xFFF4F5FF);

      // Assessment - Purple variants
      case 'concern_slip_assessed':
        return const Color(0xFFFAF5FF);

      // Work Order - Green variants
      case 'work_order_submitted':
      case 'work_order_assigned':
      case 'job_service_received':
      case 'job_service_completed':
        return const Color(0xFFE8F7F1);

      // Schedule/Time - Orange variants
      case 'work_order_schedule_updated':
      case 'permit_expiring':
      case 'maintenance_overdue':
        return const Color(0xFFFFFAEB);

      // Warnings/Errors - Red variants
      case 'work_order_canceled':
      case 'permit_rejected':
      case 'inventory_critical_stock':
        return const Color(0xFFFDECEC);

      // Success/Approval - Green variants
      case 'permit_approved':
      case 'maintenance_completed':
      case 'inventory_restocked':
      case 'user_approved':
        return const Color(0xFFE8F7F1);

      // Information - Cyan variants
      case 'permit_created':
      case 'announcement_published':
      case 'announcement_updated':
      case 'user_invited':
        return const Color(0xFFE0F7FA);

      // Inventory - Amber variants
      case 'inventory_low_stock':
      case 'inventory_request_submitted':
      case 'inventory_request_ready':
        return const Color(0xFFFFF8E1);

      default:
        return const Color(0xFFF2F4F7);
    }
  }

  /// Get icon color based on notification type
  Color get iconColor {
    switch (notificationType.toLowerCase()) {
      // Concern Slip - Blue variants
      case 'concern_slip_submitted':
      case 'concern_slip_assigned':
      case 'concern_slip_evaluated':
      case 'concern_slip_resolution_set':
      case 'concern_slip_returned':
        return const Color(0xFF005CE7);

      // Assessment - Purple variants
      case 'concern_slip_assessed':
        return const Color(0xFF7C3AED);

      // Work Order - Green variants
      case 'work_order_submitted':
      case 'work_order_assigned':
      case 'job_service_received':
      case 'job_service_completed':
      case 'permit_approved':
      case 'maintenance_completed':
      case 'inventory_restocked':
      case 'user_approved':
        return const Color(0xFF19B36E);

      // Schedule/Time - Orange variants
      case 'work_order_schedule_updated':
      case 'permit_expiring':
      case 'maintenance_overdue':
        return const Color(0xFFF79009);

      // Warnings/Errors - Red variants
      case 'work_order_canceled':
      case 'permit_rejected':
      case 'inventory_critical_stock':
        return const Color(0xFFE84545);

      // Information - Cyan variants
      case 'permit_created':
      case 'announcement_published':
      case 'announcement_updated':
      case 'user_invited':
        return const Color(0xFF0891B2);

      // Inventory - Amber variants
      case 'inventory_low_stock':
      case 'inventory_request_submitted':
      case 'inventory_request_ready':
        return const Color(0xFFD97706);

      default:
        return const Color(0xFF6B7280);
    }
  }

  /// Convert to legacy NotificationItem for backward compatibility
  /// This helps maintain compatibility with existing UI components
  NotificationItem toLegacyNotificationItem() {
    return NotificationItem(
      title: title,
      message: message,
      timestamp: createdAt,
      isRead: isRead,
      icon: typeIcon,
      iconBg: iconBackgroundColor,
      iconColor: iconColor,
    );
  }

  /// Check if notification is expired
  bool get isExpired {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  /// Check if notification requires immediate attention
  bool get isHighPriority {
    return isUrgent || priority == 'urgent' || priority == 'critical';
  }

  /// Get formatted time ago string
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
  }
}

/// Legacy model for backward compatibility
class NotificationItem {
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  NotificationItem({
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  NotificationItem copyWith({
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    IconData? icon,
    Color? iconBg,
    Color? iconColor,
  }) {
    return NotificationItem(
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      icon: icon ?? this.icon,
      iconBg: iconBg ?? this.iconBg,
      iconColor: iconColor ?? this.iconColor,
    );
  }
}

/// Filter enum for notifications
enum NotifFilter { all, unread }

/// List entry union for headers & items
abstract class ListEntry {}

class ListHeader extends ListEntry {
  final String label;
  ListHeader(this.label);
}

class ListItem extends ListEntry {
  final NotificationItem data;
  ListItem(this.data);
}

class EnhancedListItem extends ListEntry {
  final EnhancedNotificationItem data;
  EnhancedListItem(this.data);
}