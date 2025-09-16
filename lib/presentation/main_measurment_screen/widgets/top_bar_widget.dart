import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TopBarWidget extends StatelessWidget {
  final bool isImperialUnit;
  final VoidCallback onToggleUnit;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenCalibration;

  const TopBarWidget({
    Key? key,
    required this.isImperialUnit,
    required this.onToggleUnit,
    required this.onOpenSettings,
    required this.onOpenCalibration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 1.h,
      left: 4.w,
      right: 4.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Unit toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _buildUnitButton(
                  label: 'Imperial',
                  isActive: isImperialUnit,
                  onTap: isImperialUnit ? null : onToggleUnit,
                ),
                _buildUnitButton(
                  label: 'Metric',
                  isActive: !isImperialUnit,
                  onTap: !isImperialUnit ? null : onToggleUnit,
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            children: [
              // Calibration button
              _buildActionButton(
                icon: 'tune',
                onTap: onOpenCalibration,
                tooltip: 'Calibration',
              ),

              SizedBox(width: 2.w),

              // Settings button
              _buildActionButton(
                icon: 'settings',
                onTap: onOpenSettings,
                tooltip: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitButton({
    required String label,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color:
              isActive ? AppTheme.lightTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.5),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6.w),
            onTap: onTap,
            child: Center(
              child: CustomIconWidget(
                iconName: icon,
                color: Colors.white,
                size: 5.w,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
