import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_bottom_sheet.dart';
import '../../../profile/data/user_requests_provider.dart';

/// Shows the "Lhotse Private" lock bottom sheet for VIP projects that the
/// current user cannot access. The CTA inside is state-aware: it submits a
/// `user_requests` row (`type = 'vip_access'`) on the first tap and reflects
/// "SOLICITUD EN ESTUDIO" on subsequent opens once a non-declined request
/// exists. Mirrors the `_PrivateBanner` pattern in `profile_screen.dart`.
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
    final exists = ref
            .watch(userRequestExistsProvider(UserRequestType.vipAccess))
            .valueOrNull ??
        false;

    final bodyText = exists
        ? 'Hemos recibido tu solicitud. Te contactaremos para confirmar tu acceso a Lhotse Private.'
        : 'Este proyecto es de acceso exclusivo para Inversores VIP. '
            'Sigue invirtiendo con nosotros para desbloquear oportunidades privadas.';
    final label = exists ? 'SOLICITUD EN ESTUDIO' : 'SOLICITAR INVITACIÓN';

    Future<void> onTap() async {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      try {
        await submitUserRequest(ref, UserRequestType.vipAccess);
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Solicitud recibida. Te contactaremos pronto.'),
            duration: Duration(seconds: 3),
          ),
        );
      } catch (_) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No se pudo enviar la solicitud. Inténtalo de nuevo.'),
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
            onTap: exists ? null : onTap,
            behavior: HitTestBehavior.opaque,
            child: Opacity(
              opacity: exists ? 0.6 : 1.0,
              child: Row(
                children: [
                  Text(
                    label,
                    style: AppTypography.labelUppercaseMd.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (!exists) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const PhosphorIcon(
                      PhosphorIconsThin.arrowRight,
                      size: 14,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
