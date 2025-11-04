import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' show FittedSizes, applyBoxFit;

import '../../../theme/app_theme.dart';
import '../models/measurement_point.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController? cameraController;
  final MeasurementPoint? selectedPoint;
  final ValueChanged<MeasurementPoint> onPointSelected;
  final bool isCapturing;
  final bool showFrozenFrame;
  final Float32List? depthMap;
  final Uint8List? staticImageBytes;
  final Size? capturedImageSize;
  final double? calculatedDistance;
  final String? unit;

  const CameraPreviewWidget({
    super.key,
    required this.cameraController,
    required this.selectedPoint,
    required this.onPointSelected,
    required this.isCapturing,
    this.showFrozenFrame = false,
    this.depthMap,
    this.staticImageBytes,
    this.capturedImageSize,
    this.calculatedDistance,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size widgetSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final bool cameraReady =
            cameraController != null && cameraController!.value.isInitialized;

        // Prioritaskan menampilkan gambar statis jika ada
        final bool displayStaticFrame =
            staticImageBytes != null && showFrozenFrame;

        final Size? contentSize = displayStaticFrame
            ? capturedImageSize ?? _effectivePreviewSize(cameraController)
            : _effectivePreviewSize(cameraController);

        // Hanya tampilkan "camera unavailable" jika tidak ada gambar statis DAN kamera tidak ready
        if (!displayStaticFrame && !cameraReady) {
          return _buildCameraUnavailable();
        }

        const BoxFit fit = BoxFit.contain;
        final Offset? displayPoint =
            (selectedPoint != null && contentSize != null)
            ? _normalizedToDisplay(
                selectedPoint!.normalized,
                widgetSize,
                contentSize,
                fit,
              )
            : null;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: isCapturing
              ? (details) {
                  if (contentSize == null) return;
                  final Offset? normalized = _toNormalized(
                    details.localPosition,
                    widgetSize,
                    contentSize,
                    fit,
                  );
                  if (normalized != null) {
                    onPointSelected(MeasurementPoint(normalized));
                  }
                }
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (displayStaticFrame)
                _buildStaticImage(contentSize, fit)
              else
                _buildCameraPreview(contentSize, fit),
              if (depthMap != null &&
                  depthMap!.isNotEmpty &&
                  contentSize != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: DepthMapOverlayPainter(
                        depthMap: depthMap!,
                        contentSize: contentSize,
                        fit: fit,
                      ),
                    ),
                  ),
                ),
              if (displayPoint != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: MeasurementOverlayPainter(
                        point: displayPoint,
                        primaryColor: AppTheme.lightTheme.primaryColor,
                        accentColor: AppTheme.accentLight,
                        calculatedDistance: calculatedDistance,
                        unit: unit,
                      ),
                    ),
                  ),
                ),
              if (isCapturing && displayPoint == null)
                _buildCaptureOverlay(false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraUnavailable() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text(
              'Camera not available',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Load an image to continue measurement',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticImage(Size? contentSize, BoxFit fit) {
    final Size effectiveSize = contentSize ?? const Size(1080, 1920);

    return FittedBox(
      fit: fit,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: effectiveSize.width,
        height: effectiveSize.height,
        child: staticImageBytes != null
            ? Image.memory(
                staticImageBytes!,
                fit: BoxFit.fill,
                gaplessPlayback: true, // Prevents flicker
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCameraPreview(Size? contentSize, BoxFit fit) {
    final Size effectiveSize = contentSize ?? const Size(1080, 1920);

    // Jangan render CameraPreview jika sedang menampilkan frozen frame
    if (showFrozenFrame && staticImageBytes != null) {
      return const SizedBox.shrink();
    }

    return FittedBox(
      fit: fit,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: effectiveSize.width,
        height: effectiveSize.height,
        child: cameraController != null
            ? CameraPreview(cameraController!)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCaptureOverlay(bool hasPoint) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                Text(
                  hasPoint
                      ? 'Point selected! Calculating distance...'
                      : 'Tap to select a point for measurement',
                  style: const TextStyle(
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
    );
  }

  Size? _effectivePreviewSize(CameraController? controller) {
    if (controller == null || !controller.value.isInitialized) {
      return null;
    }

    final Size? previewSize = controller.value.previewSize;
    if (previewSize == null) return null;

    final int orientation = controller.description.sensorOrientation;
    final bool isPortrait = orientation == 90 || orientation == 270;
    return isPortrait
        ? Size(previewSize.height, previewSize.width)
        : Size(previewSize.width, previewSize.height);
  }

  Offset? _toNormalized(
    Offset localPosition,
    Size widgetSize,
    Size contentSize,
    BoxFit fit,
  ) {
    final FittedSizes fitted = applyBoxFit(fit, contentSize, widgetSize);
    final Size renderSize = fitted.destination;
    final Offset offset = Offset(
      (widgetSize.width - renderSize.width) / 2,
      (widgetSize.height - renderSize.height) / 2,
    );

    final double dx = (localPosition.dx - offset.dx) / renderSize.width;
    final double dy = (localPosition.dy - offset.dy) / renderSize.height;
    if (dx < 0 || dx > 1 || dy < 0 || dy > 1) {
      return null;
    }
    return Offset(dx.clamp(0.0, 1.0), dy.clamp(0.0, 1.0));
  }

  Offset _normalizedToDisplay(
    Offset normalized,
    Size widgetSize,
    Size contentSize,
    BoxFit fit,
  ) {
    final FittedSizes fitted = applyBoxFit(fit, contentSize, widgetSize);
    final Size renderSize = fitted.destination;
    final Offset offset = Offset(
      (widgetSize.width - renderSize.width) / 2,
      (widgetSize.height - renderSize.height) / 2,
    );

    return Offset(
      offset.dx + normalized.dx * renderSize.width,
      offset.dy + normalized.dy * renderSize.height,
    );
  }
}

class MeasurementOverlayPainter extends CustomPainter {
  final Offset? point;
  final Color primaryColor;
  final Color accentColor;
  final double? calculatedDistance;
  final String? unit;

  MeasurementOverlayPainter({
    required this.point,
    required this.primaryColor,
    required this.accentColor,
    this.calculatedDistance,
    this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (point == null) return;
    final Offset center = point!;

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final Paint fillPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    final Paint crosshairPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 25, borderPaint);
    canvas.drawCircle(center, 20, fillPaint);

    const double lineLength = 16;
    canvas.drawLine(
      Offset(center.dx - lineLength, center.dy),
      Offset(center.dx + lineLength, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - lineLength),
      Offset(center.dx, center.dy + lineLength),
      crosshairPaint,
    );
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);

    if (calculatedDistance == null || calculatedDistance! <= 0) return;

    final String distanceLabel =
        '${calculatedDistance!.toStringAsFixed(2)} ${unit ?? 'm'}';
    final TextPainter distancePainter = TextPainter(
      text: TextSpan(
        text: distanceLabel,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final Offset distanceOffset = Offset(
      center.dx - distancePainter.width / 2,
      center.dy - 60,
    );

    final Rect backgroundRect = Rect.fromLTWH(
      distanceOffset.dx - 10,
      distanceOffset.dy - 6,
      distancePainter.width + 20,
      distancePainter.height + 12,
    );

    final Paint backgroundPaint = Paint()
      ..color = primaryColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(8)),
      backgroundPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(8)),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    distancePainter.paint(canvas, distanceOffset);

    const String subtitle = 'Distance from camera';
    final TextPainter subtitlePainter = TextPainter(
      text: TextSpan(
        text: subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.85),
          fontSize: 12,
          shadows: const [
            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final Offset subtitleOffset = Offset(
      center.dx - subtitlePainter.width / 2,
      distanceOffset.dy + distancePainter.height + 4,
    );

    subtitlePainter.paint(canvas, subtitleOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DepthMapOverlayPainter extends CustomPainter {
  final Float32List depthMap;
  final Size contentSize;
  final BoxFit fit;

  DepthMapOverlayPainter({
    required this.depthMap,
    required this.contentSize,
    required this.fit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (depthMap.isEmpty) return;

    const int mapSize = 384;
    double minDepth = depthMap.reduce((a, b) => a < b ? a : b);
    double maxDepth = depthMap.reduce((a, b) => a > b ? a : b);
    if (maxDepth <= minDepth) return;

    final FittedSizes fitted = applyBoxFit(fit, contentSize, size);
    final Size renderSize = fitted.destination;
    final Offset offset = Offset(
      (size.width - renderSize.width) / 2,
      (size.height - renderSize.height) / 2,
    );

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(renderSize.width / mapSize, renderSize.height / mapSize);

    final Paint cellPaint = Paint();
    const int step = 8;

    for (int y = 0; y < mapSize; y += step) {
      for (int x = 0; x < mapSize; x += step) {
        final int index = y * mapSize + x;
        if (index >= depthMap.length) continue;

        final double normalized =
            (depthMap[index] - minDepth) / (maxDepth - minDepth);
        cellPaint.color = Color.lerp(
          Colors.red.withOpacity(0.25),
          Colors.blue.withOpacity(0.25),
          normalized,
        )!;

        canvas.drawRect(
          Rect.fromLTWH(
            x.toDouble(),
            y.toDouble(),
            step.toDouble(),
            step.toDouble(),
          ),
          cellPaint,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
