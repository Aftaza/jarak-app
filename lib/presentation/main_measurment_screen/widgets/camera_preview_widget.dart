import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? cameraController;
  final List<Offset> selectedPoints;
  final Function(Offset) onPointSelected;
  final bool isCapturing;

  const CameraPreviewWidget({
    Key? key,
    required this.cameraController,
    required this.selectedPoints,
    required this.onPointSelected,
    required this.isCapturing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.lightTheme.primaryColor,
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
                    final localPosition =
                        renderBox.globalToLocal(details.globalPosition);
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
  final List<Offset> points;
  final Color primaryColor;
  final Color accentColor;

  MeasurementOverlayPainter({
    required this.points,
    required this.primaryColor,
    required this.accentColor,
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
