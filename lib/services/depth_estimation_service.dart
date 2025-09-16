import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
// import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class DepthEstimationService {
  Interpreter? _interpreter;
  static const String _modelPath = 'assets/models/midas_v2.tflite';
  static const int _inputSize = 256; // MiDaS model input size

  bool _isInitialized = false;

  /// Initialize the TensorFlow Lite interpreter with the MiDaS model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load model from assets
      final modelData = await rootBundle.load(_modelPath);
      final buffer = modelData.buffer.asUint8List();

      // Create interpreter options for better performance
      final options = InterpreterOptions()
        ..threads = 4;

      // Create interpreter
      _interpreter = Interpreter.fromBuffer(buffer, options: options);
      _isInitialized = true;
    } catch (e) {
      print('Error initializing depth estimation service: $e');
      rethrow;
    }
  }

  /// Dispose of the interpreter to free resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }

  /// Estimate depth from an image file
  Future<Float32List> estimateDepthFromFile(String imagePath) async {
    if (!_isInitialized) {
      throw Exception('DepthEstimationService not initialized');
    }

    try {
      // Load image file
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      
      // Process image and estimate depth
      return await estimateDepthFromBytes(imageBytes);
    } catch (e) {
      print('Error estimating depth from file: $e');
      rethrow;
    }
  }

  /// Estimate depth from image bytes
  Future<Float32List> estimateDepthFromBytes(Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('DepthEstimationService not initialized');
    }

    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image to model input size
      final resizedImage = img.copyResize(
        image,
        width: _inputSize,
        height: _inputSize,
      );

      // Convert to tensor (normalized to [0, 1])
      final inputTensor = _imageToTensor(resizedImage);

      // Prepare output tensor
      final outputTensor = Float32List(_inputSize * _inputSize);

      // Run inference
      _interpreter!.run(inputTensor, outputTensor);

      return outputTensor;
    } catch (e) {
      print('Error estimating depth from bytes: $e');
      rethrow;
    }
  }

  /// Convert image to tensor for model input
  Float32List _imageToTensor(img.Image image) {
    final pixels = image.getBytes();
    final tensor = Float32List(_inputSize * _inputSize * 3);

    // Convert RGB to normalized tensor ([0, 1] range)
    for (int i = 0; i < pixels.length; i += 4) {
      final r = pixels[i] / 255.0;
      final g = pixels[i + 1] / 255.0;
      final b = pixels[i + 2] / 255.0;

      final index = (i ~/ 4) * 3;
      tensor[index] = r;
      tensor[index + 1] = g;
      tensor[index + 2] = b;
    }

    return tensor;
  }

  /// Get depth value at specific coordinates (normalized to [0, 1])
  double getDepthAt(Float32List depthMap, double x, double y) {
    if (depthMap.isEmpty) return 0.0;

    // Convert normalized coordinates to pixel coordinates
    final pixelX = (x * (_inputSize - 1)).round();
    final pixelY = (y * (_inputSize - 1)).round();

    // Clamp to valid range
    final clampedX = pixelX.clamp(0, _inputSize - 1);
    final clampedY = pixelY.clamp(0, _inputSize - 1);

    // Calculate index in depth map
    final index = clampedY * _inputSize + clampedX;

    // Return depth value (ensure it's within valid range)
    return index < depthMap.length ? depthMap[index] : 0.0;
  }

  /// Calculate distance between two points using depth information
  double calculateDistance(
    Float32List depthMap,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    if (depthMap.isEmpty) return 0.0;

    // Get depth values at both points
    final depth1 = getDepthAt(depthMap, x1, y1);
    final depth2 = getDepthAt(depthMap, x2, y2);

    // Calculate Euclidean distance in 3D space
    // Using simplified model where depth represents distance from camera
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dz = depth2 - depth1;

    // Calculate 3D distance
    final distance = sqrt(dx * dx + dy * dy + dz * dz);

    return distance;
  }

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;
}