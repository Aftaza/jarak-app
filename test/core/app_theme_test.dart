import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarak_app/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('exports light and dark themes', () {
      expect(AppTheme.lightTheme, isA<ThemeData>());
      expect(AppTheme.darkTheme, isA<ThemeData>());
    });

    test('light theme has correct primary color', () {
      expect(AppTheme.lightTheme.colorScheme.primary, AppTheme.primaryLight);
    });

    test('dark theme has correct primary color', () {
      expect(AppTheme.darkTheme.colorScheme.primary, AppTheme.primaryDark);
    });

    test('themes have consistent text themes', () {
      expect(AppTheme.lightTheme.textTheme, isNotNull);
      expect(AppTheme.darkTheme.textTheme, isNotNull);
    });

    test('themes have correct scaffold background colors', () {
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, AppTheme.backgroundLight);
      expect(AppTheme.darkTheme.scaffoldBackgroundColor, AppTheme.backgroundDark);
    });
  });
}