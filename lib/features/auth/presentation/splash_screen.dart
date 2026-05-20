import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../app/router.dart';
import '../../../core/data/assets_provider.dart';
import '../../../core/data/brands_provider.dart';
import '../../../core/data/document_categories_provider.dart';
import '../../../core/data/documents_provider.dart';
import '../../../core/data/news_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../../investments/data/investments_provider.dart';
import '../data/auth_repository.dart';
import 'otp_verify_screen.dart';

/// First screen after the native bootstrap. Plays the Lhotse brand intro
/// video full-bleed and muted, then routes to welcome / home / OTP capture
/// based on auth state. Provider warm-up runs in parallel during playback.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const String _introAsset = 'assets/videos/intro_lhotse.mp4';
  static const int _fadeOutMs = 500;

  late final VideoPlayerController _videoCtrl;
  late final AnimationController _fadeOutCtrl;

  bool _ready = false;
  bool _navigated = false;
  bool _nativeSplashRemoved = false;

  @override
  void initState() {
    super.initState();

    _fadeOutCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _fadeOutMs),
    );

    _videoCtrl = VideoPlayerController.asset(_introAsset);
    _videoCtrl.addListener(_onVideoTick);

    final user = Supabase.instance.client.auth.currentUser;
    unawaited(_warmUp(user != null));

    unawaited(_bootVideo());
  }

  Future<void> _bootVideo() async {
    try {
      await _videoCtrl.initialize();
      await _videoCtrl.setVolume(0);
      await _videoCtrl.setLooping(false);
      if (!mounted) return;
      setState(() => _ready = true);
      _removeNativeSplash();
      await _videoCtrl.play();
    } catch (_) {
      // Asset corrupt, codec unsupported, etc. Don't block boot — route now.
      _removeNativeSplash();
      _completeAndNavigate(skipFade: true);
    }
  }

  void _removeNativeSplash() {
    if (_nativeSplashRemoved) return;
    _nativeSplashRemoved = true;
    FlutterNativeSplash.remove();
  }

  void _onVideoTick() {
    if (_navigated) return;
    final v = _videoCtrl.value;
    if (!v.isInitialized) return;
    final duration = v.duration;
    if (duration <= Duration.zero) return;
    if (v.position >= duration) {
      _completeAndNavigate();
    }
  }

  Future<void> _completeAndNavigate({bool skipFade = false}) async {
    if (_navigated) return;
    _navigated = true;

    if (!skipFade && mounted) {
      await _fadeOutCtrl.forward();
    }
    if (!mounted) return;

    final user = Supabase.instance.client.auth.currentUser;
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

    context.go(AppRoutes.completePhone);
  }

  Future<void> _safe(Future<Object?> future) async {
    try {
      await future;
    } catch (_) {
      // Each screen surfaces its own error state when navigated to; warm-up
      // failures must not block the splash.
    }
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
  void dispose() {
    _videoCtrl.removeListener(_onVideoTick);
    _videoCtrl.dispose();
    _fadeOutCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _fadeOutCtrl,
        builder: (context, child) {
          return Opacity(
            opacity: (1.0 - _fadeOutCtrl.value).clamp(0.0, 1.0),
            child: child,
          );
        },
        child: _ready
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoCtrl.value.size.width,
                    height: _videoCtrl.value.size.height,
                    child: VideoPlayer(_videoCtrl),
                  ),
                ),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}
