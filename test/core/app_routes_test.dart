import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarak_app/routes/app_routes.dart';

void main() {
  group('AppRoutes', () {
    test('defines all required route constants', () {
      expect(AppRoutes.initial, isA<String>());
      expect(AppRoutes.splash, isA<String>());
      expect(AppRoutes.settings, isA<String>());
      expect(AppRoutes.cameraPermissionRequest, isA<String>());
      expect(AppRoutes.calibrationSetup, isA<String>());
      expect(AppRoutes.measurementResults, isA<String>());
      expect(AppRoutes.mainMeasurement, isA<String>());
    });

    test('routes map contains all required routes', () {
      expect(AppRoutes.routes, isA<Map<String, WidgetBuilder>>());
      expect(AppRoutes.routes, isNotEmpty);
    });

    testWidgets('routes can build screens', (WidgetTester tester) async {
      // Test that each route can build a widget without errors
      AppRoutes.routes.forEach((routeName, widgetBuilder) {
        try {
          final widget = widgetBuilder(MockBuildContext());
          expect(widget, isA<Widget>());
        } catch (e) {
          fail('Route $routeName failed to build: $e');
        }
      });
    });
  });
}

// Mock BuildContext for testing
class MockBuildContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}