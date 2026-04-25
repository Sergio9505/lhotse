import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Rectangular filter chip — sharp edges, black when active, transparent when inactive.
/// Used for document category filters, status filters, etc.
class LhotseFilterChip extends StatelessWidget {
  const LhotseFilterChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 9, AppSpacing.sm, 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : AppColors.textPrimary.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.labelUppercaseSm.copyWith(
            color: isActive ? AppColors.textOnDark : AppColors.accentMuted,
            letterSpacing: 1.0,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
