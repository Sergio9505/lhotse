import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/data/audio_session_helper.dart';
import '../../../core/data/playable_video_url_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../onboarding/data/onboarding_repository.dart';

/// CEO welcome video (Bunny Stream). Raw, unsigned URL — resolved to a signed
/// playback URL via [playableVideoUrlProvider] at runtime. Pinned here as a
/// constant after removing the 'Bienvenido' news row from the feed/Noticias
/// (ADR: welcome video is no longer feed content). To swap the video, update
/// this constant (requires a release). See ADR.
const kWelcomeVideoUrl =
    'https://vz-44710bc5-f88.b-cdn.net/d318450d-b111-455d-9ba0-7cf01120a228/play_1080p.mp4';

/// Presents the one-time welcome video as a blocking fullscreen route on the
/// root navigator (covers the bottom nav + everything). Awaited by the shell
/// first-run orchestration so it lands after the permission sheets.
Future<void> showWelcomeVideo(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const WelcomeVideoScreen(),
    ),
  );
}

/// One-time CEO welcome video. Plays full-bleed with audio (the CEO explains
/// the why of the app), blocking every action behind it — the only affordance
/// is the X skip. Mirrors the splash brand-video grammar (full-bleed cover,
/// black, single-shot) rather than the feed's content player (no scrubber,
/// seek, mute toggle or drag-to-dismiss). On end or skip it stamps
/// `welcome_seen_at` so it never shows again for this account.
class WelcomeVideoScreen extends ConsumerStatefulWidget {
  const WelcomeVideoScreen({super.key});

  @override
  ConsumerState<WelcomeVideoScreen> createState() => _WelcomeVideoScreenState();
}

class _WelcomeVideoScreenState extends ConsumerState<WelcomeVideoScreen> {
  /// The skip control is withheld for a beat so the CEO's opening lands before
  /// the user can dismiss it (still skippable — just not from second 0).
  static const _kSkipDelay = Duration(seconds: 4);

  VideoPlayerController? _controller;
  bool _ready = false;
  bool _closing = false;
  bool _skipVisible = false;
  Timer? _skipTimer;

  @override
  void initState() {
    super.initState();
    _skipTimer = Timer(_kSkipDelay, () {
      if (mounted) setState(() => _skipVisible = true);
    });
    _init();
  }

  Future<void> _init() async {
    // Keep a live listener while awaiting `.future` — playableVideoUrlProvider
    // is autoDispose; reading `.future` bare can throw "disposed during
    // loading" (see global gotcha). The subscription holds it alive.
    final sub = ref.listenManual(
      playableVideoUrlProvider(kWelcomeVideoUrl),
      (_, _) {},
    );
    try {
      final signedUrl =
          await ref.read(playableVideoUrlProvider(kWelcomeVideoUrl).future);
      final c = VideoPlayerController.networkUrl(Uri.parse(signedUrl));
      await c.initialize();
      await c.setVolume(1);
      await c.setLooping(false);
      c.addListener(_onTick);
      // Raise the iOS audio session to `.playback` before play so the CEO
      // audio isn't silenced by the hardware mute switch (same as the
      // fullscreen content player). Downgraded back to `.ambient` on dispose.
      await upgradeAudioSessionToPlayback();
      await c.play();
      if (!mounted) {
        await c.pause();
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _ready = true;
      });
    } catch (_) {
      // Fail open: never trap the user behind a broken video. Close WITHOUT
      // marking seen so the next launch retries (it was likely transient).
      if (mounted) _close(markSeen: false);
    } finally {
      sub.close();
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || _closing) return;
    final v = c.value;
    if (v.duration > Duration.zero && v.position >= v.duration) {
      _close(markSeen: true);
    }
  }

  Future<void> _close({required bool markSeen}) async {
    if (_closing) return;
    _closing = true;
    if (markSeen) {
      // Best-effort — a write failure must not block the dismissal.
      try {
        await ref.read(onboardingRepositoryProvider).markWelcomeSeen();
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _skipTimer?.cancel();
    _controller?.removeListener(_onTick);
    // pause() before dispose() is load-bearing on iOS (idle-timer flag stays
    // stuck otherwise — screen won't sleep on later screens).
    _controller?.pause();
    _controller?.dispose();
    downgradeAudioSessionToAmbient();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewPaddingOf(context);
    final topOffset =
        (viewInsets.top > 0 ? viewInsets.top : AppSpacing.lg) + AppSpacing.sm;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The CEO video has a light (beige) background → dark status-bar icons.
      value: SystemUiOverlayStyle.dark,
      // Block every action behind the video — the system back does nothing;
      // only the SALTAR control (or the video ending) closes it.
      child: PopScope<Object?>(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (_ready && _controller != null)
                // `cover`: the CEO video is portrait with generous margin, so
                // filling edge-to-edge (cropping ~11% per side) keeps the
                // subject framed and reads as immersive — contain left black
                // bars top/bottom (verified against a real capture).
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.textOnDark,
                    ),
                  ),
                ),
              // Thin, non-interactive progress bar — sets the "how much is
              // left" expectation without inviting scrubbing. Dark on the
              // light video; inset from the edges so it doesn't look cut.
              if (_ready && _controller != null)
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: bottomPadding + AppSpacing.md,
                  child: IgnorePointer(
                    child: VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: false,
                      padding: EdgeInsets.zero,
                      colors: VideoProgressColors(
                        playedColor: AppColors.primary,
                        bufferedColor:
                            AppColors.primary.withValues(alpha: 0.30),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
              // SALTAR — minimal dark text (light video → dark chrome, like
              // LhotseBackButton.overImage). Withheld for ~4s, then fades in.
              Positioned(
                top: topOffset,
                right: AppSpacing.lg,
                child: AnimatedOpacity(
                  opacity: _skipVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_skipVisible,
                    child: _SkipLabel(onTap: () => _close(markSeen: true)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkipLabel extends StatefulWidget {
  const _SkipLabel({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SkipLabel> createState() => _SkipLabelState();
}

class _SkipLabelState extends State<_SkipLabel> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.4 : 1.0,
        // Padding gives a comfortable ~44pt hit target without a container.
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Text(
            'SALTAR',
            style: AppTypography.labelUppercaseMd
                .copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
