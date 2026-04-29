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
import '../../../core/theme/app_theme.dart';
import '../../investments/data/investments_provider.dart';

/// First screen after the native bootstrap. Plays the branded splash video
/// (muted, looping) while warming up the critical Riverpod providers so that
/// any tab the user jumps into first has data ready.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late final VideoPlayerController _controller;

  static const _minSplashDuration = Duration(milliseconds: 3000);
  static const _warmUpTimeout = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Hold the native splash until the video controller is initialized so the
  /// hand-off goes native PNG → playing video, with no black gap while
  /// AVFoundation/ExoPlayer warm up. The native splash is the safety net: if
  /// the video init times out, we still dismiss it so the user is never
  /// frozen — but the timeout is generous (5 s) because debug builds on real
  /// devices can take ~2-4 s the first time, and missing the video to a black
  /// background defeats the purpose of having one.
  Future<void> _bootstrap() async {
    _controller = VideoPlayerController.asset('assets/videos/lhotse_splash.mp4')
      ..setVolume(0)
      ..setLooping(true);

    try {
      await _controller.initialize().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Fall through — we'll dismiss the splash and show black/empty body
      // until the user navigates onward. Better than a frozen native splash.
    }

    if (!mounted) return;
    setState(() {});
    if (_controller.value.isInitialized) {
      _controller.play();
    }
    FlutterNativeSplash.remove();
    _warmUpAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Runs a future and swallows any error. Returns `Future<void>` so all
  /// warm-up tasks share a single signature regardless of provider type.
  Future<void> _safe(Future<Object?> future) async {
    try {
      await future;
    } catch (_) {
      // Individual provider errors are not blocking the splash. Each screen
      // will surface its own error state when the user navigates there.
    }
  }

  Future<void> _warmUpAndNavigate() async {
    final authed = Supabase.instance.client.auth.currentUser != null;

    // homeFeedProvider is not warmed here — home screen fetches it on first
    // paint; the 4 source providers below are what it joins on.
    final futures = <Future<void>>[
      _safe(ref.read(brandsProvider.future)),
      _safe(ref.read(projectsProvider.future)),
      _safe(ref.read(assetsProvider.future)),
      _safe(ref.read(allDocumentCategoriesProvider.future)),
      _safe(ref.read(newsProvider.future)),
      Future<void>.delayed(_minSplashDuration),
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

    try {
      await Future.wait(futures).timeout(_warmUpTimeout);
    } catch (_) {
      // Timeout — navigate anyway; each screen re-fetches what it needs.
    }

    if (!mounted) return;
    context.go(authed ? AppRoutes.home : AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: _controller.value.isInitialized
          // Cover the whole viewport — same pattern as WelcomeScreen so the
          // splash never shows black bars on tall phones / non-matching
          // aspect ratios.
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
