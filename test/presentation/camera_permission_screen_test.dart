import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarak_app/presentation/camera_permission_screen/camera_permission_screen.dart';

void main() {
  group('CameraPermissionRequest', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CameraPermissionRequest(),
        ),
      );

      // Verify key elements are present
      expect(find.text('Camera Access Required'), findsOneWidget);
      expect(find.text('Allow Camera Access'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows learn more section when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CameraPermissionRequest(),
        ),
      );

      // Initially learn more should not be visible
      expect(find.text('How DistanceMeter Works'), findsNothing);

      // Tap the learn more button
      await tester.tap(find.text('Learn More'));
      await tester.pumpAndSettle();

      // Now learn more should be visible
      expect(find.text('How DistanceMeter Works'), findsOneWidget);
    });

    testWidgets('shows privacy badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CameraPermissionRequest(),
        ),
      );

      // Verify privacy badge is present
      expect(find.text('No images stored'), findsOneWidget);
    });
  });
}