import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Rectangular filter chip — sharp edges, black when active, transparent when inactive.
/// Used for catalog status filters (Firmas archives) and document category
/// filters across investment detail screens + bottom sheets.
class LhotseFilterChip extends StatelessWidget {
  const LhotseFilterChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.large = false,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  /// Larger variant (taller padding + `labelUppercaseMd` 12pt instead of `Sm`
  /// 10pt) so a chip strip has presence comparable to the Proyectos brand-logo
  /// row (~52pt). Default keeps the compact size (Docs L3 category filters).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final base = large
        ? AppTypography.labelUppercaseMd
        : AppTypography.labelUppercaseSm;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: large
            ? const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 8)
            : const EdgeInsets.fromLTRB(AppSpacing.sm, 9, AppSpacing.sm, 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          border: Border.all(
            width: isActive ? 1.0 : 0.5,
            color: isActive
                ? AppColors.primary
                : AppColors.textPrimary.withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          // EXCEPTION: ls 1.0 + h 1.0 for chip bounds — native 1.2/1.4 spills vertically
          style: base.copyWith(
            color: isActive ? AppColors.textOnDark : AppColors.accentMuted,
            letterSpacing: 1.0,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
