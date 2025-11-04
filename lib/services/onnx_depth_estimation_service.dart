import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

// Placeholder ONNX service - we'll implement with a more basic approach first
class OnnxDepthEstimationService {
  bool _isInitialized = false;
  static const String _modelPath = 'assets/models/model_q4f16.onnx';
  
  // Model dimensions
  static const int _inputHeight = 384;
  static const int _inputWidth = 512;
  static const int _inputChannels = 3;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Verify model file exists in assets
      final modelData = await rootBundle.load(_modelPath);
      if (modelData.lengthInBytes > 0) {
        _isInitialized = true;
      }
    } catch (e) {
      print('Error initializing ONNX depth estimation service: $e');
      rethrow;
    }
  }

  /// Dispose of the service 
  void dispose() {
    _isInitialized = false;
  }

  /// Estimate depth from an image file (stub implementation for now)
  Future<Float32List> estimateDepthFromFile(String imagePath) async {
    if (!_isInitialized) {
      throw Exception('OnnxDepthEstimationService not initialized');
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

  /// Estimate depth from image bytes (stub implementation for now)
  Future<Float32List> estimateDepthFromBytes(Uint8List imageBytes) async {
    if (!_isInitialized) {
      throw Exception('OnnxDepthEstimationService not initialized');
    }

    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // For now, return a simulated depth map as we need to get the ONNX runtime working properly
      // In a real implementation, this would involve actual ONNX inference
      final depthMap = Float32List(_inputHeight * _inputWidth);
      
      // Simulate a depth map with some variation (this is just for demo purposes)
      for (int i = 0; i < depthMap.length; i++) {
        // Create a pattern that decreases from top to bottom (closer objects in foreground)
        final row = (i ~/ _inputWidth);
        depthMap[i] = 5.0 - (row / _inputHeight) * 3.0; // Range from 2m to 5m
      }
      
      return depthMap;
    } catch (e) {
      print('Error estimating depth from bytes: $e');
      rethrow;
    }
  }

  /// Get depth value at specific coordinates (normalized to [0, 1])
  double getDepthAt(Float32List depthMap, double x, double y) {
    if (depthMap.isEmpty) return 0.0;

    // For this ONNX model, the output is [384, 512] as specified
    final outputHeight = 384;
    final outputWidth = 512;
    
    // Convert normalized coordinates to pixel coordinates
    final pixelX = (x * (outputWidth - 1)).round();
    final pixelY = (y * (outputHeight - 1)).round();

    // Clamp to valid range
    final clampedX = pixelX.clamp(0, outputWidth - 1);
    final clampedY = pixelY.clamp(0, outputHeight - 1);

    // Calculate index in depth map (assuming output is [H, W] format)
    final index = clampedY * outputWidth + clampedX;

    // Return depth value (ensure it's within valid range)
    // The ONNX model typically outputs depth values in meters
    final rawDepth = index < depthMap.length ? depthMap[index] : 0.0;
    
    // Ensure the depth value is positive and reasonable
    return rawDepth > 0 ? rawDepth : 0.0;
  }

  /// Calculate distance in pixels between two points: sqrt(dx² + dy²)
  double calculatePixelDistance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return sqrt(dx * dx + dy * dy);
  }

  /// Calculate depth difference between two points: |depth2 - depth1|
  double calculateDepthDifference(Float32List depthMap, double x1, double y1, double x2, double y2) {
    final depth1 = getDepthAt(depthMap, x1, y1);
    final depth2 = getDepthAt(depthMap, x2, y2);
    return (depth2 - depth1).abs();
  }

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;
}