import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_bottom_sheet.dart';

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
    builder: (_) => LhotseBottomSheetBody(
      title: 'LHOTSE PRIVATE',
      bodyBuilder: (bottomPadding) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl + bottomPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PhosphorIcon(
              PhosphorIconsThin.lock,
              size: 24,
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Este proyecto es de acceso exclusivo para Inversores VIP. '
              'Sigue invirtiendo con nosotros para desbloquear oportunidades privadas.',
              style: AppTypography.annotationParagraph.copyWith(
                color: AppColors.accentMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              height: 0.5,
              color: AppColors.textPrimary.withValues(alpha: 0.08),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'SOLICITAR INVITACIÓN',
              style: AppTypography.labelUppercaseMd.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
