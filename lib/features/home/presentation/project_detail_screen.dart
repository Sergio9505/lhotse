import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/projects_provider.dart';
import '../../../core/domain/asset_info.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_gallery_helpers.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_key_value_list.dart';
import '../../../core/widgets/lhotse_section_label.dart';

const _kHeroHeight = 200.0;
const _kMaxVisibleGallery = 5;

class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  final _scrollController = ScrollController();
  bool _heroGone = false;
  bool _showCollapsedTitle = false;

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
    final heroThreshold = _kHeroHeight - kToolbarHeight;
    final heroGone = offset >= heroThreshold;
    final titleThreshold = _kHeroHeight + 50.0;
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
    final project = projectAsync.valueOrNull;

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

    // Build characteristics entries from typed asset fields
    String _m2(double v) => '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} m²';
    final characteristicEntries = <AssetInfoEntry>[
      if (project.surfaceM2 != null)
        AssetInfoEntry(label: 'Superficie', value: _m2(project.surfaceM2!)),
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
      if (project.plotM2 != null)
        AssetInfoEntry(label: 'Parcela', value: _m2(project.plotM2!)),
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
              expandedHeight: _kHeroHeight,
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
                    LhotseImage(project.imageUrl),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [Color(0x66000000), Colors.transparent],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =========================================================
            // 2. IDENTITY
            // =========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name.toUpperCase(),
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          project.brand.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 1.8,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '•',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textPrimary
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            project.location.toUpperCase(),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.accentMuted,
                              letterSpacing: 1.35,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                                child: Image.asset(
                                  'assets/images/mock_floor_plan.png',
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
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  bottomPadding + AppSpacing.xl,
                ),
                child: GestureDetector(
                  onTap: () {
                    // TODO: download brochure
                  },
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
                          child: Image.asset(
                            'assets/images/mock_floor_plan.png',
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
