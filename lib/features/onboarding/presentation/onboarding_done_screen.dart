import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_mark.dart';

/// Final screen of the onboarding flow.
///
/// Welcoming greeting + explicit "Continuar" CTA that fades out and
/// navigates to home. The push-permission soft-ask is *not* triggered
/// here — it's owned by `ShellScreen.initState`, which fires it ~800 ms
/// after Inicio mounts (both for fresh signups and for returning logins
/// in the same place). Keeping this screen as the closing rite of
/// onboarding — no sheet over a fading background.
class OnboardingDoneScreen extends StatefulWidget {
  const OnboardingDoneScreen({super.key});

  @override
  State<OnboardingDoneScreen> createState() => _OnboardingDoneScreenState();
}

class _OnboardingDoneScreenState extends State<OnboardingDoneScreen> {
  bool _visible = false;
  bool _fadingOut = false;
  bool _handling = false;
  Timer? _fadeInTimer;

  String get _firstName {
    final fullName = Supabase.instance.client.auth.currentUser
        ?.userMetadata?['full_name'] as String?;
    if (fullName == null || fullName.trim().isEmpty) return '';
    return fullName.trim().split(' ').first;
  }

  @override
  void initState() {
    super.initState();
    _fadeInTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _fadeInTimer?.cancel();
    super.dispose();
  }

  void _onContinue() {
    if (_handling) return;
    setState(() {
      _handling = true;
      _fadingOut = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _firstName;
    final greeting =
        firstName.isNotEmpty ? 'Bienvenido,\n$firstName.' : 'Bienvenido.';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 700),
            opacity: _visible && !_fadingOut ? 1.0 : 0.0,
            curve: Curves.easeInOut,
            onEnd: () {
              if (_fadingOut && mounted) {
                context.go(AppRoutes.home);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                const _BrandLockup(),
                const SizedBox(height: 96),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Text(
                    greeting,
                    textAlign: TextAlign.center,
                    style: AppTypography.editorialTitle.copyWith(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: _ContinueCta(
                    enabled: !_handling,
                    onTap: _onContinue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueCta extends StatelessWidget {
  const _ContinueCta({required this.onTap, this.enabled = true});

  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: Colors.white.withValues(alpha: enabled ? 0.45 : 0.15),
            width: 0.6,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'Continuar',
          style: AppTypography.bodyEmphasis.copyWith(
            color: Colors.white.withValues(alpha: enabled ? 1 : 0.4),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── Brand stamp ─────────────────────────────────────────────────────────────
//
// Discreet stamp at the top of the screen: the greeting is the hero, the
// brand provides context. Logo 32 + wordmark in wordmarkByline (10pt ls 1.5)
// — same lockup grammar as login/search wordmark rows.

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    final wordmarkStyle = AppTypography.wordmarkByline.copyWith(
      color: Colors.white,
      height: 1.0,
    );
    const strut = StrutStyle(
      fontSize: 10,
      height: 1.0,
      forceStrutHeight: true,
    );

    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LhotseMark(color: Colors.white, height: 32),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LHOTSE', style: wordmarkStyle, strutStyle: strut),
              Text('GROUP', style: wordmarkStyle, strutStyle: strut),
            ],
          ),
        ],
      ),
    );
  }
}
