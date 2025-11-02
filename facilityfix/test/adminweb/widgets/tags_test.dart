import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:facilityfix/adminweb/widgets/tags.dart';

void main() {
  group('Tag Widget', () {
    testWidgets('renders with required properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Tag(
              label: 'Test Label',
              bg: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('uses white as default foreground color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Tag(
              label: 'Test',
              bg: Colors.blue,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Test'));
      expect(textWidget.style?.color, Colors.white);
    });

    testWidgets('uses custom foreground color when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Tag(
              label: 'Test',
              bg: Colors.blue,
              fg: Colors.black,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Test'));
      expect(textWidget.style?.color, Colors.black);
    });
  });

  group('InventoryClassification Widget', () {
    testWidgets('renders consumable classification correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InventoryClassification('Consumable'),
          ),
        ),
      );

      expect(find.text('Consumable'), findsOneWidget);
    });

    testWidgets('handles abbreviated classification "con"', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InventoryClassification('con'),
          ),
        ),
      );

      expect(find.text('Consumable'), findsOneWidget);
    });

    testWidgets('handles spare part classification variations', (WidgetTester tester) async {
      for (final variant in ['spare part', 'spare parts', 'sparepart']) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InventoryClassification(variant),
            ),
          ),
        );
        
        expect(find.text('Spare Part'), findsOneWidget);
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('converts unknown classification to title case', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InventoryClassification('custom item'),
          ),
        ),
      );

      expect(find.text('Custom Item'), findsOneWidget);
    });
  });

  group('DepartmentTag Widget', () {
    testWidgets('renders department name in title case', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DepartmentTag('carpentry'),
          ),
        ),
      );

      expect(find.text('Carpentry'), findsOneWidget);
    });

    testWidgets('handles multi-word departments', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DepartmentTag('pest control'),
          ),
        ),
      );

      expect(find.text('Pest Control'), findsOneWidget);
    });
  });

  group('StatusTag Widget', () {
    testWidgets('renders status in title case', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusTag(status: 'pending'),
          ),
        ),
      );

      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('normalizes status with underscores', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusTag(status: 'in_progress'),
          ),
        ),
      );

      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('handles all defined statuses', (WidgetTester tester) async {
      final statuses = [
        'pending',
        'approved',
        'rejected',
        'new',
        'assigned',
        'in progress',
        'completed',
      ];

      for (final status in statuses) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusTag(status: status),
            ),
          ),
        );
        
        expect(find.byType(Container), findsWidgets);
        await tester.pumpWidget(Container());
      }
    });

    test('colorsFor returns correct colors for status', () {
      final colors = StatusTag.colorsFor('pending');
      expect(colors.fg, isA<Color>());
      expect(colors.bg, isA<Color>());
    });
  });

  group('PriorityTag Widget', () {
    testWidgets('renders priority in title case', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PriorityTag(priority: 'high'),
          ),
        ),
      );

      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('handles all priority levels', (WidgetTester tester) async {
      final priorities = ['high', 'medium', 'low'];

      for (final priority in priorities) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PriorityTag(priority: priority),
            ),
          ),
        );
        
        expect(find.byType(Container), findsWidgets);
        await tester.pumpWidget(Container());
      }
    });
  });

  group('RequestTypeTag Widget', () {
    testWidgets('renders request type in title case by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RequestTypeTag('concern slip'),
          ),
        ),
      );

      expect(find.text('Concern Slip'), findsOneWidget);
    });

    testWidgets('handles null type with hideIfEmpty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RequestTypeTag(null, hideIfEmpty: true),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('shows "Unknown" for null type when not hiding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RequestTypeTag(null),
          ),
        ),
      );

      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('respects displayCasing parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RequestTypeTag(
              'concern slip',
              displayCasing: DisplayCasing.upper,
            ),
          ),
        ),
      );

      expect(find.text('CONCERN SLIP'), findsOneWidget);
    });
  });

  group('StockStatusTag Widget', () {
    testWidgets('renders various stock statuses', (WidgetTester tester) async {
      final statuses = ['in stock', 'out of stock', 'low stock', 'critical'];

      for (final status in statuses) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StockStatusTag(status),
            ),
          ),
        );
        
        expect(find.byType(Container), findsWidgets);
        await tester.pumpWidget(Container());
      }
    });
  });

  group('MaintenanceType Widget', () {
    testWidgets('renders maintenance types correctly', (WidgetTester tester) async {
      final types = ['internal', 'external', 'safety compliance'];

      for (final type in types) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MaintenanceType(type),
            ),
          ),
        );
        
        expect(find.byType(Container), findsWidgets);
        await tester.pumpWidget(Container());
      }
    });
  });

  group('AnnouncementType Widget', () {
    testWidgets('renders announcement types with proper formatting', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnnouncementType('utility interruption'),
          ),
        ),
      );

      expect(find.text('Utility Interruption'), findsOneWidget);
    });
  });
}