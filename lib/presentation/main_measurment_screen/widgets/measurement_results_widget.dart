import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MeasurementResultsWidget extends StatelessWidget {
  final double? distance;
  final String unit;
  final bool isVisible;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onRetake;
  final double? pixelDistance;
  final double? depthDifference;

  const MeasurementResultsWidget({
    Key? key,
    required this.distance,
    required this.unit,
    required this.isVisible,
    required this.onClose,
    required this.onSave,
    required this.onShare,
    required this.onRetake,
    this.pixelDistance,
    this.depthDifference,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 1.h),
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Measurement Result',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: EdgeInsets.all(2.w),
                        child: CustomIconWidget(
                          iconName: 'close',
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                          size: 6.w,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Distance display
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          distance?.toStringAsFixed(2) ?? '0.00',
                          style: AppTheme.lightTheme.textTheme.displayMedium
                              ?.copyWith(
                            color: AppTheme.lightTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 36.sp,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          unit,
                          style: AppTheme.lightTheme.textTheme.titleLarge
                              ?.copyWith(
                            color: AppTheme.lightTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Depth-based distance measurement',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              // Measurement details
              _buildMeasurementDetails(),

              SizedBox(height: 3.h),

              // Action buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRetake,
                        icon: CustomIconWidget(
                          iconName: 'refresh',
                          color: AppTheme.lightTheme.primaryColor,
                          size: 5.w,
                        ),
                        label: Text('Retake'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 3.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onSave,
                        icon: CustomIconWidget(
                          iconName: 'save',
                          color: Colors.white,
                          size: 5.w,
                        ),
                        label: Text('Save'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 3.h),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 2.h),

              // Share button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: onShare,
                    icon: CustomIconWidget(
                      iconName: 'share',
                      color: AppTheme.lightTheme.primaryColor,
                      size: 5.w,
                    ),
                    label: Text('Share Result'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                    ),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementDetails() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: 'straighten',
            label: 'Measurement Type',
            value: 'Depth-based Distance',
          ),
          SizedBox(height: 2.h),
          if (pixelDistance != null)
            _buildDetailRow(
              icon: 'space_bar',
              label: 'Pixel Distance',
              value: '${pixelDistance!.toStringAsFixed(2)} px',
            ),
          if (pixelDistance != null) SizedBox(height: 2.h),
          if (depthDifference != null)
            _buildDetailRow(
              icon: 'height',
              label: 'Depth Difference',
              value: '${depthDifference!.toStringAsFixed(2)} m',
            ),
          if (depthDifference != null) SizedBox(height: 2.h),
          _buildDetailRow(
            icon: 'schedule',
            label: 'Measured At',
            value: _formatTimestamp(DateTime.now()),
          ),
          SizedBox(height: 2.h),
          _buildDetailRow(
            icon: 'precision_manufacturing',
            label: 'Accuracy',
            value: '±10% (Estimated)',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          size: 5.w,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
