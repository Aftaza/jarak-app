import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class MockCameraController extends CameraController {
  bool _isInitialized = false;
  bool _isDisposed = false;

  MockCameraController() : super._(CameraDescription(
    name: 'mock_camera',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 0,
  ), ResolutionPreset.high);

  @override
  Future<void> initialize() async {
    _isInitialized = true;
    return Future.value();
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    return super.dispose();
  }

  @override
  Future<XFile> takePicture() async {
    return XFile('mock_image_path');
  }

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    return Future.value();
  }

  @override
  Future<void> setFocusMode(FocusMode mode) async {
    return Future.value();
  }

  @override
  Future<void> setZoomLevel(double zoom) async {
    return Future.value();
  }

  @override
  CameraValue get value => CameraValue(
    isInitialized: _isInitialized,
    errorDescription: null,
    previewSize: const Size(1920, 1080),
    isRecordingVideo: false,
    isTakingPicture: false,
    isStreamingImages: false,
    isPreviewPaused: false,
    flashMode: FlashMode.auto,
    exposureMode: ExposureMode.auto,
    focusMode: FocusMode.auto,
    exposurePointSupported: false,
    focusPointSupported: false,
  );

  bool get isDisposed => _isDisposed;
}

class MockCameraDescription extends CameraDescription {
  MockCameraDescription() : super(
    name: 'mock_camera',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 0,
  );
}

// Mock implementation of availableCameras
Future<List<CameraDescription>> mockAvailableCameras() async {
  return [
    CameraDescription(
      name: 'mock_back_camera',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 0,
    ),
    CameraDescription(
      name: 'mock_front_camera',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 0,
    ),
  ];
}