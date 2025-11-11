import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarak_app/presentation/main_measurment_screen/widgets/camera_preview_widget.dart';
import '../services/mock_camera_service.dart';

void main() {
  group('CameraPreviewWidget', () {
    testWidgets('shows loading state when camera is not initialized', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CameraPreviewWidget(
            cameraController: null,
            selectedPoints: [],
            onPointSelected: (point) {},
            isCapturing: false,
            isProcessing: false,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Initializing Camera...'), findsOneWidget);
    });

    testWidgets('renders camera preview when initialized', (WidgetTester tester) async {
      final mockController = MockCameraController();
      await mockController.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: CameraPreviewWidget(
            cameraController: mockController,
            selectedPoints: [],
            onPointSelected: (point) {},
            isCapturing: false,
            isProcessing: false,
          ),
        ),
      );

      expect(find.byType(Placeholder), findsOneWidget); // CameraPreview is internal to the widget, using Placeholder instead
    });

    testWidgets('shows capture mode overlay when capturing', (WidgetTester tester) async {
      final mockController = MockCameraController();
      await mockController.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: CameraPreviewWidget(
            cameraController: mockController,
            selectedPoints: [],
            onPointSelected: (point) {},
            isCapturing: true,
            isProcessing: false,
          ),
        ),
      );

      expect(find.text('Tap to select first point (top of object)'), findsOneWidget);
    });

    testWidgets('shows point selection instructions', (WidgetTester tester) async {
      final mockController = MockCameraController();
      await mockController.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: CameraPreviewWidget(
            cameraController: mockController,
            selectedPoints: [const Offset(100, 100)],
            onPointSelected: (point) {},
            isCapturing: true,
            isProcessing: false,
          ),
        ),
      );

      expect(find.text('Tap to select second point (bottom of object)'), findsOneWidget);
    });
  });
}