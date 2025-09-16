import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarak_app/presentation/settings_screen/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(),
        ),
      );

      // Verify app bar with title
      expect(find.text('Settings'), findsOneWidget);
      
      // Verify settings sections
      expect(find.text('Measurement Preferences'), findsOneWidget);
      expect(find.text('Camera Settings'), findsOneWidget);
      expect(find.text('Display Options'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Advanced Settings'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('has back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Navigator(
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => SettingsScreen(),
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

    testWidgets('shows reset to defaults button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(),
        ),
      );

      // Verify reset button is present
      expect(find.text('Reset to Defaults'), findsOneWidget);
    });

    testWidgets('shows about dialog when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(),
        ),
      );

      // Tap the about button
      await tester.tap(find.text('About Jarak App'));
      await tester.pumpAndSettle();

      // Verify about dialog is shown
      expect(find.text('About Jarak App'), findsOneWidget);
    });
  });
}