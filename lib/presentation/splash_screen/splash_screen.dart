import 'dart:async';

<<<<<<< HEAD
=======
import 'package:flutter/foundation.dart';
>>>>>>> 71abcb3 (push depth pro onnx)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _progressAnimation;

  bool _isInitializing = true;
  String _initializationStatus = 'Initializing DistanceMeter...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialization();
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Progress animation controller
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Logo scale animation
<<<<<<< HEAD
    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Progress animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
=======
    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Progress animation
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );
>>>>>>> 71abcb3 (push depth pro onnx)

    // Start logo animation
    _logoAnimationController.forward();
  }

  Future<void> _startInitialization() async {
    // Start progress animation
    _progressAnimationController.forward();

    // Simulate ML model loading and initialization steps
    await _initializeMLModels();
    await _checkCameraPermissions();
    await _initializeCameraServices();
    await _prepareMeasurementAlgorithms();

    // Complete initialization
    setState(() {
      _isInitializing = false;
      _initializationStatus = 'Ready to measure!';
      _progress = 1.0;
    });

    // Wait a moment before navigation
    await Future.delayed(const Duration(milliseconds: 800));

    // Navigate to appropriate screen
    _navigateToNextScreen();
  }

  Future<void> _initializeMLModels() async {
    setState(() {
      _initializationStatus = 'Loading TensorFlow Lite models...';
      _progress = 0.25;
    });
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _checkCameraPermissions() async {
    setState(() {
      _initializationStatus = 'Checking camera permissions...';
      _progress = 0.5;
    });
<<<<<<< HEAD
    
    // Check for camera permission
    var status = await Permission.camera.status;
    
=======

    // On desktop platforms, skip camera permission check
    if (kIsWeb ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      await Future.delayed(const Duration(milliseconds: 400));
      return;
    }

    // Check for camera permission (mobile only)
    var status = await Permission.camera.status;

>>>>>>> 71abcb3 (push depth pro onnx)
    if (!status.isGranted) {
      // Navigate to camera permission screen if not granted
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/camera-permission-request');
      }
      return;
    }
<<<<<<< HEAD
    
=======

>>>>>>> 71abcb3 (push depth pro onnx)
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _initializeCameraServices() async {
    setState(() {
      _initializationStatus = 'Initializing camera services...';
      _progress = 0.75;
    });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _prepareMeasurementAlgorithms() async {
    setState(() {
      _initializationStatus = 'Preparing measurement algorithms...';
      _progress = 0.9;
    });
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void _navigateToNextScreen() {
    // Check camera permissions before navigating
    // In a real implementation, we would check permissions here
    // For now, we're navigating to the main measurement screen
    Navigator.pushReplacementNamed(context, '/main-measurement-screen');
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppTheme.lightTheme.colorScheme.primary,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.lightTheme.colorScheme.primary,
                AppTheme.lightTheme.colorScheme.primaryContainer,
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo section
                Expanded(
                  flex: 3,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _logoAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Opacity(
                            opacity: _logoOpacityAnimation.value,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // App logo with measurement icon
                                Container(
                                  width: 25.w,
                                  height: 25.w,
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.lightTheme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(4.w),
                                    boxShadow: [
                                      BoxShadow(
<<<<<<< HEAD
                                        color:
                                            Colors.black.withValues(alpha: 0.2),
=======
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
>>>>>>> 71abcb3 (push depth pro onnx)
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: CustomIconWidget(
                                      iconName: 'straighten',
                                      color: AppTheme
<<<<<<< HEAD
                                          .lightTheme.colorScheme.primary,
=======
                                          .lightTheme
                                          .colorScheme
                                          .primary,
>>>>>>> 71abcb3 (push depth pro onnx)
                                      size: 12.w,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                // App name
                                Text(
                                  'Jarak App',
                                  style: AppTheme
<<<<<<< HEAD
                                      .lightTheme.textTheme.headlineMedium
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
=======
                                      .lightTheme
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: AppTheme
                                            .lightTheme
                                            .colorScheme
                                            .onPrimary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
>>>>>>> 71abcb3 (push depth pro onnx)
                                ),
                                SizedBox(height: 1.h),
                                // Tagline
                                Text(
                                  'Pengukur Jarak Digital Pintar ',
                                  style: AppTheme
<<<<<<< HEAD
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.onPrimary
                                        .withValues(alpha: 0.8),
                                    letterSpacing: 0.5,
                                  ),
=======
                                      .lightTheme
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme
                                            .lightTheme
                                            .colorScheme
                                            .onPrimary
                                            .withValues(alpha: 0.8),
                                        letterSpacing: 0.5,
                                      ),
>>>>>>> 71abcb3 (push depth pro onnx)
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Loading section
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Progress indicator
                      Container(
                        width: 60.w,
                        height: 0.8.h,
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.onPrimary
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(0.4.h),
                        ),
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Stack(
                              children: [
                                Container(
                                  width: 60.w * _progress,
                                  height: 0.8.h,
                                  decoration: BoxDecoration(
                                    color: AppTheme
<<<<<<< HEAD
                                        .lightTheme.colorScheme.onPrimary,
=======
                                        .lightTheme
                                        .colorScheme
                                        .onPrimary,
>>>>>>> 71abcb3 (push depth pro onnx)
                                    borderRadius: BorderRadius.circular(0.4.h),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme
<<<<<<< HEAD
                                            .lightTheme.colorScheme.onPrimary
=======
                                            .lightTheme
                                            .colorScheme
                                            .onPrimary
>>>>>>> 71abcb3 (push depth pro onnx)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 2.h),

                      // Status text
                      Text(
                        _initializationStatus,
<<<<<<< HEAD
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary
                              .withValues(alpha: 0.9),
                          letterSpacing: 0.3,
                        ),
=======
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onPrimary
                                  .withValues(alpha: 0.9),
                              letterSpacing: 0.3,
                            ),
>>>>>>> 71abcb3 (push depth pro onnx)
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 1.h),

                      // Progress percentage
                      Text(
                        '${(_progress * 100).toInt()}%',
<<<<<<< HEAD
                        style:
                            AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary
                              .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
=======
                        style: AppTheme.lightTheme.textTheme.labelLarge
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onPrimary
                                  .withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
>>>>>>> 71abcb3 (push depth pro onnx)
                      ),
                    ],
                  ),
                ),

                // Bottom section with version info
                Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'camera_alt',
                            color: AppTheme.lightTheme.colorScheme.onPrimary
                                .withValues(alpha: 0.6),
                            size: 4.w,
                          ),
                          SizedBox(width: 2.w),
                          CustomIconWidget(
                            iconName: 'psychology',
                            color: AppTheme.lightTheme.colorScheme.onPrimary
                                .withValues(alpha: 0.6),
                            size: 4.w,
                          ),
                          SizedBox(width: 2.w),
                          CustomIconWidget(
                            iconName: 'straighten',
                            color: AppTheme.lightTheme.colorScheme.onPrimary
                                .withValues(alpha: 0.6),
                            size: 4.w,
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Aftaza • Computer Vision • Arif',
<<<<<<< HEAD
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary
                              .withValues(alpha: 0.6),
                          letterSpacing: 0.8,
                        ),
=======
                        style: AppTheme.lightTheme.textTheme.labelSmall
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onPrimary
                                  .withValues(alpha: 0.6),
                              letterSpacing: 0.8,
                            ),
>>>>>>> 71abcb3 (push depth pro onnx)
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Version 1.0.0',
<<<<<<< HEAD
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary
                              .withValues(alpha: 0.5),
                          fontSize: 10.sp,
                        ),
=======
                        style: AppTheme.lightTheme.textTheme.labelSmall
                            ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onPrimary
                                  .withValues(alpha: 0.5),
                              fontSize: 10.sp,
                            ),
>>>>>>> 71abcb3 (push depth pro onnx)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
