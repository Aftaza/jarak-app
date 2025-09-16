import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CalibrationResultsWidget extends StatelessWidget {
  final double measuredValue;
  final double actualValue;
  final String unit;
  final double accuracyPercentage;
  final String objectName;
  final VoidCallback onSaveCalibration;
  final VoidCallback onRetryMeasurement;

  const CalibrationResultsWidget({
    super.key,
    required this.measuredValue,
    required this.actualValue,
    required this.unit,
    required this.accuracyPercentage,
    required this.objectName,
    required this.onSaveCalibration,
    required this.onRetryMeasurement,
  });

  @override
  Widget build(BuildContext context) {
    final errorPercentage =
        ((measuredValue - actualValue).abs() / actualValue * 100);
    final isAccurate =
        errorPercentage <= 5.0; // Within 5% is considered accurate

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: isAccurate
                      ? AppTheme.accentLight.withValues(alpha: 0.1)
                      : AppTheme.warningLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: isAccurate ? 'check_circle' : 'warning',
                  color:
                      isAccurate ? AppTheme.accentLight : AppTheme.warningLight,
                  size: 6.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calibration Results',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      objectName,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Measurement comparison
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
            child: Column(
              children: [
                _buildMeasurementRow(
                  'Measured Value',
                  '${measuredValue.toStringAsFixed(2)} $unit',
                  AppTheme.lightTheme.colorScheme.primary,
                ),
                SizedBox(height: 1.h),
                _buildMeasurementRow(
                  'Actual Value',
                  '${actualValue.toStringAsFixed(2)} $unit',
                  AppTheme.lightTheme.colorScheme.onSurface,
                ),
                SizedBox(height: 1.h),
                Divider(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
                SizedBox(height: 1.h),
                _buildMeasurementRow(
                  'Error Percentage',
                  '${errorPercentage.toStringAsFixed(1)}%',
                  isAccurate ? AppTheme.accentLight : AppTheme.warningLight,
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Accuracy indicator
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: isAccurate
                  ? AppTheme.accentLight.withValues(alpha: 0.1)
                  : AppTheme.warningLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isAccurate ? AppTheme.accentLight : AppTheme.warningLight,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: isAccurate ? 'thumb_up' : 'info',
                      color: isAccurate
                          ? AppTheme.accentLight
                          : AppTheme.warningLight,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        isAccurate
                            ? 'Excellent! Your calibration is highly accurate.'
                            : 'Consider recalibrating for better accuracy.',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: isAccurate
                              ? AppTheme.accentLight
                              : AppTheme.warningLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isAccurate) ...[
                  SizedBox(height: 1.h),
                  Text(
                    'Try ensuring better lighting, stable positioning, and clear object edges.',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRetryMeasurement,
                  child: Text('Retry Measurement'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSaveCalibration,
                  child: Text(isAccurate ? 'Save Calibration' : 'Save Anyway'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
