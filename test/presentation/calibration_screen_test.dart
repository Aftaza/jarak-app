import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarak_app/presentation/calibration_screen/calibration_screen.dart';

void main() {
  group('CalibrationSetup', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalibrationSetup(),
        ),
      );

      // Verify app bar with title
      expect(find.text('Calibration Setup'), findsOneWidget);
      
      // Verify introduction step elements
      expect(find.text('Welcome to Calibration'), findsOneWidget);
      expect(find.text('Improve Measurement Accuracy'), findsOneWidget);
    });

    testWidgets('has back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Navigator(
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => CalibrationSetup(),
                  );
                },
              );
            },
          ),
        ),
      );

      // Verify back button is present
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows step progression', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalibrationSetup(),
        ),
      );

      // Verify initial step
      expect(find.text('Start Calibration'), findsOneWidget);
      
      // Tap next button
      await tester.tap(find.text('Start Calibration'));
      await tester.pumpAndSettle();

      // Verify we moved to next step
      expect(find.text('Select Reference Object'), findsOneWidget);
    });

    testWidgets('shows reference object cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalibrationSetup(),
        ),
      );

      // Navigate to object selection step
      await tester.tap(find.text('Start Calibration'));
      await tester.pumpAndSettle();

      // Verify reference objects are shown
      expect(find.text('Credit Card'), findsOneWidget);
      expect(find.text('US Quarter'), findsOneWidget);
      expect(find.text('Business Card'), findsOneWidget);
    });
  });
}