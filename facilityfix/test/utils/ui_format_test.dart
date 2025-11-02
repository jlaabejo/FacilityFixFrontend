import 'package:flutter_test/flutter_test.dart';
import 'package:facilityfix/utils/ui_format.dart';

void main() {
  group('UiDateUtils', () {
    group('parse', () {
      test('parses ISO format dates correctly', () {
        final result = UiDateUtils.parse('2025-08-23T20:30:00');
        expect(result.year, 2025);
        expect(result.month, 8);
        expect(result.day, 23);
        expect(result.hour, 20);
        expect(result.minute, 30);
      });

      test('parses Month Day format with current year', () {
        final currentYear = DateTime.now().year;
        final result = UiDateUtils.parse('Aug 23');
        expect(result.year, currentYear);
        expect(result.month, 8);
        expect(result.day, 23);
      });

      test('parses Month Day, Year format', () {
        final result = UiDateUtils.parse('Aug 23, 2025');
        expect(result.year, 2025);
        expect(result.month, 8);
        expect(result.day, 23);
      });

      test('parses Month Day, Year with time (12-hour AM/PM)', () {
        final result = UiDateUtils.parse('Aug 23, 2025 8:30 PM');
        expect(result.year, 2025);
        expect(result.month, 8);
        expect(result.day, 23);
        expect(result.hour, 20);
        expect(result.minute, 30);
      });

      test('handles 12 PM correctly as noon', () {
        final result = UiDateUtils.parse('Aug 23, 2025 12:00 PM');
        expect(result.hour, 12);
      });

      test('handles 12 AM correctly as midnight', () {
        final result = UiDateUtils.parse('Aug 23, 2025 12:00 AM');
        expect(result.hour, 0);
      });

      test('handles pipe separator format', () {
        final result = UiDateUtils.parse('Aug 23, 2025 | 8:30 PM');
        expect(result.year, 2025);
        expect(result.month, 8);
        expect(result.day, 23);
        expect(result.hour, 20);
        expect(result.minute, 30);
      });

      test('handles full month names', () {
        final result = UiDateUtils.parse('August 23, 2025');
        expect(result.month, 8);
      });

      test('handles all month names correctly', () {
        final months = [
          ('Jan', 1), ('Feb', 2), ('Mar', 3), ('Apr', 4),
          ('May', 5), ('Jun', 6), ('Jul', 7), ('Aug', 8),
          ('Sep', 9), ('Oct', 10), ('Nov', 11), ('Dec', 12)
        ];
        
        for (final (abbr, expectedMonth) in months) {
          final result = UiDateUtils.parse('$abbr 15, 2025');
          expect(result.month, expectedMonth, reason: 'Failed for $abbr');
        }
      });

      test('returns fallback date for invalid format', () {
        final result = UiDateUtils.parse('invalid date string');
        expect(result.year, 1900);
        expect(result.month, 1);
        expect(result.day, 1);
      });

      test('handles extra whitespace gracefully', () {
        final result = UiDateUtils.parse('  Aug   23  ,  2025   8:30  PM  ');
        expect(result.year, 2025);
        expect(result.month, 8);
        expect(result.day, 23);
        expect(result.hour, 20);
        expect(result.minute, 30);
      });
    });

    group('compareAsc and compareDesc', () {
      test('correctly compares dates in ascending order', () {
        final result = UiDateUtils.compareAsc('Aug 22, 2025', 'Aug 23, 2025');
        expect(result, lessThan(0));
      });

      test('correctly compares dates in descending order', () {
        final result = UiDateUtils.compareDesc('Aug 23, 2025', 'Aug 22, 2025');
        expect(result, lessThan(0));
      });
    });

    group('sortLatestFirst', () {
      test('sorts list with latest dates first', () {
        final items = [
          {'date': 'Aug 20, 2025'},
          {'date': 'Aug 23, 2025'},
          {'date': 'Aug 21, 2025'},
        ];
        
        UiDateUtils.sortLatestFirst(items, (item) => item['date'] as String);
        
        expect(items[0]['date'], 'Aug 23, 2025');
        expect(items[1]['date'], 'Aug 21, 2025');
        expect(items[2]['date'], 'Aug 20, 2025');
      });
    });

    group('humanDateTime', () {
      test('formats date with time correctly in PM', () {
        final date = DateTime(2025, 8, 23, 20, 30);
        final result = UiDateUtils.humanDateTime(date);
        expect(result, 'Aug 23, 2025 · 8:30 PM');
      });

      test('handles noon correctly', () {
        final date = DateTime(2025, 8, 23, 12, 0);
        final result = UiDateUtils.humanDateTime(date);
        expect(result, 'Aug 23, 2025 · 12:00 PM');
      });

      test('handles midnight correctly', () {
        final date = DateTime(2025, 8, 23, 0, 0);
        final result = UiDateUtils.humanDateTime(date);
        expect(result, 'Aug 23, 2025 · 12:00 AM');
      });
    });

    group('dateTimeRange', () {
      test('formats single datetime', () {
        final start = DateTime(2025, 8, 23, 20, 30);
        final result = UiDateUtils.dateTimeRange(start);
        expect(result, 'Aug 23 | 8:30 PM');
      });

      test('formats datetime range', () {
        final start = DateTime(2025, 8, 23, 20, 0);
        final end = DateTime(2025, 8, 23, 22, 30);
        final result = UiDateUtils.dateTimeRange(start, end);
        expect(result, 'Aug 23 | 8 PM - 10:30 PM');
      });
    });

    group('timeAgo', () {
      test('returns "just now" for recent timestamps', () {
        final now = DateTime.now();
        final result = UiDateUtils.timeAgo(now.subtract(const Duration(seconds: 30)));
        expect(result, 'just now');
      });

      test('returns minutes ago for recent minutes', () {
        final now = DateTime.now();
        final result = UiDateUtils.timeAgo(now.subtract(const Duration(minutes: 5)));
        expect(result, '5 minutes ago');
      });

      test('returns "yesterday" for older dates', () {
        final now = DateTime.now();
        final result = UiDateUtils.timeAgo(now.subtract(const Duration(days: 5)));
        expect(result, 'yesterday');
      });
    });
  });

  group('UiIdFormatter', () {
    group('formatId', () {
      test('formats concern slip ID with numeric value', () {
        final result = UiIdFormatter.formatId('204', 'Concern Slip');
        final year = DateTime.now().year;
        expect(result, 'CS-$year-00204');
      });

      test('formats job service ID with numeric value', () {
        final result = UiIdFormatter.formatId('1', 'Job Service');
        final year = DateTime.now().year;
        expect(result, 'JS-$year-00001');
      });

      test('formats work order permit ID with numeric value', () {
        final result = UiIdFormatter.formatId('1', 'Work Order Permit');
        final year = DateTime.now().year;
        expect(result, 'WP-$year-00001');
      });

      test('returns existing properly formatted ID as-is', () {
        final result = UiIdFormatter.formatId('CS-2025-00204', 'Concern Slip');
        expect(result, 'CS-2025-00204');
      });

      test('handles underscore format IDs', () {
        final result = UiIdFormatter.formatId('cs_12345abc', 'Concern Slip');
        final year = DateTime.now().year;
        expect(result, contains('CS-$year-'));
      });

      test('extracts numeric part from complex IDs', () {
        final result = UiIdFormatter.formatId('abc123def', 'Concern Slip');
        final year = DateTime.now().year;
        expect(result, 'CS-$year-00123');
      });

      test('uses formattedId when provided', () {
        final result = UiIdFormatter.formatId(
          'raw_id',
          'Concern Slip',
          formattedId: 'CS-2025-99999',
        );
        expect(result, 'CS-2025-99999');
      });

      test('pads numeric IDs with zeros to 5 digits', () {
        final year = DateTime.now().year;
        expect(UiIdFormatter.formatId('1', 'Concern Slip'), 'CS-$year-00001');
        expect(UiIdFormatter.formatId('123', 'Concern Slip'), 'CS-$year-00123');
      });
    });

    group('convenience methods', () {
      test('formatConcernSlipId works correctly', () {
        final result = UiIdFormatter.formatConcernSlipId('204');
        final year = DateTime.now().year;
        expect(result, 'CS-$year-00204');
      });

      test('formatJobServiceId works correctly', () {
        final result = UiIdFormatter.formatJobServiceId('1');
        final year = DateTime.now().year;
        expect(result, 'JS-$year-00001');
      });

      test('formatWorkOrderPermitId works correctly', () {
        final result = UiIdFormatter.formatWorkOrderPermitId('1');
        final year = DateTime.now().year;
        expect(result, 'WP-$year-00001');
      });
    });
  });
}