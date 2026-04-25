import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LhotseMetricBlock extends StatelessWidget {
  const LhotseMetricBlock({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
  });

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.figureAmount.copyWith(
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTypography.annotation.copyWith(
            color: AppColors.accentMuted,
          ),
        ),
      ],
    );
  }
}
