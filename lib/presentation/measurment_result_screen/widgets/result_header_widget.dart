import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ResultHeaderWidget extends StatelessWidget {
  final double distance;
  final String unit;
  final double confidence;

  const ResultHeaderWidget({
    Key? key,
    required this.distance,
    required this.unit,
    required this.confidence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 2.h),

          // Main distance value
          Text(
            distance.toStringAsFixed(2),
            style: AppTheme.lightTheme.textTheme.displayMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),

          // Unit
          Text(
            unit,
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: 1.h),

          // Confidence indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: _getConfidenceColor(confidence).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getConfidenceColor(confidence),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: _getConfidenceIcon(confidence),
                  color: _getConfidenceColor(confidence),
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Text(
                  '${(confidence * 100).toInt()}% Confidence',
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: _getConfidenceColor(confidence),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return AppTheme
          .lightTheme.colorScheme.tertiary; // Green for high confidence
    } else if (confidence >= 0.6) {
      return AppTheme.warningLight; // Amber for medium confidence
    } else {
      return AppTheme.lightTheme.colorScheme.error; // Red for low confidence
    }
  }

  String _getConfidenceIcon(double confidence) {
    if (confidence >= 0.8) {
      return 'check_circle';
    } else if (confidence >= 0.6) {
      return 'warning';
    } else {
      return 'error';
    }
  }
}
