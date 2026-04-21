import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_image.dart';

/// Autoplay-muted video for feed cards. Starts only when the host card is at
/// least [playThreshold] visible, pauses otherwise, and exposes a tiny
/// mute/unmute toggle. The [posterUrl] is shown while the video downloads.
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
  bool _muted = true;

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

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() => _muted = !_muted);
    c.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Poster always present — covers the brief window while the video
        // initializes and any subsequent network stalls.
        LhotseImage(widget.posterUrl),
        if (c != null)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _ready ? 1 : 0,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
          ),
        if (_ready)
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: _MuteToggle(muted: _muted, onTap: _toggleMute),
          ),
      ],
    );
  }
}

class _MuteToggle extends StatelessWidget {
  const _MuteToggle({required this.muted, required this.onTap});
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: PhosphorIcon(
          muted
              ? PhosphorIconsThin.speakerSlash
              : PhosphorIconsThin.speakerHigh,
          size: 16,
          color: AppColors.textOnDark,
        ),
      ),
    );
  }
}
