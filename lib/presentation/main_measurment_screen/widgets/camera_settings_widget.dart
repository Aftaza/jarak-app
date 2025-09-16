import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CameraSettingsWidget extends StatelessWidget {
  final CameraController? cameraController;
  final bool isFlashOn;
  final bool isFrontCamera;
  final double zoomLevel;
  final VoidCallback onToggleFlash;
  final VoidCallback onSwitchCamera;
  final Function(double) onZoomChanged;
  final VoidCallback onFocusTap;
  final Function(String)? onShowFeedback;

  const CameraSettingsWidget({
    Key? key,
    required this.cameraController,
    required this.isFlashOn,
    required this.isFrontCamera,
    required this.zoomLevel,
    required this.onToggleFlash,
    required this.onSwitchCamera,
    required this.onZoomChanged,
    required this.onFocusTap,
    this.onShowFeedback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10.h,
      right: 4.w,
      child: Column(
        children: [
          // Flash toggle (not available on web)
          if (!kIsWeb)
            _buildSettingButton(
              icon: isFlashOn ? 'flash_on' : 'flash_off',
              onTap: onToggleFlash,
              isActive: isFlashOn,
            ),

          SizedBox(height: 2.h),

          // Camera switch
          _buildSettingButton(
            icon: 'flip_camera_ios',
            onTap: onSwitchCamera,
            isActive: false,
          ),

          SizedBox(height: 2.h),

          // Focus indicator
          _buildFocusButton(),

          // Zoom control (not available on web)
          if (!kIsWeb && cameraController != null) ...[
            SizedBox(height: 2.h),
            _buildZoomControl(),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingButton({
    required String icon,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? AppTheme.lightTheme.primaryColor
            : Colors.black.withValues(alpha: 0.5),
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
    );
  }

  Widget _buildFocusButton() {
    return _buildSettingButton(
      icon: 'center_focus_strong',
      onTap: () async {
        if (cameraController != null && cameraController!.value.isInitialized) {
          try {
            // Lakukan fokus otomatis
            await cameraController!.setFocusMode(FocusMode.auto);
            
            // Tampilkan feedback sukses
            onShowFeedback?.call('Camera focused successfully');
            
            // Panggil callback asli
            onFocusTap();
          } catch (e) {
            // Tampilkan feedback error
            onShowFeedback?.call('Failed to focus camera');
          }
        }
      },
      isActive: false,
    );
  }

  Widget _buildZoomControl() {
    return Container(
      width: 12.w,
      height: 30.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.w),
        color: Colors.black.withValues(alpha: 0.5),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Zoom in button
          Expanded(
            child: InkWell(
              onTap: () {
                final newZoom = (zoomLevel + 0.5).clamp(1.0, 8.0);
                onZoomChanged(newZoom);
              },
              borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'add',
                  color: Colors.white,
                  size: 4.w,
                ),
              ),
            ),
          ),

          // Zoom level indicator
          Container(
            padding: EdgeInsets.symmetric(vertical: 1.h),
            child: Text(
              '${zoomLevel.toStringAsFixed(1)}x',
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontSize: (2.5.w).clamp(8.0, 14.0),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Zoom out button
          Expanded(
            child: InkWell(
              onTap: () {
                final newZoom = (zoomLevel - 0.5).clamp(1.0, 8.0);
                onZoomChanged(newZoom);
              },
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(6.w)),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'remove',
                  color: Colors.white,
                  size: 4.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
