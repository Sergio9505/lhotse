import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_image.dart';

/// Fullscreen video reproducer. Audio active by default — thumbnails handle
/// the passive/muted side of the rule. Controls auto-hide 3s after load or
/// last interaction; tap anywhere on the video toggles them. Pausing or
/// reaching the end pins the controls visible.
class FullscreenVideoPlayer extends StatefulWidget {
  const FullscreenVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.posterUrl,
  });

  final String videoUrl;
  final String posterUrl;

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _muted = false;
  bool _controlsVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await c.initialize();
      c.setVolume(1);
      c.addListener(_onVideoEvent);
      await c.play();
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _ready = true;
      });
      _armHideTimer();
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _onVideoEvent() {
    final c = _controller;
    if (c == null || !mounted) return;
    final v = c.value;
    final atEnd = v.duration > Duration.zero && v.position >= v.duration;
    final shouldPin = !v.isPlaying || atEnd;
    if (shouldPin && !_controlsVisible) {
      _hideTimer?.cancel();
      setState(() => _controlsVisible = true);
    }
  }

  void _armHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      final c = _controller;
      if (c == null || !c.value.isPlaying) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideTimer?.cancel();
      setState(() => _controlsVisible = false);
    } else {
      setState(() => _controlsVisible = true);
      _armHideTimer();
    }
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() => _muted = !_muted);
    c.setVolume(_muted ? 0 : 1);
    _armHideTimer();
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      if (c.value.position >= c.value.duration) {
        c.seekTo(Duration.zero);
      }
      c.play();
      _armHideTimer();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_onVideoEvent);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_failed) ...[
              LhotseImage(widget.posterUrl),
              const DecoratedBox(
                decoration: BoxDecoration(color: Color(0x99000000)),
              ),
              Center(
                child: Text(
                  'Vídeo no disponible',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
              ),
            ] else if (!_ready) ...[
              LhotseImage(widget.posterUrl),
              const DecoratedBox(
                decoration: BoxDecoration(color: Color(0x99000000)),
              ),
            ] else ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
              _ControlsOverlay(
                visible: _controlsVisible,
                controller: _controller!,
                muted: _muted,
                topPadding: topPadding,
                bottomPadding: bottomPadding,
                onClose: () => Navigator.of(context).pop(),
                onToggleMute: _toggleMute,
                onTogglePlayPause: _togglePlayPause,
              ),
            ],
            if (_failed || !_ready)
              Positioned(
                top: topPadding + AppSpacing.sm,
                left: AppSpacing.sm,
                child: _ChromeButton(
                  icon: PhosphorIconsThin.x,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({
    required this.visible,
    required this.controller,
    required this.muted,
    required this.topPadding,
    required this.bottomPadding,
    required this.onClose,
    required this.onToggleMute,
    required this.onTogglePlayPause,
  });

  final bool visible;
  final VideoPlayerController controller;
  final bool muted;
  final double topPadding;
  final double bottomPadding;
  final VoidCallback onClose;
  final VoidCallback onToggleMute;
  final VoidCallback onTogglePlayPause;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: topPadding + AppSpacing.sm,
              left: AppSpacing.sm,
              child: _ChromeButton(
                icon: PhosphorIconsThin.x,
                onTap: onClose,
              ),
            ),
            Positioned(
              top: topPadding + AppSpacing.sm,
              right: AppSpacing.sm,
              child: _ChromeButton(
                icon: muted
                    ? PhosphorIconsThin.speakerSlash
                    : PhosphorIconsThin.speakerHigh,
                onTap: onToggleMute,
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: onTogglePlayPause,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: PhosphorIcon(
                    controller.value.isPlaying
                        ? PhosphorIconsThin.pause
                        : PhosphorIconsThin.play,
                    color: AppColors.textOnDark,
                    size: 32,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPadding + AppSpacing.md,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _ProgressStrip(controller: controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.controller});

  final VideoPlayerController controller;

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: EdgeInsets.zero,
              colors: VideoProgressColors(
                playedColor: AppColors.textOnDark,
                bufferedColor: Colors.white.withValues(alpha: 0.38),
                backgroundColor: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _format(value.position),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
                Text(
                  _format(value.duration),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textOnDark
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ChromeButton extends StatelessWidget {
  const _ChromeButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: PhosphorIcon(
          icon,
          size: 20,
          color: AppColors.textOnDark,
        ),
      ),
    );
  }
}
