import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/biometric_lock_controller.dart';
import '../../../core/auth/biometric_service.dart';
import '../../../core/boot/boot_state.dart';
import '../../../core/data/supabase_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_mark.dart';

/// Hard gate that fires when the boot state machine resolves to
/// `BootPendingBiometric`. Auto-triggers the OS biometric prompt on mount;
/// on success, marks the unlock timestamp and asks the boot machine to
/// re-resolve — the router transitions to the captured pending destination
/// (or Home) without any explicit `context.go(...)` from this screen.
///
/// Visual idiom — bank-grade dark gate à la JPM / Lloyds / 1Password:
///   - Solid dark background (brand `AppColors.primary`) blends with the iOS
///     system Face ID sheet — no white flash on prompt open/close.
///   - Isotype as the single visual anchor; no buttons cluttering the layout.
///   - Tap anywhere on the body to re-fire Face ID. Hint copy guides first-
///     time users. Sign-out is a low-alpha footer link — visible only when
///     looked for.
///
/// Cancellation / failure does NOT let the user through. If biometrics get
/// disabled OS-side between sessions, we detect `notAvailable` and let
/// the user in once with `enabled = false` persisted.
class BiometricGateScreen extends ConsumerStatefulWidget {
  const BiometricGateScreen({super.key});

  @override
  ConsumerState<BiometricGateScreen> createState() =>
      _BiometricGateScreenState();
}

class _BiometricGateScreenState extends ConsumerState<BiometricGateScreen> {
  bool _inFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attempt());
  }

  Future<void> _attempt() async {
    if (_inFlight) return;
    setState(() => _inFlight = true);

    final service = ref.read(biometricServiceProvider);
    final result = await service.authenticate(reason: 'Verificar su identidad');
    if (!mounted) return;

    switch (result) {
      case BiometricResult.success:
        ref.read(biometricLockControllerProvider.notifier).markUnlocked();
        await ref.read(bootStateProvider.notifier).refresh();
        return;
      case BiometricResult.notAvailable:
        // OS no longer has biometrics enrolled — fail open with `enabled =
        // false` and proceed to Home. The user can re-activate in Settings
        // once biometrics are re-enrolled.
        await ref
            .read(biometricLockControllerProvider.notifier)
            .disableExplicitly();
        await ref.read(bootStateProvider.notifier).refresh();
        return;
      case BiometricResult.userCancelled:
      case BiometricResult.failed:
        if (!mounted) return;
        setState(() => _inFlight = false);
        return;
    }
  }

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          '¿Cerrar sesión?',
          style: AppTypography.editorialSubtitle
              .copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Tendrá que volver a iniciar sesión para acceder a su cartera.',
          style: AppTypography.bodyReading
              .copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancelar',
              style: AppTypography.bodyEmphasis
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Cerrar sesión',
              style: AppTypography.bodyEmphasis
                  .copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    ref.read(biometricLockControllerProvider.notifier).invalidateUnlock();
    await ref.read(supabaseClientProvider).auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.padding.bottom;
    // Anchor the isotype on the upper third — keeps the brand mark out of
    // the visual zone where iOS Face ID animations land, and the lower
    // half breathes empty (premium restraint).
    final topAnchor = mq.size.height * 0.30;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark background needs light status bar icons. Overrides the app-level
      // `SystemUiOverlayStyle.dark` set in `LhotseApp.build`.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tap zone — the entire upper body re-fires Face ID. Sign-out
                // footer below has its own GestureDetector and wins by hit-
                // testing as a child of this Expanded.
                Expanded(
                  child: GestureDetector(
                    onTap: _inFlight ? null : _attempt,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: topAnchor),
                        // Explicit width on the LhotseMark wrapper — sin
                        // width, `SvgPicture(fit: contain)` se infla a
                        // `parent.maxWidth` (gotcha conocido en CLAUDE.md
                        // global) y rompe el centrado de los siblings del
                        // Column. 83 = 72 × (580.72/503) — el aspect ratio
                        // exacto del viewBox del SVG.
                        const SizedBox(
                          width: 83,
                          height: 72,
                          child: LhotseMark(
                            color: AppColors.textOnDark,
                            height: 72,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Center(
                          child: Text(
                            'Toque para autenticar.',
                            style: AppTypography.labelUppercaseMd.copyWith(
                              color: AppColors.textOnDark
                                  .withValues(alpha: 0.55),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: _inFlight ? null : _confirmSignOut,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text(
                        'Cerrar sesión',
                        style: AppTypography.labelUppercaseMd.copyWith(
                          color: AppColors.textOnDark.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: bottomPadding + AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
