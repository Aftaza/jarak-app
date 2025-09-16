import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class VisualReferenceWidget extends StatelessWidget {
  final String? capturedImagePath;
  final List<Offset> selectedPoints;

  const VisualReferenceWidget({
    Key? key,
    this.capturedImagePath,
    required this.selectedPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 25.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background image or placeholder
            if (capturedImagePath != null)
              CustomImageWidget(
                imageUrl: capturedImagePath!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: double.infinity,
                color: AppTheme.lightTheme.colorScheme.surface
                    .withValues(alpha: 0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'camera_alt',
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                      size: 48,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Camera Preview',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

            // Measurement overlay
            CustomPaint(
              size: Size(double.infinity, double.infinity),
              painter: MeasurementOverlayPainter(
                points: selectedPoints,
                lineColor: AppTheme.lightTheme.colorScheme.primary,
                pointColor: AppTheme.lightTheme.colorScheme.tertiary,
              ),
            ),

            // Corner label
            Positioned(
              top: 2.w,
              left: 2.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface
                      .withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Measurement Reference',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeasurementOverlayPainter extends CustomPainter {
  final List<Offset> points;
  final Color lineColor;
  final Color pointColor;

  MeasurementOverlayPainter({
    required this.points,
    required this.lineColor,
    required this.pointColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw measurement line
    canvas.drawLine(points[0], points[1], linePaint);

    // Draw measurement points
    for (final point in points) {
      canvas.drawCircle(point, 8.0, pointPaint);
      canvas.drawCircle(point, 8.0, pointBorderPaint);
    }

    // Draw distance label
    if (points.length >= 2) {
      final midPoint = Offset(
        (points[0].dx + points[1].dx) / 2,
        (points[0].dy + points[1].dy) / 2,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Distance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final labelRect = Rect.fromCenter(
        center: midPoint,
        width: textPainter.width + 16,
        height: textPainter.height + 8,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, Radius.circular(4)),
        Paint()..color = lineColor,
      );

      textPainter.paint(
        canvas,
        Offset(
          midPoint.dx - textPainter.width / 2,
          midPoint.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
