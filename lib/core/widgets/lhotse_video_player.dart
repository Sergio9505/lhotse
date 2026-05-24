import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../data/audio_session_helper.dart';
import 'lhotse_image.dart';

/// Autoplay-muted inline video. Starts only when [isActive] is true and pauses
/// otherwise. Feed uses this with a PageView-driven isActive flag; catalog cards
/// pass isActive: true (ListView builds only visible items, so built == active).
/// Audio always off — fullscreen player is where audio lives.
///
/// [playDelay] holds the controller paused on its first frame for the given
/// duration after init, so the swap poster→VideoPlayer happens silently behind
/// a still image and the only visible event is motion starting. Used by detail
/// heros to mask `initialize()` latency. Default `Duration.zero` plays as soon
/// as ready.
///
/// External callers can hand a `GlobalKey<LhotseVideoPlayerState>` and use
/// [LhotseVideoPlayerState.position], [pauseExternal], [resumeFrom] to keep
/// playback continuity with a fullscreen overlay.
class LhotseVideoPlayer extends StatefulWidget {
  const LhotseVideoPlayer({
    super.key,
    required this.videoUrl,
    this.rawVideoUrl,
    this.imageUrl,
    required this.isActive,
    this.playDelay = Duration.zero,
  });

  /// Signed playback URL. Used by the controller.
  final String videoUrl;

  /// Raw (unsigned) source URL used only to derive the poster cascade via
  /// [LhotseImage.poster]. Falls back to [videoUrl] when null.
  final String? rawVideoUrl;

  /// Explicit DB image used as last-resort poster fallback.
  final String? imageUrl;

  final bool isActive;
  final Duration playDelay;

  @override
  State<LhotseVideoPlayer> createState() => LhotseVideoPlayerState();
}

class LhotseVideoPlayerState extends State<LhotseVideoPlayer> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _canPlay = false;
  bool _showPoster = true;
  bool _externallyPaused = false;
  // Tab switching with IndexedStack keeps non-current branches in the tree but
  // unpainted. AVPlayer keeps decoding frames offscreen, so iOS classifies the
  // app as a "media app" and the screen never sleeps. VisibilityDetector lets
  // us pause the controller when the widget is not painted to the screen.
  bool _isVisible = false;
  Timer? _playTimer;

  /// Current playback position. Returns [Duration.zero] before the controller
  /// is ready.
  Duration get position => _controller?.value.position ?? Duration.zero;

  /// Pause the controller from outside (e.g. a fullscreen overlay is taking
  /// over). The widget will not auto-resume on `didUpdateWidget` until
  /// [resumeFrom] is called.
  void pauseExternal() {
    _externallyPaused = true;
    _controller?.pause();
  }

  /// Seek to [target] and resume playback (if [widget.isActive] and visible).
  /// Clears the external-pause flag so the regular play/pause gating takes
  /// over again.
  Future<void> resumeFrom(Duration target) async {
    _externallyPaused = false;
    final c = _controller;
    if (c == null || !_ready) return;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > c.value.duration ? c.value.duration : target);
    await c.seekTo(clamped);
    _tryPlay();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await c.initialize();
      c.setLooping(true);
      c.setVolume(0);
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _ready = true;
      });
      if (widget.playDelay == Duration.zero) {
        _canPlay = true;
        _tryPlay();
      } else {
        _playTimer = Timer(widget.playDelay, () {
          if (!mounted) return;
          _canPlay = true;
          _tryPlay();
        });
      }
    } catch (_) {
      // Video failed — poster stays, no error shown.
    }
  }

  /// Centralised play gate. Plays only when every condition holds: controller
  /// initialised, delay elapsed, no external pause overlay, parent says active,
  /// and the widget is currently painted to screen.
  void _tryPlay() {
    final c = _controller;
    if (c == null || !_ready || !_canPlay) return;
    if (_externallyPaused) return;
    if (!widget.isActive || !_isVisible) return;
    if (c.value.isPlaying) return;
    c.play();
    // Inline hero is muted/decorative — downgrade AVAudioSession to `.ambient`
    // so iOS doesn't classify the app as a media app, otherwise the screen
    // never sleeps even after the user moves away from the video surface.
    downgradeAudioSessionToAmbient();
    if (_showPoster) setState(() => _showPoster = false);
  }

  void _tryPause() {
    final c = _controller;
    if (c == null || !c.value.isPlaying) return;
    c.pause();
  }

  @override
  void didUpdateWidget(LhotseVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_externallyPaused) return;
    if (widget.isActive) {
      _tryPlay();
    } else {
      _tryPause();
    }
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _controller?.dispose();
    // Downgrade tras destruir el controller — sin esto iOS sigue clasificando
    // la app como "media app" y la pantalla no se apaga tras volver del detail.
    downgradeAudioSessionToAmbient();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return VisibilityDetector(
      key: Key('lhotse-video-${widget.videoUrl}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        final visible = info.visibleFraction > 0.0;
        if (visible == _isVisible) return;
        _isVisible = visible;
        if (visible) {
          _tryPlay();
        } else {
          _tryPause();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (c != null && _ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showPoster ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: LhotseImage.poster(
                videoUrl: widget.rawVideoUrl ?? widget.videoUrl,
                imageUrl: widget.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
