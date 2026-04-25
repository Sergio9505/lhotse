import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';

/// Shows the "Lhotse Private" lock bottom sheet for VIP projects that the
/// current user cannot access.
void showVipLockSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => const _VipLockSheet(),
  );
}

class _VipLockSheet extends StatelessWidget {
  const _VipLockSheet();

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          const PhosphorIcon(
            PhosphorIconsThin.lock,
            size: 28,
            color: AppColors.textPrimary,
          ),

          const SizedBox(height: AppSpacing.xl),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Lhotse Private',
              style: AppTypography.editorialSubtitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Este proyecto es de acceso exclusivo para Inversores VIP. Sigue invirtiendo con nosotros para desbloquear oportunidades privadas.',
              style: AppTypography.annotation.copyWith(
                color: AppColors.accentMuted,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Container(
              height: 0.5,
              color: AppColors.textPrimary.withValues(alpha: 0.15)),

          const SizedBox(height: AppSpacing.xl),

          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SOLICITAR INVITACIÓN',
                  style: AppTypography.labelUppercaseMd.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const PhosphorIcon(
                  PhosphorIconsThin.arrowRight,
                  size: 14,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
