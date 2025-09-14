import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class CameraPermissionRequest extends StatefulWidget {
  const CameraPermissionRequest({Key? key}) : super(key: key);

  @override
  State<CameraPermissionRequest> createState() =>
      _CameraPermissionRequestState();
}

class _CameraPermissionRequestState extends State<CameraPermissionRequest>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _showLearnMore = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kIsWeb) {
        // Web handles permissions through browser
        _navigateToMeasurementScreen();
        return;
      }

      final PermissionStatus status = await Permission.camera.request();

      if (status.isGranted) {
        // Haptic feedback on success
        HapticFeedback.lightImpact();
        _navigateToMeasurementScreen();
      } else if (status.isDenied) {
        _showPermissionDeniedDialog();
      } else if (status.isPermanentlyDenied) {
        _showOpenSettingsDialog();
      }
    } catch (e) {
      _showErrorDialog();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToMeasurementScreen() {
    Navigator.pushReplacementNamed(context, '/main-measurement-screen');
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Camera Access Denied',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Text(
            'Camera access is required for distance measurement. Please allow camera permission to continue.',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/splash-screen');
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestCameraPermission();
              },
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Permission Required',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Camera permission has been permanently denied. Please enable it manually in settings:',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              SizedBox(height: 2.h),
              Text(
                '1. Open device Settings',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
              Text(
                '2. Find DistanceMeter app',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
              Text(
                '3. Enable Camera permission',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
              Text(
                '4. Return to the app',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/splash-screen');
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Error',
            style: AppTheme.lightTheme.textTheme.titleLarge,
          ),
          content: Text(
            'An error occurred while requesting camera permission. Please try again.',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _toggleLearnMore() {
    setState(() {
      _showLearnMore = !_showLearnMore;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/splash-screen');
                    },
                    icon: CustomIconWidget(
                      iconName: 'arrow_back',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                ),

                SizedBox(height: 4.h),

                // Camera illustration
                Container(
                  width: 60.w,
                  height: 25.h,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Phone illustration
                      Container(
                        width: 25.w,
                        height: 15.h,
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: CustomIconWidget(
                                iconName: 'camera_alt',
                                color:
                                    AppTheme.lightTheme.colorScheme.onPrimary,
                                size: 20,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Container(
                              width: 15.w,
                              height: 8.h,
                              decoration: BoxDecoration(
                                color: AppTheme
                                    .lightTheme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Dotted measurement lines
                      Positioned(
                        right: 8.w,
                        child: Column(
                          children: [
                            Container(
                              width: 12.w,
                              height: 6.h,
                              decoration: BoxDecoration(
                                color: AppTheme.lightTheme.colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Container(
                              width: 12.w,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.lightTheme.colorScheme.secondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Dotted lines connecting phone to objects
                      Positioned(
                        right: 20.w,
                        child: CustomPaint(
                          size: Size(15.w, 12.h),
                          painter: DottedLinePainter(
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 6.h),

                // Main heading
                Text(
                  'Camera Access Required',
                  style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 2.h),

                // Description
                Text(
                  'DistanceMeter uses your camera for real-time distance measurement without storing any images on your device.',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 3.h),

                // Privacy badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.tertiary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'security',
                        color: AppTheme.lightTheme.colorScheme.tertiary,
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'No images stored',
                        style:
                            AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 6.h),

                // Primary button
                SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestCameraPermission,
                    child: _isLoading
                        ? SizedBox(
                            width: 5.w,
                            height: 5.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.lightTheme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Allow Camera Access',
                            style: AppTheme.lightTheme.textTheme.labelLarge
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: 2.h),

                // Learn more button
                TextButton(
                  onPressed: _toggleLearnMore,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Learn More',
                        style:
                            AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      AnimatedRotation(
                        turns: _showLearnMore ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: CustomIconWidget(
                          iconName: 'keyboard_arrow_down',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // Learn more content
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _showLearnMore ? null : 0,
                  child: _showLearnMore
                      ? Container(
                          margin: EdgeInsets.only(top: 2.h),
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.lightTheme.colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How DistanceMeter Works',
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              _buildLearnMoreItem(
                                'Real-time Processing',
                                'Uses TensorFlow Lite for on-device machine learning calculations',
                                'psychology',
                              ),
                              SizedBox(height: 1.5.h),
                              _buildLearnMoreItem(
                                'Privacy Protection',
                                'All processing happens locally - no images are uploaded or stored',
                                'shield',
                              ),
                              SizedBox(height: 1.5.h),
                              _buildLearnMoreItem(
                                'Accurate Measurements',
                                'Advanced computer vision algorithms provide precise distance calculations',
                                'straighten',
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLearnMoreItem(
      String title, String description, String iconName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: CustomIconWidget(
            iconName: iconName,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 16,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                description,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double dashWidth = 5;
    const double dashSpace = 3;
    double startX = 0;

    // Draw horizontal dotted lines
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height * 0.3),
        Offset(startX + dashWidth, size.height * 0.3),
        paint,
      );
      canvas.drawLine(
        Offset(startX, size.height * 0.7),
        Offset(startX + dashWidth, size.height * 0.7),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
