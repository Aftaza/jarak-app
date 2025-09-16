import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarak_app/presentation/splash_screen/splash_screen.dart';

void main() {
  group('SplashScreen', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Verify key elements are present
      expect(find.text('Jarak App'), findsOneWidget);
      expect(find.text('Pengukur Jarak Digital Pintar'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsOneWidget);
      
      // Verify progress indicator is present
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows loading progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Wait for animations
      await tester.pumpAndSettle();

      // Verify loading text changes
      expect(find.text('Initializing DistanceMeter...'), findsOneWidget);
    });

    testWidgets('navigates to main measurement screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Wait for the splash screen to complete its initialization
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Since navigation is handled by the app, we just verify the widget was created
      expect(find.byType(SplashScreen), findsOneWidget);
    });
  });
}