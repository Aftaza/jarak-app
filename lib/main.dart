import 'package:flutter/material.dart';
import 'package:jarak_app/core/app_export.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jarak App',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.cameraPermission,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
