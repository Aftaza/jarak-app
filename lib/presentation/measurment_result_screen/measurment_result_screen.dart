import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/expandable_details_widget.dart';
import './widgets/result_header_widget.dart';
import './widgets/save_measurement_dialog.dart';
import './widgets/visual_reference_widget.dart';

class MeasurementResults extends StatefulWidget {
  const MeasurementResults({Key? key}) : super(key: key);

  @override
  State<MeasurementResults> createState() => _MeasurementResultsState();
}

class _MeasurementResultsState extends State<MeasurementResults>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  // Mock measurement data
  final List<Map<String, dynamic>> _measurementData = [
    {
      "id": 1,
      "distance": 5.47,
      "unit": "feet",
      "confidence": 0.89,
      "timestamp": DateTime.now().subtract(Duration(minutes: 2)),
      "deviceOrientation": "Portrait",
      "cameraUsed": "Rear Camera",
      "processingTime": 1247,
      "selectedPoints": [
        Offset(120, 80),
        Offset(280, 320),
      ],
      "capturedImagePath":
          "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
    }
  ];

  bool _isMetricUnit = false;
  late Map<String, dynamic> _currentMeasurement;

  @override
  void initState() {
    super.initState();
    _currentMeasurement = _measurementData.first;

    _animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: GestureDetector(
        onTap: _dismissModal,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Background blur effect
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withValues(alpha: 0.3),
              ),

              // Bottom sheet modal
              Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: GestureDetector(
                    onTap: () {}, // Prevent tap from bubbling up
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxHeight: 85.h,
                        minHeight: 50.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Result header with distance and confidence
                            ResultHeaderWidget(
                              distance: _getCurrentDistance(),
                              unit: _getCurrentUnit(),
                              confidence:
                                  (_currentMeasurement["confidence"] as double),
                            ),

                            // Visual reference with measurement overlay
                            VisualReferenceWidget(
                              capturedImagePath:
                                  _currentMeasurement["capturedImagePath"]
                                      as String?,
                              selectedPoints:
                                  (_currentMeasurement["selectedPoints"]
                                          as List)
                                      .cast<Offset>(),
                            ),

                            // Expandable details section
                            ExpandableDetailsWidget(
                              timestamp:
                                  _currentMeasurement["timestamp"] as DateTime,
                              deviceOrientation:
                                  _currentMeasurement["deviceOrientation"]
                                      as String,
                              cameraUsed:
                                  _currentMeasurement["cameraUsed"] as String,
                              processingTime:
                                  _currentMeasurement["processingTime"] as int,
                            ),

                            // Action buttons
                            ActionButtonsWidget(
                              distance: _getCurrentDistance(),
                              unit: _getCurrentUnit(),
                              onSave: _showSaveDialog,
                              onShare: _shareMeasurement,
                              onRetake: _retakeMeasurement,
                              onConvertUnits: _convertUnits,
                            ),

                            // Bottom padding for safe area
                            SizedBox(height: 2.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getCurrentDistance() {
    final originalDistance = _currentMeasurement["distance"] as double;
    if (_isMetricUnit) {
      // Convert feet to meters
      return originalDistance * 0.3048;
    }
    return originalDistance;
  }

  String _getCurrentUnit() {
    return _isMetricUnit ? "meters" : "feet";
  }

  void _dismissModal() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _showSaveDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => SaveMeasurementDialog(
        distance: _getCurrentDistance(),
        unit: _getCurrentUnit(),
        onSave: _saveMeasurement,
      ),
    );
  }

  void _saveMeasurement(String name) {
    HapticFeedback.mediumImpact();

    // Create measurement record
    final measurementRecord = {
      "id": DateTime.now().millisecondsSinceEpoch,
      "name": name,
      "distance": _getCurrentDistance(),
      "unit": _getCurrentUnit(),
      "timestamp": DateTime.now(),
      "confidence": _currentMeasurement["confidence"],
    };

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text('Measurement saved as "$name"'),
            ),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  void _shareMeasurement() {
    HapticFeedback.lightImpact();

    final shareText = '''
Distance Measurement Result

📏 Distance: ${_getCurrentDistance().toStringAsFixed(2)} ${_getCurrentUnit()}
🎯 Confidence: ${((_currentMeasurement["confidence"] as double) * 100).toInt()}%
📅 Measured: ${_formatTimestamp(_currentMeasurement["timestamp"] as DateTime)}
📱 Device: ${_currentMeasurement["cameraUsed"]}

Measured with DistanceMeter App
''';

    // Simulate sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'share',
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text('Measurement shared successfully'),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  void _retakeMeasurement() {
    HapticFeedback.lightImpact();
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
      Navigator.pushReplacementNamed(context, '/main-measurement-screen');
    });
  }

  void _convertUnits() {
    HapticFeedback.selectionClick();
    setState(() {
      _isMetricUnit = !_isMetricUnit;
    });

    // Show conversion feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Converted to ${_getCurrentUnit()}'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.month.toString().padLeft(2, '0')}/${timestamp.day.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
