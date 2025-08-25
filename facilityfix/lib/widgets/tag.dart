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

// Stock Status
class StockStatusTag extends StatelessWidget {
  final String status; // In Stock | Out of Stock | Critical
  const StockStatusTag(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    if (s.contains('out')) {
      return const Tag(
        label: 'Out of Stock',
        bg: Color(0xFFF79009),
        fontSize: 12,
      );
    }
    if (s.contains('critical')) {
      return const Tag(
        label: 'Critical',
        bg: Color(0xFFF04438),
        fontSize: 12,
      );
    }
    return const Tag(
      label: 'In Stock',
      bg: Color(0xFF005CE7),
      fontSize: 12,
    );
  }
}

// Department Tags
class DepartmentTag extends StatelessWidget {
  final String department;
  const DepartmentTag(this.department, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFF666666);
    switch (department.toLowerCase()) {
      case 'general maintenance':
        bg = const Color(0xFF19B36E);
        break;
      case 'civil/carpentry':
        bg = const Color(0xFFF79009);
        break;
      case 'plumbing':
        bg = const Color(0xFF005CE7);
        break;
      case 'electrical':
        bg = const Color(0xFFF95555);
        break;
    }
    return Tag(label: department, bg: bg, fg: Colors.white);
  }
}

/// ---------- Small helper for label/value lines ----------
class KeyValueRow extends StatelessWidget {
  final String label;
  final Widget value;
  final double labelWidth;
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 120,
  });

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: Color(0xFF475467),
      fontSize: 13,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      height: 1.54,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: labelWidth, child: Text(label, style: labelStyle)),
        Flexible(child: Align(alignment: Alignment.centerRight, child: value)),
      ],
    );
  }
}

// Status Tag
class StatusTag extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsets padding;
  final double borderRadius;
  final FontWeight fontWeight;
  final double width;

  /// Optional overrides. If provided, these take precedence over the map.
  final Color? fgColor;
  final Color? bgColor;

  const StatusTag({
    super.key,
    required this.status,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.borderRadius = 100,
    this.fontWeight = FontWeight.w500,
    this.width = 90,
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
    'in progress': _StatusStyle(fg: Color(0xFF475467), bg: Color(0xFFEAECF0)),
    'on hold':      _StatusStyle(fg: Color(0xFFF79009), bg: Color(0xFFFFFAEB)),
    'assigned':    _StatusStyle(fg: Color(0xFF005CE7), bg: Color(0xFFF4F5FF)),
    'done':        _StatusStyle(fg: Color(0xFF19B36E), bg: Color(0xFFE8F7F1)),
    'pending':     _StatusStyle(fg: Color(0xFF7A5AF8), bg: Color(0xFFF4F5FF)),
    'scheduled':   _StatusStyle(fg: Color(0xFF005CE7), bg: Color(0xFFF4F5FF)),
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

  @override
  Widget build(BuildContext context) {
    final mapped = _styleFor(status);
    final fg = fgColor ?? mapped.fg;
    final bg = bgColor ?? mapped.bg;

    return Container(
      width: width, 
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        status,
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
  final double width;

  const PriorityTag({
    super.key,
    required this.priority,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.width = 80,
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
    return Container(
      width: width,                
      padding: padding,
      alignment: Alignment.center,  
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        priority,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
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

// Request Type Tag
class RequestTypeTag extends StatelessWidget {
  final String? type;

  // Style knobs (optional)
  final double fontSize;
  final EdgeInsets padding;
  final double borderRadius;
  final FontWeight fontWeight;
  final double? width;

  /// Optional color overrides
  final Color? fgColor;
  final Color? bgColor;

  /// If true and [type] is null/empty, render nothing.
  final bool hideIfEmpty;

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
  });

  // Default fallback
  static const _defaultStyle = _TypeStyle(
    fg: Color(0xFF667085),
    bg: Color(0xFFEAECF0),
  );

  // Map of request types
  static const Map<String, _TypeStyle> _styles = {
    'concern slip':       _TypeStyle(fg: Color(0xFF2563EB), bg: Color(0xFFE0F2FE)),
    'job service':        _TypeStyle(fg: Color(0xFF19B36E), bg: Color(0xFFE8F7F1)),
    'work order permit':  _TypeStyle(fg: Color(0xFFF79009), bg: Color(0xFFFFFAEB)),
  };

  static String _normalize(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'[_\-]+'), ' ').replaceAll(RegExp(r'\s+'), ' ');

  static _TypeStyle _styleFor(String? s) {
    if (s == null || s.trim().isEmpty) return _defaultStyle;
    return _styles[_normalize(s)] ?? _defaultStyle;
  }

  @override
  Widget build(BuildContext context) {
    if ((type == null || type!.trim().isEmpty) && hideIfEmpty) {
      return const SizedBox.shrink();
    }

    final mapped = _styleFor(type);
    final fg = fgColor ?? mapped.fg;
    final bg = bgColor ?? mapped.bg;
    final label = (type?.trim().isNotEmpty ?? false) ? type!.trim() : 'Unknown';

    final child = Container(
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'Inter',
          letterSpacing: -0.2,
        ),
      ),
    );

    // Optional fixed width
    return width == null ? child : SizedBox(width: width, child: child);
  }
}

// Internal style holder
class _TypeStyle {
  final Color fg;
  final Color bg;
  const _TypeStyle({required this.fg, required this.bg});
}
