import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/depth_estimation_service.dart';
import '../../services/depth_measurement_service.dart';
import '../../theme/app_theme.dart';
import './widgets/camera_preview_widget.dart';
import './widgets/camera_settings_widget.dart';
import './widgets/measurement_controls_widget.dart';
import './widgets/measurement_history_widget.dart';
import './widgets/measurement_results_widget.dart';
import './widgets/top_bar_widget.dart';
import './models/measurement_point.dart';

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
  bool _cameraSupported = true;
  bool _isPreviewPaused = false;

  // Depth estimation service
  final DepthEstimationService _depthService = DepthEstimationService();
  DepthMeasurementService? _depthMeasurementService;
  Float32List? _currentDepthMap;
  Uint8List? _staticImageBytes;
  Size? _capturedImageSize;

  // Measurement related variables
  MeasurementPoint? _selectedPoint;
  bool _isCapturing = false;
  bool _isProcessing = false;
  double? _calculatedDistance;
  bool _showResults = false;
  bool _showFrozenFrame = false;

  // Settings
  bool _isImperialUnit = true;
  bool _isHistoryExpanded = false;
  double _calibrationScale = 1.0;
  double? _lastCalibrationAccuracy;
  String? _lastCalibrationObject;

  // Mock measurement history data
  final List<Map<String, dynamic>> _measurementHistory = [
    {
      "id": 1,
      "distance": 2.45,
      "unit": "ft",
      "timestamp": DateTime.now().subtract(Duration(hours: 2)),
      "accuracy": "±5%",
      "imageBytes": null, // Gambar untuk entry lama tidak tersedia
      "selectedPoint": null,
    },
    {
      "id": 2,
      "distance": 1.83,
      "unit": "m",
      "timestamp": DateTime.now().subtract(Duration(days: 1)),
      "accuracy": "±3%",
      "imageBytes": null, // Gambar untuk entry lama tidak tersedia
      "selectedPoint": null,
    },
    {
      "id": 3,
      "distance": 4.12,
      "unit": "ft",
      "timestamp": DateTime.now().subtract(Duration(days: 2)),
      "accuracy": "±4%",
      "imageBytes": null, // Gambar untuk entry lama tidak tersedia
      "selectedPoint": null,
    },
  ];

  @override
  void initState() {
    super.initState();
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
    // Lazy-initialize depth service on first capture to reduce startup memory pressure
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
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            );

      // Initialize camera controller
      // Use a moderate resolution to reduce memory and processing time.
      // High resolutions can cause OOM when combined with ML processing on low-end devices.
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
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

  // Camera capture disabled on desktop; static image flow is used instead.

  // Depth service now initializes lazily on first capture to avoid high startup memory usage.

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isImperialUnit = prefs.getBool('imperial_unit') ?? true;
        _calibrationScale = prefs.getDouble('calibration_factor') ?? 1.0;
        _lastCalibrationAccuracy = prefs.getDouble('calibration_accuracy');
        _lastCalibrationObject = prefs.getString('calibration_object');
      });

      _updateMeasurementService();
    } catch (e) {
      debugPrint('Settings loading error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('imperial_unit', _isImperialUnit);
      await prefs.setDouble('calibration_factor', _calibrationScale);
      if (_lastCalibrationAccuracy != null) {
        await prefs.setDouble(
          'calibration_accuracy',
          _lastCalibrationAccuracy!,
        );
      }
      if (_lastCalibrationObject != null) {
        await prefs.setString('calibration_object', _lastCalibrationObject!);
      }
    } catch (e) {
      debugPrint('Settings saving error: $e');
    }
  }

  void _updateMeasurementService() {
    if (_currentDepthMap == null || _currentDepthMap!.isEmpty) {
      _depthMeasurementService = null;
      return;
    }

    _depthMeasurementService = DepthMeasurementService(
      depthService: _depthService,
      calibrationScale: _calibrationScale,
    );
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

  void _onPointSelected(MeasurementPoint point) {
    setState(() {
      _selectedPoint = point;
      _showResults = false; // Reset results when new point is selected
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Calculate distance immediately when point is selected
    _calculateDistance();
  }

  void _calculateDistance() {
    if (_selectedPoint == null) return;

    // Cek apakah depth map sudah tersedia
    if (_currentDepthMap == null || _currentDepthMap!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Depth map not ready. Please wait for processing to complete.',
          ),
          backgroundColor: AppTheme.errorLight,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Use depth estimation to calculate distance from camera to selected point
    Future.delayed(Duration(milliseconds: 500), () async {
      if (!mounted) return;

      double finalDistance = 0.0;

      try {
        // If depth service is initialized and we have depth map, use it for accurate measurement
        if (_depthMeasurementService != null &&
            _currentDepthMap != null &&
            _currentDepthMap!.isNotEmpty) {
          debugPrint(
            'Calculating distance at point: (${_selectedPoint!.normalized.dx}, ${_selectedPoint!.normalized.dy})',
          );

          final double distanceInMeters = _depthMeasurementService!
              .distanceAtNormalizedPoint(
                normalizedX: _selectedPoint!.normalized.dx,
                normalizedY: _selectedPoint!.normalized.dy,
              );

          debugPrint('Distance in meters: $distanceInMeters');

          if (distanceInMeters > 0) {
            finalDistance = _isImperialUnit
                ? distanceInMeters * 3.28084
                : distanceInMeters;
          }
        }

        if (finalDistance == 0.0) {
          // Fallback to simple estimation when depth service is not available or returns invalid data
          // Use simple position-based estimation: objects lower in frame assumed closer
          final normalizedY = _selectedPoint!.normalized.dy;

          // Simple linear interpolation: top = 10m, bottom = 1m
          final estimatedDistanceMeters = 10.0 - (normalizedY * 9.0);

          finalDistance = _isImperialUnit
              ? estimatedDistanceMeters * 3.28084
              : estimatedDistanceMeters;

          debugPrint('Using fallback distance calculation: $finalDistance');
        }
      } catch (e) {
        debugPrint('Error calculating distance with depth estimation: $e');

        // Final fallback to very simple calculation
        final normalizedY = _selectedPoint!.normalized.dy;
        final estimatedDistanceMeters =
            5.0 - (normalizedY * 4.0); // 1m to 5m range

        finalDistance = _isImperialUnit
            ? estimatedDistanceMeters * 3.28084
            : estimatedDistanceMeters;
      }

      if (mounted) {
        setState(() {
          _calculatedDistance = finalDistance.clamp(
            0.1,
            100.0,
          ); // Reasonable range
          _isProcessing = false;
          _showResults = true;
        });

        debugPrint(
          'Final calculated distance: $_calculatedDistance ${_isImperialUnit ? 'ft' : 'm'}',
        );
      }
    });
  }

  void _onCapture() {
    if (_isProcessing) return;

    if (_cameraSupported && _cameraController != null) {
      _captureFrameAndEstimateDepth();
    } else {
      setState(() {
        _isCapturing = true;
        _selectedPoint = null; // Clear selected point
        _showResults = false;
        _currentDepthMap = null;
        _staticImageBytes = null;
        _capturedImageSize = null;
        _showFrozenFrame = _staticImageBytes != null;
      });
    }
  }

  Future<void> _captureFrameAndEstimateDepth() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('❌ Camera not ready');
      return;
    }

    debugPrint('📸 Starting capture process...');
    setState(() {
      _isProcessing = true;
      _showResults = false;
      _selectedPoint = null;
    });

    try {
      // 1. Capture gambar terlebih dahulu
      debugPrint('📸 Step 1: Taking picture...');
      final capturedFile = await _cameraController!.takePicture();
      final bytes = await capturedFile.readAsBytes();
      debugPrint('✅ Picture taken, size: ${bytes.length} bytes');

      final Size? imageSize = await _decodeImageSize(bytes);
      debugPrint('📐 Image size: ${imageSize?.width} x ${imageSize?.height}');

      // 2. Pause preview SETELAH capture berhasil
      debugPrint('⏸️ Step 2: Pausing camera preview...');
      try {
        await _cameraController!.pausePreview();
        if (mounted) {
          setState(() {
            _isPreviewPaused = true;
          });
        }
        debugPrint('✅ Camera preview paused');
      } catch (pauseError) {
        debugPrint('⚠️ Unable to pause preview: $pauseError');
      }

      // 3. Tampilkan gambar yang di-capture (freeze frame)
      debugPrint('🖼️ Step 3: Displaying frozen frame...');
      if (!mounted) return;
      // Downscale preview to reduce UI memory usage on low-end devices
      final previewBytes = await _downscaleForPreview(bytes, maxWidth: 1080);
      setState(() {
        _staticImageBytes = previewBytes ?? bytes;
        _capturedImageSize = imageSize;
        _showFrozenFrame = true;
      });
      debugPrint(
        '✅ Frozen frame displayed, showFrozenFrame: $_showFrozenFrame',
      );

      // 4. Proses depth estimation (ini yang memakan waktu)
      if (!_depthService.isInitialized) {
        debugPrint('🔧 Initializing depth service...');
        await _depthService.initialize();
      }

      debugPrint('🧠 Step 4: Starting depth estimation...');
      // Jalankan inference dari file path untuk menekan penggunaan RAM
      final depth = await _depthService.estimateDepthFromFile(
        capturedFile.path,
      );
      debugPrint(
        '✅ Depth estimation completed. Depth map size: ${depth.length}',
      );

      if (!mounted) return;

      // 5. Update state dengan hasil depth estimation
      debugPrint('💾 Step 5: Updating state with depth map...');
      setState(() {
        _currentDepthMap = depth;
        _isCapturing = true;
        _isProcessing = false;
        _calculatedDistance = null;
      });

      _updateMeasurementService();
      debugPrint(
        '✅ All done! Ready for point selection. isCapturing: $_isCapturing',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Frame captured. Tap a point to measure depth.'),
          backgroundColor: AppTheme.accentLight,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error capturing frame: $e');
      try {
        if (_isPreviewPaused) {
          await _cameraController?.resumePreview();
          if (mounted) {
            setState(() {
              _isPreviewPaused = false;
            });
          }
        }
      } catch (resumeError) {
        debugPrint('Failed to resume preview after error: $resumeError');
      }
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _isCapturing = false;
        _showFrozenFrame = false;
        _staticImageBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture frame: ${e.toString()}'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }

  void _onReset() {
    if (_isPreviewPaused) {
      _cameraController?.resumePreview().catchError((e) {
        debugPrint('Failed to resume preview on reset: $e');
      });
      _isPreviewPaused = false;
    }

    setState(() {
      _selectedPoint = null; // Clear selected point
      _isCapturing = false;
      _isProcessing = false;
      _calculatedDistance = null;
      _showResults = false;
      _staticImageBytes = null;
      _currentDepthMap = null;
      _capturedImageSize = null;
      _showFrozenFrame = false;
      _depthMeasurementService = null;
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
      "imageBytes": _staticImageBytes, // Simpan gambar yang sudah diproses
      "selectedPoint": _selectedPoint?.normalized, // Simpan titik yang dipilih
      "depthMap": _currentDepthMap, // Simpan depth map jika ada
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
      ResolutionPreset.medium,
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

  Future<void> _openCalibration() async {
    final result = await Navigator.pushNamed(context, '/calibration-setup');
    if (!mounted) return;

    if (result is Map<String, dynamic>) {
      final double? factor = (result['calibrationFactor'] as num?)?.toDouble();
      final double? accuracy = (result['accuracy'] as num?)?.toDouble();
      final String? objectUsed = result['objectUsed'] as String?;

      setState(() {
        if (factor != null && factor > 0) {
          _calibrationScale = factor;
        }
        _lastCalibrationAccuracy = accuracy;
        _lastCalibrationObject = objectUsed;
      });

      _updateMeasurementService();
      await _saveSettings();

      if (factor != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Calibration updated using ${objectUsed ?? 'reference object'}',
            ),
            backgroundColor: AppTheme.accentLight,
          ),
        );
      }
    }
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
          'This app needs camera access to measure distances. Please grant camera permission in settings.',
        ),
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
            cameraController: _cameraSupported ? _cameraController : null,
            selectedPoint:
                _selectedPoint, // Changed from selectedPoints to selectedPoint
            onPointSelected: _onPointSelected,
            isCapturing: _isCapturing,
            showFrozenFrame: _showFrozenFrame,
            depthMap: _currentDepthMap,
            staticImageBytes: _staticImageBytes,
            capturedImageSize: _capturedImageSize,
            calculatedDistance: _calculatedDistance,
            unit: _isImperialUnit ? 'ft' : 'm',
          ),

          // Top Bar
          TopBarWidget(
            isImperialUnit: _isImperialUnit,
            onToggleUnit: _toggleUnit,
            onOpenSettings: () =>
                Navigator.pushNamed(context, '/settings-screen'),
            onOpenCalibration: () {
              _openCalibration();
            },
          ),

          // Camera Settings
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

          // Measurement Controls
          MeasurementControlsWidget(
            isCapturing: _isCapturing,
            isProcessing: _isProcessing,
            selectedPointsCount: _selectedPoint != null
                ? 1
                : 0, // Update to use single point
            onCapture: _onCapture,
            onReset: _onReset,
            onSave: _onSave,
            onShare: _onShare,
            onLoadImage: _pickImageAndProcess,
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

          // Processing overlay (for depth estimation)
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.lightTheme.primaryColor,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Processing depth estimation...',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Please wait...',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Desktop info banner if camera unsupported
          if (!_cameraSupported)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
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
        ],
      ),
    );
  }

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
      final Size? imageSize = await _decodeImageSize(bytes);

      setState(() {
        _staticImageBytes = bytes;
        _capturedImageSize = imageSize;
        _isCapturing = true; // enable point selection overlay
        _showFrozenFrame = true;
        _isPreviewPaused = true;
        _selectedPoint = null;
        _showResults = false;
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

        _updateMeasurementService();

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

  Future<Size?> _decodeImageSize(Uint8List bytes) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final Size size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      codec.dispose();
      return size;
    } catch (e) {
      debugPrint('Image size decode error: $e');
      return null;
    }
  }

  // Downscale image bytes for preview to avoid keeping very large frames in memory.
  Future<Uint8List?> _downscaleForPreview(
    Uint8List bytes, {
    int maxWidth = 1080,
  }) async {
    try {
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: maxWidth,
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image img = frame.image;
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      codec.dispose();
      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Preview downscale error: $e');
      return null;
    }
  }
}
