import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarak_app/widgets/custom_icon_widget.dart';

void main() {
  group('CustomIconWidget', () {
    testWidgets('renders icon correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconWidget(
              iconName: 'arrow_back',
              size: 24,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('renders fallback icon for unknown icon name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconWidget(
              iconName: 'unknown_icon',
              size: 24,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('applies size and color correctly', (WidgetTester tester) async {
      const testSize = 32.0;
      const testColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomIconWidget(
              iconName: 'check',
              size: testSize,
              color: testColor,
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.check);
      expect(iconFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.size, testSize);
      expect(iconWidget.color, testColor);
    });
  });
}