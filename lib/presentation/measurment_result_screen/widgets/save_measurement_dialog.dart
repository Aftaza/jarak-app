import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SaveMeasurementDialog extends StatefulWidget {
  final double distance;
  final String unit;
  final Function(String name) onSave;

  const SaveMeasurementDialog({
    Key? key,
    required this.distance,
    required this.unit,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SaveMeasurementDialog> createState() => _SaveMeasurementDialogState();
}

class _SaveMeasurementDialogState extends State<SaveMeasurementDialog> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-generate a default name
    final now = DateTime.now();
    _nameController.text = 'Measurement ${now.month}/${now.day}/${now.year}';

    // Auto-focus and select text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _nameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _nameController.text.length,
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'save',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Save Measurement',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Measurement preview
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '${widget.distance.toStringAsFixed(2)} ${widget.unit}',
                    style:
                        AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Distance Measurement',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            // Name input
            Text(
              'Measurement Name',
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),

            TextField(
              controller: _nameController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Enter measurement name',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'label',
                    color: AppTheme.lightTheme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveMeasurement(),
            ),

            SizedBox(height: 4.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveMeasurement,
                    child: Text('Save'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveMeasurement() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      widget.onSave(name);
      Navigator.of(context).pop();
    }
  }
}
