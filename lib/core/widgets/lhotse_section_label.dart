import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LhotseSectionLabel extends StatelessWidget {
  const LhotseSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        label,
        style: AppTypography.labelUppercaseMd.copyWith(
          color: AppColors.accentMuted,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}
