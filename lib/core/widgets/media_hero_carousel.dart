import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'lhotse_image.dart';
import 'lhotse_play_button.dart';

/// Hero media for `news_detail_screen.dart` and `project_detail_screen.dart`
/// (and any future entity whose detail screen wants a multi-image hero).
///
/// Three rendering modes, derived from the input params:
///
///   1. `videoUrl` set            → single-frame poster + `LhotsePlayButton`
///      (no carousel, no dots). Tap is handled by the caller via the
///      `onOpenVideo` callback wired through a `GestureDetector` around
///      this widget. Per ADR-62, video always wins over a multi-image
///      gallery.
///   2. `imageUrls.length > 1`    → `PageView` carousel with dots; slot 0
///      is wrapped in `Hero(tag: heroTag)` so the shared-element
///      transition from feed/card still lands smoothly. Subsequent slots
///      are plain images without Hero tags.
///   3. otherwise                 → single image (or video poster
///      fallback) identical to the pre-carousel behaviour.
///
/// Top + bottom gradients sit on top of every slot so the back button and
/// the collapsed title stay readable on bright media.
///
/// Per ADR-70 (news) and ADR-71 (projects). The widget owns zero domain
/// knowledge — all decisions live in the params, so it is reusable for
/// any entity that exposes `imageUrls` + `videoUrl`.
class MediaHeroCarousel extends StatefulWidget {
  const MediaHeroCarousel({
    super.key,
    required this.heroTag,
    required this.imageUrls,
    required this.videoUrl,
    required this.coverImageUrl,
    required this.useLightOverlay,
    required this.signedVideoUrl,
    required this.onOpenVideo,
    required this.heroGone,
    this.videoChild,
  });

  /// Hero tag for the shared-element transition. Applied only to slot 0
  /// of the carousel (or to the single image / video poster) so the
  /// flight from feed/card always lands on the first frame.
  final String heroTag;

  /// Ordered hero gallery. Empty or 1-element lists fall back to the
  /// single-image rendering path. Per ADR-70 / ADR-71 these are always
  /// `image`-type entries from `hero_media`.
  final List<String> imageUrls;

  /// Optional Bunny / native video URL. When non-empty, video takes
  /// precedence over the gallery (ADR-62 + ADR-70).
  final String? videoUrl;

  /// Denormalized cover (used as the poster when [videoUrl] is set, and
  /// as the source for the single-image rendering when [imageUrls] is
  /// empty / 1-length).
  final String? coverImageUrl;

  /// Drives the dots indicator tint so they stay legible on bright media.
  final bool useLightOverlay;

  /// Signed playback URL (when resolved). Toggles the play overlay's
  /// visibility — the play button only shows once playback is actually
  /// possible.
  final String? signedVideoUrl;

  /// Wired to the `GestureDetector` in the caller. The widget itself
  /// never opens the fullscreen player; the caller decides where the
  /// tap surface lives.
  final VoidCallback onOpenVideo;

  /// Mirrors the detail screen's `_heroGone` flag — used to fade the
  /// dots indicator out as the user scrolls past the hero.
  final bool heroGone;

  /// Optional inline video widget rendered in place of the poster when
  /// [videoUrl] is set. Projects use this to embed `LhotseVideoPlayer`
  /// (muted autoplay loop, DESIGN_SYSTEM § Video System); news leaves it
  /// null and falls back to the poster + play overlay (ADR-62 — news
  /// never autoplays inline).
  final Widget? videoChild;

  @override
  State<MediaHeroCarousel> createState() => _MediaHeroCarouselState();
}

class _MediaHeroCarouselState extends State<MediaHeroCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    if (i != _index) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = widget.videoUrl != null && widget.videoUrl!.isNotEmpty;
    final hasGallery = !hasVideo && widget.imageUrls.length > 1;

    if (hasVideo) {
      // Inline video (project pattern) when `videoChild` is supplied; the
      // caller owns the player widget so MediaHeroCarousel does not need
      // to depend on LhotseVideoPlayer + playable url providers.
      // Otherwise (news pattern, ADR-62) fall back to the static poster +
      // play overlay; the caller wires tap-to-fullscreen via the
      // surrounding GestureDetector.
      final showPoster = widget.videoChild == null;
      final body = widget.videoChild ??
          LhotseImage.poster(
            videoUrl: widget.videoUrl,
            imageUrl: widget.coverImageUrl,
          );
      return _Frame(
        useLightOverlay: widget.useLightOverlay,
        showPlay: showPoster && widget.signedVideoUrl != null,
        child: Hero(tag: widget.heroTag, child: body),
      );
    }

    if (!hasGallery) {
      return _Frame(
        useLightOverlay: widget.useLightOverlay,
        showPlay: false,
        child: Hero(
          tag: widget.heroTag,
          child: LhotseImage.poster(
            videoUrl: null,
            imageUrl:
                widget.imageUrls.isNotEmpty ? widget.imageUrls.first : widget.coverImageUrl,
          ),
        ),
      );
    }

    return _Frame(
      useLightOverlay: widget.useLightOverlay,
      showPlay: false,
      footer: _Dots(
        count: widget.imageUrls.length,
        index: _index,
        useLightOverlay: widget.useLightOverlay,
        visible: !widget.heroGone,
      ),
      child: PageView.builder(
        controller: _controller,
        onPageChanged: _onPageChanged,
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, i) {
          final image = LhotseImage.poster(
            videoUrl: null,
            imageUrl: widget.imageUrls[i],
          );
          if (i == 0) {
            return Hero(tag: widget.heroTag, child: image);
          }
          return image;
        },
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.child,
    required this.useLightOverlay,
    required this.showPlay,
    this.footer,
  });

  final Widget child;
  final bool useLightOverlay;
  final bool showPlay;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0x66000000), Colors.transparent],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0, 0.2),
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0x8C1F1916)],
            ),
          ),
        ),
        if (showPlay) const Center(child: LhotsePlayButton(size: 64)),
        if (footer != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.lg,
            child: SafeArea(
              top: false,
              child: Center(child: footer!),
            ),
          ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.index,
    required this.useLightOverlay,
    required this.visible,
  });

  final int count;
  final int index;
  final bool useLightOverlay;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final base = useLightOverlay ? AppColors.textOnDark : AppColors.textPrimary;
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : AppSpacing.sm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: base.withValues(alpha: i == index ? 1.0 : 0.4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
