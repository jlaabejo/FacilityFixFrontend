/// Unified date parser + formatter 
class UiDateUtils {
  // ────────────────────────────────
  // Month lookup
  // ────────────────────────────────
  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  static const Map<String, int> _monthIndex = {
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'sept': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };

  // ────────────────────────────────
  //  PARSING
  // ────────────────────────────────

  static DateTime parse(String input, {int? defaultYear}) {
    final year = defaultYear ?? DateTime.now().year;
    final raw = input.trim();

    // 1️⃣ ISO-like check
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    // 2️⃣ Normalize spacing & separators
    var clean = raw
        .replaceAll(RegExp(r'\s*\|\s*'), ' ')
        .replaceAll(RegExp(r'\s*,\s*'), ',')
        .replaceAll(RegExp(r'\s+at\s+', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // 3️⃣ Pattern: "Mon Day[,Year] [Hour[:Min]][AM|PM]"
    final re = RegExp(
      r'^([A-Za-z]+)\s+(\d{1,2})(?:,(\d{4}))?(?:\s*(\d{1,2})(?::(\d{2}))?\s*(AM|PM|am|pm)?)?$'
    );
    final m = re.firstMatch(clean);
    if (m == null) return DateTime(1900, 1, 1);

    final monStr = m.group(1)!.toLowerCase();
    final day = int.tryParse(m.group(2) ?? '') ?? 1;
    final yr = int.tryParse(m.group(3) ?? '') ?? year;
    final mon = _monthIndex[monStr] ?? 12;

    var hour = int.tryParse(m.group(4) ?? '') ?? 0;
    var minute = int.tryParse(m.group(5) ?? '') ?? 0;
    final meridian = m.group(6)?.toLowerCase();

    if (meridian != null) {
      if (meridian.contains('pm') && hour < 12) hour += 12;
      if (meridian.contains('am') && hour == 12) hour = 0;
    }

    return DateTime(yr, mon, day, hour, minute);
  }

  // ────────────────────────────────
  //  COMPARATORS
  // ────────────────────────────────
  static int compareAsc(String a, String b, {int? defaultYear}) =>
      parse(a, defaultYear: defaultYear).compareTo(parse(b, defaultYear: defaultYear));

  static int compareDesc(String a, String b, {int? defaultYear}) =>
      parse(b, defaultYear: defaultYear).compareTo(parse(a, defaultYear: defaultYear));

  static void sortLatestFirst<T>(List<T> list, String Function(T) dateSelector, {int? defaultYear}) {
    list.sort((a, b) => compareDesc(dateSelector(a), dateSelector(b), defaultYear: defaultYear));
  }

  // ────────────────────────────────
  //  FORMATTING
  // ────────────────────────────────

  /// "Aug 23, 2025 · 8:30 PM"
  static String humanDateTime(DateTime d) {
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final mm = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${_months[d.month - 1]} ${d.day}, ${d.year} · $h12:$mm $ampm';
  }

  /// "Aug 23, 2025"
  static String fullDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  /// "Aug 23"
  static String shortDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}';

  /// "Aug 23, 2025 | 8 PM"
  static String dateWithTime(DateTime d) {
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${_months[d.month - 1]} ${d.day}, ${d.year} | $h12 $ampm';
  }

  /// Accepts a raw date string (e.g. from API or form) and outputs a clean schedule label.
  static String formatSchedule(String raw) {
    final dt = DateTime.tryParse(raw) ?? parse(raw);
    return dateWithTime(dt);
  }

  // ────────────────────────────────
  //  TIME AGO FORMATTER
  // ────────────────────────────────

  /// Returns human-readable elapsed time like:
  /// - "just now"
  /// - "5 minutes ago"
  /// - "3 hours ago"
  /// - "yesterday"
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else {
      // Anything older than yesterday
      return 'yesterday';
    }
  }
}

/// Utility class for formatting request IDs with proper prefixes
class UiIdFormatter {
  /// Formats an ID with the appropriate prefix based on request type
  /// 
  /// Examples:
  /// - Concern Slip: CS-2025-00204
  /// - Job Service: JS-2025-00001
  /// - Work Order Permit: WP-2025-00001
  /// 
  /// If the ID already has the correct prefix, returns it as-is.
  /// If formatted_id is provided, uses that instead.
  static String formatId(String id, String requestType, {String? formattedId}) {
    // If formatted_id is provided and not empty, use it
    if (formattedId != null && formattedId.trim().isNotEmpty) {
      return formattedId;
    }
    
    final type = requestType.toLowerCase().trim();
    final idUpper = id.toUpperCase();
    final idLower = id.toLowerCase();
    
    // Determine prefix based on request type
    String prefix;
    if (type.contains('concern slip') || type == 'concern slip') {
      prefix = 'CS';
    } else if (type.contains('job service') || type == 'job service') {
      prefix = 'JS';
    } else if (type.contains('work order') || type.contains('work permit') || 
               type == 'work order permit' || type == 'work order') {
      prefix = 'WP';
    } else {
      // Unknown type, return as-is
      return id;
    }
    
    // Check if ID already has the correct prefix format (e.g., CS-2025-00204)
    if (idUpper.startsWith('$prefix-') && RegExp(r'^[A-Z]{2,3}-\d{4}-\d+$', caseSensitive: false).hasMatch(id)) {
      return id;
    }
    
    // Check for underscore format (e.g., wp_uuid or cs_uuid)
    // If it starts with prefix_, extract the UUID part
    if (idLower.startsWith('${prefix.toLowerCase()}_')) {
      final uuidPart = id.substring(3); // Remove the "wp_" or "cs_" or "js_" part
      final year = DateTime.now().year;
      
      // Try to extract numeric part from UUID
      final numericMatch = RegExp(r'\d+').firstMatch(uuidPart);
      if (numericMatch != null) {
        final numericPart = numericMatch.group(0)!;
        final paddedId = numericPart.padLeft(5, '0');
        return '$prefix-$year-$paddedId';
      }
      
      // If no numeric part found, use a hash-like representation
      // Take first 8 characters of UUID for readability
      final shortId = uuidPart.length > 8 ? uuidPart.substring(0, 8) : uuidPart;
      return '$prefix-$year-$shortId';
    }
    
    final year = DateTime.now().year;
    
    // If the ID is purely numeric, format it nicely
    final numericMatch = RegExp(r'^\d+$').firstMatch(id);
    if (numericMatch != null) {
      // Pad with zeros to make it 5 digits
      final paddedId = id.padLeft(5, '0');
      return '$prefix-$year-$paddedId';
    }
    
    // For UUIDs or complex IDs (e.g., abc123def), try to extract numeric part
    final numInComplexId = RegExp(r'\d+').firstMatch(id);
    if (numInComplexId != null) {
      final numericPart = numInComplexId.group(0)!;
      final paddedId = numericPart.padLeft(5, '0');
      return '$prefix-$year-$paddedId';
    }
    
    // If no numeric part at all, take first 8 chars and use as-is
    final shortId = id.length > 8 ? id.substring(0, 8) : id;
    return '$prefix-$year-$shortId';
  }
  
  /// Formats a Concern Slip ID
  static String formatConcernSlipId(String id, {String? formattedId}) {
    return formatId(id, 'Concern Slip', formattedId: formattedId);
  }
  
  /// Formats a Job Service ID
  static String formatJobServiceId(String id, {String? formattedId}) {
    return formatId(id, 'Job Service', formattedId: formattedId);
  }
  
  /// Formats a Work Order Permit ID
  static String formatWorkOrderPermitId(String id, {String? formattedId}) {
    return formatId(id, 'Work Order Permit', formattedId: formattedId);
  }
}
