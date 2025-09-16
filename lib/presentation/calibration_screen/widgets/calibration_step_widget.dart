import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CalibrationStepWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String stepTitle;
  final String stepDescription;
  final Widget stepContent;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final bool isNextEnabled;
  final String nextButtonText;

  const CalibrationStepWidget({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitle,
    required this.stepDescription,
    required this.stepContent,
    this.onNext,
    this.onPrevious,
    this.isNextEnabled = true,
    this.nextButtonText = 'Next',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicator
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step $currentStep of $totalSteps',
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${((currentStep / totalSteps) * 100).round()}%',
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              LinearProgressIndicator(
                value: currentStep / totalSteps,
                backgroundColor: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightTheme.colorScheme.primary,
                ),
                minHeight: 0.5.h,
              ),
            ],
          ),
        ),

        // Step content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2.h),
                Text(
                  stepTitle,
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  stepDescription,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 3.h),
                stepContent,
                SizedBox(height: 3.h),
              ],
            ),
          ),
        ),

        // Navigation buttons
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              if (currentStep > 1) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPrevious,
                    child: Text('Previous'),
                  ),
                ),
                SizedBox(width: 3.w),
              ],
              Expanded(
                flex: currentStep > 1 ? 1 : 2,
                child: ElevatedButton(
                  onPressed: isNextEnabled ? onNext : null,
                  child: Text(nextButtonText),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
