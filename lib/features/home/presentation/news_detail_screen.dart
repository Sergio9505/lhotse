import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/data/news_provider.dart';
import '../../../core/data/playable_video_url_provider.dart';
import '../../../core/domain/news_item_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/media_hero_carousel.dart';
import 'widgets/fullscreen_video_player.dart';

const double _kHeroSlop = 8.0;
const Duration _kHeroTapMax = Duration(milliseconds: 300);
const double _kFullyExpandedTolerance = 4.0;
const Duration _kCarouselSnapDuration = Duration(milliseconds: 280);

class NewsDetailScreen extends ConsumerStatefulWidget {
  const NewsDetailScreen({
    super.key,
    required this.newsId,
    this.initialNews,
  });

  final String newsId;

  /// Pre-loaded snapshot from the caller (e.g. Home feed) so the Hero tag is
  /// in the widget tree on the first frame. See `ProjectDetailScreen` for the
  /// full rationale.
  final NewsItemData? initialNews;

  @override
  ConsumerState<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends ConsumerState<NewsDetailScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late final AnimationController _carouselAnim;

  // Hero collapse state
  bool _heroGone = false;
  bool _showCollapsedTitle = false;
  double _heroHeight = 0;
  double _topPadding = 0;

  // Carousel state
  double _carouselOffset = 0;
  int _carouselIndex = 0;
  double _animFrom = 0;
  double _animTo = 0;

  // Pointer tracking (body-level Listener)
  int? _activePointer;
  double _pointerStartX = 0;
  double _pointerStartY = 0;
  Duration _pointerStartTime = Duration.zero;
  double _dragAnchorX = 0;
  double _dragAnchorOffset = 0;
  Axis? _direction;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _carouselAnim = AnimationController(
      vsync: this,
      duration: _kCarouselSnapDuration,
    )..addListener(_onCarouselAnimTick);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _carouselAnim.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final heroThreshold = _heroHeight - kToolbarHeight - _topPadding;
    final heroGone = offset >= heroThreshold;
    final titleThreshold = _heroHeight + 50.0;
    final showTitle = offset >= titleThreshold;

    if (heroGone != _heroGone || showTitle != _showCollapsedTitle) {
      setState(() {
        _heroGone = heroGone;
        _showCollapsedTitle = showTitle;
      });
    }
  }

  void _onCarouselAnimTick() {
    final t = Curves.easeOutCubic.transform(_carouselAnim.value);
    setState(() {
      _carouselOffset = _animFrom + (_animTo - _animFrom) * t;
    });
  }

  void _animateCarouselTo(double target, int targetIndex) {
    _animFrom = _carouselOffset;
    _animTo = target;
    if (targetIndex != _carouselIndex) {
      setState(() => _carouselIndex = targetIndex);
    }
    _carouselAnim.forward(from: 0);
  }

  Future<void> _openVideoPlayer(
    String videoUrl,
    String? rawVideoUrl,
    String? imageUrl,
  ) async {
    // Per ADR-62: news playback only happens in fullscreen with audio,
    // never inline. No inline player to pause/resume around the push.
    await Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) => Opacity(
              opacity: animation.value,
              child: child,
            ),
            child: FullscreenVideoPlayer(
              videoUrl: videoUrl,
              rawVideoUrl: rawVideoUrl,
              imageUrl: imageUrl,
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // BODY-LEVEL POINTER HANDLERS
  // ===========================================================================
  // All hero gestures live HERE, at the top of the widget tree. Five previous
  // attempts to handle swipe (and v4's tap-to-video) from inside MediaHeroCarousel
  // failed because pointer events did not reach the inner Listener/GestureDetector
  // for reasons opaque to read of the widget tree. At Scaffold.body level nothing
  // intercepts pointer events — see docs/solutions/2026-05-21-pageview-inside-sliverappbar-swipe.md.

  void _onPointerDown(PointerDownEvent e) {
    // Gate: only handle touches inside the hero area.
    if (e.position.dy >= _heroHeight) return;
    _activePointer = e.pointer;
    _pointerStartX = e.position.dx;
    _pointerStartY = e.position.dy;
    _pointerStartTime = e.timeStamp;
    _dragAnchorX = e.position.dx;
    _dragAnchorOffset = _carouselOffset;
    _direction = null;
    if (_carouselAnim.isAnimating) _carouselAnim.stop();
  }

  void _onPointerMove(
    PointerMoveEvent e,
    double pageWidth,
    int count,
    bool hasGallery,
  ) {
    if (e.pointer != _activePointer) return;

    // Direction lock after `_kHeroSlop` movement.
    if (_direction == null) {
      final dx = (e.position.dx - _pointerStartX).abs();
      final dy = (e.position.dy - _pointerStartY).abs();
      if (dx < _kHeroSlop && dy < _kHeroSlop) return;
      _direction = dx > dy ? Axis.horizontal : Axis.vertical;
      if (_direction == Axis.horizontal) {
        _dragAnchorX = e.position.dx;
        _dragAnchorOffset = _carouselOffset;
      }
    }

    // Vertical drags fall through to CustomScrollView via translucent Listener.
    if (_direction != Axis.horizontal) return;
    // Horizontal swipe only allowed: gallery mode AND fully expanded.
    if (!hasGallery) return;
    final scrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    if (scrollOffset > _kFullyExpandedTolerance) return;

    final delta = e.position.dx - _dragAnchorX;
    final next =
        (_dragAnchorOffset - delta).clamp(0.0, (count - 1) * pageWidth);
    if (next == _carouselOffset) return;
    setState(() => _carouselOffset = next);
  }

  void _onPointerUp(
    PointerUpEvent e,
    double pageWidth,
    int count,
    bool hasVideo,
    bool hasGallery,
    String? signedVideoUrl,
    String? videoUrlRaw,
    String? imageUrl,
  ) {
    if (e.pointer != _activePointer) return;
    _activePointer = null;

    if (_direction == Axis.horizontal && hasGallery) {
      // Snap to nearest page.
      final page = pageWidth > 0 ? _carouselOffset / pageWidth : 0.0;
      final target = page.round().clamp(0, count - 1);
      _animateCarouselTo(target.toDouble() * pageWidth, target);
    } else if (_direction == null) {
      // No significant movement — interpret as tap.
      final duration = e.timeStamp - _pointerStartTime;
      final isTap = duration < _kHeroTapMax;
      // Exclude the toolbar region so back-button taps don't double-trigger.
      final belowToolbar = e.position.dy > _topPadding + kToolbarHeight;
      final fullyExpanded = (_scrollController.hasClients
              ? _scrollController.offset
              : 0.0) <=
          _kFullyExpandedTolerance;
      if (isTap &&
          belowToolbar &&
          fullyExpanded &&
          hasVideo &&
          signedVideoUrl != null) {
        _openVideoPlayer(signedVideoUrl, videoUrlRaw, imageUrl);
      }
    }
    _direction = null;
  }

  void _onPointerCancel(PointerCancelEvent e, double pageWidth, int count) {
    if (e.pointer != _activePointer) return;
    _activePointer = null;
    if (_direction == Axis.horizontal) {
      final page = pageWidth > 0 ? _carouselOffset / pageWidth : 0.0;
      final target = page.round().clamp(0, count - 1);
      _animateCarouselTo(target.toDouble() * pageWidth, target);
    }
    _direction = null;
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsByIdProvider(widget.newsId));
    // Prefer the caller-supplied snapshot on the first frame so the Hero
    // tag exists when Flutter starts the flight.
    final news = newsAsync.valueOrNull ?? widget.initialNews;
    final signedVideoUrl = news?.videoUrl?.isNotEmpty == true
        ? ref.watch(playableVideoUrlProvider(news!.videoUrl!)).valueOrNull
        : null;

    if (news == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: newsAsync.isLoading
              ? const CircularProgressIndicator(strokeWidth: 1.5)
              : Text(
                  'Noticia no encontrada',
                  style: AppTypography.bodyRow.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
      );
    }

    final mq = MediaQuery.of(context);
    final bottomPadding = mq.padding.bottom;
    _topPadding = mq.padding.top;
    _heroHeight = mq.size.height * 0.55;
    final pageWidth = mq.size.width;
    final imageCount = news.imageUrls.length;
    final hasVideo = news.videoUrl != null && news.videoUrl!.isNotEmpty;
    final hasGallery = !hasVideo && imageCount > 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _heroGone
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        // Body-level Listener owns ALL hero gestures (swipe + tap-to-video).
        // Translucent so vertical drags propagate to the CustomScrollView
        // and other GestureDetectors in the body content keep working.
        body: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onPointerDown,
          onPointerMove: (e) =>
              _onPointerMove(e, pageWidth, imageCount, hasGallery),
          onPointerUp: (e) => _onPointerUp(
            e,
            pageWidth,
            imageCount,
            hasVideo,
            hasGallery,
            signedVideoUrl,
            news.videoUrl,
            news.imageUrl,
          ),
          onPointerCancel: (e) =>
              _onPointerCancel(e, pageWidth, imageCount),
          child: Stack(
            children: [
              // =====================================================
              // LAYER 0 — scrollable content (spacer + body)
              // =====================================================
              Positioned.fill(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(height: _heroHeight),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.xl,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              news.title,
                              style: AppTypography.editorialHero.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildByline(news),
                          ],
                        ),
                      ),
                    ),
                    if (news.body?.isNotEmpty == true)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.xxl,
                            AppSpacing.lg,
                            0,
                          ),
                          child: Text(
                            news.body!,
                            style: AppTypography.bodyReading.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.7,
                            ),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                          height: AppSpacing.xxl + bottomPadding),
                    ),
                  ],
                ),
              ),

              // =====================================================
              // LAYER 1 — carousel overlay (translates with scroll)
              // =====================================================
              AnimatedBuilder(
                animation: _scrollController,
                builder: (context, _) {
                  final offset = _scrollController.hasClients
                      ? _scrollController.offset
                      : 0.0;
                  final translateY = -offset.clamp(0.0, _heroHeight);
                  return Positioned(
                    left: 0,
                    right: 0,
                    top: translateY,
                    height: _heroHeight,
                    child: MediaHeroCarousel(
                      heroTag: 'news-hero-${news.id}',
                      imageUrls: news.imageUrls,
                      videoUrl: news.videoUrl,
                      coverImageUrl: news.imageUrl,
                      useLightOverlay: news.useLightOverlay,
                      signedVideoUrl: signedVideoUrl,
                      heroGone: _heroGone,
                      galleryOffset: _carouselOffset,
                      galleryIndex: _carouselIndex,
                    ),
                  );
                },
              ),

              // =====================================================
              // LAYER 2 — pinned toolbar
              // =====================================================
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  color: _heroGone
                      ? AppColors.background
                      : Colors.transparent,
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: 44,
                            child: _heroGone
                                ? const LhotseBackButton.onSurface()
                                : LhotseBackButton.overImage(
                                    useLightOverlay: news.useLightOverlay,
                                  ),
                          ),
                          Center(
                            child: AnimatedOpacity(
                              opacity: _showCollapsedTitle ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    news.title.toUpperCase(),
                                    style: AppTypography.titleUppercase
                                        .copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (news.brand ?? '').toUpperCase(),
                                    style: AppTypography.labelUppercaseSm
                                        .copyWith(
                                      color: AppColors.accentMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

  /// 2-token byline `{BRAND} · {DATE}` mirroring `LhotseNewsCard` for visual
  /// continuity across the Hero transition.
  Widget _buildByline(NewsItemData news) {
    final brand = news.brand;
    final hasBrand = brand != null && brand.isNotEmpty;
    final dateStr = DateFormat('d MMM yyyy', 'es_ES').format(news.date);
    final children = <InlineSpan>[];
    if (hasBrand) {
      children.add(TextSpan(
        text: brand.toUpperCase(),
        style: AppTypography.wordmarkByline.copyWith(
          color: AppColors.textPrimary,
        ),
      ));
      children.add(TextSpan(
        text: '  ·  ',
        style: AppTypography.annotation.copyWith(
          color: AppColors.textPrimary.withValues(alpha: 0.4),
        ),
      ));
    }
    children.add(TextSpan(
      text: dateStr,
      style: AppTypography.annotation.copyWith(color: AppColors.accentMuted),
    ));
    return RichText(text: TextSpan(children: children));
  }
}
