<<<<<<< HEAD
import 'dart:math' as math;
=======
import 'dart:io';
import 'dart:typed_data';
>>>>>>> 71abcb3 (push depth pro onnx)

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
<<<<<<< HEAD
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
=======
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
>>>>>>> 71abcb3 (push depth pro onnx)

import '../../core/app_export.dart';
import '../../services/depth_estimation_service.dart';
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
<<<<<<< HEAD
=======
  bool _cameraSupported = true;
>>>>>>> 71abcb3 (push depth pro onnx)

  // Depth estimation service
  final DepthEstimationService _depthService = DepthEstimationService();
  Float32List? _currentDepthMap;
<<<<<<< HEAD

  // Measurement related variables
  List<Offset> _selectedPoints = [];
=======
  Uint8List? _staticImageBytes;

  // Measurement related variables
  Offset? _selectedPoint; // Ubah dari List ke single point
>>>>>>> 71abcb3 (push depth pro onnx)
  bool _isCapturing = false;
  bool _isProcessing = false;
  double? _calculatedDistance;
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
<<<<<<< HEAD
    _initializeCamera();
=======
    // Disable camera on desktop platforms where camera plugin is unsupported
    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);
    _cameraSupported = !isDesktop;
    if (_cameraSupported) {
      _initializeCamera();
    } else {
      // Mark as initialized to avoid loading overlay
      _isCameraInitialized = true;
    }
>>>>>>> 71abcb3 (push depth pro onnx)
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
<<<<<<< HEAD
              orElse: () => _cameras.first)
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first);
=======
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            );
>>>>>>> 71abcb3 (push depth pro onnx)

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

<<<<<<< HEAD
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
=======
  // Camera capture disabled on desktop; static image flow is used instead.
>>>>>>> 71abcb3 (push depth pro onnx)

  Future<void> _initializeDepthService() async {
    try {
      await _depthService.initialize();
      debugPrint('Depth estimation service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize depth estimation service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize depth estimation service'),
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
<<<<<<< HEAD
    if (_selectedPoints.length >= 2) return;

    setState(() {
      _selectedPoints.add(point);
=======
    setState(() {
      _selectedPoint = point;
      _showResults = false; // Reset results when new point is selected
>>>>>>> 71abcb3 (push depth pro onnx)
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();

<<<<<<< HEAD
    // If we have two points, calculate distance
    if (_selectedPoints.length == 2) {
      _calculateDistance();
    }
  }

  void _calculateDistance() {
    if (_selectedPoints.length != 2) return;
=======
    // Calculate distance immediately when point is selected
    _calculateDistance();
  }

  void _calculateDistance() {
    if (_selectedPoint == null) return;
>>>>>>> 71abcb3 (push depth pro onnx)

    setState(() {
      _isProcessing = true;
    });

<<<<<<< HEAD
    // Use depth estimation for more accurate distance calculation
=======
    // Use depth estimation to calculate distance from camera to selected point
>>>>>>> 71abcb3 (push depth pro onnx)
    Future.delayed(Duration(milliseconds: 1500), () async {
      if (!mounted) return;

      double finalDistance = 0.0;

      try {
<<<<<<< HEAD
        // If depth service is initialized, use it for more accurate measurement
        if (_depthService.isInitialized && _currentDepthMap != null) {
          // Get screen size for normalization
          final screenSize = MediaQuery.of(context).size;
          
          // Normalize coordinates to 0-1 range
          final normX1 = _selectedPoints[0].dx / screenSize.width;
          final normY1 = _selectedPoints[0].dy / screenSize.height;
          final normX2 = _selectedPoints[1].dx / screenSize.width;
          final normY2 = _selectedPoints[1].dy / screenSize.height;
          
          // Get depth values at both points
          final depth1 = _depthService.getDepthAt(_currentDepthMap!, normX1, normY1);
          final depth2 = _depthService.getDepthAt(_currentDepthMap!, normX2, normY2);
          
          // Calculate 3D distance (simplified)
          final dx = _selectedPoints[1].dx - _selectedPoints[0].dx;
          final dy = _selectedPoints[1].dy - _selectedPoints[0].dy;
          final dz = (depth2 - depth1) * 1000; // Scale depth difference
          
          final pixelDistance = math.sqrt(dx * dx + dy * dy + dz * dz);
          
          // Convert to real world distance (this would be calibrated)
          double distanceInFeet = pixelDistance * 0.005; // More realistic conversion
          finalDistance = _isImperialUnit ? distanceInFeet : distanceInFeet * 0.3048;
        } else {
          // Fallback to simple pixel-based calculation
          final pixelDistance = math.sqrt(
              math.pow(_selectedPoints[1].dx - _selectedPoints[0].dx, 2) +
                  math.pow(_selectedPoints[1].dy - _selectedPoints[0].dy, 2));

          // Assuming 1 pixel = 0.01 feet for demonstration
          double distanceInFeet = pixelDistance * 0.01;
          finalDistance = _isImperialUnit ? distanceInFeet : distanceInFeet * 0.3048;
        }
      } catch (e) {
        debugPrint('Error calculating distance with depth estimation: $e');
        // Fallback to simple calculation if depth estimation fails
        final pixelDistance = math.sqrt(
            math.pow(_selectedPoints[1].dx - _selectedPoints[0].dx, 2) +
                math.pow(_selectedPoints[1].dy - _selectedPoints[0].dy, 2));

        double distanceInFeet = pixelDistance * 0.01;
        finalDistance = _isImperialUnit ? distanceInFeet : distanceInFeet * 0.3048;
=======
        // If depth service is initialized and we have depth map, use it for accurate measurement
        if (_depthService.isInitialized && _currentDepthMap != null) {
          // Get screen size for normalization
          final screenSize = MediaQuery.of(context).size;

          // Use the depth service to calculate distance to the selected point
          final distanceInMeters = _depthService.calculateDistanceToPoint(
            _selectedPoint!.dx / screenSize.width,
            _selectedPoint!.dy / screenSize.height,
          );

          // Convert to desired unit
          finalDistance = _isImperialUnit
              ? distanceInMeters *
                    3.28084 // Convert meters to feet
              : distanceInMeters;
        } else {
          // Fallback to simple estimation when depth service is not available
          final screenSize = MediaQuery.of(context).size;

          // Use simple position-based estimation
          // Objects at the bottom of screen are assumed closer
          final normalizedY = _selectedPoint!.dy / screenSize.height;

          // Simple linear interpolation: top = 10m, bottom = 1m
          final estimatedDistanceMeters = 10.0 - (normalizedY * 9.0);

          finalDistance = _isImperialUnit
              ? estimatedDistanceMeters *
                    3.28084 // Convert meters to feet
              : estimatedDistanceMeters;
        }
      } catch (e) {
        debugPrint('Error calculating distance with depth estimation: $e');

        // Final fallback to very simple calculation
        final screenSize = MediaQuery.of(context).size;
        final normalizedY = _selectedPoint!.dy / screenSize.height;
        final estimatedDistanceMeters =
            5.0 - (normalizedY * 4.0); // 1m to 5m range

        finalDistance = _isImperialUnit
            ? estimatedDistanceMeters * 3.28084
            : estimatedDistanceMeters;
>>>>>>> 71abcb3 (push depth pro onnx)
      }

      if (mounted) {
        setState(() {
<<<<<<< HEAD
          _calculatedDistance = finalDistance;
=======
          _calculatedDistance = finalDistance.clamp(
            0.1,
            100.0,
          ); // Reasonable range
>>>>>>> 71abcb3 (push depth pro onnx)
          _isProcessing = false;
          _showResults = true;
        });
      }
    });
  }

  void _onCapture() {
    setState(() {
      _isCapturing = true;
<<<<<<< HEAD
      _selectedPoints.clear();
=======
      _selectedPoint = null; // Clear selected point
>>>>>>> 71abcb3 (push depth pro onnx)
      _showResults = false;
    });
  }

  void _onReset() {
    setState(() {
<<<<<<< HEAD
      _selectedPoints.clear();
=======
      _selectedPoint = null; // Clear selected point
>>>>>>> 71abcb3 (push depth pro onnx)
      _isCapturing = false;
      _isProcessing = false;
      _calculatedDistance = null;
      _showResults = false;
<<<<<<< HEAD
=======
      _staticImageBytes = null;
      _currentDepthMap = null;
>>>>>>> 71abcb3 (push depth pro onnx)
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

<<<<<<< HEAD
    final unit = _isImperialUnit ? "ft" : "m";
    final shareText =
        'Distance Measurement: ${_calculatedDistance!.toStringAsFixed(2)} $unit\nMeasured with DistanceMeter App';

=======
>>>>>>> 71abcb3 (push depth pro onnx)
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
<<<<<<< HEAD
            'This app needs camera access to measure distances. Please grant camera permission in settings.'),
=======
          'This app needs camera access to measure distances. Please grant camera permission in settings.',
        ),
>>>>>>> 71abcb3 (push depth pro onnx)
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
<<<<<<< HEAD
        backgroundColor: message.contains('success') 
          ? Colors.green 
          : Colors.red,
=======
        backgroundColor: message.contains('success')
            ? Colors.green
            : Colors.red,
>>>>>>> 71abcb3 (push depth pro onnx)
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
<<<<<<< HEAD
            cameraController: _cameraController,
            selectedPoints: _selectedPoints,
            onPointSelected: _onPointSelected,
            isCapturing: _isCapturing,
            depthMap: _currentDepthMap,
=======
            cameraController: _cameraSupported ? _cameraController : null,
            selectedPoint:
                _selectedPoint, // Changed from selectedPoints to selectedPoint
            onPointSelected: _onPointSelected,
            isCapturing: _isCapturing,
            depthMap: _currentDepthMap,
            staticImageBytes: _staticImageBytes,
>>>>>>> 71abcb3 (push depth pro onnx)
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
<<<<<<< HEAD
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
=======
          if (_cameraSupported)
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
>>>>>>> 71abcb3 (push depth pro onnx)

          // Measurement Controls
          MeasurementControlsWidget(
            isCapturing: _isCapturing,
            isProcessing: _isProcessing,
<<<<<<< HEAD
            selectedPointsCount: _selectedPoints.length,
=======
            selectedPointsCount: _selectedPoint != null
                ? 1
                : 0, // Update to use single point
>>>>>>> 71abcb3 (push depth pro onnx)
            onCapture: _onCapture,
            onReset: _onReset,
            onSave: _onSave,
            onShare: _onShare,
          ),

          // Measurement Results
          MeasurementResultsWidget(
            distance: _calculatedDistance,
            unit: _isImperialUnit ? 'ft' : 'm',
            isVisible: _showResults,
            onClose: () => setState(() => _showResults = false),
            onSave: _onSave,
            onShare: _onShare,
            onRetake: _onReset,
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
<<<<<<< HEAD
=======

          // Desktop info banner if camera unsupported
          if (!_cameraSupported)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Camera is disabled on desktop. You can still test depth processing using static images.',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Load Image button for desktop/static testing
          if (!_cameraSupported)
            Positioned(
              bottom: 90,
              left: 16,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentLight,
                  foregroundColor: Colors.white,
                ),
                onPressed: _pickImageAndProcess,
                icon: const Icon(Icons.file_open),
                label: const Text('Load Image'),
              ),
            ),
>>>>>>> 71abcb3 (push depth pro onnx)
        ],
      ),
    );
  }
<<<<<<< HEAD
=======

  Future<void> _pickImageAndProcess() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      if (file.path == null && file.bytes == null) return;

      final path = file.path;
      final bytes = file.bytes ?? await File(path!).readAsBytes();

      setState(() {
        _staticImageBytes = bytes;
        _isCapturing = true; // enable point selection overlay
      });

      // Show processing dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Processing depth estimation...'),
              ],
            ),
          ),
        );
      }

      // Initialize depth service if needed
      if (!_depthService.isInitialized) {
        await _depthService.initialize();
      }

      // Prefer file path if available for potential EXIF orientation handling later
      final Float32List depth = (path != null)
          ? await _depthService.estimateDepthFromFile(path)
          : await _depthService.estimateDepthFromBytes(bytes);

      // Close processing dialog and show success
      if (mounted) {
        Navigator.of(context).pop(); // Close processing dialog

        setState(() {
          _currentDepthMap = depth;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Depth estimation completed! Tap on image to measure.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking/processing image: $e');
      if (mounted) {
        // Close processing dialog if it's open
        try {
          Navigator.of(context).pop();
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to process image: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorLight,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
>>>>>>> 71abcb3 (push depth pro onnx)
}
