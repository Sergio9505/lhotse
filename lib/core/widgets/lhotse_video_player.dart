import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
    this.posterUrl,
    required this.isActive,
    this.playDelay = Duration.zero,
  });

  final String videoUrl;
  final String? posterUrl;
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

  /// Seek to [target] and resume playback (if [widget.isActive]). Clears the
  /// external-pause flag so `didUpdateWidget` re-acquires control.
  Future<void> resumeFrom(Duration target) async {
    _externallyPaused = false;
    final c = _controller;
    if (c == null || !_ready) return;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > c.value.duration ? c.value.duration : target);
    await c.seekTo(clamped);
    if (widget.isActive && _canPlay) {
      await c.play();
    }
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
        if (widget.isActive && !_externallyPaused) c.play();
        setState(() => _showPoster = false);
      } else {
        _playTimer = Timer(widget.playDelay, () {
          if (!mounted) return;
          _canPlay = true;
          if (widget.isActive && !_externallyPaused && _controller != null) {
            _controller!.play();
          }
          setState(() => _showPoster = false);
        });
      }
    } catch (_) {
      // Video failed — poster stays, no error shown.
    }
  }

  @override
  void didUpdateWidget(LhotseVideoPlayer old) {
    super.didUpdateWidget(old);
    final c = _controller;
    if (c == null || !_ready || !_canPlay) return;
    if (_externallyPaused) return;
    if (widget.isActive && !c.value.isPlaying) {
      c.play();
    } else if (!widget.isActive && c.value.isPlaying) {
      c.pause();
    }
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Stack(
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
            child: (widget.posterUrl == null || widget.posterUrl!.isEmpty)
                ? const SizedBox.shrink()
                : LhotseImage(widget.posterUrl, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }
}
