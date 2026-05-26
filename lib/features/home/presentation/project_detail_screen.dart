import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/news_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../../../core/domain/content_block.dart';
import '../../../core/domain/news_item_data.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/domain/project_phase.dart' as timeline;
import '../../../core/domain/user_role.dart';
import '../../../core/utils/precache_helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/data/supabase_provider.dart';
import 'widgets/project_content_renderer.dart';
import 'widgets/vip_lock_sheet.dart';
import '../../../core/widgets/floor_plan_viewer.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_bottom_sheet.dart';
import '../../../core/widgets/lhotse_key_value_list.dart';
import '../../../core/widgets/lhotse_news_card.dart';
import '../../../core/widgets/lhotse_project_timeline.dart';
import '../../../core/widgets/lhotse_section_label.dart';
import '../../../core/widgets/lhotse_tab_bar_delegate.dart';
import '../../../core/widgets/media_hero_carousel.dart';
import '../../../core/data/playable_video_url_provider.dart';
import '../../../core/widgets/lhotse_video_player.dart';
import '../../investments/data/investments_provider.dart';
import 'widgets/fullscreen_video_player.dart';
import 'widgets/virtual_tour_section.dart';

const double _kHeroSlop = 8.0;
const Duration _kHeroTapMax = Duration(milliseconds: 300);
const double _kFullyExpandedTolerance = 4.0;
const Duration _kCarouselSnapDuration = Duration(milliseconds: 280);

/// Tabs of the commercial project detail. Mirrors the L3 grammar
/// (Proyecto / Avance / Activo). Finalised projects skip Avance.
enum _ProjectTab {
  proyecto,
  avance,
  activo;

  String get label => switch (this) {
        _ProjectTab.proyecto => 'Proyecto',
        _ProjectTab.avance => 'Avance',
        _ProjectTab.activo => 'Activo',
      };
}

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
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _videoKey = GlobalKey<LhotseVideoPlayerState>();
  late final AnimationController _carouselAnim;

  // Tabs (length recomputed when project.phase resolves; see _ensureTabController).
  TabController? _tabController;
  int _currentTab = 0;

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
    _tabController?.dispose();
    super.dispose();
  }

  List<_ProjectTab> _visibleTabs(ProjectData project) => [
        _ProjectTab.proyecto,
        if (project.phase != ProjectPhase.exited) _ProjectTab.avance,
        _ProjectTab.activo,
      ];

  void _ensureTabController(int length) {
    if (_tabController != null && _tabController!.length == length) return;
    _tabController?.dispose();
    final initial = _currentTab.clamp(0, length - 1);
    _tabController = TabController(length: length, vsync: this, initialIndex: initial)
      ..addListener(() {
        if (!mounted) return;
        if (_tabController!.indexIsChanging) return;
        if (_tabController!.index == _currentTab) return;
        setState(() => _currentTab = _tabController!.index);
      });
    _currentTab = initial;
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final heroSpacer = _heroHeight - _topPadding - kToolbarHeight;
    final heroGone = offset >= heroSpacer;
    final titleThreshold = heroSpacer + 50.0;
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
    // When the snap completes, fold the offset back into [0, totalWidth) and
    // the index into [0, count) to keep them bounded across long loop chains.
    // The renderer's modulo math is identical before/after — visually nothing
    // changes; this only protects against floating-point drift over time.
    if (_carouselAnim.isCompleted) {
      _normalizeCarousel();
    }
  }

  void _normalizeCarousel() {
    final pageWidth = _lastPageWidth;
    final count = _lastImageCount;
    if (pageWidth <= 0 || count <= 1) return;
    final totalWidth = count * pageWidth;
    final wrapped = _carouselOffset.remainder(totalWidth);
    final normalized = wrapped < 0 ? wrapped + totalWidth : wrapped;
    final newIndex = ((_carouselIndex % count) + count) % count;
    if (normalized == _carouselOffset && newIndex == _carouselIndex) return;
    setState(() {
      _carouselOffset = normalized;
      _carouselIndex = newIndex;
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

  // Captured at the start of each build of the hero gallery — used by the
  // settle normalization once the snap animation ends.
  double _lastPageWidth = 0;
  int _lastImageCount = 0;

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
    // No clamp — looping allows the target to fall outside [0, count-1].
    // The renderer wraps via modulo; we normalize at settle end.
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

  /// Bottom sheet with all news linked to this project. Mirrors the
  /// `showAllGallery` pattern but with `LhotseNewsCard` (full 3:2
  /// editorial card, not compact) stacked vertically. Each card keeps
  /// its `heroTag` so the shared-element flight to news_detail still
  /// lands smoothly from the sheet.
  void _showAllRelatedNews(
    BuildContext context,
    List<NewsItemData> news,
  ) {
    showLhotseBottomSheet(
      context: context,
      title: 'NOTICIAS RELEVANTES',
      itemCount: news.length,
      listPadding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (sheetContext, i) {
        final n = news[i];
        return LhotseNewsCard(
          title: n.title,
          imageUrl: n.imageUrl,
          videoUrl: n.videoUrl,
          heroTag: 'news-hero-${n.id}',
          brand: n.brand,
          date: DateFormat('d MMM yyyy', 'es_ES').format(n.date),
          type: n.type.label,
          onTap: () {
            Navigator.of(sheetContext).pop();
            context.push('/news/${n.id}', extra: n);
          },
        );
      },
    );
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
    // No clamp — looping is unbounded in both directions.
    final next = _dragAnchorOffset - delta;
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

  List<String?> _collectProjectUrls(ProjectData p) => [
        p.imageUrl,
        ...p.imageUrls,
        p.floorPlanUrl,
        p.virtualTourThumbnailUrl,
        p.progressTourThumbnailUrl,
        ...p.content.expand<String?>(_contentBlockUrls),
      ];

  Iterable<String?> _contentBlockUrls(ContentBlock b) => switch (b) {
        ImageBlock(:final url) => [url],
        GalleryBlock(:final items) => items.map((i) => i.url),
        _ => const <String?>[],
      };

  @override
  Widget build(BuildContext context) {
    // Warm the ImageCache as soon as the project's data lands. Fire and
    // forget — by the time the user reaches each carousel the bytes are
    // already decoded, so swipe / tap-to-fullscreen never blocks on a
    // network roundtrip.
    ref.listen(projectByIdProvider(widget.projectId), (_, next) {
      next.whenData((project) {
        if (project == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) precacheImageUrls(context, _collectProjectUrls(project));
        });
      });
    });
    ref.listen(newsProvider, (_, next) {
      next.whenData((news) {
        final related = news.where((n) => n.projectId == widget.projectId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) precacheImageUrls(context, related.map((n) => n.imageUrl));
        });
      });
    });

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
    final bottomPadding = mq.padding.bottom;
    _topPadding = mq.padding.top;
    _heroHeight = mq.size.height * 0.55;
    final pageWidth = mq.size.width;
    final imageCount = project.imageUrls.length;
    // Cache for the post-settle normalizer (the animation tick has no access
    // to layout — these are the latest known dims when the gesture settles).
    _lastPageWidth = pageWidth;
    _lastImageCount = imageCount;

    final visibleTabs = _visibleTabs(project);
    _ensureTabController(visibleTabs.length);

    // News linked to this project, excluding work-in-progress updates
    // (subtype='progress' lives in the L3 Avance tab of coinversions —
    // here in the commercial detail we surface only editorial/press
    // news, consistent with the global archive rule).
    final allNews =
        ref.watch(newsProvider).valueOrNull ?? const <NewsItemData>[];
    final relatedNews = allNews
        .where((n) =>
            n.projectId == project.id &&
            n.subtype != NewsSubtype.progress)
        .toList();

    final phases = ref
            .watch(projectPhasesProvider(widget.projectId))
            .valueOrNull ??
        const <timeline.ProjectPhase>[];
    final currentPhaseIndex = phases.isEmpty
        ? 0
        : phases.where((p) => p.isCompleted).length.clamp(0, phases.length - 1);

    final hasVideo =
        project.videoUrl != null && project.videoUrl!.isNotEmpty;
    final hasGallery = !hasVideo && imageCount > 1;
    final visibleTopInset = _topPadding + kToolbarHeight;

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
              //
              // Shifted down by `visibleTopInset` (status bar + toolbar)
              // so the pinned tab sliver lands flush under the floating
              // toolbar. The hero overlay (Layer 1) extends above into
              // the toolbar area to preserve the edge-to-edge image.
              // =====================================================
              Positioned(
                top: visibleTopInset,
                left: 0,
                right: 0,
                bottom: 0,
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: _heroHeight - visibleTopInset,
                        ),
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
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: LhotseTabBarDelegate(
                          controller: _tabController!,
                          tabs: visibleTabs
                              .map((t) => Tab(text: t.label))
                              .toList(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(visibleTabs[_currentTab]),
                            child: _buildTabContent(
                              context,
                              visibleTabs[_currentTab],
                              project,
                              relatedNews,
                              phases,
                              currentPhaseIndex,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: bottomPadding + AppSpacing.xl,
                        ),
                      ),
                    ],
                  ),
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
                  final maxTranslate = _heroHeight - visibleTopInset;
                  final translateY = -offset.clamp(0.0, maxTranslate);
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

  // ===========================================================================
  // TAB CONTENT BUILDERS
  // ===========================================================================

  Widget _buildTabContent(
    BuildContext context,
    _ProjectTab tab,
    ProjectData project,
    List<NewsItemData> relatedNews,
    List<timeline.ProjectPhase> phases,
    int currentPhaseIndex,
  ) {
    return switch (tab) {
      _ProjectTab.proyecto => _buildProyectoTab(context, project, relatedNews),
      _ProjectTab.avance =>
        _buildAvanceTab(context, project, phases, currentPhaseIndex),
      _ProjectTab.activo => _buildActivoTab(context, project),
    };
  }

  Widget _buildProyectoTab(
    BuildContext context,
    ProjectData project,
    List<NewsItemData> relatedNews,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProjectContentRenderer(blocks: project.content),
        if (relatedNews.isNotEmpty) _buildNewsCarousel(context, relatedNews),
      ],
    );
  }

  Widget _buildAvanceTab(
    BuildContext context,
    ProjectData project,
    List<timeline.ProjectPhase> phases,
    int currentPhaseIndex,
  ) {
    final hasTimeline = phases.isNotEmpty;
    final hasTour = project.progressTourUrl != null &&
        project.progressTourUrl!.isNotEmpty &&
        project.imageUrl != null;

    if (!hasTimeline && !hasTour) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Text(
          'Sin avances publicados por ahora.',
          style: AppTypography.bodyReading.copyWith(
            color: AppColors.accentMuted,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTimeline) ...[
          const SizedBox(height: AppSpacing.xl),
          const LhotseSectionLabel(label: 'TIEMPOS DEL PROYECTO'),
          const SizedBox(height: AppSpacing.lg),
          LhotseProjectTimeline(
            phases: phases,
            currentIndex: currentPhaseIndex,
          ),
        ],
        if (hasTour) ...[
          const SizedBox(height: AppSpacing.xxl),
          VirtualTourSection(
            imageUrl:
                project.progressTourThumbnailUrl ?? project.imageUrl!,
            tourUrl: project.progressTourUrl!,
            label: 'ESTADO ACTUAL',
          ),
        ],
      ],
    );
  }

  Widget _buildActivoTab(BuildContext context, ProjectData project) {
    final assetInfo = project.assetInfo;
    final hasAssetInfo = assetInfo.isNotEmpty;
    final hasPlan = project.floorPlanUrl != null;
    final hasTour = project.virtualTourUrl != null &&
        project.virtualTourUrl!.isNotEmpty &&
        project.imageUrl != null;

    if (!hasAssetInfo && !hasPlan && !hasTour) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Text(
          'Sin información del activo por ahora.',
          style: AppTypography.bodyReading.copyWith(
            color: AppColors.accentMuted,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasAssetInfo) ...[
          const SizedBox(height: AppSpacing.xl),
          const LhotseSectionLabel(label: 'INFORMACIÓN'),
          const SizedBox(height: AppSpacing.sm),
          LhotseKeyValueList(entries: assetInfo),
        ],
        if (hasPlan) ...[
          const SizedBox(height: AppSpacing.xxl),
          const LhotseSectionLabel(label: 'PLANO'),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GestureDetector(
              onTap: () => showFloorPlan(context, project.floorPlanUrl!),
              child: CachedNetworkImage(
                imageUrl: project.floorPlanUrl!,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                placeholder: (_, _) => Container(
                  height: 200,
                  color: AppColors.surface,
                ),
                errorWidget: (_, _, _) => Container(
                  height: 200,
                  color: AppColors.surface,
                ),
                imageBuilder: (context, imageProvider) => Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Image(
                      image: imageProvider,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: PhosphorIcon(
                        PhosphorIconsThin.arrowsOut,
                        color: AppColors.accentMuted,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (hasTour) ...[
          const SizedBox(height: AppSpacing.xxl),
          VirtualTourSection(
            imageUrl:
                project.virtualTourThumbnailUrl ?? project.imageUrl!,
            tourUrl: project.virtualTourUrl!,
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // NOTICIAS RELEVANTES — carrusel compact horizontal + arrow → bottomsheet
  // con todas. Filtra subtype=progress (avance de obra vive en el L3 Avance
  // del coinversion).
  // ===========================================================================
  Widget _buildNewsCarousel(
    BuildContext context,
    List<NewsItemData> relatedNews,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Text(
                'NOTICIAS RELEVANTES',
                style: AppTypography.sectionLabel.copyWith(
                  color: AppColors.accentMuted,
                ),
              ),
              if (relatedNews.length >= 2) ...[
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () => _showAllRelatedNews(context, relatedNews),
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
          height: 160,
          child: ListView.separated(
            key: const PageStorageKey('project-news'),
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: relatedNews.length > 1
                ? relatedNews.length * 1000
                : relatedNews.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              final n = relatedNews[i % relatedNews.length];
              return LhotseNewsCard.compact(
                title: n.title,
                imageUrl: n.imageUrl,
                videoUrl: n.videoUrl,
                brand: n.brand,
                subtitle:
                    DateFormat('d MMM', 'es_ES').format(n.date),
                onTap: () => context.push(
                  '/news/${n.id}',
                  extra: n,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
