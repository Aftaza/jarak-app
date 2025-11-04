import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/onnx_depth_estimation_service.dart';

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
  
  // ONNX depth estimation service
  final OnnxDepthEstimationService _depthService = OnnxDepthEstimationService();

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

    // Start logo animation
    _logoAnimationController.forward();
  }

  Future<void> _startInitialization() async {
    // Start progress animation
    _progressAnimationController.forward();

    // First check camera permissions
    await _checkCameraPermissions();
    
    // Then load the ONNX model
    await _initializeONNXModel();
    
    // Initialize camera services
    await _initializeCameraServices();
    
    // Prepare measurement algorithms
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

  Future<void> _initializeONNXModel() async {
    setState(() {
      _initializationStatus = 'Loading ONNX depth estimation model...';
      _progress = 0.25;
    });
    
    try {
      await _depthService.initialize();
      setState(() {
        _progress = 0.5;
      });
    } catch (e) {
      print('Error initializing ONNX model: $e');
      setState(() {
        _initializationStatus = 'Failed to load model - $e';
      });
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> _checkCameraPermissions() async {
    setState(() {
      _initializationStatus = 'Checking camera permissions...';
      _progress = 0.25; // Adjust progress since we now check permissions first
    });
    
    // Check for camera permission
    var status = await Permission.camera.status;
    
    if (!status.isGranted) {
      // Navigate to camera permission screen if not granted
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/camera-permission-request');
      }
      return;
    }
    
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
    _depthService.dispose();
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
                                        color:
                                            Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: CustomIconWidget(
                                      iconName: 'straighten',
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary,
                                      size: 12.w,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                // App name
                                Text(
                                  'Jarak App',
                                  style: AppTheme
                                      .lightTheme.textTheme.headlineMedium
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                // Tagline
                                Text(
                                  'Pengukur Jarak Digital Pintar ',
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.onPrimary
                                        .withValues(alpha: 0.8),
                                    letterSpacing: 0.5,
                                  ),
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
                                        .lightTheme.colorScheme.onPrimary,
                                    borderRadius: BorderRadius.circular(0.4.h),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme
                                            .lightTheme.colorScheme.onPrimary
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
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary
                              .withValues(alpha: 0.9),
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 1.h),

                      // Progress percentage
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style:
                            AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary
                              .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
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
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary
                              .withValues(alpha: 0.6),
                          letterSpacing: 0.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Version 1.0.0',
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary
                              .withValues(alpha: 0.5),
                          fontSize: 10.sp,
                        ),
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
