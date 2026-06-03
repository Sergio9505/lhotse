import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/launch_whatsapp.dart';
import '../../../../core/widgets/lhotse_bottom_sheet.dart';
import '../../../profile/data/user_requests_provider.dart';

/// Shows the "Lhotse Private" lock bottom sheet for VIP projects that the
/// current user cannot access. The CTA always opens WhatsApp and submits a
/// `user_requests` row (`type = 'vip_access'`) only if none is open yet
/// (idempotent). No "EN ESTUDIO" state. Mirrors the `_PrivateBanner` pattern
/// in `profile_screen.dart`. See ADR-92.
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
      bodyBuilder: (bottomPadding) =>
          _VipLockSheetBody(bottomPadding: bottomPadding),
    ),
  );
}

class _VipLockSheetBody extends ConsumerWidget {
  const _VipLockSheetBody({required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bodyText =
        'Este proyecto es de acceso exclusivo para Inversores VIP. '
        'Sigue invirtiendo con nosotros para desbloquear oportunidades privadas.';
    const label = 'SOLICITAR INVITACIÓN';

    // Single pattern (ADR-92): always opens WhatsApp; creates the vip_access
    // request only if none is open yet (submitUserRequest is idempotent). No
    // "EN ESTUDIO" state.
    Future<void> onTap() async {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final exists = ref
              .read(userRequestExistsProvider(UserRequestType.vipAccess))
              .valueOrNull ??
          false;
      if (!exists) {
        try {
          await submitUserRequest(ref, UserRequestType.vipAccess);
        } catch (_) {/* swallow — WhatsApp hand-off is the primary action */}
      }
      navigator.pop();
      final ok = await launchWhatsApp(
        'Hola, me gustaría solicitar acceso a Lhotse Private (inversión VIP).',
      );
      if (!ok) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp. Inténtalo de nuevo.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    return Padding(
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
            bodyText,
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
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  label,
                  style: AppTypography.labelUppercaseMd.copyWith(
                    color: AppColors.textPrimary,
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
