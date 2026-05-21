import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/projects_provider.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/domain/user_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/data/supabase_provider.dart';
import 'widgets/vip_lock_sheet.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/domain/media_item.dart';
import '../../../core/widgets/lhotse_gallery_helpers.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/media_hero_carousel.dart';
import '../../../core/data/playable_video_url_provider.dart';
import '../../../core/widgets/lhotse_video_player.dart';
import 'widgets/fullscreen_video_player.dart';
import 'widgets/virtual_tour_section.dart';

const _kMaxVisibleGallery = 5;
const double _kHeroSlop = 8.0;
const Duration _kHeroTapMax = Duration(milliseconds: 300);
const double _kFullyExpandedTolerance = 4.0;
const Duration _kCarouselSnapDuration = Duration(milliseconds: 280);

class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.initialProject,
  });

  final String projectId;

  /// When the caller already has the project data (e.g. navigated from the
  /// Home feed or a list), pass it here so the detail can build the Hero
  /// widget on the very first frame. Without this, the screen would show a
  /// loading spinner while `projectByIdProvider` fetches, and Flutter would
  /// have nothing to match the Hero tag against — no flight animation. The
  /// provider still refreshes in the background to pick up any server-side
  /// changes the feed snapshot might have missed.
  final ProjectData? initialProject;

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _videoKey = GlobalKey<LhotseVideoPlayerState>();
  late final AnimationController _carouselAnim;

  // Hero collapse state
  bool _heroGone = false;
  bool _showCollapsedTitle = false;
  double _heroHeight = 0;
  double _topPadding = 0;
  bool _gateDone = false;

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
  // Tracks recent pointer positions for velocity-aware snap on release.
  // Fresh instance per drag — created in onPointerDown with the correct
  // PointerDeviceKind, discarded in onPointerUp/Cancel.
  VelocityTracker? _velocityTracker;

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

  /// Snap to nearest page based on velocity + position. Mirrors the feel of
  /// `PageScrollPhysics.createBallisticSimulation`. A fast flick (>300 px/s)
  /// snaps in the fling direction regardless of position; a slow release
  /// snaps to the nearest page (50% threshold via `round()`).
  void _snapWithVelocity(double pageWidth, int count) {
    final velocity =
        _velocityTracker?.getVelocity().pixelsPerSecond.dx ?? 0.0;
    final currentPageF = pageWidth > 0 ? _carouselOffset / pageWidth : 0.0;
    const flingThreshold = 300.0;
    int target;
    if (velocity.abs() > flingThreshold) {
      target = velocity > 0 ? currentPageF.floor() : currentPageF.ceil();
    } else {
      target = currentPageF.round();
    }
    target = target.clamp(0, count - 1);
    _animateCarouselTo(target.toDouble() * pageWidth, target);
  }

  Future<void> _openProjectVideoPlayer(
    String videoUrl,
    String? rawVideoUrl,
    String? imageUrl,
  ) async {
    final start = _videoKey.currentState?.position ?? Duration.zero;
    _videoKey.currentState?.pauseExternal();
    final result = await Navigator.of(context, rootNavigator: true)
        .push<Duration>(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) =>
                Opacity(opacity: animation.value, child: child),
            child: FullscreenVideoPlayer(
              videoUrl: videoUrl,
              rawVideoUrl: rawVideoUrl,
              imageUrl: imageUrl,
              initialPosition: start,
            ),
          );
        },
      ),
    );
    if (!mounted) return;
    await _videoKey.currentState?.resumeFrom(result ?? start);
  }

  // ===========================================================================
  // BODY-LEVEL POINTER HANDLERS
  // ===========================================================================
  // See `news_detail_screen.dart` for the architectural rationale.

  void _onPointerDown(PointerDownEvent e) {
    if (e.position.dy >= _heroHeight) return;
    _activePointer = e.pointer;
    _pointerStartX = e.position.dx;
    _pointerStartY = e.position.dy;
    _pointerStartTime = e.timeStamp;
    _dragAnchorX = e.position.dx;
    _dragAnchorOffset = _carouselOffset;
    _direction = null;
    _velocityTracker = VelocityTracker.withKind(e.kind);
    _velocityTracker!.addPosition(e.timeStamp, e.position);
    if (_carouselAnim.isAnimating) _carouselAnim.stop();
  }

  void _onPointerMove(
    PointerMoveEvent e,
    double pageWidth,
    int count,
    bool hasGallery,
  ) {
    if (e.pointer != _activePointer) return;
    _velocityTracker?.addPosition(e.timeStamp, e.position);

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

    if (_direction != Axis.horizontal) return;
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
      _snapWithVelocity(pageWidth, count);
    } else if (_direction == null) {
      final duration = e.timeStamp - _pointerStartTime;
      final isTap = duration < _kHeroTapMax;
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
        _openProjectVideoPlayer(signedVideoUrl, videoUrlRaw, imageUrl);
      }
    }
    _direction = null;
    _velocityTracker = null;
  }

  void _onPointerCancel(PointerCancelEvent e, double pageWidth, int count) {
    if (e.pointer != _activePointer) return;
    _activePointer = null;
    if (_direction == Axis.horizontal) {
      _snapWithVelocity(pageWidth, count);
    }
    _direction = null;
    _velocityTracker = null;
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectByIdProvider(widget.projectId));
    final project = projectAsync.valueOrNull ?? widget.initialProject;
    final signedVideoUrl = project?.videoUrl?.isNotEmpty == true
        ? ref.watch(playableVideoUrlProvider(project!.videoUrl!)).valueOrNull
        : null;

    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: projectAsync.isLoading
              ? const CircularProgressIndicator(strokeWidth: 1.5)
              : Text(
                  'Proyecto no encontrado',
                  style: AppTypography.bodyRow.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
      );
    }

    // Defense-in-depth: if a VIP project slips through an unguarded entry point,
    // bounce the user out and show the sheet.
    if (!_gateDone &&
        project.isVip &&
        ref.read(currentUserRoleProvider) != UserRole.investorVip) {
      _gateDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        popOrGoHome(context);
        showVipLockSheet(context);
      });
    }
    _gateDone = true;

    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final bottomPadding = mq.padding.bottom;
    _topPadding = mq.padding.top;
    _heroHeight = mq.size.height * 0.55;
    final pageWidth = mq.size.width;
    final imageCount = project.imageUrls.length;
    final hasVideo =
        project.videoUrl != null && project.videoUrl!.isNotEmpty;
    final hasGallery = !hasVideo && imageCount > 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _heroGone
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
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
            project.videoUrl,
            project.imageUrl,
          ),
          onPointerCancel: (e) =>
              _onPointerCancel(e, pageWidth, imageCount),
          child: Stack(
            children: [
              // =====================================================
              // LAYER 0 — scrollable content
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
                              project.name,
                              style: AppTypography.editorialHero.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            RichText(
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: AppTypography.wordmarkByline,
                                children: [
                                  if (project.brand.isNotEmpty) ...[
                                    TextSpan(
                                      text: project.brand.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (project.city.isNotEmpty)
                                      TextSpan(
                                        text: '  ·  ',
                                        style: TextStyle(
                                          color: AppColors.textPrimary
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                  ],
                                  if (project.city.isNotEmpty)
                                    TextSpan(
                                      text: project.city,
                                      style:
                                          AppTypography.annotation.copyWith(
                                        color: AppColors.accentMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Text(
                          project.description.replaceAll('**', ''),
                          style: AppTypography.bodyReading.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ),
                    if (project.virtualTourUrl != null &&
                        project.imageUrl != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(top: AppSpacing.xxl),
                          child: VirtualTourSection(
                            imageUrl: project.virtualTourThumbnailUrl ??
                                project.imageUrl!,
                            tourUrl: project.virtualTourUrl!,
                          ),
                        ),
                      ),
                    if (project.galleryMedia.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.xxl),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg),
                              child: Row(
                                children: [
                                  Text(
                                    'GALERÍA',
                                    style:
                                        AppTypography.sectionLabel.copyWith(
                                      color: AppColors.accentMuted,
                                    ),
                                  ),
                                  if (project.galleryMedia.length >
                                      _kMaxVisibleGallery) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    GestureDetector(
                                      onTap: () => showAllGallery(context,
                                          'GALERÍA', project.galleryMedia),
                                      child: PhosphorIcon(
                                        PhosphorIconsThin.arrowUpRight,
                                        size: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              height: 200,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg),
                                itemCount: project.galleryMedia.length >
                                        _kMaxVisibleGallery
                                    ? _kMaxVisibleGallery
                                    : project.galleryMedia.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: AppSpacing.sm),
                                itemBuilder: (context, i) {
                                  final item = project.galleryMedia[i];
                                  return GestureDetector(
                                    onTap: () => showMediaGallery(
                                      context,
                                      items: project.galleryMedia,
                                      initialIndex: i,
                                    ),
                                    child: Container(
                                      width: screenWidth * 0.75,
                                      decoration: const BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x1A000000),
                                            blurRadius: 20,
                                            offset: Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: item.type == MediaType.image
                                          ? LhotseImage(item.url)
                                          : VideoThumbnailTile(
                                              url: item.url),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (project.brochureUrl != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.xxl,
                            AppSpacing.lg,
                            bottomPadding + AppSpacing.xl,
                          ),
                          child: GestureDetector(
                            onTap: () => launchUrl(
                              Uri.parse(project.brochureUrl!),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              color: AppColors.primary,
                              child: Center(
                                child: Text(
                                  'DESCARGAR FOLLETO',
                                  style: AppTypography.labelUppercaseMd
                                      .copyWith(
                                          color: AppColors.textOnDark),
                                ),
                              ),
                            ),
                          ),
                        ),
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
                      heroTag: 'project-hero-${project.id}',
                      imageUrls: project.imageUrls,
                      videoUrl: project.videoUrl,
                      coverImageUrl: project.imageUrl,
                      useLightOverlay: project.useLightOverlay,
                      signedVideoUrl: signedVideoUrl,
                      heroGone: _heroGone,
                      galleryOffset: _carouselOffset,
                      galleryIndex: _carouselIndex,
                      videoChild: signedVideoUrl != null
                          ? LhotseVideoPlayer(
                              key: _videoKey,
                              videoUrl: signedVideoUrl,
                              rawVideoUrl: project.videoUrl,
                              imageUrl: project.imageUrl,
                              isActive: true,
                              playDelay:
                                  const Duration(milliseconds: 2500),
                            )
                          : null,
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
                      // Standard toolbar layout: backButton + Expanded title +
                      // 44px right spacer for symmetric centering. `Expanded`
                      // constrains the title width so `maxLines: 1` +
                      // `TextOverflow.ellipsis` actually clip long titles
                      // instead of overlapping the back button.
                      child: Row(
                        children: [
                          _heroGone
                              ? const LhotseBackButton.onSurface()
                              : LhotseBackButton.overImage(
                                  useLightOverlay:
                                      project.useLightOverlay,
                                ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm),
                              child: AnimatedOpacity(
                                opacity:
                                    _showCollapsedTitle ? 1.0 : 0.0,
                                duration:
                                    const Duration(milliseconds: 200),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      project.name.toUpperCase(),
                                      style: AppTypography.titleUppercase
                                          .copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    if (project.brand.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        project.brand.toUpperCase(),
                                        style: AppTypography
                                            .labelUppercaseSm
                                            .copyWith(
                                          color: AppColors.accentMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 44),
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
}
