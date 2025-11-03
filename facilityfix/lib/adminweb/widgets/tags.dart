import 'package:flutter/material.dart';

/// Tags
class Tag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color? fg; // made optional
  final EdgeInsets padding;
  final double radius;
  final double fontSize;

  const Tag({
    super.key,
    required this.label,
    required this.bg,
    this.fg, // optional now
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.radius = 100,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      padding: padding,
      child: Text(
        label,
        style: TextStyle(
          color: fg ?? Colors.white, // default to white if not given
          fontSize: fontSize,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

// Inventory Classification Tag
class InventoryClassification extends StatelessWidget {
  final String classification;

  const InventoryClassification(this.classification, {super.key});

  Color _getBackgroundColor(String classification) {
    final normalized = classification.toLowerCase().replaceAll('_', ' ').trim();
    
    switch (normalized) {
      case 'consumable':
      case 'con':
        return const Color(0xFFE3F2FD); // light blue
      case 'equipment':
      case 'equip':
        return const Color(0xFFFFF3E0); // light orange
      case 'tool':
        return const Color(0xFFE8F5E9); // light green
      case 'material':
      case 'mat':
        return const Color(0xFFFFF3E0); // light orange
      case 'chemical':
      case 'chem':
        return const Color(0xFFF3E5F5); // light purple
      case 'spare part':
      case 'spare parts':
      case 'sparepart':
      case 'spareparts':
        return const Color(0xFFF3E5F5); // light purple
      default:
        return const Color(0xFFF5F5F7); // light gray
    }
  }

  Color _getTextColor(String classification) {
    final normalized = classification.toLowerCase().replaceAll('_', ' ').trim();
    
    switch (normalized) {
      case 'consumable':
      case 'con':
        return const Color(0xFF1976D2); // blue
      case 'equipment':
      case 'equip':
        return const Color(0xFFEF6C00); // orange
      case 'tool':
        return const Color(0xFF2E7D32); // green
      case 'material':
      case 'mat':
        return const Color(0xFFEF6C00); // orange
      case 'chemical':
      case 'chem':
        return const Color(0xFF7B1FA2); // purple
      case 'spare part':
      case 'spare parts':
      case 'sparepart':
      case 'spareparts':
        return const Color(0xFF7B1FA2); // purple
      default:
        return const Color(0xFF7D7D7D); // gray
    }
  }
  
  String _getDisplayText(String classification) {
    final normalized = classification.toLowerCase().replaceAll('_', ' ').trim();
    
    // Map abbreviations to full names
    switch (normalized) {
      case 'con':
        return 'Consumable';
      case 'equip':
        return 'Equipment';
      case 'mat':
        return 'Material';
      case 'chem':
        return 'Chemical';
      case 'spare part':
      case 'spare parts':
      case 'sparepart':
      case 'spareparts':
        return 'Spare Part';
      default:
        // Convert to Title Case for other classifications
        return normalized
            .split(RegExp(r'\s+'))
            .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _getDisplayText(classification);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(classification),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _getTextColor(classification),
        ),
      ),
    );
  }
}

// Department Tags
class DepartmentTag extends StatelessWidget {
  final String department;
  const DepartmentTag(this.department, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFE0E0E0); // Soft light grey default
    final departmentLower = department.toLowerCase();
    
    switch (departmentLower) {
      case 'carpentry':
        bg = const Color(0xFFFFE0B2); // Softer peachy orange
        break;
      case 'plumbing':
        bg = const Color(0xFFBBDEFB); // Softer sky blue
        break;
      case 'electrical':
        bg = const Color(0xFFFFCDD2); // Softer pink/light red
        break;
      case 'masonry':
        bg = const Color(0xFFCFD8DC); // Softer blue-grey
        break;
      case 'pest control':
        bg = const Color(0xFFC8E6C9); // Softer mint green
        break;
      case 'house keeping':
        bg = const Color(0xFFE1BEE7); // Soft lavender/purple
        break;
    }
    
    // Capitalize the first letter of each word for display
    String displayText = department
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
    
    return Tag(label: displayText, bg: bg, fg: Colors.black87);
  }
}

// Status Tag
class StatusTag extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;
  final double borderRadius;
  final FontWeight fontWeight;

  /// Optional overrides. If provided, these take precedence over the map.
  final Color? fgColor;
  final Color? bgColor;

  const StatusTag({
    super.key,
    required this.status,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius = 20,
    this.fontWeight = FontWeight.w500,
    this.fgColor,
    this.bgColor,
  });

  // Default style (fallback)
  static const _defaultStyle = _StatusStyle(
    fg: Color(0xFF667085),
    bg: Color(0xFFEAECF0),
  );

  // Map of normalized status -> colors
static const Map<String, _StatusStyle> _styles = {
  // Inventory request statuses (only these three)
  'pending':         _StatusStyle(fg: Color(0xFF667085), bg: Color(0xFFF2F4F7)), 
  'approved':        _StatusStyle(fg: Color(0xFF12B76A), bg: Color(0xFFEFFAF5)), 
  'rejected':        _StatusStyle(fg: Color(0xFFD92D20), bg: Color(0xFFFEF3F2)),
  
  // Work order statuses
  'new':             _StatusStyle(fg: Color(0xFF1570EF), bg: Color(0xFFEFF4FF)),
  'assigned':        _StatusStyle(fg: Color(0xFF7A5AF8), bg: Color(0xFFF4F5FF)), 
  'in progress':     _StatusStyle(fg: Color(0xFF1570EF), bg: Color(0xFFEFF4FF)),
  'on hold':         _StatusStyle(fg: Color(0xFFF79009), bg: Color(0xFFFFFAEB)), 
  'scheduled':       _StatusStyle(fg: Color(0xFF7A5AF8), bg: Color(0xFFF4F5FF)), 
  'completed':       _StatusStyle(fg: Color(0xFF12B76A), bg: Color(0xFFEFFAF5)),
  
  // Inspection statuses
  'to be inspect':   _StatusStyle(fg: Color(0xFF667085), bg: Color(0xFFF2F4F7)),
  'inspected':       _StatusStyle(fg: Color(0xFF12B76A), bg: Color(0xFFEFFAF5)),
  
  // Other approval statuses
  'for work order form': _StatusStyle(fg: Color(0xFF667085), bg: Color(0xFFF2F4F7)),
  'for approval':    _StatusStyle(fg: Color(0xFFF79009), bg: Color(0xFFFFFAEB)),
};
  // Normalize "In-Progress", "in_progress", "in progress" → "in progress"
  static String _normalize(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'[_\-]+'), ' ').replaceAll(RegExp(r'\s+'), ' ');

  static _StatusStyle _styleFor(String s) => _styles[_normalize(s)] ?? _defaultStyle;

  /// Public helper to fetch colors elsewhere (e.g. for borders/icons)
  static StatusStyle colorsFor(String status) {
    final st = _styleFor(status);
    return StatusStyle(fg: st.fg, bg: st.bg);
  }

  /// Convert to Title Case for display
  static String _toTitleCase(String input) {
    // First normalize: replace underscores and hyphens with spaces
    final normalized = input
        .trim()
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    
    // Then convert to title case
    return normalized
        .split(' ')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final mapped = _styleFor(status);
    final fg = fgColor ?? mapped.fg;
    final bg = bgColor ?? mapped.bg;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        _toTitleCase(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'Inter',
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

// Public style to use outside the widget
class StatusStyle {
  final Color fg;
  final Color bg;
  const StatusStyle({required this.fg, required this.bg});
}

// Internal holder for the map
class _StatusStyle {
  final Color fg; // text color
  final Color bg; // background color
  const _StatusStyle({required this.fg, required this.bg});
}

// Priority Tag
class PriorityTag extends StatelessWidget {
  final String priority;
  final double fontSize;
  final EdgeInsets padding;

  const PriorityTag({
    super.key,
    required this.priority,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  Color _getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFF04438); // red
      case 'medium':
        return const Color(0xFFF79009); // orange
      case 'low':
        return const Color(0xFF12B76A); // green
      default:
        return const Color(0xFF667085); // gray
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getPriorityColor();
    
    // Capitalize the first letter for display
    String displayText = priority.isNotEmpty 
      ? priority[0].toUpperCase() + priority.substring(1).toLowerCase()
      : priority;
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}


// Announcement Type ----------------------------------------------
class AnnouncementType extends StatelessWidget {
  final String classification;

  const AnnouncementType(this.classification, {super.key});

  Color _getBackgroundColor(String classification) {
    switch (classification.toLowerCase()) {
      case 'utility interruption':
        return const Color(0xFFEFF5FF); // blue background
      case 'power outage':
        return const Color(0xFFFDF6A3); // yellow background
      case 'pest control':
        return const Color(0xFF91E5B0); // green background
      case 'maintenance':
        return const Color(0xFFFFD4B1); // orange-ish
      default:
        return const Color(0xFFF5F5F7); // gray background
    }
  }

  Color _getTextColor(String classification) {
    switch (classification.toLowerCase()) {
      case 'utility interruption':
        return const Color(0xFF005CE7); // blue text
      case 'power outage':
        return const Color(0xFFF3B40D); // yellow text
      case 'pest control':
        return const Color(0xFF00A651); // green text
      case 'maintenance':
        return const Color(0xFFF97316); // orange-ish
      default:
        return const Color(0xFF7D7D7D); // gray text
    }
  }

  @override
  Widget build(BuildContext context) {
    // Convert to Title Case for display
    String displayText = classification
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(classification),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _getTextColor(classification),
        ),
      ),
    );
  }
}

// Stock Status
class StockStatusTag extends StatelessWidget {
  final String status; // In Stock | Out of Stock | Critical | Low Stock
  const StockStatusTag(this.status, {super.key});

  Color _getBackgroundColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('in') && s.contains('stock')) {
      return const Color(0xFFE3F2FD); // light blue
    }
    if (s.contains('low')) {
      return const Color(0xFFFFF3E0); // light orange
    }
    if (s.contains('out')) {
      return const Color(0xFFFFEBEE); // light red
    }
    if (s.contains('critical')) {
      return const Color(0xFFFFEBEE); // light red
    }
    return const Color(0xFFF5F5F7); // light gray
  }

  Color _getTextColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('in') && s.contains('stock')) {
      return const Color(0xFF1976D2); // blue
    }
    if (s.contains('low')) {
      return const Color(0xFFE65100); // orange
    }
    if (s.contains('out')) {
      return const Color(0xFFD32F2F); // red
    }
    if (s.contains('critical')) {
      return const Color(0xFFD32F2F); // red
    }
    return const Color(0xFF7D7D7D); // gray
  }

  @override
  Widget build(BuildContext context) {
    // Convert to Title Case for display
    String displayText = status
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(status),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getTextColor(status),
        ),
      ),
    );
  }
}

// Maintenance Type Status Widget 
class MaintenanceType extends StatelessWidget {
  final String type;

  const MaintenanceType(this.type, {super.key});

  Color _getBackgroundColor(String type) {
    switch (type.toLowerCase()) {
      case 'internal':
        return const Color(0xFFE8F5E9); // light green background
      case 'external':
        return const Color(0xFFE3F2FD); // light blue background
      case 'safety compliance':
        return const Color(0xFFFFF3E0); // light orange background
      default:
        return const Color(0xFFF5F5F7); // gray background
    }
  }

  Color _getTextColor(String type) {
    switch (type.toLowerCase()) {
      case 'internal':
        return const Color(0xFF2E7D32); // green text
      case 'external':
        return const Color(0xFF1976D2); // blue text
      case 'safety compliance':
        return const Color(0xFFE65100); // orange text
      default:
        return const Color(0xFF7D7D7D); // gray text
    }
  }

  @override
  Widget build(BuildContext context) {
    // Convert to Title Case for display
    String displayText = type
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(type),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _getTextColor(type),
        ),
      ),
    );
  }
}

// Request Type Tag -----------------------------------------

enum DisplayCasing { original, title, upper, lower }

class RequestTypeTag extends StatelessWidget {
  final String? type;

  // Style knobs
  final double fontSize;
  final EdgeInsets padding;
  final double borderRadius;
  final FontWeight fontWeight;
  final double? width;

  // Optional color overrides
  final Color? fgColor;
  final Color? bgColor;

  /// If true and [type] is null/empty, render nothing.
  final bool hideIfEmpty;

  /// Text wrapping
  final int? maxLines;
  final TextOverflow? overflow;

  /// How to render the label text (default = Title Case like "Concern Slip")
  final DisplayCasing displayCasing;

  const RequestTypeTag(
    this.type, {
    super.key,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius = 999,
    this.fontWeight = FontWeight.w500,
    this.width,
    this.fgColor,
    this.bgColor,
    this.hideIfEmpty = false,
    this.maxLines,
    this.overflow,
    this.displayCasing = DisplayCasing.title,
  });

  // Default fallback
  static const _defaultStyle = _TypeStyle(
    fg: Color(0xFF667085),
    bg: Color(0xFFEAECF0),
  );

  // Map of request types (lookup is done on the normalized key)
  static const Map<String, _TypeStyle> _styles = {
    'concern slip': _TypeStyle(fg: Color(0xFF2563EB), bg: Color(0xFFE0F2FE)),
    'job service': _TypeStyle(fg: Color(0xFF19B36E), bg: Color(0xFFE8F7F1)),
    'work order':  _TypeStyle(fg: Color(0xFFF79009), bg: Color(0xFFFFFAEB)),
    'maintenance': _TypeStyle(fg: Color(0xFF9333EA), bg: Color(0xFFF3E8FF)),
  };

  static String _normalize(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  static _TypeStyle _styleFor(String? s) {
    if (s == null || s.trim().isEmpty) return _defaultStyle;
    final normalized = _normalize(s);
    // Remove noisy prints; if you still want them in debug only:
    // if (kDebugMode) debugPrint('Normalized "$s" to "$normalized"');
    return _styles[normalized] ?? _defaultStyle;
  }

  static String _toTitleCase(String input) {
    // Basic Title Case: split by whitespace and capitalize each word.
    // Keeps words like "of", "and" capitalized as well (simple rule fits our tags).
    return input
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _displayLabel(String raw) {
    switch (displayCasing) {
      case DisplayCasing.original:
        return raw;
      case DisplayCasing.title:
        return _toTitleCase(raw);
      case DisplayCasing.upper:
        return raw.toUpperCase();
      case DisplayCasing.lower:
        return raw.toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final raw = (type?.trim() ?? '');
    if (raw.isEmpty && hideIfEmpty) return const SizedBox.shrink();

    final mapped = _styleFor(type);
    final fg = fgColor ?? mapped.fg;
    final bg = bgColor ?? mapped.bg;

    // Render label in your preferred casing (default Title Case → "Concern Slip")
    final label = raw.isEmpty ? 'Unknown' : _displayLabel(raw);

    final text = Text(
      label,
      maxLines: maxLines ?? 1,
      overflow: overflow ?? TextOverflow.ellipsis,
      style: TextStyle(
        color: fg,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamily: 'Inter',
        letterSpacing: -0.2,
      ),
    );

    final pill = Container(
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: text,
    );

    return SizedBox(width: 100, child: pill);
  }
}

// Internal style holder
class _TypeStyle {
  final Color fg;
  final Color bg;
  const _TypeStyle({required this.fg, required this.bg});
}