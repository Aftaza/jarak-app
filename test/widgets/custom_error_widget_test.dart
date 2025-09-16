import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarak_app/widgets/custom_error_widget.dart';

void main() {
  group('CustomErrorWidget', () {
    testWidgets('renders error message correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomErrorWidget(
            errorMessage: 'Test error message',
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('We encountered an unexpected error while processing your request.'), findsOneWidget);
    });

    testWidgets('renders with error details', (WidgetTester tester) async {
      final errorDetails = FlutterErrorDetails(
        exception: Exception('Test exception'),
        stack: StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomErrorWidget(
            errorDetails: errorDetails,
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });
}