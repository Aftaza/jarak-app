import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? cameraController;
  final Offset? selectedPoint; // Changed from List<Offset> to single Offset?
  final Function(Offset) onPointSelected;
  final bool isCapturing;
  final Float32List? depthMap;
  final Uint8List? staticImageBytes;

  const CameraPreviewWidget({
    Key? key,
    required this.cameraController,
    required this.selectedPoint, // Changed parameter name
    required this.onPointSelected,
    required this.isCapturing,
    this.depthMap,
    this.staticImageBytes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      // If a static image is provided, show it and allow point selection
      if (staticImageBytes != null && staticImageBytes!.isNotEmpty) {
        return GestureDetector(
          onTapDown: isCapturing
              ? (details) {
                  final RenderBox renderBox =
                      context.findRenderObject() as RenderBox;
                  final localPosition = renderBox.globalToLocal(
                    details.globalPosition,
                  );
                  onPointSelected(localPosition);
                }
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(staticImageBytes!, fit: BoxFit.cover),
              // Depth map overlay (semi-transparent)
              if (depthMap != null && depthMap!.isNotEmpty)
                Positioned.fill(
                  child: CustomPaint(
                    painter: DepthMapOverlayPainter(depthMap: depthMap!),
                  ),
                ),
              if (selectedPoint != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: MeasurementOverlayPainter(
                      point: selectedPoint, // Changed from points to point
                      primaryColor: AppTheme.lightTheme.primaryColor,
                      accentColor: AppTheme.accentLight,
                      depthMap: depthMap,
                    ),
                  ),
                ),
              if (isCapturing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.2),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: Colors.white,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              selectedPoints.isEmpty
                                  ? 'Tap to select first point'
                                  : selectedPoints.length == 1
                                  ? 'Tap to select second point'
                                  : 'Measuring distance...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }

      // Fallback placeholder when neither camera nor image is available
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'photo',
                color: Colors.white70,
                size: 64,
              ),
              const SizedBox(height: 12),
              Text(
                'Camera unavailable. Use Load Image to test on desktop.',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(
          child: GestureDetector(
            onTapDown: isCapturing
                ? (details) {
                    final RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    final localPosition = renderBox.globalToLocal(
                      details.globalPosition,
                    );
                    onPointSelected(localPosition);
                  }
                : null,
            child: CameraPreview(cameraController!),
          ),
        ),

        // Point Markers and Measurement Line
        if (selectedPoints.isNotEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: MeasurementOverlayPainter(
                points: selectedPoints,
                primaryColor: AppTheme.lightTheme.primaryColor,
                accentColor: AppTheme.accentLight,
                depthMap: depthMap,
              ),
            ),
          ),

        // Capture Mode Overlay
        if (isCapturing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'touch_app',
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      selectedPoints.isEmpty
                          ? 'Tap to select first point (top of object)'
                          : selectedPoints.length == 1
                          ? 'Tap to select second point (bottom of object)'
                          : 'Processing measurement...',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class MeasurementOverlayPainter extends CustomPainter {
  final Offset? point; // Changed from List<Offset> to single Offset?
  final Color primaryColor;
  final Color accentColor;
  final Float32List? depthMap;

  MeasurementOverlayPainter({
    required this.point, // Changed parameter name
    required this.primaryColor,
    required this.accentColor,
    this.depthMap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (point == null) return;

    final pointPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final targetPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw target crosshair at selected point
    final targetPoint = point!;

    // Draw outer circle (white border)
    canvas.drawCircle(targetPoint, 25, borderPaint);

    // Draw inner circle (colored)
    canvas.drawCircle(targetPoint, 20, pointPaint);

    // Draw crosshair lines
    const lineLength = 15.0;
    
    // Horizontal line
    canvas.drawLine(
      Offset(targetPoint.dx - lineLength, targetPoint.dy),
      Offset(targetPoint.dx + lineLength, targetPoint.dy),
      targetPaint,
    );
    
    // Vertical line
    canvas.drawLine(
      Offset(targetPoint.dx, targetPoint.dy - lineLength),
      Offset(targetPoint.dx, targetPoint.dy + lineLength),
      targetPaint,
    );

    // Draw center dot
    canvas.drawCircle(targetPoint, 3, Paint()..color = Colors.white);

    // If we have depth information, display it
    if (depthMap != null && depthMap!.isNotEmpty) {
      // Calculate normalized coordinates
      final normalizedX = (targetPoint.dx / size.width).clamp(0.0, 1.0);
      final normalizedY = (targetPoint.dy / size.height).clamp(0.0, 1.0);

          // Get approximate depth value (this is simplified)
          final depthIndex =
              ((normalizedY * 384).round() * 384 + (normalizedX * 384).round())
                  .clamp(0, depthMap!.length - 1);
          final depthValue = depthMap![depthIndex];

          final depthText = "D: ${depthValue.toStringAsFixed(2)}m";
          final depthTextPainter = TextPainter(
            text: TextSpan(
              text: depthText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                background: Paint()..color = Colors.blue.withValues(alpha: 0.8),
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          depthTextPainter.layout();
          depthTextPainter.paint(
            canvas,
            Offset(points[i].dx + 15, points[i].dy - 25),
          );
        }

        // Show depth estimation status
        final statusText = "✓ Depth Estimation Active";
        final statusTextPainter = TextPainter(
          text: TextSpan(
            text: statusText,
            style: TextStyle(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              background: Paint()..color = Colors.black.withValues(alpha: 0.7),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        statusTextPainter.layout();
        statusTextPainter.paint(
          canvas,
          Offset(size.width - statusTextPainter.width - 20, 20),
        );
      }
    }
  }

  void _drawArrowLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Calculate arrow direction
    final direction = (end - start);
    final length = direction.distance;
    final unitVector = direction / length;

    // Arrow size
    const arrowLength = 15.0;
    const arrowWidth = 8.0;

    // Draw arrows at both ends
    _drawArrow(canvas, start, unitVector, paint, arrowLength, arrowWidth);
    _drawArrow(canvas, end, -unitVector, paint, arrowLength, arrowWidth);
  }

  void _drawArrow(
    Canvas canvas,
    Offset point,
    Offset direction,
    Paint paint,
    double length,
    double width,
  ) {
    final perpendicular = Offset(-direction.dy, direction.dx);

    final arrowTip = point + direction * length;
    final arrowLeft = point + perpendicular * width;
    final arrowRight = point - perpendicular * width;

    final path = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowLeft.dx, arrowLeft.dy)
      ..lineTo(arrowRight.dx, arrowRight.dy)
      ..close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DepthMapOverlayPainter extends CustomPainter {
  final Float32List depthMap;

  DepthMapOverlayPainter({required this.depthMap});

  @override
  void paint(Canvas canvas, Size size) {
    if (depthMap.isEmpty) return;

    // Assuming depth map is 384x384 (model output size)
    const int mapSize = 384;

    // Find min/max depth values for normalization
    double minDepth = depthMap.reduce((a, b) => a < b ? a : b);
    double maxDepth = depthMap.reduce((a, b) => a > b ? a : b);

    if (maxDepth <= minDepth) return;

    // Create a simple depth visualization using colored rectangles
    final paint = Paint();
    final cellWidth = size.width / mapSize;
    final cellHeight = size.height / mapSize;

    // Sample every 8th pixel to avoid performance issues
    for (int y = 0; y < mapSize; y += 8) {
      for (int x = 0; x < mapSize; x += 8) {
        final index = y * mapSize + x;
        if (index >= depthMap.length) continue;

        // Normalize depth value to 0-1
        final normalizedDepth =
            (depthMap[index] - minDepth) / (maxDepth - minDepth);

        // Create color based on depth (blue for close, red for far)
        final color = Color.lerp(
          Colors.red.withValues(alpha: 0.3), // Far (red)
          Colors.blue.withValues(alpha: 0.3), // Close (blue)
          normalizedDepth,
        )!;

        paint.color = color;

        // Draw small rectangle representing depth
        canvas.drawRect(
          Rect.fromLTWH(
            x * cellWidth,
            y * cellHeight,
            cellWidth * 8,
            cellHeight * 8,
          ),
          paint,
        );
      }
    }

    // Add depth map legend
    _drawDepthLegend(canvas, size);
  }

  void _drawDepthLegend(Canvas canvas, Size size) {
    final legendHeight = 20.0;
    final legendWidth = 150.0;
    const legendX = 20.0;
    final legendY = size.height - 60.0;

    // Draw gradient bar
    final gradientPaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              Colors.red.withValues(alpha: 0.8),
              Colors.blue.withValues(alpha: 0.8),
            ],
          ).createShader(
            Rect.fromLTWH(legendX, legendY, legendWidth, legendHeight),
          );

    canvas.drawRect(
      Rect.fromLTWH(legendX, legendY, legendWidth, legendHeight),
      gradientPaint,
    );

    // Draw legend labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // "Far" label
    textPainter.text = TextSpan(
      text: 'Far',
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(legendX, legendY + legendHeight + 5));

    // "Close" label
    textPainter.text = TextSpan(
      text: 'Close',
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        legendX + legendWidth - textPainter.width,
        legendY + legendHeight + 5,
      ),
    );

    // "Depth Map" title
    textPainter.text = TextSpan(
      text: 'Depth Map',
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(legendX, legendY - 25));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
