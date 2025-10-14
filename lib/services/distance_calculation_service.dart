<<<<<<< HEAD
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';

/// Service for calculating real-world distances from camera coordinates
class DistanceCalculationService {
  static const double _focalLength = 1000.0; // Approximate focal length in pixels
  static const double _objectHeight = 0.1; // Average object height in meters (10cm)
  
  /// Calculate distance based on two points in the camera view
  /// This is a simplified implementation - in a real app, you would use 
  /// the depth estimation model for more accurate results
  double calculateDistance(
    Offset point1,
    Offset point2,
    Size screenSize,
  ) {
    // Calculate pixel distance between points
    final dx = point2.dx - point1.dx;
    final dy = point2.dy - point1.dy;
    final pixelDistance = sqrt(dx * dx + dy * dy);
    
    // Simple distance estimation (this would be replaced with ML model results)
    // In a real implementation, we would use the depth map from the MiDaS model
    final estimatedDistance = pixelDistance * 0.01; // Convert pixels to approximate meters
    
    return estimatedDistance;
  }
  
  /// Convert pixel coordinates to normalized coordinates (0-1 range)
  (double, double) _normalizeCoordinates(Offset point, Size screenSize) {
    final normalizedX = point.dx / screenSize.width;
    final normalizedY = point.dy / screenSize.height;
    return (normalizedX, normalizedY);
  }
  
  /// More advanced distance calculation using depth estimation
  /// This method would use the actual MiDaS model output
  double calculateDistanceWithDepth(
    Offset point1,
    Offset point2,
    List<Float32List> depthMap, // Depth map from MiDaS model
    Size screenSize,
  ) {
    // In a real implementation, we would:
    // 1. Normalize coordinates to match depth map dimensions
    // 2. Get depth values at both points from the depth map
    // 3. Triangulate the 3D positions
    // 4. Calculate Euclidean distance between the points
    
    // For now, we'll use a simplified approach
    return calculateDistance(point1, point2, screenSize);
  }
}
=======
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Service for calculating real-world distances from camera to selected point
class DistanceCalculationService {
  static const double _defaultFocalLength =
      1000.0; // Approximate focal length in pixels
  static const double _defaultSensorWidth =
      6.17; // Default sensor width in mm for smartphones

  /// Calculate distance from camera to a single point using depth estimation.
  /// This is the correct approach for depth-based distance measurement.
  double calculateDistanceToPoint(
    Offset point,
    Size screenSize,
    Float32List depthMap,
    int depthMapWidth,
    int depthMapHeight, {
    double focalLengthPixels = _defaultFocalLength,
    double sensorWidthMm = _defaultSensorWidth,
  }) {
    // Normalize screen coordinates to 0-1 range
    final normalizedX = point.dx / screenSize.width;
    final normalizedY = point.dy / screenSize.height;

    // Convert to depth map coordinates
    final depthX = (normalizedX * depthMapWidth)
        .clamp(0, depthMapWidth - 1)
        .toInt();
    final depthY = (normalizedY * depthMapHeight)
        .clamp(0, depthMapHeight - 1)
        .toInt();

    // Get depth value at the point
    final depthIndex = depthY * depthMapWidth + depthX;
    if (depthIndex >= depthMap.length) return 0.0;

    final depthValue = depthMap[depthIndex];

    if (depthValue <= 0) return 0.0;

    // Convert depth value to real distance
    // This depends on the depth model's output format
    double distanceInMeters = _convertDepthToDistance(depthValue);

    return distanceInMeters.clamp(0.1, 100.0);
  }

  /// Fallback method for simple distance estimation without depth map
  /// This is much less accurate but can be used when depth estimation fails
  double calculateSimpleDistance(
    Offset point,
    Size screenSize, {
    double assumedObjectHeight = 0.1, // 10cm default object height
    double focalLengthPixels = _defaultFocalLength,
  }) {
    // Very simple approximation based on position in frame
    // Objects at the bottom are assumed closer, objects at top are farther
    final normalizedY = point.dy / screenSize.height;

    // Simple linear interpolation: top of screen = 10m, bottom = 1m
    final estimatedDistance = 10.0 - (normalizedY * 9.0);

    return estimatedDistance.clamp(0.5, 10.0);
  }

  /// Convert depth value from model output to real-world distance in meters
  double _convertDepthToDistance(double depthValue) {
    // Different depth models output values in different formats:
    // 1. Some output inverse depth (1/distance)
    // 2. Some output normalized depth (0-1 range)
    // 3. Some output direct distance values

    // For DepthPro model, we need to experiment to see the output format
    // Here are some common conversion approaches:

    if (depthValue < 0.001) {
      return 50.0; // Very far if depth is near zero
    }

    // Method 1: If output is inverse depth
    if (depthValue < 1.0) {
      return 1.0 / (depthValue + 1e-6);
    }

    // Method 2: If output is already in meters but scaled
    if (depthValue > 100) {
      return depthValue / 1000.0; // Convert from mm to meters
    }

    // Method 3: Direct value (assume already in meters)
    return depthValue;
  }

  /// Calculate distance between two points (legacy method for backward compatibility)
  /// Note: This is not the correct approach for depth-based measurement
  @deprecated
  double calculateDistance(Offset point1, Offset point2, Size screenSize) {
    final dx = point2.dx - point1.dx;
    final dy = point2.dy - point1.dy;
    final pixelDistance = math.sqrt(dx * dx + dy * dy);

    // Very rough approximation
    return pixelDistance * 0.01;
  }
}
>>>>>>> 71abcb3 (push depth pro onnx)
