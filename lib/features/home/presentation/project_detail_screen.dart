import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/projects_provider.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_gallery_helpers.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_video_player.dart';

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
                  style: AppTypography.bodyRow.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    _heroHeight = MediaQuery.of(context).size.height * 0.55;

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
                  : LhotseBackButton.overImage(
                      useLightOverlay: project.useLightOverlay,
                    ),
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
                      style: AppTypography.titleUppercase.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      project.brand.toUpperCase(),
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: AppColors.accentMuted,
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
                          ? LhotseVideoPlayer(
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
            // 2. IDENTITY
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
                      project.name,
                      style: AppTypography.editorialHero.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (project.tagline.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        project.tagline,
                        style: AppTypography.annotationParagraph.copyWith(
                          color: AppColors.accentMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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
                              style: AppTypography.annotation.copyWith(
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

            // =========================================================
            // 3. DESCRIPTION
            // =========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  project.description.replaceAll('**', ''),
                  style: AppTypography.bodyReading.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.7,
                  ),
                ),
              ),
            ),

            // =========================================================
            // 4. GALERÍA
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
                            style: AppTypography.sectionLabel.copyWith(
                              color: AppColors.accentMuted,
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
            // 5. CTA — DESCARGAR FOLLETO
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
                        style: AppTypography.labelUppercaseMd.copyWith(
                          color: AppColors.textOnDark,
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
