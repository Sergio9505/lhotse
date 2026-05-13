import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../core/notifications/onesignal_service.dart';
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
    // Ask for iOS push permission after the user has seen the welcome.
    // The native dialog is non-blocking — if rejected, the fade-out still
    // routes to home on schedule.
    _timers.add(Timer(const Duration(milliseconds: 1500), () {
      OneSignalService.requestPermission();
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
                Text(
                  greeting,
                  textAlign: TextAlign.center,
                  style: AppTypography.editorialTitle.copyWith(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
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
