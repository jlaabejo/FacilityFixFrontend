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
        default:
        bg = const Color(0xFFE0E0E0); // Soft light grey
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
Widget StatusTag(String status) {
  // Normalize input to be tolerant of canonical lowercase tokens or Title-Cased labels
  final s = (status ?? '').toString().trim().toLowerCase();

  Color bgColor;
  Color textColor;
  String displayLabel;

  if (s.contains('in progress') || s.contains('in_progress')) {
    bgColor = const Color(0xFFFFF3E0);
    textColor = const Color(0xFFFF8F00);
    displayLabel = 'In Progress';
  } else if (s.contains('pending')) {
    bgColor = const Color(0xFFFFEBEE);
    textColor = const Color(0xFFD32F2F);
    displayLabel = 'Pending';
  } else if (s.contains('assigned') || s.contains('to inspect') || s.contains('to_inspect')) {
    bgColor = const Color(0xFFE3F2FD);
    textColor = const Color(0xFF1976D2);
    displayLabel = 'To Inspect';
  } else if (s.contains('inspected') || s.contains('completed') || s.contains('assessed') || s.contains('sent') || s.contains('done') || s.contains('return to tenant')) {
    bgColor = const Color(0xFFF3E5F5);
    textColor = const Color(0xFF7B1FA2);
    displayLabel = 'Inspected';
  } else if (s.contains('pending js') || s.contains('pendingjs') || s.contains('job service')) {
    bgColor = const Color(0xFFFFF8E1);
    textColor = const Color(0xFFFF8F00);
    displayLabel = 'Pending JS';
  } else if (s.contains('pending wop') || s.contains('pendingwop') || s.contains('work order')) {
    bgColor = const Color(0xFFE0F2F1);
    textColor = const Color(0xFF00695C);
    displayLabel = 'Pending WO';
  } else if (s.contains('approved') || s.contains('accept')) {
    bgColor = const Color(0xFFE8F5E8);
    textColor = const Color(0xFF2E7D32);
    displayLabel = 'Approved';
  } else if (s.contains('reject')) {
    bgColor = const Color(0xFFFFEBEE);
    textColor = const Color(0xFFD32F2F);
    displayLabel = 'Rejected';
  } else {
    bgColor = Colors.grey[100]!;
    textColor = Colors.grey[700]!;
    // Title-case the incoming value for display if possible
    displayLabel = status
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
    if (displayLabel.isEmpty) displayLabel = 'Unknown';
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      displayLabel,
      style: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

// Priority Tag

  Widget PriorityTag(String priority) {
  // Normalize input to be case-insensitive and robust
  final key = priority.toString().trim().toLowerCase();
    Color bgColor;
    Color textColor;
    String displayLabel;

    switch (key) {
      case 'high':
        bgColor = const Color(0xFFFFEBEE); // light red
        textColor = const Color(0xFFD32F2F); // red
        displayLabel = 'High';
        break;
      case 'medium':
        bgColor = const Color(0xFFFFF3E0); // light orange
        textColor = const Color(0xFFFF8F00); // orange
        displayLabel = 'Medium';
        break;
      case 'low':
        bgColor = const Color(0xFFE8F5E8); // light green
        textColor = const Color(0xFF2E7D32); // green
        displayLabel = 'Low';
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
        // If caller passed a custom string, title-case it for display
        if (key.isEmpty) {
          displayLabel = 'Unknown';
        } else {
          displayLabel = key.split(RegExp(r'\s+')).map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
        }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayLabel,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
class MaintenanceTypeTag extends StatelessWidget {
  final String type;

  const MaintenanceTypeTag(this.type, {super.key});

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
    'work order': _TypeStyle(fg: Color(0xFFB45309), bg: Color(0xFFFEF3C7)),
  };

  static String _normalize(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  static _TypeStyle _styleFor(String? s) {
    if (s == null || s.trim().isEmpty) return _defaultStyle;
    final normalized = _normalize(s);
    return _styles[normalized] ?? _defaultStyle;
  }

  static String _toTitleCase(String input) {
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

    // Use intrinsic width if width is not specified, otherwise use fixed width
    return width != null 
        ? SizedBox(width: width, child: pill)
        : IntrinsicWidth(child: pill);
  }
}

// Internal style holder
class _TypeStyle {
  final Color fg;
  final Color bg;

  const _TypeStyle({required this.fg, required this.bg});
}


// Role Tag Widget -----------------------------------------
class RoleTag extends StatelessWidget {
  final String role;
  final Map<String, Map<String, Color>>? customStyles;

  const RoleTag({
    Key? key,
    required this.role,
    this.customStyles,
  }) : super(key: key);

  static final Map<String, Map<String, Color>> _defaultRoleStyles = {
    'Admin': {
      'bg': Color(0xFFDDEAFE), // light blue
      'text': Color(0xFF1D4ED8), // dark blue
    },
    'Staff': {
      'bg': Color(0xFFE5E7EB), // light gray
      'text': Color(0xFF374151), // dark gray
    },
    'Tenant': {
      'bg': Color(0xFFFEF9C3), // light yellow
      'text': Color(0xFFB45309), // orange
    },
  };

  @override
  Widget build(BuildContext context) {
    final styles = customStyles ?? _defaultRoleStyles;
    final style = styles[role] ?? {
      'bg': Colors.grey.shade200,
      'text': Colors.grey.shade700,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style['bg'],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: style['text'],
        ),
      ),
    );
  }
}

