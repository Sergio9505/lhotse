import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Autoplay-muted video for feed cards. Starts only when the host card is at
/// least visible (via [isActive]) and pauses otherwise. Thumbnails always
/// play silent — the fullscreen player is where audio lives.
class FeedVideoPlayer extends StatefulWidget {
  const FeedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.posterUrl,
    required this.isActive,
  });

  final String videoUrl;
  final String posterUrl;

  /// Parent tells the player whether the card is the one currently in view.
  /// We pause when false to save battery and bandwidth.
  final bool isActive;

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _ready = false;

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
      if (widget.isActive) c.play();
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _ready = true;
      });
    } catch (_) {
      // Video failed — poster stays, no error shown to user.
    }
  }

  @override
  void didUpdateWidget(FeedVideoPlayer old) {
    super.didUpdateWidget(old);
    final c = _controller;
    if (c == null || !_ready) return;
    if (widget.isActive && !c.value.isPlaying) {
      c.play();
    } else if (!widget.isActive && c.value.isPlaying) {
      c.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    // While the VideoPlayerController is initializing we render nothing on
    // top of the parent (black in Home, beige in detail). The Hero flight
    // shuttle in FeedCard still draws the poster image during the transition
    // so the visual is covered during navigation. Once the controller is
    // ready, the video widget appears — no cross-fade from a static poster.
    if (c == null || !_ready) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: c.value.size.width,
        height: c.value.size.height,
        child: VideoPlayer(c),
      ),
    );
  }
}
