import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Autoplay-muted inline video. Starts only when [isActive] is true and pauses
/// otherwise. Feed uses this with a PageView-driven isActive flag; catalog cards
/// pass isActive: true (ListView builds only visible items, so built == active).
/// Audio always off — fullscreen player is where audio lives.
class LhotseVideoPlayer extends StatefulWidget {
  const LhotseVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.posterUrl,
    required this.isActive,
  });

  final String videoUrl;
  final String posterUrl;
  final bool isActive;

  @override
  State<LhotseVideoPlayer> createState() => _LhotseVideoPlayerState();
}

class _LhotseVideoPlayerState extends State<LhotseVideoPlayer> {
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
      // Video failed — poster stays, no error shown.
    }
  }

  @override
  void didUpdateWidget(LhotseVideoPlayer old) {
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
