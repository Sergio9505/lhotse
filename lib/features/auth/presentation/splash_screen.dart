import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../app/router.dart';
import '../../../core/boot/boot_state.dart';
import '../../../core/data/assets_provider.dart';
import '../../../core/data/audio_session_helper.dart';
import '../../../core/data/brands_provider.dart';
import '../../../core/data/document_categories_provider.dart';
import '../../../core/data/documents_provider.dart';
import '../../../core/data/news_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../../../core/data/supabase_provider.dart';
import '../../investments/data/investments_provider.dart';

/// First screen after the native bootstrap. Plays the Lhotse brand intro
/// video full-bleed and muted (always in full, regardless of how quickly the
/// boot state machine resolves — it's a brand asset, not a loader), then
/// hands off navigation to the router by jumping to `/`. The router redirect
/// reads `bootStateProvider` and decides the actual destination
/// (`/welcome`, `/home`, `/accept-consent`, etc.).
///
/// The boot state machine ([BootStateNotifier]) computes consent / onboarding
/// state in parallel with the video so by the time the video + fade finish,
/// the answer is usually already cached.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const String _introAsset = 'assets/videos/intro_lhotse.mp4';
  static const int _fadeOutMs = 500;
  static const Duration _bootWaitTimeout = Duration(seconds: 30);

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

    // Touch the boot state provider so it starts computing immediately, in
    // parallel with the video. The router redirect reads it later.
    ref.read(bootStateProvider);

    final user = ref.read(supabaseClientProvider).auth.currentUser;
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
      // Downgrade `AVAudioSession.category` a `.ambient` — el splash video
      // es decorativo + breve, no necesita comportamiento de "media app"
      // iOS. El plugin sube a `.playback` en cada `play()`; sin downgrade
      // la session queda pegada y iOS mantiene la pantalla activa en
      // pantallas posteriores de la sesión.
      downgradeAudioSessionToAmbient();
    } catch (_) {
      // Asset corrupt, codec unsupported, etc. Don't block boot — hand off
      // immediately, router decides what to render.
      _removeNativeSplash();
      _handOff(skipFade: true);
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
      _handOff();
    }
  }

  Future<void> _handOff({bool skipFade = false}) async {
    if (_navigated) return;
    _navigated = true;

    if (!skipFade && mounted) {
      await _fadeOutCtrl.forward();
    }
    if (!mounted) return;

    // Wait for the boot state machine to resolve (or 30s safety timeout).
    // The vast majority of the time this completes instantly — the consent +
    // onboarding queries had the full video duration to run in background.
    await _waitForBootStateReady();
    if (!mounted) return;

    // Hand off to the router; the redirect callback in `routerProvider`
    // reads `bootStateProvider` and routes to the canonical destination.
    context.go(AppRoutes.home);
  }

  Future<void> _waitForBootStateReady() {
    final current = ref.read(bootStateProvider);
    if (current is! BootLoading) return Future.value();

    final completer = Completer<void>();
    final sub = ref.listenManual<BootState>(bootStateProvider, (_, next) {
      if (next is! BootLoading && !completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future
        .timeout(_bootWaitTimeout, onTimeout: () {
      // Safety net: if the state machine never escapes Loading (network
      // hang past the 8s inner timeout + retries, broken DB, etc.), let the
      // router decide what to do with whatever state is there. The
      // fail-closed in BootStateNotifier should have caught it already.
    }).whenComplete(sub.close);
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
    // pause() antes de dispose() es load-bearing en iOS — el plugin
    // video_player_avfoundation setea `isIdleTimerDisabled = true` al play()
    // y solo lo resetea al pause(). Un dispose() sin pause previo deja el
    // flag global colgado y la pantalla del iPhone no se apaga en pantallas
    // posteriores (feed, etc.).
    _videoCtrl.dispose();
    // Downgrade asegura que la session queda en `.ambient` para que la
    // próxima pantalla (welcome o home) permita auto-lock normal — sin
    // esto iOS mantiene la pantalla activa indefinidamente.
    downgradeAudioSessionToAmbient();
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
