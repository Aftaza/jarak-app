import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SettingsToggleWidget extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggleWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.lightTheme.colorScheme.primary,
      activeTrackColor:
          AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
      inactiveThumbColor: AppTheme.lightTheme.colorScheme.outline,
      inactiveTrackColor:
          AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }
}
