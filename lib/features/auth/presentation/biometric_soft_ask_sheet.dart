import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/biometric_lock_controller.dart';
import '../../../core/theme/app_theme.dart';

/// Branded pre-permission sheet for the Face ID / Touch ID / fingerprint
/// opt-in, mirroring [`push_soft_ask_sheet.dart`] one-to-one: same fond,
/// same CTA shapes, same lifetime cap (2). Returns `true` when the user
/// completed activation (system prompt accepted), `false` otherwise.
///
/// Unlike push, biometric is not a system "permission" — the OS doesn't
/// expose a tri-state. So the gating lives entirely in our controller:
/// `enabled` flips to `true` only on a successful unlock; cancel / "Más
/// tarde" leave it as `null` (re-eligible until cap).
Future<bool> showBiometricSoftAsk(BuildContext context, WidgetRef ref) async {
  await ref
      .read(biometricLockControllerProvider.notifier)
      .markSoftAskShown();
  if (!context.mounted) return false;
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    barrierColor: AppColors.primary.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => const _BiometricSoftAskContent(),
  );
  return result ?? false;
}

class _BiometricSoftAskContent extends ConsumerStatefulWidget {
  const _BiometricSoftAskContent();

  @override
  ConsumerState<_BiometricSoftAskContent> createState() =>
      _BiometricSoftAskContentState();
}

class _BiometricSoftAskContentState
    extends ConsumerState<_BiometricSoftAskContent> {
  bool _busy = false;

  Future<void> _onActivate() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await ref
        .read(biometricLockControllerProvider.notifier)
        .activate(reason: 'Verificar su identidad');
    if (!mounted) return;
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + bottomPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Active Face ID.',
              style: AppTypography.editorialTitle.copyWith(
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Le pediremos Face ID al abrir Lhotse y tras unos minutos sin '
              'actividad, para que su cartera mantenga su privacidad.',
              style: AppTypography.bodyReading.copyWith(
                color: AppColors.accentMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _PrimaryCta(
              label: 'Activar',
              busy: _busy,
              onTap: _onActivate,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        color: AppColors.primary,
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  valueColor: AlwaysStoppedAnimation(AppColors.textOnDark),
                ),
              )
            : Text(
                label,
                style: AppTypography.bodyEmphasis.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
      ),
    );
  }
}

