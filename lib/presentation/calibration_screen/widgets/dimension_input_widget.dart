import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DimensionInputWidget extends StatefulWidget {
  final String label;
  final String unit;
  final double? initialValue;
  final Function(double?) onChanged;
  final String? errorText;
  final bool isRequired;

  const DimensionInputWidget({
    super.key,
    required this.label,
    required this.unit,
    this.initialValue,
    required this.onChanged,
    this.errorText,
    this.isRequired = true,
  });

  @override
  State<DimensionInputWidget> createState() => _DimensionInputWidgetState();
}

class _DimensionInputWidgetState extends State<DimensionInputWidget> {
  late TextEditingController _controller;
  String _selectedUnit = 'inches';
  final List<String> _units = ['inches', 'cm', 'mm', 'feet'];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
    _selectedUnit = widget.unit;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onValueChanged() {
    final value = double.tryParse(_controller.text);
    widget.onChanged(value);
  }

  void _onUnitChanged(String? newUnit) {
    if (newUnit != null) {
      setState(() {
        _selectedUnit = newUnit;
      });
      _onValueChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label + (widget.isRequired ? ' *' : ''),
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _controller,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter ${widget.label.toLowerCase()}',
                  errorText: widget.errorText,
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: CustomIconWidget(
                            iconName: 'clear',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 5.w,
                          ),
                          onPressed: () {
                            _controller.clear();
                            _onValueChanged();
                          },
                        )
                      : null,
                ),
                onChanged: (_) => _onValueChanged(),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedUnit,
                decoration: InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                ),
                items: _units.map((String unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(
                      unit,
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                    ),
                  );
                }).toList(),
                onChanged: _onUnitChanged,
              ),
            ),
          ],
        ),
        if (widget.errorText == null) ...[
          SizedBox(height: 0.5.h),
          Text(
            'Provide accurate dimensions for better calibration',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
