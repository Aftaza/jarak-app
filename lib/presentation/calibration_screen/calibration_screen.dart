import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/calibration_results_widget.dart';
import './widgets/calibration_step_widget.dart';
import './widgets/camera_overlay_widget.dart';
import './widgets/dimension_input_widget.dart';
import './widgets/reference_object_card.dart';

class CalibrationSetup extends StatefulWidget {
  const CalibrationSetup({super.key});

  @override
  State<CalibrationSetup> createState() => _CalibrationSetupState();
}

class _CalibrationSetupState extends State<CalibrationSetup> {
  int _currentStep = 1;
  final int _totalSteps = 5;

  // Camera related
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  XFile? _capturedImage;

  // Calibration data
  String? _selectedObjectId;
  Map<String, dynamic>? _selectedObject;
  List<Offset> _selectedPoints = [];
  double? _customWidth;
  double? _customHeight;
  String _customUnit = 'inches';
  double _measuredValue = 0.0;
  double _actualValue = 0.0;
  double _calibrationFactor = 1.0;

  // UI state
  bool _isProcessing = false;
  String _guidanceText = 'Position object within the frame';

  final List<Map<String, dynamic>> _referenceObjects = [
    {
      "id": "credit_card",
      "name": "Credit Card",
      "dimensions": "3.37 × 2.13 inches",
      "width": 3.37,
      "height": 2.13,
      "unit": "inches",
      "description": "Standard credit card size",
      "image":
          "https://images.pexels.com/photos/164501/pexels-photo-164501.jpeg?auto=compress&cs=tinysrgb&w=400",
    },
    {
      "id": "quarter",
      "name": "US Quarter",
      "dimensions": "0.955 inches diameter",
      "width": 0.955,
      "height": 0.955,
      "unit": "inches",
      "description": "Standard US quarter coin",
      "image":
          "https://images.pexels.com/photos/259027/pexels-photo-259027.jpeg?auto=compress&cs=tinysrgb&w=400",
    },
    {
      "id": "business_card",
      "name": "Business Card",
      "dimensions": "3.5 × 2.0 inches",
      "width": 3.5,
      "height": 2.0,
      "unit": "inches",
      "description": "Standard business card",
      "image":
          "https://images.pexels.com/photos/6801648/pexels-photo-6801648.jpeg?auto=compress&cs=tinysrgb&w=400",
    },
    {
      "id": "a4_paper",
      "name": "A4 Paper",
      "dimensions": "11.7 × 8.3 inches",
      "width": 11.7,
      "height": 8.3,
      "unit": "inches",
      "description": "Standard A4 paper size",
      "image":
          "https://images.pexels.com/photos/6801874/pexels-photo-6801874.jpeg?auto=compress&cs=tinysrgb&w=400",
    },
    {
      "id": "custom",
      "name": "Custom Object",
      "dimensions": "Enter dimensions",
      "width": 0.0,
      "height": 0.0,
      "unit": "inches",
      "description": "Use your own reference object",
      "image":
          "https://images.pexels.com/photos/6801648/pexels-photo-6801648.jpeg?auto=compress&cs=tinysrgb&w=400",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    return (await Permission.camera.request()).isGranted;
  }

  Future<void> _initializeCamera() async {
    try {
      if (!await _requestCameraPermission()) {
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first)
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first);

      _cameraController = CameraController(
          camera, kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high);

      await _cameraController!.initialize();
      await _applySettings();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
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
      debugPrint('Settings error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile photo = await _cameraController!.takePicture();

      setState(() {
        _capturedImage = photo;
        _selectedPoints.clear();
        _guidanceText = 'Tap two points on the object to measure';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      debugPrint('Photo capture error: $e');
    }
  }

  void _onPointSelected(Offset point) {
    if (_selectedPoints.length < 2) {
      setState(() {
        _selectedPoints.add(point);
        if (_selectedPoints.length == 1) {
          _guidanceText = 'Tap the second point';
        } else if (_selectedPoints.length == 2) {
          _guidanceText = 'Points selected. Processing measurement...';
          _processMeasurement();
        }
      });
    }
  }

  void _processMeasurement() {
    if (_selectedPoints.length != 2 || _selectedObject == null) return;

    // Calculate pixel distance
    final double pixelDistance =
        (_selectedPoints[0] - _selectedPoints[1]).distance;

    // Mock measurement calculation (in real app, this would use ML model)
    final double mockMeasuredValue = (_selectedObject!['width'] as double) *
        (0.95 + (0.1 * (pixelDistance / 100)));

    setState(() {
      _measuredValue = mockMeasuredValue;
      _actualValue = _selectedObject!['width'] as double;
      _calibrationFactor = _actualValue / _measuredValue;
    });

    // Auto advance to results step
    Future.delayed(Duration(seconds: 1), () {
      _nextStep();
    });
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _selectObject(String objectId) {
    final object = _referenceObjects.firstWhere((obj) => obj['id'] == objectId);
    setState(() {
      _selectedObjectId = objectId;
      _selectedObject = object;
    });
  }

  void _saveCalibration() {
    // In real app, save calibration factor to persistent storage
    Navigator.pop(context, {
      'calibrationFactor': _calibrationFactor,
      'accuracy':
          (1 - ((_measuredValue - _actualValue).abs() / _actualValue)) * 100,
      'objectUsed': _selectedObject!['name'],
    });
  }

  void _retryMeasurement() {
    setState(() {
      _currentStep = 3; // Go back to camera step
      _selectedPoints.clear();
      _capturedImage = null;
      _guidanceText = 'Position object within the frame';
    });
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 2:
        return _selectedObjectId != null;
      case 3:
        if (_selectedObjectId == 'custom') {
          return _customWidth != null && _customWidth! > 0;
        }
        return true;
      case 4:
        return _capturedImage != null && _selectedPoints.length == 2;
      default:
        return true;
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 1:
        return 'Start Calibration';
      case 2:
        return 'Continue';
      case 3:
        return _selectedObjectId == 'custom'
            ? 'Start Measurement'
            : 'Start Measurement';
      case 4:
        return 'Calculate Results';
      case 5:
        return 'Complete';
      default:
        return 'Next';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildIntroductionStep();
      case 2:
        return _buildObjectSelectionStep();
      case 3:
        return _buildCustomDimensionsStep();
      case 4:
        return _buildMeasurementStep();
      case 5:
        return _buildResultsStep();
      default:
        return Container();
    }
  }

  Widget _buildIntroductionStep() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              CustomIconWidget(
                iconName: 'tune',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 12.w,
              ),
              SizedBox(height: 2.h),
              Text(
                'Improve Measurement Accuracy',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                'Calibrate your device using known reference objects to achieve more precise measurements.',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 3.h),
        _buildBenefitsList(),
      ],
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      {
        'icon': 'accuracy',
        'title': 'Higher Accuracy',
        'description': 'Reduce measurement errors by up to 90%',
      },
      {
        'icon': 'device_hub',
        'title': 'Device-Specific',
        'description': 'Optimized for your specific device camera',
      },
      {
        'icon': 'trending_up',
        'title': 'Improved Results',
        'description': 'Better performance across all measurements',
      },
    ];

    return Column(
      children: benefits
          .map((benefit) => Container(
                margin: EdgeInsets.only(bottom: 2.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: benefit['icon'] as String,
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 6.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            benefit['title'] as String,
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            benefit['description'] as String,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildObjectSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a Reference Object',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Select a common object with known dimensions that you have available.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 3.h),
        ..._referenceObjects
            .map((object) => ReferenceObjectCard(
                  name: object['name'] as String,
                  dimensions: object['dimensions'] as String,
                  imageUrl: object['image'] as String,
                  description: object['description'] as String,
                  isSelected: _selectedObjectId == object['id'],
                  onTap: () => _selectObject(object['id'] as String),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildCustomDimensionsStep() {
    if (_selectedObjectId != 'custom') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color:
              AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 12.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Reference Object Selected',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'You selected: ${_selectedObject!['name']}\nDimensions: ${_selectedObject!['dimensions']}',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Object Dimensions',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Provide the exact dimensions of your reference object for accurate calibration.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 3.h),
        DimensionInputWidget(
          label: 'Width',
          unit: _customUnit,
          initialValue: _customWidth,
          onChanged: (value) {
            setState(() {
              _customWidth = value;
              if (_selectedObject != null) {
                _selectedObject!['width'] = value ?? 0.0;
              }
            });
          },
          errorText: _customWidth == null || _customWidth! <= 0
              ? 'Please enter a valid width'
              : null,
        ),
        SizedBox(height: 2.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'info',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Use a ruler or measuring tape to get the most accurate dimensions.',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementStep() {
    return Column(
      children: [
        if (!_isCameraInitialized) ...[
          Container(
            height: 40.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.hardEdge,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 2.h),
                  Text(
                    'Initializing Camera...',
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Container(
            height: 40.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                if (_capturedImage == null && _cameraController != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CameraPreview(_cameraController!),
                  )
                else if (_capturedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _capturedImage!.path,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                CameraOverlayWidget(
                  showPositioningGuide: _capturedImage == null,
                  showAccuracyIndicator: _selectedPoints.isNotEmpty,
                  accuracyScore: _selectedPoints.length / 2,
                  guidanceText: _guidanceText,
                  selectedPoints: _selectedPoints,
                  onPointSelected:
                      _capturedImage != null ? _onPointSelected : (_) {},
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 3.h),
        if (_capturedImage == null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _isCameraInitialized && !_isProcessing ? _capturePhoto : null,
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 4.w,
                          height: 4.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.lightTheme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text('Processing...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'camera_alt',
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          size: 5.w,
                        ),
                        SizedBox(width: 2.w),
                        Text('Capture Photo'),
                      ],
                    ),
            ),
          ),
        ] else if (_selectedPoints.length < 2) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'touch_app',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Measurement Points',
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Tap two points on the object to measure its width.',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_capturedImage != null) ...[
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _capturedImage = null;
                      _selectedPoints.clear();
                      _guidanceText = 'Position object within the frame';
                    });
                  },
                  child: Text('Retake Photo'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildResultsStep() {
    return CalibrationResultsWidget(
      measuredValue: _measuredValue,
      actualValue: _actualValue,
      unit: _selectedObject!['unit'] as String,
      accuracyPercentage:
          (1 - ((_measuredValue - _actualValue).abs() / _actualValue)) * 100,
      objectName: _selectedObject!['name'] as String,
      onSaveCalibration: _saveCalibration,
      onRetryMeasurement: _retryMeasurement,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Calibration Setup'),
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 6.w,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_currentStep > 1)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Exit Calibration?'),
                    content: Text(
                        'Your progress will be lost. Are you sure you want to exit?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text('Exit'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Exit'),
            ),
        ],
      ),
      body: CalibrationStepWidget(
        currentStep: _currentStep,
        totalSteps: _totalSteps,
        stepTitle: _getStepTitle(),
        stepDescription: _getStepDescription(),
        stepContent: _buildStepContent(),
        onNext: _isStepValid() ? _nextStep : null,
        onPrevious: _currentStep > 1 ? _previousStep : null,
        isNextEnabled: _isStepValid(),
        nextButtonText: _getNextButtonText(),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Welcome to Calibration';
      case 2:
        return 'Select Reference Object';
      case 3:
        return _selectedObjectId == 'custom'
            ? 'Enter Dimensions'
            : 'Object Confirmed';
      case 4:
        return 'Measure Object';
      case 5:
        return 'Calibration Complete';
      default:
        return 'Calibration Setup';
    }
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 1:
        return 'Learn how calibration improves your measurement accuracy and what you\'ll need to get started.';
      case 2:
        return 'Choose a reference object with known dimensions from our library or add your own custom object.';
      case 3:
        return _selectedObjectId == 'custom'
            ? 'Provide the exact dimensions of your custom reference object for accurate calibration.'
            : 'Your selected reference object is ready for measurement. Let\'s proceed to the next step.';
      case 4:
        return 'Use your camera to capture and measure the reference object. This will create your calibration profile.';
      case 5:
        return 'Review your calibration results and save the settings to improve all future measurements.';
      default:
        return 'Follow the steps to calibrate your device for better measurement accuracy.';
    }
  }
}