import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.announcement_outlined,
              size: 64,
              color: Color(0xFF9AA0A6),
            ),
            SizedBox(height: 12),
            Text(
              'Nothing to see here yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'No announcements match your current filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF697076)),
            ),
          ],
        ),
      ),
    );
  }
}


class SegmentChip extends StatelessWidget {
  const SegmentChip({super.key, 
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color:
            selected
                ? const Color(0xFF005CE7).withOpacity(0.10)
                : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? const Color(0xFF005CE7) : const Color(0xFFE4E7EC),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onSelected,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected ? const Color(0xFF005CE7) : const Color(0xFF475467),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// Notification
// ===== Models / helpers =====

enum NotifFilter { all, unread }

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

// List entry union for headers & items
abstract class ListEntry {}

class ListHeader extends ListEntry {
  final String label;
  ListHeader(this.label);
}

class ListItem extends ListEntry {
  final NotificationItem data;
  ListItem(this.data);
}
