import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarak_app/main.dart';
import 'package:jarak_app/routes/app_routes.dart';

void main() {
  group('App Integration', () {
    testWidgets('app launches and shows splash screen', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());

      // Verify splash screen is shown
      expect(find.text('Jarak App'), findsOneWidget);
      expect(find.text('Pengukur Jarak Digital Pintar'), findsOneWidget);
    });

    testWidgets('app has all required routes', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());

      // Check that all routes are defined
      expect(AppRoutes.routes.containsKey(AppRoutes.initial), isTrue);
      expect(AppRoutes.routes.containsKey(AppRoutes.splash), isTrue);
      expect(AppRoutes.routes.containsKey(AppRoutes.settings), isTrue);
      expect(AppRoutes.routes.containsKey(AppRoutes.cameraPermissionRequest), isTrue);
      expect(AppRoutes.routes.containsKey(AppRoutes.calibrationSetup), isTrue);
      expect(AppRoutes.routes.containsKey(AppRoutes.measurementResults), isTrue);
      expect(AppRoutes.routes.containsKey(AppRoutes.mainMeasurement), isTrue);
    });

    testWidgets('app uses correct theme', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());

      // Access the MaterialApp to verify theme
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
    });
  });
}