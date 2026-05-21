import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'lhotse_image.dart';
import 'lhotse_play_button.dart';

/// Pure renderer for the detail screens' hero media. Has THREE rendering
/// modes derived from the input props:
///
///   1. `videoUrl` non-null            → static poster + optional play
///      overlay (single Hero, no gallery, no internal gestures).
///   2. `imageUrls.length > 1`         → Stack of `Positioned` images
///      with `left: i * pageWidth - galleryOffset`. Slot 0 wrapped in
///      `Hero(tag: heroTag)` for the shared-element transition. Dots
///      indicator driven by `galleryIndex`.
///   3. otherwise                      → single image (or video poster
///      fallback) identical to the pre-carousel behaviour.
///
/// **Gestures are NOT handled here.** Both tap-to-fullscreen (video mode)
/// and horizontal swipe (gallery mode) are owned by a `Listener` at the
/// detail screen's `Scaffold.body` level — empirically, gesture handlers
/// embedded inside this widget did not receive pointer events in this
/// tree across five different architectures (see `docs/solutions/2026-05-21-pageview-inside-sliverappbar-swipe.md`).
///
/// Per ADR-70 (news) and ADR-71 (projects). Zero domain knowledge — all
/// decisions live in the props.
class MediaHeroCarousel extends StatelessWidget {
  const MediaHeroCarousel({
    super.key,
    required this.heroTag,
    required this.imageUrls,
    required this.videoUrl,
    required this.coverImageUrl,
    required this.useLightOverlay,
    required this.signedVideoUrl,
    required this.heroGone,
    this.galleryOffset = 0,
    this.galleryIndex = 0,
    this.videoChild,
  });

  /// Hero tag for the shared-element transition. Applied only to slot 0
  /// of the gallery (or to the single image / video poster) so the
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
  /// possible. The actual tap-to-fullscreen is handled by the screen's
  /// `Listener` at `Scaffold.body` level.
  final String? signedVideoUrl;

  /// Mirrors the detail screen's `_heroGone` flag — used to fade the
  /// dots indicator out as the user scrolls past the hero.
  final bool heroGone;

  /// Current horizontal scroll offset of the gallery in pixels, owned
  /// by the screen's State and animated externally. Drives the
  /// `left: i * pageWidth - galleryOffset` of each `Positioned` image.
  final double galleryOffset;

  /// Current page index of the gallery. Drives the dots indicator's
  /// active dot.
  final int galleryIndex;

  /// Optional inline video widget rendered in place of the poster when
  /// [videoUrl] is set. Projects use this to embed `LhotseVideoPlayer`
  /// (muted autoplay loop, DESIGN_SYSTEM § Video System); news leaves it
  /// null and falls back to the poster + play overlay (ADR-62 — news
  /// never autoplays inline).
  final Widget? videoChild;

  @override
  Widget build(BuildContext context) {
    final hasVideo = videoUrl != null && videoUrl!.isNotEmpty;
    final hasGallery = !hasVideo && imageUrls.length > 1;

    if (hasVideo) {
      final showPoster = videoChild == null;
      final body = videoChild ??
          LhotseImage.poster(
            videoUrl: videoUrl,
            imageUrl: coverImageUrl,
          );
      return _Frame(
        useLightOverlay: useLightOverlay,
        showPlay: showPoster && signedVideoUrl != null,
        child: Hero(tag: heroTag, child: body),
      );
    }

    if (!hasGallery) {
      return _Frame(
        useLightOverlay: useLightOverlay,
        showPlay: false,
        child: Hero(
          tag: heroTag,
          child: LhotseImage.poster(
            videoUrl: null,
            imageUrl:
                imageUrls.isNotEmpty ? imageUrls.first : coverImageUrl,
          ),
        ),
      );
    }

    return _Frame(
      useLightOverlay: useLightOverlay,
      showPlay: false,
      footer: _Dots(
        count: imageUrls.length,
        index: galleryIndex,
        useLightOverlay: useLightOverlay,
        visible: !heroGone,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pageWidth = constraints.maxWidth;
          final count = imageUrls.length;
          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (var i = 0; i < count; i++)
                  Positioned(
                    left: i * pageWidth - galleryOffset,
                    top: 0,
                    bottom: 0,
                    width: pageWidth,
                    child: i == 0
                        ? Hero(
                            tag: heroTag,
                            child: LhotseImage.poster(
                              videoUrl: null,
                              imageUrl: imageUrls[i],
                            ),
                          )
                        : LhotseImage.poster(
                            videoUrl: null,
                            imageUrl: imageUrls[i],
                          ),
                  ),
              ],
            ),
          );
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
