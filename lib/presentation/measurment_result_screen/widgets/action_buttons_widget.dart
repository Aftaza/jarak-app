import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActionButtonsWidget extends StatelessWidget {
  final double distance;
  final String unit;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onRetake;
  final VoidCallback onConvertUnits;

  const ActionButtonsWidget({
    Key? key,
    required this.distance,
    required this.unit,
    required this.onSave,
    required this.onShare,
    required this.onRetake,
    required this.onConvertUnits,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: [
          // Primary action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  icon: CustomIconWidget(
                    iconName: 'save',
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    size: 18,
                  ),
                  label: Text('Save'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onShare,
                  icon: CustomIconWidget(
                    iconName: 'share',
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    size: 18,
                  ),
                  label: Text('Share'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Secondary action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(context),
                  icon: CustomIconWidget(
                    iconName: 'content_copy',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 16,
                  ),
                  label: Text('Copy Value'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onConvertUnits,
                  icon: CustomIconWidget(
                    iconName: 'swap_horiz',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 16,
                  ),
                  label: Text('Convert'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Retake button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onRetake,
              icon: CustomIconWidget(
                iconName: 'camera_alt',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 18,
              ),
              label: Text('Retake Measurement'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    final value = '${distance.toStringAsFixed(2)} $unit';
    Clipboard.setData(ClipboardData(text: value));

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "$value" to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }
}
