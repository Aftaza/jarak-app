import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/permission_status_widget.dart';
import './widgets/settings_dropdown_widget.dart';
import './widgets/settings_row_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/settings_slider_widget.dart';
import './widgets/settings_toggle_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Measurement Preferences
  bool _isImperialUnits = true;
  double _decimalPrecision = 2.0;
  bool _autoSave = true;

  // Camera Settings
  String _defaultCamera = 'Rear Camera';
  bool _gridOverlay = false;
  String _imageQuality = 'High';

  // Display Options
  bool _darkMode = false;
  bool _hapticFeedback = true;
  bool _measurementOverlay = true;

  // Privacy
  bool _cameraPermissionGranted = false;

  // Advanced Settings
  bool _optimizeProcessing = true;

  final List<Map<String, dynamic>> _appInfo = [
    {
      "title": "App Version",
      "value": "1.0.0",
      "description": "Current application version"
    },
    {
      "title": "Model Version",
      "value": "TensorFlow Lite 2.14.0",
      "description": "Machine learning model version"
    },
    {
      "title": "Device Compatibility",
      "value": "Fully Compatible",
      "description": "Device supports all features"
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (!kIsWeb) {
      final cameraStatus = await Permission.camera.status;
      setState(() {
        _cameraPermissionGranted = cameraStatus.isGranted;
      });
    } else {
      setState(() {
        _cameraPermissionGranted = true; // Web handles permissions differently
      });
    }
  }

  Future<void> _openAppSettings() async {
    if (!kIsWeb) {
      await openAppSettings();
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reset to Defaults',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          content: Text(
            'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _resetToDefaults();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to defaults'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  void _resetToDefaults() {
    setState(() {
      _isImperialUnits = true;
      _decimalPrecision = 2.0;
      _autoSave = true;
      _defaultCamera = 'Rear Camera';
      _gridOverlay = false;
      _imageQuality = 'High';
      _darkMode = false;
      _hapticFeedback = true;
      _measurementOverlay = true;
      _optimizeProcessing = true;
    });
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'About Jarak App',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jarak App is a computer vision application that enables accurate distance measurement using your device camera and machine learning.',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              SizedBox(height: 2.h),
              Text(
                'Developed with Flutter and TensorFlow Lite for precise measurements in professional and personal use.',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        title: Text(
          'Settings',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Column(
          children: [
            // Measurement Preferences Section
            SettingsSectionWidget(
              title: 'Measurement Preferences',
              children: [
                SettingsRowWidget(
                  title: 'Default Units',
                  subtitle: 'Choose between Imperial and Metric units',
                  trailing: SettingsToggleWidget(
                    value: _isImperialUnits,
                    onChanged: (value) {
                      setState(() {
                        _isImperialUnits = value;
                      });
                    },
                  ),
                  isFirst: true,
                ),
                SettingsRowWidget(
                  title: 'Decimal Precision',
                  subtitle: 'Number of decimal places in measurements',
                  trailing: SizedBox(
                    width: 30.w,
                    child: SettingsSliderWidget(
                      value: _decimalPrecision,
                      min: 0,
                      max: 4,
                      divisions: 4,
                      onChanged: (value) {
                        setState(() {
                          _decimalPrecision = value;
                        });
                      },
                      labelFormatter: (value) => '${value.toInt()} places',
                    ),
                  ),
                ),
                SettingsRowWidget(
                  title: 'Auto-Save Results',
                  subtitle: 'Automatically save measurement results',
                  trailing: SettingsToggleWidget(
                    value: _autoSave,
                    onChanged: (value) {
                      setState(() {
                        _autoSave = value;
                      });
                    },
                  ),
                  isLast: true,
                  showDivider: false,
                ),
              ],
            ),

            // Camera Settings Section
            SettingsSectionWidget(
              title: 'Camera Settings',
              children: [
                SettingsRowWidget(
                  title: 'Default Camera',
                  subtitle: 'Choose which camera to use by default',
                  trailing: SizedBox(
                    width: 35.w,
                    child: SettingsDropdownWidget(
                      value: _defaultCamera,
                      options: ['Rear Camera', 'Front Camera'],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _defaultCamera = value;
                          });
                        }
                      },
                    ),
                  ),
                  isFirst: true,
                ),
                SettingsRowWidget(
                  title: 'Grid Overlay',
                  subtitle: 'Show alignment grid on camera preview',
                  trailing: SettingsToggleWidget(
                    value: _gridOverlay,
                    onChanged: (value) {
                      setState(() {
                        _gridOverlay = value;
                      });
                    },
                  ),
                ),
                SettingsRowWidget(
                  title: 'Image Quality',
                  subtitle:
                      'Higher quality improves accuracy but slows processing',
                  trailing: SizedBox(
                    width: 25.w,
                    child: SettingsDropdownWidget(
                      value: _imageQuality,
                      options: ['Low', 'Medium', 'High'],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _imageQuality = value;
                          });
                        }
                      },
                    ),
                  ),
                  isLast: true,
                  showDivider: false,
                ),
              ],
            ),

            // Display Options Section
            SettingsSectionWidget(
              title: 'Display Options',
              children: [
                SettingsRowWidget(
                  title: 'Dark Mode',
                  subtitle: 'Follow system preference for dark theme',
                  trailing: SettingsToggleWidget(
                    value: _darkMode,
                    onChanged: (value) {
                      setState(() {
                        _darkMode = value;
                      });
                    },
                  ),
                  isFirst: true,
                ),
                SettingsRowWidget(
                  title: 'Haptic Feedback',
                  subtitle: 'Vibrate on button presses and interactions',
                  trailing: SettingsToggleWidget(
                    value: _hapticFeedback,
                    onChanged: (value) {
                      setState(() {
                        _hapticFeedback = value;
                      });
                    },
                  ),
                ),
                SettingsRowWidget(
                  title: 'Measurement Overlay',
                  subtitle: 'Show measurement lines and markers on results',
                  trailing: SettingsToggleWidget(
                    value: _measurementOverlay,
                    onChanged: (value) {
                      setState(() {
                        _measurementOverlay = value;
                      });
                    },
                  ),
                  isLast: true,
                  showDivider: false,
                ),
              ],
            ),

            // Privacy Section
            SettingsSectionWidget(
              title: 'Privacy',
              children: [
                SettingsRowWidget(
                  title: 'Camera Permission',
                  subtitle: 'Required for distance measurement functionality',
                  trailing: SizedBox(
                    width: 60.w,
                    child: PermissionStatusWidget(
                      permissionName: 'Camera Access',
                      isGranted: _cameraPermissionGranted,
                      onTap: _openAppSettings,
                    ),
                  ),
                  isFirst: true,
                ),
                SettingsRowWidget(
                  title: 'Data Usage',
                  subtitle: 'All processing is done locally on your device',
                  trailing: CustomIconWidget(
                    iconName: 'info',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Data Privacy'),
                        content: const Text(
                          'Jarak App processes all images locally on your device. No images or measurement data are sent to external servers or stored in the cloud.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  isLast: true,
                  showDivider: false,
                ),
              ],
            ),

            // Advanced Settings Section
            SettingsSectionWidget(
              title: 'Advanced Settings',
              children: [
                SettingsRowWidget(
                  title: 'TensorFlow Lite Model',
                  subtitle: 'Manage machine learning model settings',
                  trailing: CustomIconWidget(
                    iconName: 'chevron_right',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onTap: () {
                    // Navigate to model management screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Model management coming soon'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  isFirst: true,
                ),
                SettingsRowWidget(
                  title: 'Calibration',
                  subtitle: 'Calibrate using known reference objects',
                  trailing: CustomIconWidget(
                    iconName: 'chevron_right',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/calibration-setup');
                  },
                ),
                SettingsRowWidget(
                  title: 'Processing Optimization',
                  subtitle: 'Optimize for speed vs accuracy balance',
                  trailing: SettingsToggleWidget(
                    value: _optimizeProcessing,
                    onChanged: (value) {
                      setState(() {
                        _optimizeProcessing = value;
                      });
                    },
                  ),
                  isLast: true,
                  showDivider: false,
                ),
              ],
            ),

            // About Section
            SettingsSectionWidget(
              title: 'About',
              children: [
                ...(_appInfo.asMap().entries.map((entry) {
                  final index = entry.key;
                  final info = entry.value;
                  return SettingsRowWidget(
                    title: info["title"] as String,
                    subtitle: info["description"] as String,
                    trailing: Text(
                      info["value"] as String,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    isFirst: index == 0,
                    isLast: index == _appInfo.length - 1,
                    showDivider: index != _appInfo.length - 1,
                  );
                }).toList()),
                SettingsRowWidget(
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy policy and terms',
                  trailing: CustomIconWidget(
                    iconName: 'open_in_new',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening privacy policy...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  showDivider: false,
                ),
              ],
            ),

            // Reset Button
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _showResetDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.lightTheme.colorScheme.error,
                  side: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.error,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 3.h),
                ),
                child: Text(
                  'Reset to Defaults',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.error,
                  ),
                ),
              ),
            ),

            // App Info Button
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              width: double.infinity,
              child: TextButton(
                onPressed: _showAboutDialog,
                child: Text(
                  'About Jarak App',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ),
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}
