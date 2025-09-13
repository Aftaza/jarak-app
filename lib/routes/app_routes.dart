import 'package:flutter/material.dart';
import 'package:jarak_app/presentation/camera_permission_screen/camera_permission_screen.dart';
import 'package:jarak_app/presentation/main_measurment_screen/main_measurment_screen.dart';
import 'package:jarak_app/presentation/measurment_result_screen/measurment_result_screen.dart';

class AppRoutes {
  static const String cameraPermission = '/camera-permission';
  static const String mainMeasurement = '/main-measurement';
  static const String measurementResult = '/measurement-result';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case cameraPermission:
        return MaterialPageRoute(
          builder: (_) => CameraPermissionScreen(),
        );
      case mainMeasurement:
        return MaterialPageRoute(
          builder: (_) => MainMeasurementScreen(),
        );
      case measurementResult:
        return MaterialPageRoute(
          builder: (_) => MeasurementResultScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => CameraPermissionScreen(),
        );
    }
  }
}
