import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/onnx_depth_estimation_service.dart';
import '../../theme/app_theme.dart';
import './widgets/camera_preview_widget.dart';
import './widgets/camera_settings_widget.dart';
import './widgets/measurement_controls_widget.dart';
import './widgets/measurement_history_widget.dart';
import './widgets/measurement_results_widget.dart';
import './widgets/top_bar_widget.dart';

class MainMeasurementScreen extends StatefulWidget {
  const MainMeasurementScreen({Key? key}) : super(key: key);

  @override
  State<MainMeasurementScreen> createState() => _MainMeasurementScreenState();
}

class _MainMeasurementScreenState extends State<MainMeasurementScreen>
    with TickerProviderStateMixin {
  // Camera related variables
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  double _zoomLevel = 1.0;

  // ONNX depth estimation service
  final OnnxDepthEstimationService _depthService = OnnxDepthEstimationService();
  Float32List? _currentDepthMap;

  // Measurement related variables
  List<Offset> _selectedPoints = [];
  bool _isCapturing = false;
  bool _isProcessing = false;
  double? _calculatedDistance;
  double? _pixelDistance;
  double? _depthDifference;
  bool _showResults = false;

  // Settings
  bool _isImperialUnit = true;
  bool _isHistoryExpanded = false;

  // Mock measurement history data
  final List<Map<String, dynamic>> _measurementHistory = [
    {
      "id": 1,
      "distance": 2.45,
      "unit": "ft",
      "timestamp": DateTime.now().subtract(Duration(hours: 2)),
      "accuracy": "±5%",
    },
    {
      "id": 2,
      "distance": 1.83,
      "unit": "m",
      "timestamp": DateTime.now().subtract(Duration(days: 1)),
      "accuracy": "±3%",
    },
    {
      "id": 3,
      "distance": 4.12,
      "unit": "ft",
      "timestamp": DateTime.now().subtract(Duration(days: 2)),
      "accuracy": "±4%",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeDepthService();
    _loadSettings();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _depthService.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      if (!await _requestCameraPermission()) {
        _showPermissionDialog();
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showErrorDialog('No cameras available on this device');
        return;
      }

      // Select appropriate camera
      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first)
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first);

      // Initialize camera controller
      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      await _applySettings();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      _showErrorDialog('Failed to initialize camera: ${e.toString()}');
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true; // Browser handles permissions

    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _captureAndProcessImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // Capture image from camera
      final image = await _cameraController!.takePicture();
      
      // Process image with depth estimation if service is available
      if (_depthService.isInitialized) {
        final depthMap = await _depthService.estimateDepthFromFile(image.path);
        setState(() {
          _currentDepthMap = depthMap;
        });
      }
    } catch (e) {
      debugPrint('Error capturing and processing image: $e');
    }
  }

  Future<void> _initializeDepthService() async {
    try {
      await _depthService.initialize();
      debugPrint('ONNX depth estimation service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize ONNX depth estimation service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize ONNX depth estimation service'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isImperialUnit = prefs.getBool('imperial_unit') ?? true;
      });
    } catch (e) {
      debugPrint('Settings loading error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('imperial_unit', _isImperialUnit);
    } catch (e) {
      debugPrint('Settings saving error: $e');
    }
  }

  Future<void> _applySettings() async {
    if (_cameraController == null) return;

    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
      if (!kIsWeb) {
        try {
          await _cameraController!.setFlashMode(FlashMode.auto);
        } catch (e) {
          debugPrint('Flash mode not supported: $e');
        }
      }
    } catch (e) {
      debugPrint('Settings application error: $e');
    }
  }

  void _onPointSelected(Offset point) {
    if (_selectedPoints.length >= 2) return;

    setState(() {
      _selectedPoints.add(point);
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // If we have two points, calculate distance
    if (_selectedPoints.length == 2) {
      _calculateDistance();
    }
  }

  void _calculateDistance() {
    if (_selectedPoints.length != 2) return;

    setState(() {
      _isProcessing = true;
    });

    // Use depth estimation for more accurate distance calculation
    Future.delayed(Duration(milliseconds: 1500), () async {
      if (!mounted) return;

      double finalDistance = 0.0;

      try {
        // If depth service is initialized, use it for more accurate measurement
        if (_depthService.isInitialized && _currentDepthMap != null) {
          // Get screen size for normalization
          final screenSize = MediaQuery.of(context).size;
          
          // Normalize coordinates to 0-1 range
          final normX1 = _selectedPoints[0].dx / screenSize.width;
          final normY1 = _selectedPoints[0].dy / screenSize.height;
          final normX2 = _selectedPoints[1].dx / screenSize.width;
          final normY2 = _selectedPoints[1].dy / screenSize.height;
          
          // Calculate pixel distance between the two points
          final pixelDistance = _depthService.calculatePixelDistance(
            _selectedPoints[0].dx, 
            _selectedPoints[0].dy, 
            _selectedPoints[1].dx, 
            _selectedPoints[1].dy
          );
          
          // Get depth values at both points
          final depth1 = _depthService.getDepthAt(_currentDepthMap!, normX1, normY1);
          final depth2 = _depthService.getDepthAt(_currentDepthMap!, normX2, normY2);
          
          // Calculate depth difference between the two points
          final depthDifference = _depthService.calculateDepthDifference(
            _currentDepthMap!, normX1, normY1, normX2, normY2
          );
          
          // Calculate both the pixel distance and depth difference as required
          // Pixel distance: sqrt(dx² + dy²)
          // Depth difference: |depth2 - depth1|
          
          // In real-world applications, you would need camera calibration to convert
          // pixel distances to real-world measurements. For now, we'll return the
          // depth difference as the primary measurement in meters, as that's what
          // the depth estimation model provides
          
          // The depth difference is already in meters from the ONNX model
          finalDistance = depthDifference; // This is the depth difference in meters
          
          // Store the calculated values to display in the UI
          setState(() {
            _pixelDistance = pixelDistance;
            _depthDifference = depthDifference;
          });
        } else {
          // Fallback to simple pixel-based calculation
          final pixelDistance = math.sqrt(
              math.pow(_selectedPoints[1].dx - _selectedPoints[0].dx, 2) +
                  math.pow(_selectedPoints[1].dy - _selectedPoints[0].dy, 2));

          // For fallback, assume 100 pixels = 1 meter as an example
          double distanceInMeters = pixelDistance * 0.01;
          finalDistance = distanceInMeters;
          
          // Store the calculated values to display in the UI
          setState(() {
            _pixelDistance = pixelDistance;
            _depthDifference = null; // No depth data available without the model
          });
        }
      } catch (e) {
        debugPrint('Error calculating distance with depth estimation: $e');
        // Fallback to simple calculation if depth estimation fails
        final pixelDistance = math.sqrt(
            math.pow(_selectedPoints[1].dx - _selectedPoints[0].dx, 2) +
                math.pow(_selectedPoints[1].dy - _selectedPoints[0].dy, 2));

        double distanceInMeters = pixelDistance * 0.01;
        finalDistance = distanceInMeters;
        
        // Store the calculated values to display in the UI
        setState(() {
          _pixelDistance = pixelDistance;
          _depthDifference = null; // Error occurred, so no depth data
        });
      }

      if (mounted) {
        setState(() {
          _calculatedDistance = finalDistance;
          _isProcessing = false;
          _showResults = true;
        });
      }
    });
  }

  void _onCapture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // Capture image from camera
      final image = await _cameraController!.takePicture();
      
      setState(() {
        _isCapturing = true;
        _selectedPoints.clear();
        _showResults = false;
        _isProcessing = true;
      });

      // Process image with ONNX model
      if (_depthService.isInitialized) {
        final depthMap = await _depthService.estimateDepthFromFile(image.path);
        setState(() {
          _currentDepthMap = depthMap;
          _isProcessing = false;
        });
        
        // Show a success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image captured and depth map generated'),
              backgroundColor: AppTheme.accentLight,
            ),
          );
        }
      } else {
        // If depth service is not initialized, show an error
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Depth estimation service not available'),
              backgroundColor: AppTheme.errorLight,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing and processing image: $e');
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: ${e.toString()}'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    }
  }

  void _onReset() {
    setState(() {
      _selectedPoints.clear();
      _isCapturing = false;
      _isProcessing = false;
      _calculatedDistance = null;
      _showResults = false;
    });
  }

  void _onSave() {
    if (_calculatedDistance == null) return;

    final newMeasurement = {
      "id": _measurementHistory.length + 1,
      "distance": _calculatedDistance!,
      "unit": _isImperialUnit ? "ft" : "m",
      "timestamp": DateTime.now(),
      "accuracy": "±5%",
    };

    setState(() {
      _measurementHistory.insert(0, newMeasurement);
      _showResults = false;
    });

    _onReset();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Measurement saved successfully'),
        backgroundColor: AppTheme.accentLight,
      ),
    );
  }

  void _onShare() {
    if (_calculatedDistance == null) return;

    final unit = _isImperialUnit ? "ft" : "m";
    final shareText =
        'Distance Measurement: ${_calculatedDistance!.toStringAsFixed(2)} $unit\nMeasured with DistanceMeter App';

    // In a real app, you would use share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality would open here'),
        backgroundColor: AppTheme.lightTheme.primaryColor,
      ),
    );
  }

  void _toggleFlash() {
    if (kIsWeb || _cameraController == null) return;

    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      _cameraController!.setFlashMode(newFlashMode);
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;

    final newCamera = _isFrontCamera
        ? _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => _cameras.first,
          )
        : _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => _cameras.first,
          );

    _cameraController?.dispose();
    _cameraController = CameraController(
      newCamera,
      kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
      enableAudio: false,
    );

    _cameraController!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isFrontCamera = !_isFrontCamera;
        });
        _applySettings();
      }
    });
  }

  void _onZoomChanged(double zoom) {
    if (kIsWeb || _cameraController == null) return;

    try {
      _cameraController!.setZoomLevel(zoom);
      setState(() {
        _zoomLevel = zoom;
      });
    } catch (e) {
      debugPrint('Zoom change error: $e');
    }
  }

  void _onFocusTap() {
    // In a real app, this would trigger autofocus
    HapticFeedback.selectionClick();
  }

  void _toggleUnit() {
    setState(() {
      _isImperialUnit = !_isImperialUnit;
    });
    _saveSettings();
  }

  void _toggleHistory() {
    setState(() {
      _isHistoryExpanded = !_isHistoryExpanded;
    });
  }

  void _deleteMeasurement(int index) {
    setState(() {
      _measurementHistory.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Measurement deleted'),
        backgroundColor: AppTheme.errorLight,
      ),
    );
  }

  void _selectMeasurement(Map<String, dynamic> measurement) {
    setState(() {
      _calculatedDistance = measurement['distance'] as double;
      _showResults = true;
      _isHistoryExpanded = false;
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Camera Permission Required'),
        content: Text(
            'This app needs camera access to measure distances. Please grant camera permission in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Method untuk menampilkan feedback
  void _showCameraFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: message.contains('success') 
          ? Colors.green 
          : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          CameraPreviewWidget(
            cameraController: _cameraController,
            selectedPoints: _selectedPoints,
            onPointSelected: _onPointSelected,
            isCapturing: _isCapturing,
            depthMap: _currentDepthMap,
          ),

          // Top Bar
          TopBarWidget(
            isImperialUnit: _isImperialUnit,
            onToggleUnit: _toggleUnit,
            onOpenSettings: () =>
                Navigator.pushNamed(context, '/settings-screen'),
            onOpenCalibration: () =>
                Navigator.pushNamed(context, '/calibration-setup'),
          ),

          // Camera Settings
          CameraSettingsWidget(
            cameraController: _cameraController,
            isFlashOn: _isFlashOn,
            isFrontCamera: _isFrontCamera,
            zoomLevel: _zoomLevel,
            onToggleFlash: _toggleFlash,
            onSwitchCamera: _switchCamera,
            onZoomChanged: _onZoomChanged,
            onFocusTap: _onFocusTap,
            onShowFeedback: _showCameraFeedback,
          ),

          // Measurement Controls
          MeasurementControlsWidget(
            isCapturing: _isCapturing,
            isProcessing: _isProcessing,
            selectedPointsCount: _selectedPoints.length,
            onCapture: _onCapture,
            onReset: _onReset,
            onSave: _onSave,
            onShare: _onShare,
          ),

          // Measurement Results
          MeasurementResultsWidget(
            distance: _calculatedDistance,
            unit: 'm', // Always display in meters as per new requirements
            isVisible: _showResults,
            onClose: () => setState(() => _showResults = false),
            onSave: _onSave,
            onShare: _onShare,
            onRetake: _onReset,
            pixelDistance: _pixelDistance,
            depthDifference: _depthDifference,
          ),

          // Measurement History
          MeasurementHistoryWidget(
            isExpanded: _isHistoryExpanded,
            measurements: _measurementHistory,
            onToggle: _toggleHistory,
            onDeleteMeasurement: _deleteMeasurement,
            onSelectMeasurement: _selectMeasurement,
          ),

          // Loading overlay
          if (!_isCameraInitialized)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.lightTheme.primaryColor,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Initializing Camera...',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
