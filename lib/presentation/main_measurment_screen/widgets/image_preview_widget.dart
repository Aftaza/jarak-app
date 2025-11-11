import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class ImagePreviewWidget extends StatelessWidget {
  final String? imagePath;
  final List<Offset> selectedPoints;
  final Function(Offset) onPointSelected;
  final bool isProcessing;
  final Float32List? depthMap;

  const ImagePreviewWidget({
    Key? key,
    this.imagePath,
    required this.selectedPoints,
    required this.onPointSelected,
    required this.isProcessing,
    this.depthMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(
          child: Text(
            'No image captured yet',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Captured Image with tap gesture detector - This must be on top to receive taps
        Positioned.fill(
          child: GestureDetector(
            onTapDown: isProcessing
                ? null
                : (details) {
                    final RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    final localPosition =
                        renderBox.globalToLocal(details.globalPosition);
                    onPointSelected(localPosition);
                  },
            child: Image.file(
              File(imagePath!),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error,
                          color: AppTheme.errorLight,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error loading image',
                          style: AppTheme.lightTheme.textTheme.bodyLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Overlay for drawing points and lines - This needs to be above the image to draw points,
        // but IgnorePointer makes it transparent to taps so they go through to the image below
        if (selectedPoints.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: MeasurementOverlayPainter(
                  points: selectedPoints,
                  primaryColor: AppTheme.lightTheme.primaryColor,
                  accentColor: AppTheme.accentLight,
                  depthMap: depthMap,
                ),
              ),
            ),
          ),

        // Capture Mode Overlay - Only show simple text overlay in corner to avoid interfering with point selection
        if (!isProcessing && selectedPoints.length < 2)
          Positioned(
            top: 20,
            left: 20,
            child: IgnorePointer( // Ignore pointer events on the overlay so taps reach the image
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedPoints.isEmpty
                      ? 'Select first point'
                      : 'Select second point',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class MeasurementOverlayPainter extends CustomPainter {
  final List<Offset> points;
  final Color primaryColor;
  final Color accentColor;
  final Float32List? depthMap;

  MeasurementOverlayPainter({
    required this.points,
    required this.primaryColor,
    required this.accentColor,
    this.depthMap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final pointPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw points
    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Draw white border
      canvas.drawCircle(point, 12, borderPaint);

      // Draw colored point
      canvas.drawCircle(point, 10, pointPaint);

      // Draw point number
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          point.dx - textPainter.width / 2,
          point.dy - textPainter.height / 2,
        ),
      );
    }

    // Draw connecting line if we have two points
    if (points.length == 2) {
      canvas.drawLine(points[0], points[1], linePaint);

      // Draw measurement line with arrows
      _drawArrowLine(canvas, points[0], points[1], linePaint);
      
      // If we have depth information, display it
      if (depthMap != null && depthMap!.isNotEmpty) {
        // Get depth values at both points
        final normX1 = points[0].dx / size.width;
        final normY1 = points[0].dy / size.height;
        final normX2 = points[1].dx / size.width;
        final normY2 = points[1].dy / size.height;
        
        // Simple depth visualization (in a real app, this would be more sophisticated)
        final depthText = "Depth info available";
        final depthTextPainter = TextPainter(
          text: TextSpan(
            text: depthText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              background: Paint()..color = Colors.black.withValues(alpha: 0.7),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        depthTextPainter.layout();
        depthTextPainter.paint(
          canvas,
          Offset(
            (points[0].dx + points[1].dx) / 2 - depthTextPainter.width / 2,
            (points[0].dy + points[1].dy) / 2 - 30,
          ),
        );
      }
    }
  }

  void _drawArrowLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Calculate arrow direction
    final direction = (end - start);
    final length = direction.distance;
    final unitVector = direction / length;
    final perpVector = Offset(-unitVector.dy, unitVector.dx);

    // Arrow size
    const arrowLength = 15.0;
    const arrowWidth = 8.0;

    // Draw arrows at both ends
    _drawArrow(canvas, start, unitVector, paint, arrowLength, arrowWidth);
    _drawArrow(canvas, end, -unitVector, paint, arrowLength, arrowWidth);
  }

  void _drawArrow(Canvas canvas, Offset point, Offset direction, Paint paint,
      double length, double width) {
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
  bool shouldRepaint(covariant MeasurementOverlayPainter oldDelegate) {
    return points.length != oldDelegate.points.length ||
           primaryColor != oldDelegate.primaryColor ||
           accentColor != oldDelegate.accentColor ||
           depthMap != oldDelegate.depthMap ||
           (depthMap != null && oldDelegate.depthMap != null && 
            depthMap!.length != oldDelegate.depthMap!.length);
  }
}