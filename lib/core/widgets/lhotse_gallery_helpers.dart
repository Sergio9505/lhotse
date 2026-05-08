import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:video_player/video_player.dart';

import '../data/bunny_thumbnail.dart';
import '../data/playable_video_url_provider.dart';
import '../domain/media_item.dart';
import '../theme/app_theme.dart';
import 'lhotse_bottom_sheet.dart';
import 'lhotse_image.dart';

/// Opens a bottom sheet with all gallery items in a vertical scroll.
/// Tapping any item opens the paged gallery viewer at that index.
void showAllGallery(
    BuildContext context, String title, List<MediaItem> items) {
  showLhotseBottomSheet(
    context: context,
    title: title,
    itemCount: items.length,
    listPadding: EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      MediaQuery.of(context).padding.bottom + AppSpacing.md,
    ),
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
    itemBuilder: (context, i) {
      final item = items[i];
      return GestureDetector(
        onTap: () => showMediaGallery(context, items: items, initialIndex: i),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: item.type == MediaType.image
              ? LhotseImage(item.url)
              : VideoThumbnailTile(url: item.url),
        ),
      );
    },
  );
}

/// Opens a paged full-screen gallery viewer starting at [initialIndex].
/// Supports swipe between all items, pinch-to-zoom and double-tap on images,
/// and auto-play (muted) on videos with tap-to-toggle controls.
void showMediaGallery(
  BuildContext context, {
  required List<MediaItem> items,
  required int initialIndex,
}) {
  if (items.isEmpty) return;
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) =>
            Opacity(opacity: animation.value, child: child),
        child: _MediaGalleryViewer(
          items: items,
          initialIndex: initialIndex,
        ),
      ),
    ),
  );
}

/// Opens a full-screen single-image viewer (pinch to zoom, tap to dismiss).
/// For galleries with multiple items use [showMediaGallery] instead.
void showFullImage(BuildContext context, String imageUrl) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) =>
              Opacity(opacity: animation.value, child: child),
          child: _FullImageView(imageUrl: imageUrl),
        );
      },
    ),
  );
}

class _FullImageView extends StatefulWidget {
  const _FullImageView({required this.imageUrl});

  final String imageUrl;

  @override
  State<_FullImageView> createState() => _FullImageViewState();
}

class _FullImageViewState extends State<_FullImageView> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(
        const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      topPadding + kToolbarHeight,
                      0,
                      bottomPadding + AppSpacing.lg,
                    ),
                    child:
                        LhotseImage(widget.imageUrl, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: topPadding + AppSpacing.md,
                right: AppSpacing.lg,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                    child: const PhosphorIcon(
                      PhosphorIconsThin.x,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
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

// ─── Gallery viewer ────────────────────────────────────────────────────────

class _MediaGalleryViewer extends StatefulWidget {
  const _MediaGalleryViewer({
    required this.items,
    required this.initialIndex,
  });

  final List<MediaItem> items;
  final int initialIndex;

  @override
  State<_MediaGalleryViewer> createState() => _MediaGalleryViewerState();
}

class _MediaGalleryViewerState extends State<_MediaGalleryViewer> {
  late final PageController _pageController;
  late int _currentPage;
  final ValueNotifier<bool> _anyZoomed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(
        const [DeviceOrientation.portraitUp]);
    _pageController.dispose();
    _anyZoomed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _anyZoomed,
            builder: (context, isZoomed, _) => PageView.builder(
              controller: _pageController,
              physics: isZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              itemCount: widget.items.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, i) {
                final item = widget.items[i];
                final isActive = i == _currentPage;
                return item.type == MediaType.video
                    ? _VideoPage(item: item, isActive: isActive)
                    : _ImagePage(
                        item: item,
                        isActive: isActive,
                        onZoomChanged: (z) => _anyZoomed.value = z,
                      );
              },
            ),
          ),
          if (widget.items.length > 1)
            Positioned(
              top: topPadding + AppSpacing.md,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    '${_currentPage + 1} / ${widget.items.length}',
                    style: AppTypography.annotation.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: topPadding + AppSpacing.sm,
            right: AppSpacing.sm,
            child: _ChromeButton(
              icon: PhosphorIconsThin.x,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Image page ────────────────────────────────────────────────────────────

class _ImagePage extends StatefulWidget {
  const _ImagePage({
    required this.item,
    required this.isActive,
    required this.onZoomChanged,
  });

  final MediaItem item;
  final bool isActive;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<_ImagePage> {
  final TransformationController _txController = TransformationController();
  Offset? _doubleTapPosition;

  @override
  void initState() {
    super.initState();
    _txController.addListener(_onTransformChanged);
  }

  @override
  void didUpdateWidget(_ImagePage old) {
    super.didUpdateWidget(old);
    if (!widget.isActive && old.isActive) {
      _txController.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _txController.removeListener(_onTransformChanged);
    _txController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    widget.onZoomChanged(_txController.value != Matrix4.identity());
  }

  void _onDoubleTapDown(TapDownDetails d) {
    _doubleTapPosition = d.globalPosition;
  }

  void _onDoubleTap() {
    if (_txController.value != Matrix4.identity()) {
      _txController.value = Matrix4.identity();
    } else {
      final rb = context.findRenderObject() as RenderBox?;
      if (rb == null || _doubleTapPosition == null) return;
      const scale = 2.5;
      final pos = rb.globalToLocal(_doubleTapPosition!);
      final tx = -pos.dx * (scale - 1);
      final ty = -pos.dy * (scale - 1);
      _txController.value =
          Matrix4.translationValues(tx, ty, 0.0)
            ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _onDoubleTapDown,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _txController,
        maxScale: 4.0,
        child: SizedBox.expand(
          child: Center(
            child: LhotseImage(widget.item.url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

// ─── Video page ────────────────────────────────────────────────────────────

class _VideoPage extends ConsumerStatefulWidget {
  const _VideoPage({required this.item, required this.isActive});

  final MediaItem item;
  final bool isActive;

  @override
  ConsumerState<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends ConsumerState<_VideoPage> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _muted = true;
  bool _controlsVisible = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _resolveAndInit();
  }

  Future<void> _resolveAndInit() async {
    try {
      final url = await ref.read(
        playableVideoUrlProvider(widget.item.url).future,
      );
      await _init(url);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  Future<void> _init(String url) async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      c.setLooping(true);
      await c.setVolume(0);
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _ready = true;
      });
      if (widget.isActive) c.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(_VideoPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive == old.isActive) return;
    if (widget.isActive) {
      _controller?.play();
    } else {
      _controller?.pause();
      _hideTimer?.cancel();
      if (mounted) setState(() => _controlsVisible = false);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _armHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _armHideTimer();
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
      if (c.value.position >= c.value.duration) c.seekTo(Duration.zero);
      c.play();
      _armHideTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    if (_failed) {
      return Center(
        child: Text(
          'Vídeo no disponible',
          style: AppTypography.bodyReading
              .copyWith(color: Colors.white.withValues(alpha: 0.6)),
        ),
      );
    }
    if (!_ready) {
      final thumb = bunnyThumbnailUrlFor(widget.item.url);
      if (thumb == null) return const SizedBox.expand();
      final signed = ref.watch(playableVideoUrlProvider(thumb));
      return signed.when(
        data: (u) => Center(
          child: LhotseImage(
            u,
            fit: BoxFit.contain,
            placeholder: LhotseImagePlaceholder.video,
          ),
        ),
        loading: () => const SizedBox.expand(),
        error: (_, _) => const SizedBox.expand(),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          IgnorePointer(
            ignoring: !_controlsVisible,
            child: AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: topPadding + AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: _ChromeButton(
                      icon: _muted
                          ? PhosphorIconsThin.speakerSlash
                          : PhosphorIconsThin.speakerHigh,
                      onTap: _toggleMute,
                    ),
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: PhosphorIcon(
                          _controller!.value.isPlaying
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      child: _ProgressStrip(controller: _controller!),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared chrome ─────────────────────────────────────────────────────────

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
        child: PhosphorIcon(icon, size: 20, color: AppColors.textOnDark),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.controller});

  final VideoPlayerController controller;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) => Column(
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
              Text(_fmt(value.position),
                  style: AppTypography.annotation
                      .copyWith(color: AppColors.textOnDark)),
              Text(_fmt(value.duration),
                  style: AppTypography.annotation.copyWith(
                      color: AppColors.textOnDark.withValues(alpha: 0.7))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Video tile for carousels and lists. Shows the Bunny static thumbnail
/// (signed) when the URL is from Bunny CDN; falls back to a dark tile with
/// a film icon otherwise (Storage uploads, broken URLs, etc.).
class VideoThumbnailTile extends ConsumerWidget {
  const VideoThumbnailTile({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumb = bunnyThumbnailUrlFor(url);
    if (thumb == null) return const _VideoTileFallback();

    final signed = ref.watch(playableVideoUrlProvider(thumb));
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          signed.when(
            data: (u) => LhotseImage(
              u,
              placeholder: LhotseImagePlaceholder.video,
            ),
            loading: () => Container(color: AppColors.surface),
            error: (_, _) => const _VideoTileFallback(),
          ),
          const Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x66000000),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIconsFill.play,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoTileFallback extends StatelessWidget {
  const _VideoTileFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: PhosphorIcon(
          PhosphorIconsThin.filmSlate,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}
