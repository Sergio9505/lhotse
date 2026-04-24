import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/projects_provider.dart';
import '../../../core/domain/asset_info.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_gallery_helpers.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_key_value_list.dart';
import '../../../core/widgets/lhotse_section_label.dart';
import 'widgets/feed_video_player.dart';

const _kMaxVisibleGallery = 5;

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

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  final _scrollController = ScrollController();
  bool _heroGone = false;
  bool _showCollapsedTitle = false;
  double _heroHeight = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final heroThreshold = _heroHeight - kToolbarHeight;
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

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectByIdProvider(widget.projectId));
    // Fall back to the caller-supplied snapshot so the Hero tag is always
    // present on the first frame. Once the provider resolves, Riverpod swaps
    // in the authoritative copy without flicker (same URL → same ImageCache
    // entry).
    final project = projectAsync.valueOrNull ?? widget.initialProject;

    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: projectAsync.isLoading
              ? const CircularProgressIndicator(strokeWidth: 1.5)
              : Text(
                  'Proyecto no encontrado',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    _heroHeight = MediaQuery.of(context).size.height * 0.55;

    // Build characteristics entries from typed asset fields
    String _m2(double v) => '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} m²';
    final characteristicEntries = <AssetInfoEntry>[
      if (project.surfaceM2 != null)
        AssetInfoEntry(label: 'Superficie', value: _m2(project.surfaceM2!)),
      if (project.plotM2 != null)
        AssetInfoEntry(label: 'Parcela', value: _m2(project.plotM2!)),
      if (project.bedrooms != null)
        AssetInfoEntry(label: 'Habitaciones', value: '${project.bedrooms}'),
      if (project.bathrooms != null)
        AssetInfoEntry(label: 'Baños', value: '${project.bathrooms}'),
      if (project.floor != null)
        AssetInfoEntry(label: 'Planta', value: project.floor!),
      if (project.orientation != null)
        AssetInfoEntry(label: 'Orientación', value: project.orientation!),
      if (project.views != null)
        AssetInfoEntry(label: 'Vistas', value: project.views!),
      if (project.terraceM2 != null)
        AssetInfoEntry(label: 'Terraza', value: _m2(project.terraceM2!)),
      if (project.hasPool == true)
        const AssetInfoEntry(label: 'Piscina', value: 'Sí'),
      if (project.parkingSpots != null)
        AssetInfoEntry(label: 'Garaje', value: project.parkingSpots == 1 ? '1 plaza' : '${project.parkingSpots} plazas'),
      if (project.storageRoom == true)
        const AssetInfoEntry(label: 'Trastero', value: 'Incluido'),
      if (project.yearBuilt != null)
        AssetInfoEntry(label: 'Año construcción', value: '${project.yearBuilt}'),
      if (project.yearRenovated != null)
        AssetInfoEntry(label: 'Año renovación', value: '${project.yearRenovated}'),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _heroGone
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // =========================================================
            // 1. HERO
            // =========================================================
            SliverAppBar(
              pinned: true,
              expandedHeight: _heroHeight,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: _heroGone
                  ? const LhotseBackButton.onSurface()
                  : const LhotseBackButton.onImage(),
              actions: const [SizedBox(width: 44)],
              centerTitle: true,
              title: AnimatedOpacity(
                opacity: _showCollapsedTitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project.name.toUpperCase(),
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      project.brand.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'project-hero-${project.id}',
                      child: (project.videoUrl != null &&
                              project.videoUrl!.isNotEmpty)
                          ? FeedVideoPlayer(
                              videoUrl: project.videoUrl!,
                              posterUrl: project.imageUrl,
                              isActive: true,
                            )
                          : LhotseImage(project.imageUrl),
                    ),
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
                          colors: [
                            Colors.transparent,
                            Color(0x8C1F1916),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =========================================================
            // 2. IDENTITY — lookbook producto (kicker · title · tagline · byline)
            // =========================================================
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
                      '${project.brand.toUpperCase()}  ·  ${project.phase.label}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentMuted,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      project.name,
                      style: AppTypography.displayHero.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (project.tagline.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        project.tagline,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.accentMuted,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      project.location.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 1.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // =========================================================
            // 3. DESCRIPTION
            // =========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  project.description.replaceAll('**', ''),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
            ),

            // =========================================================
            // 4. CARACTERÍSTICAS
            // =========================================================
            if (characteristicEntries.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    const LhotseSectionLabel(label: 'CARACTERÍSTICAS'),
                    const SizedBox(height: AppSpacing.sm),
                    LhotseKeyValueList(entries: characteristicEntries),
                  ],
                ),
              ),

            // =========================================================
            // 5. PLANO
            // =========================================================
            if (project.floorPlanUrl != null)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    const LhotseSectionLabel(label: 'PLANO'),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      child: GestureDetector(
                        onTap: () =>
                            _showFloorPlan(context, project.floorPlanUrl!),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg),
                          color: AppColors.background,
                          child: Stack(
                            children: [
                              Center(
                                child: LhotseImage(
                                  project.floorPlanUrl!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
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
                ),
              ),

            // =========================================================
            // 6. GALERÍA
            // =========================================================
            if (project.galleryImages.isNotEmpty)
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
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.accentMuted,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.8,
                            ),
                          ),
                          if (project.galleryImages.length >
                              _kMaxVisibleGallery) ...[
                            const SizedBox(width: AppSpacing.sm),
                            GestureDetector(
                              onTap: () => showAllGallery(context, 'GALERÍA',
                                  project.galleryImages),
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
                        itemCount: project.galleryImages.length >
                                _kMaxVisibleGallery
                            ? _kMaxVisibleGallery
                            : project.galleryImages.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, i) => GestureDetector(
                          onTap: () => showFullImage(
                              context, project.galleryImages[i]),
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
                            child: LhotseImage(project.galleryImages[i]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // =========================================================
            // 7. CTA — DESCARGAR FOLLETO
            // =========================================================
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: AppColors.primary,
                    child: Center(
                      child: Text(
                        'DESCARGAR FOLLETO',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textOnDark,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Floor plan fullscreen
// ===========================================================================

void _showFloorPlan(BuildContext context, String url) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        final topPadding = MediaQuery.of(context).padding.top;
        final bottomPadding = MediaQuery.of(context).padding.bottom;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Opacity(
            opacity: animation.value,
            child: child,
          ),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            extendBody: true,
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
                            AppSpacing.lg,
                            topPadding + kToolbarHeight,
                            AppSpacing.lg,
                            bottomPadding + AppSpacing.lg,
                          ),
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                          ),
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
                          color: AppColors.textPrimary
                              .withValues(alpha: 0.08),
                          child: PhosphorIcon(
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
          ),
        );
      },
    ),
  );
}
