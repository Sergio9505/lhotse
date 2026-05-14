import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_theme.dart';

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

class _ContinueCta extends StatefulWidget {
  const _ContinueCta({required this.onTap, this.enabled = true});

  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_ContinueCta> createState() => _ContinueCtaState();
}

class _ContinueCtaState extends State<_ContinueCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:
          widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: !widget.enabled ? 0.4 : (_pressed ? 0.5 : 1.0),
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 0.5,
            ),
          ),
          child: Text(
            'CONTINUAR',
            style: AppTypography.labelUppercaseMd.copyWith(
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Brand stamp ─────────────────────────────────────────────────────────────
//
// Mirrors `WelcomeScreen`'s hero lockup: SVG mark 36pt + two-line LHOTSE/GROUP
// wordmark in `splashWordmark` (24pt) inside a 48pt column. Same grammar so
// the user finishes onboarding looking at the same brand stamp that opened
// the auth flow.

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/lhotse_logo.svg',
          height: 36,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LHOTSE',
                style: AppTypography.splashWordmark.copyWith(
                  color: AppColors.textOnDark,
                ),
                strutStyle: const StrutStyle(
                  fontSize: 24,
                  height: 1.0,
                  forceStrutHeight: true,
                ),
              ),
              Text(
                'GROUP',
                style: AppTypography.splashWordmark.copyWith(
                  color: AppColors.textOnDark,
                ),
                strutStyle: const StrutStyle(
                  fontSize: 24,
                  height: 1.0,
                  forceStrutHeight: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
