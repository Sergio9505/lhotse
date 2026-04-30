import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../core/data/assets_provider.dart';
import '../../../core/data/brands_provider.dart';
import '../../../core/data/document_categories_provider.dart';
import '../../../core/data/documents_provider.dart';
import '../../../core/data/news_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../../investments/data/investments_provider.dart';

/// First screen after the native bootstrap. Animates the brand isotype on a
/// black background for a fixed 5 seconds (4.5 s visible + 0.5 s fade-out)
/// while warming up the critical Riverpod providers in parallel, then
/// navigates to home or welcome depending on the auth state.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _fadeInCtrl;
  late final AnimationController _fadeOutCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _fadeOut;

  bool _loadComplete = false;

  static const _pulsePeriod = 2.0;
  static const _pulseAmp = 0.05;
  static const _fadeInSecs = 1.5;
  static const _fadeOutSecs = 0.5;
  static const _totalSplashSecs = 5.0;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _fadeInCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_fadeInSecs * 1000).toInt()),
    );
    _fadeIn = CurvedAnimation(parent: _fadeInCtrl, curve: Curves.easeOutQuart);

    _fadeOutCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_fadeOutSecs * 1000).toInt()),
    );
    _fadeOut = CurvedAnimation(parent: _fadeOutCtrl, curve: Curves.easeIn);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _fadeInCtrl.forward();
    });

    _runSplash();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeInCtrl.dispose();
    _fadeOutCtrl.dispose();
    super.dispose();
  }

  Future<void> _safe(Future<Object?> future) async {
    try {
      await future;
    } catch (_) {
      // Each screen surfaces its own error state when navigated to; warm-up
      // failures must not block the splash.
    }
  }

  Future<void> _runSplash() async {
    final authed = Supabase.instance.client.auth.currentUser != null;

    // Provider warm-up runs in parallel and never blocks the splash timing.
    // If it finishes within the 5 s, screens hydrate instantly; if not,
    // they fall back to their own loading state on first paint.
    unawaited(_warmUp(authed));

    final visibleMs =
        ((_totalSplashSecs - _fadeOutSecs) * 1000).toInt();
    await Future<void>.delayed(Duration(milliseconds: visibleMs));
    if (!mounted) return;

    setState(() => _loadComplete = true);
    await _fadeOutCtrl.forward();
    if (!mounted) return;

    context.go(authed ? AppRoutes.home : AppRoutes.welcome);
  }

  Future<void> _warmUp(bool authed) async {
    final futures = <Future<void>>[
      _safe(ref.read(brandsProvider.future)),
      _safe(ref.read(projectsProvider.future)),
      _safe(ref.read(assetsProvider.future)),
      _safe(ref.read(allDocumentCategoriesProvider.future)),
      _safe(ref.read(newsProvider.future)),
    ];
    if (authed) {
      futures.addAll([
        _safe(ref.read(allUserDocumentsProvider.future)),
        _safe(ref.read(purchaseContractsProvider.future)),
        _safe(ref.read(coinvestmentContractsProvider.future)),
        _safe(ref.read(fixedIncomeContractsProvider.future)),
        _safe(ref.read(userPortfolioProvider.future)),
      ]);
    }
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_pulseCtrl, _fadeInCtrl, _fadeOutCtrl]),
        builder: (context, child) {
          final t = _pulseCtrl.value * 60;
          final pulse = 1.0 + _pulseAmp * sin((t / _pulsePeriod) * 2 * pi);
          final opacity =
              _fadeIn.value * (1 - (_loadComplete ? _fadeOut.value : 0));
          return Center(
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(scale: pulse, child: child),
            ),
          );
        },
        child: SvgPicture.asset(
          'assets/images/lhotse_logo.svg',
          width: 110,
          height: 97,
        ),
      ),
    );
  }
}
