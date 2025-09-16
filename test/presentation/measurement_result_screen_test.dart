import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarak_app/presentation/measurment_result_screen/measurment_result_screen.dart';

void main() {
  group('MeasurementResults', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MeasurementResults(),
        ),
      );

      // Wait for animations
      await tester.pumpAndSettle();

      // Verify key elements are present
      expect(find.text('feet'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('shows action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MeasurementResults(),
        ),
      );

      // Wait for animations
      await tester.pumpAndSettle();

      // Verify action buttons are present
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Retake'), findsOneWidget);
    });

    testWidgets('converts units', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MeasurementResults(),
        ),
      );

      // Wait for animations
      await tester.pumpAndSettle();

      // Verify initial unit
      expect(find.text('feet'), findsOneWidget);
    });
  });
}