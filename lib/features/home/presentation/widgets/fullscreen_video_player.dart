import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_image.dart';

/// Fullscreen video reproducer. Audio active by default — thumbnails handle
/// the passive/muted side of the rule.
///
/// Premium gesture set:
/// - **Tap** → toggle controls (close, mute, play/pause, progress). Controls
///   auto-hide 3s after last interaction. Mount with controls HIDDEN so the
///   video shows full-bleed immediately.
/// - **Drag down** → translate the video with the finger. Past 20% of screen
///   height or velocity > 700 px/s, pop fullscreen. Otherwise snap back
///   (`easeOutCubic` 220ms).
/// - **Double-tap right half** → seek +10s. **Double-tap left half** →
///   seek −10s. Brief circular indicator fades in/out at the corresponding
///   side.
///
/// Pausing or reaching the end pins the controls visible via `_onVideoEvent`.
class FullscreenVideoPlayer extends StatefulWidget {
  const FullscreenVideoPlayer({
    super.key,
    required this.videoUrl,
    this.rawVideoUrl,
    this.imageUrl,
    this.initialPosition = Duration.zero,
  });

  /// Signed playback URL (e.g. Bunny token-bearing). Used by the player.
  final String videoUrl;

  /// Raw (unsigned) source URL used only to derive the loading poster via
  /// [LhotseImage.poster]. Defaults to [videoUrl] when null — useful when
  /// the caller has only the signed URL.
  final String? rawVideoUrl;

  /// Explicit DB image used as last-resort poster fallback.
  final String? imageUrl;

  /// Where to start playback. Used to keep continuity with the hero player
  /// underneath. The route pops with the controller's current position so the
  /// caller can seek the hero to the same spot on close.
  final Duration initialPosition;

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer>
    with SingleTickerProviderStateMixin {
  static const double _kDismissDistanceFraction = 0.2;
  static const double _kDismissVelocity = 700.0;
  static const Duration _kSnapBackDuration = Duration(milliseconds: 220);
  static const Duration _kSeekStep = Duration(seconds: 10);
  static const Duration _kSeekIndicatorDuration =
      Duration(milliseconds: 500);

  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _muted = false;
  bool _controlsVisible = false;
  Timer? _hideTimer;

  // Drag-to-dismiss
  double _dismissDragOffset = 0;
  double _snapBackFrom = 0;
  late final AnimationController _snapBackAnim;

  // Double-tap seek
  Offset? _doubleTapPosition;
  String? _seekIndicatorText;
  Alignment _seekIndicatorAlignment = Alignment.centerRight;
  Timer? _seekIndicatorTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _snapBackAnim = AnimationController(
      vsync: this,
      duration: _kSnapBackDuration,
    )..addListener(_onSnapBackTick);
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await c.initialize();
      c.setVolume(1);
      c.addListener(_onVideoEvent);
      if (widget.initialPosition > Duration.zero &&
          widget.initialPosition < c.value.duration) {
        await c.seekTo(widget.initialPosition);
      }
      await c.play();
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _ready = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  /// Pop with the current playback position so the hero can seek to the same
  /// spot. Falls back to [widget.initialPosition] if the controller hasn't
  /// finished initializing yet — better than 0 for continuity.
  void _close() {
    final pos = _controller?.value.position ?? widget.initialPosition;
    Navigator.of(context).pop(pos);
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

  // ------ Drag-to-dismiss ------

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    if (_snapBackAnim.isAnimating) _snapBackAnim.stop();
    final next =
        (_dismissDragOffset + d.delta.dy).clamp(0.0, double.infinity);
    if (next == _dismissDragOffset) return;
    setState(() => _dismissDragOffset = next);
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    final screenHeight = MediaQuery.of(context).size.height;
    final velocity = d.primaryVelocity ?? 0;
    final shouldDismiss = _dismissDragOffset >
            screenHeight * _kDismissDistanceFraction ||
        velocity > _kDismissVelocity;
    if (shouldDismiss) {
      _close();
    } else {
      _snapBackFrom = _dismissDragOffset;
      _snapBackAnim.forward(from: 0);
    }
  }

  void _onVerticalDragCancel() {
    if (_dismissDragOffset == 0) return;
    _snapBackFrom = _dismissDragOffset;
    _snapBackAnim.forward(from: 0);
  }

  void _onSnapBackTick() {
    final t = Curves.easeOutCubic.transform(_snapBackAnim.value);
    setState(() => _dismissDragOffset = _snapBackFrom * (1 - t));
  }

  // ------ Double-tap seek ------

  void _onDoubleTapDown(TapDownDetails d) {
    _doubleTapPosition = d.globalPosition;
  }

  void _onDoubleTap() {
    final c = _controller;
    if (c == null || _doubleTapPosition == null) return;
    final width = MediaQuery.of(context).size.width;
    final isLeft = _doubleTapPosition!.dx < width / 2;
    final currentMs = c.value.position.inMilliseconds;
    final stepMs = _kSeekStep.inMilliseconds;
    final durationMs = c.value.duration.inMilliseconds;
    final targetMs = isLeft
        ? math.max(0, currentMs - stepMs)
        : math.min(durationMs, currentMs + stepMs);
    c.seekTo(Duration(milliseconds: targetMs));
    _showSeekIndicator(isLeft);
  }

  void _showSeekIndicator(bool isLeft) {
    _seekIndicatorTimer?.cancel();
    setState(() {
      _seekIndicatorText = isLeft ? '−10s' : '+10s';
      _seekIndicatorAlignment =
          isLeft ? Alignment.centerLeft : Alignment.centerRight;
    });
    _seekIndicatorTimer = Timer(_kSeekIndicatorDuration, () {
      if (!mounted) return;
      setState(() => _seekIndicatorText = null);
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(
        const [DeviceOrientation.portraitUp]);
    _hideTimer?.cancel();
    _seekIndicatorTimer?.cancel();
    _snapBackAnim.dispose();
    _controller?.removeListener(_onVideoEvent);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewPaddingOf(context);
    final topOffset =
        (viewInsets.top > 0 ? viewInsets.top : AppSpacing.lg) + AppSpacing.sm;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _close();
        },
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (_failed) ...[
                LhotseImage.poster(
                  videoUrl: widget.rawVideoUrl ?? widget.videoUrl,
                  imageUrl: widget.imageUrl,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x99000000)),
                ),
                Center(
                  child: Text(
                    'Vídeo no disponible',
                    style: AppTypography.bodyReading.copyWith(
                      color: AppColors.textOnDark,
                    ),
                  ),
                ),
              ] else if (!_ready) ...[
                LhotseImage.poster(
                  videoUrl: widget.rawVideoUrl ?? widget.videoUrl,
                  imageUrl: widget.imageUrl,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x99000000)),
                ),
              ] else ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleControls,
                  onDoubleTapDown: _onDoubleTapDown,
                  onDoubleTap: _onDoubleTap,
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  onVerticalDragCancel: _onVerticalDragCancel,
                  child: Transform.translate(
                    offset: Offset(0, _dismissDragOffset),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  ),
                ),
                // Seek indicator overlay — fades in/out at left/right edge
                // when the user double-taps. Stays in the tree always so the
                // AnimatedOpacity fade-out is smooth.
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _seekIndicatorText != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: Align(
                      alignment: _seekIndicatorAlignment,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.55),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PhosphorIcon(
                                _seekIndicatorAlignment ==
                                        Alignment.centerLeft
                                    ? PhosphorIconsThin.arrowFatLineLeft
                                    : PhosphorIconsThin.arrowFatLineRight,
                                size: 28,
                                color: AppColors.textOnDark,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _seekIndicatorText ?? '',
                                style: AppTypography.labelUppercaseSm
                                    .copyWith(
                                  color: AppColors.textOnDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _ControlsOverlay(
                  visible: _controlsVisible,
                  controller: _controller!,
                  muted: _muted,
                  topOffset: topOffset,
                  bottomPadding: bottomPadding,
                  onClose: _close,
                  onToggleMute: _toggleMute,
                  onTogglePlayPause: _togglePlayPause,
                ),
              ],
              if (_failed || !_ready)
                Positioned(
                  top: topOffset,
                  right: AppSpacing.sm,
                  child: _ChromeButton(
                    icon: PhosphorIconsThin.x,
                    onTap: _close,
                  ),
                ),
            ],
          ),
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
    required this.topOffset,
    required this.bottomPadding,
    required this.onClose,
    required this.onToggleMute,
    required this.onTogglePlayPause,
  });

  final bool visible;
  final VideoPlayerController controller;
  final bool muted;
  final double topOffset;
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
              top: topOffset,
              right: AppSpacing.sm,
              child: _ChromeButton(
                icon: PhosphorIconsThin.x,
                onTap: onClose,
              ),
            ),
            Positioned(
              top: topOffset,
              left: AppSpacing.sm,
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
                  style: AppTypography.annotation.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
                Text(
                  _format(value.duration),
                  style: AppTypography.annotation.copyWith(
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
