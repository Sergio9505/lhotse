import 'package:flutter/material.dart';

import '../../../../core/domain/news_item_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_image.dart';
import '../../../../core/widgets/lhotse_play_button.dart';

/// Hero media for `NewsDetailScreen`.
///
/// Three rendering modes, derived from the news payload:
///
///   1. `videoUrl` set            → single-frame poster + `LhotsePlayButton`
///      (no carousel, no dots). Tap is handled by the screen via the
///      `onOpenVideo` callback. Per ADR-62, video always wins over a
///      multi-image gallery.
///   2. `imageUrls.length > 1`    → `PageView` carousel with dots; slot 0 is
///      wrapped in the `Hero(tag: 'news-hero-<id>')` so the shared-element
///      transition from feed/card still lands smoothly. Subsequent slots are
///      plain images.
///   3. otherwise                 → single image (or video poster fallback)
///      identical to the pre-carousel behaviour.
///
/// The top + bottom gradients (lifted verbatim from the previous Stack in
/// `news_detail_screen.dart`) sit on top of every slot so the back button
/// and the collapsed title keep readable.
class NewsHeroCarousel extends StatefulWidget {
  const NewsHeroCarousel({
    super.key,
    required this.news,
    required this.signedVideoUrl,
    required this.onOpenVideo,
    required this.heroGone,
  });

  final NewsItemData news;
  final String? signedVideoUrl;
  final VoidCallback onOpenVideo;

  /// Mirrors `_NewsDetailScreenState._heroGone` — used to fade the dots
  /// indicator out as the user scrolls past the hero.
  final bool heroGone;

  @override
  State<NewsHeroCarousel> createState() => _NewsHeroCarouselState();
}

class _NewsHeroCarouselState extends State<NewsHeroCarousel> {
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
    final news = widget.news;
    final hasVideo = news.videoUrl != null && news.videoUrl!.isNotEmpty;
    final hasGallery = !hasVideo && news.imageUrls.length > 1;

    if (hasVideo) {
      // Video wins: keep the historical single-frame hero. Tap-to-fullscreen
      // is wired by the screen via `GestureDetector` so we do not duplicate
      // it here.
      return _Frame(
        useLightOverlay: news.useLightOverlay,
        showPlay: widget.signedVideoUrl != null,
        child: Hero(
          tag: 'news-hero-${news.id}',
          child: LhotseImage.poster(
            videoUrl: news.videoUrl,
            imageUrl: news.imageUrl,
          ),
        ),
      );
    }

    if (!hasGallery) {
      // Single image (or none): same composition as today but without the
      // play button.
      return _Frame(
        useLightOverlay: news.useLightOverlay,
        showPlay: false,
        child: Hero(
          tag: 'news-hero-${news.id}',
          child: LhotseImage.poster(
            videoUrl: null,
            imageUrl: news.imageUrl,
          ),
        ),
      );
    }

    // Multi-image carousel.
    return _Frame(
      useLightOverlay: news.useLightOverlay,
      showPlay: false,
      footer: _Dots(
        count: news.imageUrls.length,
        index: _index,
        useLightOverlay: news.useLightOverlay,
        visible: !widget.heroGone,
      ),
      child: PageView.builder(
        controller: _controller,
        onPageChanged: _onPageChanged,
        itemCount: news.imageUrls.length,
        itemBuilder: (context, i) {
          final image = LhotseImage.poster(
            videoUrl: null,
            imageUrl: news.imageUrls[i],
          );
          if (i == 0) {
            // Only slot 0 owns the Hero tag — the flight from feed/card
            // lands on the first image regardless of which slot was last
            // viewed before re-entering the screen.
            return Hero(tag: 'news-hero-${news.id}', child: image);
          }
          return image;
        },
      ),
    );
  }
}

/// Shared chrome: image fills, top + bottom gradients, optional play button,
/// optional footer (dots).
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

/// Minimal dots indicator. Active dot is fully opaque, inactive ones use a
/// low alpha. Tinted against `useLightOverlay` so it stays visible on dark
/// and on bright media alike.
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
