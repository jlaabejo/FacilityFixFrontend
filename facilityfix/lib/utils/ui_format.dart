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
