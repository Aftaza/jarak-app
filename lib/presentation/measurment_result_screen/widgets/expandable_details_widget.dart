import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ExpandableDetailsWidget extends StatefulWidget {
  final DateTime timestamp;
  final String deviceOrientation;
  final String cameraUsed;
  final int processingTime;

  const ExpandableDetailsWidget({
    Key? key,
    required this.timestamp,
    required this.deviceOrientation,
    required this.cameraUsed,
    required this.processingTime,
  }) : super(key: key);

  @override
  State<ExpandableDetailsWidget> createState() =>
      _ExpandableDetailsWidgetState();
}

class _ExpandableDetailsWidgetState extends State<ExpandableDetailsWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info_outline',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Measurement Details',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: Duration(milliseconds: 300),
                    child: CustomIconWidget(
                      iconName: 'keyboard_arrow_down',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
              child: Column(
                children: [
                  Divider(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    height: 1,
                  ),
                  SizedBox(height: 2.h),

                  // Detail items
                  _buildDetailItem(
                    icon: 'schedule',
                    label: 'Timestamp',
                    value: _formatTimestamp(widget.timestamp),
                  ),
                  SizedBox(height: 1.5.h),

                  _buildDetailItem(
                    icon: 'screen_rotation',
                    label: 'Device Orientation',
                    value: widget.deviceOrientation,
                  ),
                  SizedBox(height: 1.5.h),

                  _buildDetailItem(
                    icon: 'camera_alt',
                    label: 'Camera Used',
                    value: widget.cameraUsed,
                  ),
                  SizedBox(height: 1.5.h),

                  _buildDetailItem(
                    icon: 'timer',
                    label: 'Processing Time',
                    value: '${widget.processingTime}ms',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomIconWidget(
          iconName: icon,
          color:
              AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
          size: 18,
        ),
        SizedBox(width: 3.w),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.month.toString().padLeft(2, '0')}/${timestamp.day.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
