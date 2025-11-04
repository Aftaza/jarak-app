import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MeasurementControlsWidget extends StatelessWidget {
  final bool isCapturing;
  final bool isProcessing;
  final int selectedPointsCount;
  final VoidCallback onCapture;
  final VoidCallback onReset;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onLoadImage;

  const MeasurementControlsWidget({
    Key? key,
    required this.isCapturing,
    required this.isProcessing,
    required this.selectedPointsCount,
    required this.onCapture,
    required this.onReset,
    required this.onSave,
    required this.onShare,
    required this.onLoadImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 8.h,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(
          children: [
            // Main capture button
            if (!isCapturing) _buildIdleControls() else _buildActionButtons(),

            SizedBox(height: 2.h),

            // Secondary controls
            if (selectedPointsCount > 0 && !isProcessing)
              _buildSecondaryControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMiniButton(
          icon: 'file_upload',
          label: 'Upload',
          onTap: isProcessing ? null : onLoadImage,
        ),
        SizedBox(width: 6.w),
        _buildCaptureButton(isProcessing: isProcessing),
      ],
    );
  }

  Widget _buildCaptureButton({required bool isProcessing}) {
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isProcessing
            ? Colors.grey.withValues(alpha: 0.6)
            : AppTheme.lightTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10.w),
          onTap: isProcessing ? null : onCapture,
          child: Center(
            child: isProcessing
                ? SizedBox(
                    width: 8.w,
                    height: 8.w,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : CustomIconWidget(
                    iconName: 'camera_alt',
                    color: Colors.white,
                    size: 8.w,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Reset button
        _buildActionButton(
          icon: 'refresh',
          label: 'Reset',
          onTap: onReset,
          color: AppTheme.errorLight,
        ),

        // Capture indicator
        Container(
          width: 16.w,
          height: 16.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isProcessing
                ? AppTheme.warningLight
                : selectedPointsCount > 0
                ? AppTheme.accentLight
                : AppTheme.lightTheme.primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: isProcessing
                ? SizedBox(
                    width: 6.w,
                    height: 6.w,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : CustomIconWidget(
                    iconName: selectedPointsCount == 0
                        ? 'radio_button_unchecked'
                        : 'radio_button_checked',
                    color: Colors.white,
                    size: 6.w,
                  ),
          ),
        ),

        // Done/Continue button
        _buildActionButton(
          icon: selectedPointsCount > 0 ? 'check' : 'add',
          label: selectedPointsCount > 0 ? 'Finish' : 'Continue',
          onTap: (!isProcessing && selectedPointsCount > 0) ? onReset : () {},
          color: AppTheme.accentLight,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
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
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryControls() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSecondaryButton(icon: 'save', label: 'Save', onTap: onSave),
          _buildSecondaryButton(icon: 'share', label: 'Share', onTap: onShare),
          _buildSecondaryButton(
            icon: 'history',
            label: 'History',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMiniButton({
    required String icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onTap == null
                ? Colors.grey.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
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
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        child: Column(
          children: [
            CustomIconWidget(iconName: icon, color: Colors.white, size: 5.w),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
