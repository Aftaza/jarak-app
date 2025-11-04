import 'package:flutter/foundation.dart';

import 'depth_estimation_service.dart';

/// Converts raw depth-map samples into real-world distances.
/// DepthPro model menghasilkan metric depth langsung dalam meter (Bochkovskii et al., Apple, 2024).
class DepthMeasurementService {
  DepthMeasurementService({
    required DepthEstimationService depthService,
    required double? calibrationScale,
  }) : _depthService = depthService,
       _calibrationScale = calibrationScale ?? 1.0;

  final DepthEstimationService _depthService;
  final double _calibrationScale;

  /// Returns the distance in meters at the supplied normalized coordinate.
  /// DepthPro output sudah dalam satuan METER, tidak perlu konversi inverse depth.
  double distanceAtNormalizedPoint({
    required double normalizedX,
    required double normalizedY,
    int sampleRadius = 3,
  }) {
    if (!_depthService.hasDepth) {
      return 0.0;
    }

    final int width = _depthService.outputWidth;
    final int height = _depthService.outputHeight;
    if (width == 0 || height == 0) {
      return 0.0;
    }

    final int centerX = (normalizedX.clamp(0.0, 1.0) * (width - 1)).round();
    final int centerY = (normalizedY.clamp(0.0, 1.0) * (height - 1)).round();

    final depthMeters = _sampleMedianDepth(
      centerX,
      centerY,
      radius: sampleRadius,
    );
    if (depthMeters <= 0) {
      return 0.0;
    }

    // DepthPro menghasilkan METRIC DEPTH langsung dalam meter
    // Tidak perlu inversi atau konversi kompleks
    // Hanya apply calibration scale untuk fine-tuning jika diperlukan
    final distanceMeters = depthMeters * _calibrationScale;

    print(
      '📏 DepthPro metric depth: $depthMeters m -> Calibrated: $distanceMeters m (scale: $_calibrationScale)',
    );

    return distanceMeters.clamp(0.1, 50.0);
  }

  double _sampleMedianDepth(int cx, int cy, {int radius = 3}) {
    final Float32List? map = _depthService.lastDepthMap;
    if (map == null || map.isEmpty) {
      return 0.0;
    }

    final int width = _depthService.outputWidth;
    final int height = _depthService.outputHeight;
    final int r = radius < 1 ? 1 : radius;

    final List<double> samples = [];
    for (int dy = -r; dy <= r; dy++) {
      final int y = (cy + dy).clamp(0, height - 1);
      for (int dx = -r; dx <= r; dx++) {
        final int x = (cx + dx).clamp(0, width - 1);
        final double depth = map[y * width + x];
        if (depth > 0) {
          samples.add(depth);
        }
      }
    }

    if (samples.isEmpty) {
      return 0.0;
    }

    samples.sort();
    final median = samples[samples.length ~/ 2];

    // Debug: print metric depth values dari DepthPro
    print(
      '🎯 DepthPro depth samples (meters): min=${samples.first.toStringAsFixed(2)}m, max=${samples.last.toStringAsFixed(2)}m, median=${median.toStringAsFixed(2)}m',
    );

    return median;
  }
}
