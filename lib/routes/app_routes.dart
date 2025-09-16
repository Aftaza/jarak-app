import 'package:flutter/material.dart';
import 'package:jarak_app/presentation/calibration_screen/calibration_screen.dart';
import 'package:jarak_app/presentation/settings_screen/settings_screen.dart';
import 'package:jarak_app/presentation/splash_screen/splash_screen.dart';
import 'package:jarak_app/presentation/camera_permission_screen/camera_permission_screen.dart';
import 'package:jarak_app/presentation/main_measurment_screen/main_measurment_screen.dart';
import 'package:jarak_app/presentation/measurment_result_screen/measurment_result_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String settings = '/settings-screen';
  static const String cameraPermissionRequest = '/camera-permission-request';
  static const String calibrationSetup = '/calibration-setup';
  static const String measurementResults = '/measurement-results';
  static const String mainMeasurement = '/main-measurement-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    settings: (context) => const SettingsScreen(),
    cameraPermissionRequest: (context) => const CameraPermissionRequest(),
    calibrationSetup: (context) => const CalibrationSetup(),
    measurementResults: (context) => const MeasurementResults(),
    mainMeasurement: (context) => const MainMeasurementScreen(),
  };
}
