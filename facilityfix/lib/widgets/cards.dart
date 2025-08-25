import 'package:facilityfix/widgets/helper_models.dart';
import 'package:facilityfix/widgets/tag.dart';
import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData? icon;
  final Color iconColor;
  final Color backgroundColor; // base for gradient
  final Color borderColor;

  const StatusCard({
    super.key,
    required this.title,
    required this.count,
    this.icon,
    this.iconColor = const Color(0xFF475467),
    this.backgroundColor = const Color(0xFFEFF5FF),
    this.borderColor = const Color(0xFF005CE7),
  });

  @override
  Widget build(BuildContext context) {
    final Color gStart = Color.lerp(backgroundColor, Colors.white, 0.88)!;
    final Color gEnd   = Color.lerp(backgroundColor, Colors.white, 0.70)!;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gStart, gEnd],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor.withOpacity(0.45), width: 1),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias, // ensures glow respects rounded corners
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475467),
                            fontFamily: 'Inter',
                            letterSpacing: -0.2,
                          ),
                        ),
                        const Spacer(),
                        // Count
                        Text(
                          count,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: const TextStyle(
                            fontSize: 26,
                            height: 1.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101828),
                            fontFamily: 'Inter',
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Icon (no border, just clean)
                  if (icon != null) ...[
                    const SizedBox(width: 12),
                    Align(
                      alignment: Alignment.topRight,
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: Icon(icon, size: 30, color: iconColor),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Announcement Card
class AnnouncementCard extends StatelessWidget {
  final String title;
  final String datePosted;   // e.g., "Aug 7, 2025"
  final String details;
  final String classification; // e.g., "utility interruption", "power outage", "pest control", "maintenance"
  final VoidCallback onTap;

  /// Optional knobs
  final int maxDetailLines;
  final bool showChevron;

  const AnnouncementCard({
    super.key,
    required this.title,
    required this.datePosted,
    required this.details,
    required this.classification,
    required this.onTap,
    this.maxDetailLines = 3,
    this.showChevron = true,
  });

  // Right-side-only radius used everywhere (Material, InkWell, Container)
  static const BorderRadius _rightOnly = BorderRadius.only(
    topRight: Radius.circular(16),
    bottomRight: Radius.circular(16),
  );

  // Normalize classification for map lookups
  String _norm(String s) => s.trim().toLowerCase();

  _ClassStyle get _style {
    final key = _norm(classification);
    return _styles[key] ?? _styles['default']!;
  }

  // Title Case helper for badge text
  String _titleCase(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    return parts
        .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;

    return Material(
      color: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: _rightOnly),
      clipBehavior: Clip.antiAlias, // ripple respects right-only radius
      child: InkWell(
        onTap: onTap,
        customBorder: const RoundedRectangleBorder(borderRadius: _rightOnly),
        child: Stack(
          children: [
            // Card container (right-only rounded)
            Container(
              decoration: BoxDecoration(
                color: style.tint,
                borderRadius: _rightOnly,
                border: Border.all(color: style.accent.withOpacity(0.18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: title + (optional chevron)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF101828),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                            if (showChevron) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.chevron_right, color: style.accent, size: 22),
                            ],
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Meta row: classification badge + date
                        Row(
                          children: [
                            // classification pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: style.badgeBg,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: style.accent.withOpacity(0.35)),
                              ),
                              child: Text(
                                _titleCase(classification),
                                style: TextStyle(
                                  color: style.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Posted $datePosted',
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF667085),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Details/preview
                        Text(
                          details,
                          maxLines: maxDetailLines,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF475467),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Left accent bar (straight edge; no rounding on the left)
            Positioned.fill(
              left: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 4,
                  color: style.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// --- Classification color system ------------------------------------------

class _ClassStyle {
  final Color accent;  // strong accent (bar/badge text)
  final Color tint;    // soft background
  final Color badgeBg; // pill background

  const _ClassStyle({
    required this.accent,
    required this.tint,
    required this.badgeBg,
  });
}

// Palette map (extend as needed)
const Map<String, _ClassStyle> _styles = {
  // Utility / water interruptions (blue)
  'utility interruption': _ClassStyle(
    accent: Color(0xFF005CE7),
    tint: Color(0xFFEFF4FF),
    badgeBg: Color(0xFFF4F5FF),
  ),

  // Power outage (amber)
  'power outage': _ClassStyle(
    accent: Color(0xFFF79009),
    tint: Color(0xFFFFF7E8),
    badgeBg: Color(0xFFFFFAEB),
  ),

  // Pest control (green)
  'pest control': _ClassStyle(
    accent: Color(0xFF12B76A),
    tint: Color(0xFFEAFBF3),
    badgeBg: Color(0xFFE8F7F1),
  ),

  // Maintenance (indigo/purple)
  'general maintenance': _ClassStyle(
    accent: Color(0xFF7A5AF8),
    tint: Color(0xFFF4F5FF),
    badgeBg: Color(0xFFF4F5FF),
  ),

  // Fallback neutral
  'default': _ClassStyle(
    accent: Color(0xFF667085),
    tint: Color(0xFFF2F4F7),
    badgeBg: Color(0xFFF7F9FC),
  ),
};

// Inventory Card
class InventoryCard extends StatefulWidget {
  final String itemName;
  final String stockStatus;    
  final String itemId;
  final String department;
  final String quantity;
  final VoidCallback? onTap;    

  const InventoryCard({
    super.key,
    required this.itemName,
    required this.stockStatus,  
    required this.itemId,
    required this.department,
    required this.quantity,
    this.onTap,
  });

  @override
  State<InventoryCard> createState() => _InventoryCardState();
}

class _InventoryCardState extends State<InventoryCard> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap ??
            () {
              debugPrint('InventoryCard tapped: ${widget.itemId}');
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: ShapeDecoration(
                color: const Color(0xFFF6F7F9),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: Colors.black.withOpacity(0.10),
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // itemName + stock status tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.itemName,
                          style: const TextStyle(
                            color: Color(0xFF101828),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.50,
                            fontFamily: 'Inter',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StockStatusTag(widget.stockStatus),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Item ID
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'ID: ${widget.itemId}',
                      style: const TextStyle(
                        color: Color(0xFF4A5154),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // category and quantity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: ShapeDecoration(
                          color: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: Text(
                          widget.department,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),

                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inventory_2,
                              size: 14,
                              color: Color(0xFF101828),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.quantity,
                              style: const TextStyle(
                                color: Color(0xFF101828),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.50,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        );
      }
    }

// Inventory Request Card
class InventoryRequestCard extends StatelessWidget {
  final String itemName;
  final String requestId;
  final String department; // department name (e.g., "Electrical", "Plumbing")
  final String status;     // "Pending", "Approved", "Rejected"
  final VoidCallback? onTap;

  const InventoryRequestCard({
    super.key,
    required this.itemName,
    required this.requestId,
    required this.department,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: ShapeDecoration(
          color: const Color(0xFFF6F7F9),
          shape: shape.copyWith(
            side: BorderSide(
              width: 1,
              color: Colors.black.withAlpha((0.10 * 255).toInt()),
            ),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: shape, // ensures splash follows the rounded shape
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Item Name + StatusTag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        itemName,
                        style: const TextStyle(
                          color: Color(0xFF101828),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.50,
                          fontFamily: 'Inter',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusTag(status: status),
                  ],
                ),

                const SizedBox(height: 4),

                // Request ID
                Text(
                  'ID: $requestId',
                  style: const TextStyle(
                    color: Color(0xFF4A5154),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1,
                    fontFamily: 'Inter',
                  ),
                ),

                const SizedBox(height: 8),

                // Department Tag
                DepartmentTag(department),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Notification Message card
class NotificationMessageCard extends StatelessWidget {
  const NotificationMessageCard({
    super.key,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.isUnread = false,
    this.onTap,
    this.leading,
    this.borderColor = const Color(0xFFE5E7E8),
    this.unreadTint = const Color(0xFFF7F9FF),
    this.titleColor = Colors.black,
    this.subtitleColor = const Color(0xFF515978),
    this.radius = 12,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    this.maxMessageLines = 3,
    this.showUnreadDot = true,
  });

  final String title;
  final String message;
  final String timeLabel;
  final bool isUnread;
  final VoidCallback? onTap;
  final Widget? leading;

  final Color borderColor;
  final Color unreadTint;
  final Color titleColor;
  final Color subtitleColor;

  final double radius;
  final EdgeInsets contentPadding;
  final int maxMessageLines;
  final bool showUnreadDot;

  @override
  Widget build(BuildContext context) {
    final cardBg = isUnread ? unreadTint : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          decoration: ShapeDecoration(
            color: cardBg,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: borderColor),
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          padding: contentPadding,
          child: Row(
            // 🔧 DO NOT USE stretch in a ListView/Sliver context
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                // Keep a finite size; never use double.infinity here
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: leading!,
                ),
              ],
              // Text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Title + Time (+ optional unread dot)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              height: 1.3,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeLabel,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12.5,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                                letterSpacing: 0.1,
                              ),
                            ),
                            if (isUnread && showUnreadDot) ...[
                              const SizedBox(width: 8),
                              const _UnreadDot(),
                            ]
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Message
                    Text(
                      message,
                      maxLines: maxMessageLines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8, height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF005CE7),
        shape: BoxShape.circle,
      ),
    );
  }
}

// Repair Card
class RepairCard extends StatelessWidget {
  // Required
  final String title;
  final String requestId;
  final String date;         
  final String status;     

  // For Admin side 
  final String? unit;       
  final String? priority;    
  final String? department;   
  final bool showAvatar;      
  final String? avatarUrl;   
  final String? requestType;

  // Actions
  final VoidCallback? onTap;      
  final VoidCallback? onChatTap;  

  const RepairCard({
    super.key,
    required this.title,
    required this.requestId,
    required this.date,
    required this.status,
    this.unit,
    this.priority,
    this.department,    
    this.showAvatar = false,
    this.avatarUrl,
    this.onTap,
    this.onChatTap,
    this.requestType,
  }); 

  @override
  Widget build(BuildContext context) {
    const cardBg    = Color(0xFFFFFFFF);
    const border    = Color(0xFFDDDEE0);
    const titleCol  = Color(0xFF101828);
    const sub1Color = Color(0xFF4A5154);
    const sub2Color = Color(0xFF667085);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: ShapeDecoration(
            color: cardBg,
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: border),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Title + Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: titleCol,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        PriorityTag(priority: priority!),
                        StatusTag(status: status),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Request ID
                Row(
                  children: [
                    const Icon(Icons.tag, size: 14, color: sub1Color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        requestId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: sub1Color,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // ── Unit / Location
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: sub2Color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        unit!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: sub2Color,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE6E7EA)),
                const SizedBox(height: 12),

                // ── Footer: (Avatar + Department) | (Date Pill + Chat IconPill)
                Row(
                  children: [
                    // Left group: avatar + department (like RepairCard)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showAvatar) ...[
                          Avatar(avatarUrl: avatarUrl),
                          const SizedBox(width: 8),
                        ],
                        DepartmentTag(department!),
                        const SizedBox(width: 8),
                        if (requestType != null) ...[
                          RequestTypeTag(requestType!),
                        ],
                      ],
                    ),

                    const Spacer(),

                    // Right group: Pill (date) + IconPill (chat)
                    Pill(icon: Icons.calendar_today, label: date, iconSize: 16),
                    const SizedBox(width: 8),
                    IconPill(icon: Icons.chat_bubble_outline, onTap: onChatTap),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Maintenance Task
class MaintenanceCard extends StatelessWidget {
  // Required core fields
  final String title;
  final String requestId;
  final String date;
  final String status; // "Scheduled" | "In Progress" | "Done"

  // Optional / can be null from callers
  final String? unit;
  final String? priority;   // "High" | "Medium" | "Low"
  final String? department; // e.g. "Maintenance"

  // Handlers (nullable is fine)
  final VoidCallback? onTap;
  final VoidCallback? onChatTap;

  // Avatar (same pattern as RepairCard)
  final bool showAvatar;
  final String? avatarUrl;

  const MaintenanceCard({
    super.key,
    required this.title,
    required this.requestId,
    required this.date,
    required this.status,
    this.unit,
    this.priority,
    this.department,
    this.onTap,
    this.onChatTap,
    this.showAvatar = false,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Safe fallbacks
    const cardBg    = Color(0xFFFFFFFF);
    const border    = Color(0xFFDDDEE0);
    const titleCol  = Color(0xFF101828);
    const sub1Color = Color(0xFF4A5154);
    const sub2Color = Color(0xFF667085);

    final String unitText = (unit == null || unit!.trim().isEmpty) ? '-' : unit!.trim();
    final String priorityText = (priority == null || priority!.trim().isEmpty) ? 'Medium' : priority!.trim();
    final String deptText = (department == null || department!.trim().isEmpty) ? '-' : department!.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, // null is OK (disabled)
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: ShapeDecoration(
            color: cardBg,
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: border),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Title + Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: titleCol,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        PriorityTag(priority: priorityText), // safe
                        StatusTag(status: status),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Request ID
                Row(
                  children: [
                    const Icon(Icons.tag, size: 14, color: sub1Color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        requestId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: sub1Color,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // ── Unit / Location
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: sub2Color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        unitText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: sub2Color,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE6E7EA)),
                const SizedBox(height: 12),

                // ── Footer: (Avatar + Department) | (Date Pill + Chat IconPill)
                Row(
                  children: [
                    // Left group: avatar + department (like RepairCard)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showAvatar) ...[
                          Avatar(avatarUrl: avatarUrl),
                          const SizedBox(width: 8),
                        ],
                        DepartmentTag(deptText),
                      ],
                    ),

                    const Spacer(),

                    // Right group: Pill (date) + IconPill (chat)
                    Pill(icon: Icons.calendar_today, label: date, iconSize: 16),
                    const SizedBox(width: 8),
                    IconPill(icon: Icons.chat_bubble_outline, onTap: onChatTap),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile Section Cards

/// Soft card section wrapper for groups like Personal Details, Settings, etc.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry? contentPadding;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: const Color(0xFFF9FAFB),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: contentPadding ?? EdgeInsets.zero,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsOption extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  const SettingsOption({
    super.key,
    required this.text,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF4B5563)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

