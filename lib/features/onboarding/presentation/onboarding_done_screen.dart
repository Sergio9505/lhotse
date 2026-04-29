import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_mark.dart';

class OnboardingDoneScreen extends StatefulWidget {
  const OnboardingDoneScreen({super.key});

  @override
  State<OnboardingDoneScreen> createState() => _OnboardingDoneScreenState();
}

class _OnboardingDoneScreenState extends State<OnboardingDoneScreen> {
  bool _visible = false;
  bool _fadingOut = false;
  final List<Timer> _timers = [];

  String get _firstName {
    final fullName = Supabase.instance.client.auth.currentUser
        ?.userMetadata?['full_name'] as String?;
    if (fullName == null || fullName.trim().isEmpty) return '';
    return fullName.trim().split(' ').first;
  }

  @override
  void initState() {
    super.initState();
    _timers.add(Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _visible = true);
    }));
    _timers.add(Timer(const Duration(milliseconds: 3400), () {
      if (mounted) setState(() => _fadingOut = true);
    }));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _firstName;
    final greeting =
        firstName.isNotEmpty ? 'Bienvenido, $firstName.' : 'Bienvenido.';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
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
              mainAxisSize: MainAxisSize.min,
              children: [
                _BrandLockup(),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: 40,
                  height: 0.5,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  greeting,
                  style: AppTypography.annotation.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.4,
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

// ── Logo + wordmark lockup ──────────────────────────────────────────────────
//
// Mirrors the welcome_screen lockup but scaled up for hero presence.
// Logo height 72 + wordmark 28pt w600 ls 2.0 — same proportional ratio
// (3:1 height-to-fontSize) as welcome_screen's 48 / 24 pairing.

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    const wordmarkStyle = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 2.0,
      height: 1.0,
    );
    const strut = StrutStyle(
      fontSize: 28,
      height: 1.0,
      forceStrutHeight: true,
    );

    return SizedBox(
      height: 72,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LhotseMark(color: Colors.white, height: 72),
          const SizedBox(width: 16),
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
