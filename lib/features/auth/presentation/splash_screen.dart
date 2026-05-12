import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router.dart';
import '../../../core/data/assets_provider.dart';
import '../../../core/data/brands_provider.dart';
import '../../../core/data/document_categories_provider.dart';
import '../../../core/data/documents_provider.dart';
import '../../../core/data/news_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../investments/data/investments_provider.dart';
import '../data/auth_repository.dart';
import 'otp_verify_screen.dart';

/// First screen after the native bootstrap (~7.35 s). Two strokes ascend
/// simultaneously toward the summit (1.8 s); a 150 ms beat marks the outline
/// complete; the silhouette consacrates over 2.0 s as the stroke fades and
/// the fill wipes upward. The wordmark fade-in (0.7 s) is timed to peak
/// exactly when the fill completes — silhouette, wordmark, letter-spacing
/// settle, and haptic all arrive in the same instant ("you've reached the
/// summit: here is Lhotse"). A 2.5 s hold sustains the tableau before
/// fade-out. (Lhotse: 4th highest mountain in the world; brand metaphor =
/// reaching the financial summit with this firm.)
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final AnimationController _fadeOutCtrl;

  static const int _animMs = 6850;
  static const int _fadeOutMs = 500;
  static const int _kStrokeStartMs = 400;
  static const int _kStrokeEndMs = 2200;
  static const int _kStrokeFadeStartMs = 2350;
  static const int _kStrokeFadeEndMs = 4350;
  static const int _kFillStartMs = 2350;
  static const int _kFillEndMs = 4350;
  static const int _kWordmarkStartMs = 3650;
  static const int _kWordmarkEndMs = 4350;

  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _animMs),
    );
    _fadeOutCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _fadeOutMs),
    );

    _animCtrl.addListener(_maybeFireHaptic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _animCtrl.forward();
    });

    _runSplash();
  }

  @override
  void dispose() {
    _animCtrl.removeListener(_maybeFireHaptic);
    _animCtrl.dispose();
    _fadeOutCtrl.dispose();
    super.dispose();
  }

  void _maybeFireHaptic() {
    if (!_hapticFired && _animCtrl.value >= _kWordmarkEndMs / _animMs) {
      _hapticFired = true;
      HapticFeedback.lightImpact();
    }
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
    final user = Supabase.instance.client.auth.currentUser;
    final authed = user != null;

    // Provider warm-up runs in parallel and never blocks the splash timing.
    unawaited(_warmUp(authed));

    await Future<void>.delayed(const Duration(milliseconds: _animMs));
    if (!mounted) return;

    await _fadeOutCtrl.forward();
    if (!mounted) return;

    if (user == null) {
      context.go(AppRoutes.welcome);
      return;
    }

    if (user.phoneConfirmedAt != null) {
      context.go(AppRoutes.home);
      return;
    }

    // Logged in but phone unverified → try to resume the OTP flow via
    // get_pending_phone() (auth.users.phone_change, not exposed by the SDK).
    final pendingPhone =
        await ref.read(authRepositoryProvider).getPendingPhone();
    if (!mounted) return;

    if (pendingPhone != null && pendingPhone.isNotEmpty) {
      context.go(
        AppRoutes.otpVerify,
        extra: OtpVerifyArgs(
          phone: pendingPhone,
          purpose: OtpPurpose.signupVerification,
          isResume: true,
        ),
      );
      return;
    }

    // Session exists, no phone confirmed, no pending — attachPhone failed
    // at some point. Treat as unauthenticated so /welcome takes over.
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    context.go(AppRoutes.welcome);
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

  double _remap(
    double value,
    double inMin,
    double inMax,
    double outMin,
    double outMax, {
    Curve curve = Curves.linear,
  }) {
    final t = ((value - inMin) / (inMax - inMin)).clamp(0.0, 1.0);
    return outMin + curve.transform(t) * (outMax - outMin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnimatedBuilder(
        animation: Listenable.merge([_animCtrl, _fadeOutCtrl]),
        builder: (context, _) {
          final t = _animCtrl.value;

          final strokeProgress = _remap(
            t,
            _kStrokeStartMs / _animMs,
            _kStrokeEndMs / _animMs,
            0,
            1,
            curve: Curves.easeOutCubic,
          );
          final strokeOpacity = 1.0 -
              _remap(
                t,
                _kStrokeFadeStartMs / _animMs,
                _kStrokeFadeEndMs / _animMs,
                0,
                1,
                curve: Curves.easeInCubic,
              );
          final fillProgress = _remap(
            t,
            _kFillStartMs / _animMs,
            _kFillEndMs / _animMs,
            0,
            1,
            curve: Curves.easeOutQuart,
          );
          final wordOp = _remap(
            t,
            _kWordmarkStartMs / _animMs,
            _kWordmarkEndMs / _animMs,
            0,
            1,
            curve: Curves.easeOut,
          );

          return Opacity(
            opacity: (1.0 - _fadeOutCtrl.value).clamp(0.0, 1.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 160,
                    height: 141,
                    child: CustomPaint(
                      painter: _IsotypePainter(
                        strokeProgress: strokeProgress,
                        strokeOpacity: strokeOpacity.clamp(0.0, 1.0),
                        fillProgress: fillProgress,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _Wordmark(opacity: wordOp, targetWidth: 160),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Wordmark ──────────────────────────────────────────────────────────────

class _Wordmark extends StatelessWidget {
  final double opacity;
  final double targetWidth;

  const _Wordmark({
    required this.opacity,
    this.targetWidth = 160,
  });

  static const double _baseFontSize = 24.0;
  static const double _baseLetterSpacing = 2.0;

  @override
  Widget build(BuildContext context) {
    // Scale fontSize + letterSpacing so "LHOTSE" spans the isotype canvas width.
    final tp = TextPainter(
      text: TextSpan(text: 'LHOTSE', style: AppTypography.splashWordmark),
      textDirection: TextDirection.ltr,
    )..layout();
    final scale = targetWidth / tp.width;
    final scaledFontSize = _baseFontSize * scale;
    final scaledLs = _baseLetterSpacing * scale;

    // Letter-spacing settle: tracking starts 22% tighter and relaxes to the
    // final value during the fade-in — "ink settling on paper" (Hermès, JPM
    // Private Bank, Brunello Cucinelli). At opacity=1, width matches targetWidth.
    final lsScale = 0.78 + 0.22 * opacity.clamp(0.0, 1.0);
    final activeLs = scaledLs * lsScale;

    final wordStyle = AppTypography.splashWordmark.copyWith(
      fontSize: scaledFontSize,
      letterSpacing: activeLs,
      color: AppColors.textOnDark,
    );
    final strut = StrutStyle(
      fontSize: scaledFontSize,
      height: 1.0,
      forceStrutHeight: true,
    );

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('LHOTSE', style: wordStyle, strutStyle: strut),
          Text('GROUP', style: wordStyle, strutStyle: strut),
        ],
      ),
    );
  }
}

// ── Isotype CustomPainter ─────────────────────────────────────────────────

class _IsotypePainter extends CustomPainter {
  final double strokeProgress;
  final double strokeOpacity;
  final double fillProgress;

  const _IsotypePainter({
    required this.strokeProgress,
    required this.strokeOpacity,
    required this.fillProgress,
  });

  // Closed silhouette — used by the ascending fill phase.
  static final Path _logo =
      Path()
        ..moveTo(12.5, 0)
        ..lineTo(0, 22)
        ..lineTo(25, 22)
        ..lineTo(22.0577, 16.8172)
        ..lineTo(8.65436, 16.8712)
        ..lineTo(15.3693, 5.0546)
        ..lineTo(12.5, 0)
        ..close();

  // Open trace paths — both ascend from base-left, converging at the summit.
  // _strokeLeft: long left-exterior diagonal.
  // _strokeRight: base + right exterior + valley + summit-right + summit.
  // Together they cover the full outline with no descending segments.
  static final Path _strokeLeft =
      Path()
        ..moveTo(0, 22)
        ..lineTo(12.5, 0);

  static final Path _strokeRight =
      Path()
        ..moveTo(0, 22)
        ..lineTo(25, 22)
        ..lineTo(22.0577, 16.8172)
        ..lineTo(8.65436, 16.8712)
        ..lineTo(15.3693, 5.0546)
        ..lineTo(12.5, 0);

  @override
  void paint(Canvas canvas, Size size) {
    // Scale viewBox (25×22) to canvas (160×141).
    canvas.scale(size.width / 25.0, size.height / 22.0);

    // Stroke trace — dual ascending paths, same progress, converging at summit.
    if (strokeProgress > 0 && strokeOpacity > 0) {
      final paint = Paint()
        ..color = AppColors.textOnDark.withValues(alpha: strokeOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.35
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.miter
        ..isAntiAlias = true;

      for (final path in [_strokeLeft, _strokeRight]) {
        final metric = path.computeMetrics().first;
        final partial = metric.extractPath(0, metric.length * strokeProgress);
        canvas.drawPath(partial, paint);
      }
    }

    // Ascending fill wipe — clipRect from wipeY down to base, crossfading
    // with the stroke fade-out so they hand off without a visible gap.
    if (fillProgress > 0) {
      final wipeY = (1.0 - fillProgress) * 22.0;
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, wipeY, 25, 22 - wipeY));
      canvas.drawPath(
        _logo,
        Paint()
          ..color = AppColors.textOnDark
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_IsotypePainter old) =>
      old.strokeProgress != strokeProgress ||
      old.strokeOpacity != strokeOpacity ||
      old.fillProgress != fillProgress;
}
