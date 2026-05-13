import 'package:flutter/material.dart';

import '../../../core/notifications/onesignal_service.dart';
import '../../../core/theme/app_theme.dart';

/// Custom pre-permission bottom sheet shown before triggering the OS-level
/// push permission dialog.
///
/// Apple HIG explicitly advises against using `UIAlertController` for this
/// step: the OS dialog should appear once and clearly attributable to the
/// system. Our soft-ask owns the editorial framing and the symmetric
/// "Activar / Más tarde" decision; only "Activar" elevates to the real
/// system dialog. "Más tarde" closes without consuming the OS-side ask, so
/// the permission stays `notDetermined` and we can ask again later.
///
/// Returns `true` if the user accepted (system dialog granted) and `false`
/// otherwise. Either way the soft-ask count is incremented, contributing
/// to the lifetime cap (see [OneSignalService.canShowSoftAsk]).
Future<bool> showPushSoftAsk(BuildContext context) async {
  OneSignalService.softAskShownThisSession = true;
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    barrierColor: AppColors.primary.withValues(alpha: 0.35),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => const _PushSoftAskContent(),
  );
  return result ?? false;
}

class _PushSoftAskContent extends StatefulWidget {
  const _PushSoftAskContent();

  @override
  State<_PushSoftAskContent> createState() => _PushSoftAskContentState();
}

class _PushSoftAskContentState extends State<_PushSoftAskContent> {
  bool _busy = false;

  Future<void> _close(bool accepted) async {
    await OneSignalService.incrementSoftAskCount();
    if (!mounted) return;
    Navigator.of(context).pop(accepted);
  }

  Future<void> _onActivate() async {
    if (_busy) return;
    setState(() => _busy = true);
    final granted = await OneSignalService.requestPermission();
    if (!mounted) return;
    await _close(granted);
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
              'Active las notificaciones.',
              style: AppTypography.editorialTitle.copyWith(
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Le avisaremos cuando haya nuevas oportunidades, documentos '
              'disponibles o cambios relevantes en su cartera.',
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
            const SizedBox(height: AppSpacing.sm + 4),
            _SecondaryCta(
              label: 'Más tarde',
              enabled: !_busy,
              onTap: () => _close(false),
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
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
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

class _SecondaryCta extends StatelessWidget {
  const _SecondaryCta({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.bodyEmphasis.copyWith(
            color: AppColors.textPrimary.withValues(alpha: enabled ? 1 : 0.4),
          ),
        ),
      ),
    );
  }
}
