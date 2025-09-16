import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CameraOverlayWidget extends StatelessWidget {
  final bool showPositioningGuide;
  final bool showAccuracyIndicator;
  final double accuracyScore;
  final String guidanceText;
  final List<Offset> selectedPoints;
  final Function(Offset) onPointSelected;

  const CameraOverlayWidget({
    super.key,
    this.showPositioningGuide = true,
    this.showAccuracyIndicator = false,
    this.accuracyScore = 0.0,
    this.guidanceText = 'Position object within the frame',
    this.selectedPoints = const [],
    required this.onPointSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Positioning guide overlay
        if (showPositioningGuide)
          CustomPaint(
            size: Size(double.infinity, double.infinity),
            painter: PositioningGuidePainter(),
          ),

        // Selected points overlay
        if (selectedPoints.isNotEmpty)
          CustomPaint(
            size: Size(double.infinity, double.infinity),
            painter: PointsPainter(points: selectedPoints),
          ),

        // Guidance text
        Positioned(
          top: 4.h,
          left: 4.w,
          right: 4.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface
                  .withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowLight,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    guidanceText,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Accuracy indicator
        if (showAccuracyIndicator)
          Positioned(
            bottom: 12.h,
            left: 4.w,
            right: 4.w,
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface
                    .withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowLight,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accuracy Score',
                        style: AppTheme.lightTheme.textTheme.titleSmall,
                      ),
                      Text(
                        '${(accuracyScore * 100).toInt()}%',
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          color: _getAccuracyColor(accuracyScore),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  LinearProgressIndicator(
                    value: accuracyScore,
                    backgroundColor: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _getAccuracyColor(accuracyScore)),
                    minHeight: 0.5.h,
                  ),
                ],
              ),
            ),
          ),

        // Touch detector for point selection
        GestureDetector(
          onTapDown: (details) {
            onPointSelected(details.localPosition);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }

  Color _getAccuracyColor(double score) {
    if (score >= 0.8) return AppTheme.accentLight;
    if (score >= 0.6) return AppTheme.warningLight;
    return AppTheme.errorLight;
  }
}

class PositioningGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryLight.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final guideRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.7,
      height: size.height * 0.5,
    );

    // Draw guide rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(guideRect, Radius.circular(12)),
      paint,
    );

    // Draw corner markers
    final cornerSize = 20.0;
    final corners = [
      guideRect.topLeft,
      guideRect.topRight,
      guideRect.bottomLeft,
      guideRect.bottomRight,
    ];

    for (final corner in corners) {
      canvas.drawLine(
        corner,
        corner + Offset(cornerSize, 0),
        paint..strokeWidth = 3,
      );
      canvas.drawLine(
        corner,
        corner + Offset(0, cornerSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PointsPainter extends CustomPainter {
  final List<Offset> points;

  PointsPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryLight
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = AppTheme.lightTheme.colorScheme.surface
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      // Draw point circle
      canvas.drawCircle(points[i], 8, paint);
      canvas.drawCircle(points[i], 8, strokePaint);

      // Draw point number
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: AppTheme.lightTheme.colorScheme.onPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        points[i] - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Draw line between points if there are 2 points
    if (points.length == 2) {
      final linePaint = Paint()
        ..color = AppTheme.primaryLight
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(points[0], points[1], linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
