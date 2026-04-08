import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LhotseMetricBlock extends StatelessWidget {
  const LhotseMetricBlock({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.headingSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.accentMuted,
          ),
        ),
      ],
    );
  }
}
