import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MeasurementHistoryWidget extends StatelessWidget {
  final bool isExpanded;
  final List<Map<String, dynamic>> measurements;
  final VoidCallback onToggle;
  final Function(int) onDeleteMeasurement;
  final Function(Map<String, dynamic>) onSelectMeasurement;

  const MeasurementHistoryWidget({
    Key? key,
    required this.isExpanded,
    required this.measurements,
    required this.onToggle,
    required this.onDeleteMeasurement,
    required this.onSelectMeasurement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isExpanded ? 0 : -70.w,
      top: 0,
      bottom: 0,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 75.w,
        child: Row(
          children: [
            // History panel
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        4.w,
                        MediaQuery.of(context).padding.top + 2.h,
                        4.w,
                        2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'history',
                            color: Colors.white,
                            size: 6.w,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              'Measurement History',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Measurements list
                    Expanded(
                      child: measurements.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              itemCount: measurements.length,
                              itemBuilder: (context, index) {
                                return _buildMeasurementItem(
                                  measurements[index],
                                  index,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Toggle handle
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 8.w,
                height: 15.h,
                margin: EdgeInsets.only(top: 40.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 5,
                      offset: Offset(2, 0),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: isExpanded ? 'chevron_left' : 'chevron_right',
                    color: Colors.white,
                    size: 6.w,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'straighten',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant.withValues(
              alpha: 0.5,
            ),
            size: 15.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'No measurements yet',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Start measuring to see\nyour history here',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementItem(Map<String, dynamic> measurement, int index) {
    final distance = measurement['distance'] as double;
    final unit = measurement['unit'] as String;
    final timestamp = measurement['timestamp'] as DateTime;

    return Dismissible(
      key: Key('measurement_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        color: AppTheme.errorLight,
        child: CustomIconWidget(
          iconName: 'delete',
          color: Colors.white,
          size: 6.w,
        ),
      ),
      onDismissed: (direction) {
        onDeleteMeasurement(index);
      },
      child: InkWell(
        onTap: () => onSelectMeasurement(measurement),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline.withValues(
                alpha: 0.3,
              ),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (measurement['thumbnail'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            measurement['thumbnail'],
                            width: 14.w,
                            height: 14.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                      if (measurement['thumbnail'] != null)
                        SizedBox(width: 3.w),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            distance.toStringAsFixed(2),
                            style: AppTheme.lightTheme.textTheme.titleLarge
                                ?.copyWith(
                                  color: AppTheme.lightTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            unit,
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.lightTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 5.w,
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'schedule',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    _formatTimestamp(timestamp),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
