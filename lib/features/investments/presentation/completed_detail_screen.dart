import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/document_categories_provider.dart';
import '../../../core/data/documents_provider.dart';
import '../../../core/domain/asset_info.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/open_supabase_doc.dart';
import '../../../core/utils/strip_iso_suffix.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_tab_bar_delegate.dart';
import '../../../core/domain/media_item.dart';
import '../../../core/widgets/lhotse_gallery_helpers.dart';
import '../../../core/data/bunny_thumbnail.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/data/playable_video_url_provider.dart';
import '../../../core/widgets/lhotse_video_player.dart';
import '../../home/presentation/widgets/fullscreen_video_player.dart';
import '../../../core/widgets/lhotse_doc_row.dart';
import '../../../core/widgets/lhotse_key_value_list.dart';
import '../../../core/widgets/lhotse_documents_section.dart';
import '../../../core/widgets/lhotse_filter_chip.dart';
import '../../../core/widgets/lhotse_metric_block.dart';
import '../../../core/widgets/lhotse_section_label.dart';
import '../data/investments_provider.dart';
import '../domain/completed_contract_data.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');
const _kHeroHeight = 200.0;
const _kMaxVisibleGallery = 5;

class CompletedDetailScreen extends ConsumerStatefulWidget {
  const CompletedDetailScreen({super.key, required this.data});

  final CompletedContractData data;

  @override
  ConsumerState<CompletedDetailScreen> createState() =>
      _CompletedDetailScreenState();
}

class _CompletedDetailScreenState extends ConsumerState<CompletedDetailScreen>
    with SingleTickerProviderStateMixin {
  final _outerController = ScrollController();
  final _videoKey = GlobalKey<LhotseVideoPlayerState>();
  late final TabController _tabController;
  bool _heroGone = false;
  bool _showCollapsedTitle = false;

  final Set<String> _activeDocFilters = {};

  void _toggleDocFilter(String key) {
    setState(() {
      if (_activeDocFilters.contains(key)) {
        _activeDocFilters.remove(key);
      } else {
        _activeDocFilters.add(key);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _outerController.addListener(_onOuterScroll);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _outerController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onOuterScroll() {
    final offset = _outerController.offset;
    final heroGone = offset >= _kHeroHeight - kToolbarHeight;
    final showTitle = offset >= _kHeroHeight + 50.0;
    if (heroGone != _heroGone || showTitle != _showCollapsedTitle) {
      setState(() {
        _heroGone = heroGone;
        _showCollapsedTitle = showTitle;
      });
    }
  }

  Future<void> _openCompletedVideoPlayer(
    String videoUrl,
    String? posterUrl,
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
              posterUrl: posterUrl ?? '',
              initialPosition: start,
            ),
          );
        },
      ),
    );
    if (!mounted) return;
    await _videoKey.currentState?.resumeFrom(result ?? start);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final returnAmount = d.totalReturn ?? d.amount;

    // Gallery + asset info are lazy-loaded per-asset or per-project depending on the
    // business model (physical/render images live outside the contract view).
    final coinvestmentProjectDetail = d.projectId != null
        ? ref
            .watch(coinvestmentProjectDetailProvider(d.projectId!))
            .valueOrNull
        : null;
    final purchaseAssetDetail = d.assetId != null
        ? ref.watch(purchaseAssetDetailProvider(d.assetId!)).valueOrNull
        : null;
    final rawVideoUrl = purchaseAssetDetail?.videoUrl ??
        coinvestmentProjectDetail?.videoUrl;
    final signedVideoUrl = rawVideoUrl?.isNotEmpty == true
        ? ref.watch(playableVideoUrlProvider(rawVideoUrl!)).valueOrNull
        : null;
    final videoPosterUrl = posterUrlFor(videoUrl: rawVideoUrl, fallback: d.imageUrl ?? '');
    final galleryMedia = d.galleryMedia.isNotEmpty
        ? d.galleryMedia
        : purchaseAssetDetail?.galleryMedia ??
            coinvestmentProjectDetail?.renderMedia ??
            const <MediaItem>[];
    final assetInfoEntries = purchaseAssetDetail?.assetInfo ??
        coinvestmentProjectDetail?.assetInfo ??
        const <AssetInfoEntry>[];
    final assetInfo = assetInfoEntries.isNotEmpty
        ? AssetInfo(entries: assetInfoEntries)
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _heroGone ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ExtendedNestedScrollView(
          controller: _outerController,
          onlyOneScrollInBody: true,
          pinnedHeaderSliverHeightBuilder: () =>
              MediaQuery.paddingOf(context).top + kToolbarHeight + 49,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Hero
            SliverAppBar(
              pinned: true,
              expandedHeight: _kHeroHeight,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              forceElevated: innerBoxIsScrolled,
              leading: _heroGone
                  ? const LhotseBackButton.onSurface()
                  : LhotseBackButton.overImage(
                      useLightOverlay: (purchaseAssetDetail?.useLightOverlay ??
                          coinvestmentProjectDetail?.useLightOverlay) ??
                          true,
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
                      '${_eurFormat.format(returnAmount)}€',
                      style: AppTypography.figureAmount.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.brandName.toUpperCase(),
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),
                  ],
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: GestureDetector(
                  onTap: signedVideoUrl != null
                      ? () => _openCompletedVideoPlayer(
                            signedVideoUrl,
                            videoPosterUrl,
                          )
                      : null,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      signedVideoUrl != null
                          ? LhotseVideoPlayer(
                              key: _videoKey,
                              videoUrl: signedVideoUrl,
                              posterUrl: videoPosterUrl,
                              isActive: true,
                              playDelay: const Duration(milliseconds: 2500),
                            )
                          : LhotseImage(videoPosterUrl),
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
            ),

            // Identity + metrics
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.projectName,
                      style: AppTypography.editorialTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Brand stays UPPERCASE tracked across the app (wordmark
                    // convention). City is also UPPERCASE to share the
                    // register; hierarchy via color (textPrimary vs
                    // accentMuted). Location stripped of trailing ISO
                    // country suffix per `ProjectShowcaseCard.city`.
                    Row(
                      children: [
                        Text(
                          d.brandName.toUpperCase(),
                          style: AppTypography.labelUppercaseSm.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (d.location != null && d.location!.isNotEmpty) ...[
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '·',
                              style: AppTypography.labelUppercaseSm.copyWith(
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              stripIsoSuffix(d.location!).toUpperCase(),
                              style: AppTypography.labelUppercaseSm.copyWith(
                                color: AppColors.accentMuted,
                                letterSpacing: 1.35,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${_eurFormat.format(returnAmount)}€',
                      style: AppTypography.figureHero.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Retorno total',
                      style: AppTypography.bodyReading.copyWith(
                        color: AppColors.accentMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: LhotseMetricBlock(
                            value: '${_eurFormat.format(d.amount)}€',
                            label: 'Invertido',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: LhotseMetricBlock(
                            value:
                                '+${d.actualRoi?.toStringAsFixed(1) ?? '-'}%',
                            label: 'ROI',
                            valueColor: const Color(0xFF2D6A4F),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: LhotseMetricBlock(
                            value:
                                '+${d.actualTir?.toStringAsFixed(1) ?? '-'}%',
                            label: 'TIR',
                            valueColor: const Color(0xFF2D6A4F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tabs
            SliverPersistentHeader(
              pinned: true,
              delegate: LhotseTabBarDelegate(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Activo'),
                  Tab(text: 'Docs'),
                ],
              ),
            ),
          ],

          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _TabScrollWrapper(
                storageKey: 'activo',
                bottomPadding: bottomPadding,
                child: _ActivoTab(
                  assetInfo: assetInfo,
                  galleryMedia: galleryMedia,
                  cardWidth: screenWidth * 0.75,
                ),
              ),
              _DocsTab(
                modelType: d.modelType,
                modelId: d.id,
                activeFilters: _activeDocFilters,
                onToggleFilter: _toggleDocFilter,
                onClearFilters: () =>
                    setState(() => _activeDocFilters.clear()),
                bottomPadding: bottomPadding,
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// ── Tab scroll wrapper ────────────────────────────────────────────────────────

class _TabScrollWrapper extends StatelessWidget {
  const _TabScrollWrapper({
    required this.child,
    required this.bottomPadding,
    required this.storageKey,
  });
  final Widget child;
  final double bottomPadding;
  final String storageKey;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: PageStorageKey<String>(storageKey),
      padding: EdgeInsets.only(bottom: bottomPadding + AppSpacing.lg),
      child: child,
    );
  }
}

// ── ACTIVO tab ────────────────────────────────────────────────────────────────

class _ActivoTab extends StatelessWidget {
  const _ActivoTab({
    required this.assetInfo,
    required this.galleryMedia,
    required this.cardWidth,
  });

  final AssetInfo? assetInfo;
  final List<MediaItem> galleryMedia;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (assetInfo != null) ...[
          const SizedBox(height: AppSpacing.xl),
          const LhotseSectionLabel(label: 'INFORMACIÓN'),
          const SizedBox(height: AppSpacing.sm),
          LhotseKeyValueList(entries: assetInfo!.entries),
        ],
        if (galleryMedia.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'GALERÍA',
                  style: AppTypography.sectionLabel.copyWith(
                    color: AppColors.accentMuted,
                  ),
                ),
                if (galleryMedia.length > _kMaxVisibleGallery) ...[
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () =>
                        showAllGallery(context, 'GALERÍA', galleryMedia),
                    child: const PhosphorIcon(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: galleryMedia.length > _kMaxVisibleGallery
                  ? _kMaxVisibleGallery
                  : galleryMedia.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final item = galleryMedia[i];
                return GestureDetector(
                  onTap: () => showMediaGallery(
                      context,
                      items: galleryMedia,
                      initialIndex: i),
                  child: Container(
                    width: cardWidth,
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
                        : VideoThumbnailTile(url: item.url),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ── DOCS tab ──────────────────────────────────────────────────────────────────

class _DocsTab extends ConsumerWidget {
  const _DocsTab({
    required this.modelType,
    required this.modelId,
    required this.activeFilters,
    required this.onToggleFilter,
    required this.onClearFilters,
    required this.bottomPadding,
  });

  final String modelType;
  final String modelId;
  final Set<String> activeFilters;
  final ValueChanged<String> onToggleFilter;
  final VoidCallback onClearFilters;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync =
        ref.watch(documentsProvider((type: modelType, id: modelId)));
    final allCategories =
        ref.watch(allDocumentCategoriesProvider).valueOrNull ?? const [];

    return docsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No se pudieron cargar los documentos.',
                style: AppTypography.bodyReading
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: () => ref.invalidate(
                    documentsProvider((type: modelType, id: modelId))),
                child: Text(
                  'Inténtalo de nuevo',
                  style: AppTypography.bodyReading
                      .copyWith(color: AppColors.accentMuted),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (rawDocs) {
        if (rawDocs.isEmpty) {
          return Center(
            child: Text(
              'Aún no hay documentos disponibles.',
              style: AppTypography.bodyReading
                  .copyWith(color: AppColors.textSecondary),
            ),
          );
        }
        final iconMap = {for (var c in allCategories) c.id: c.iconName};
        final filterCategories =
            categoriesForIds(rawDocs.map((d) => d.categoryId), allCategories);
        final allDocs = rawDocs
            .map((d) => d.toLhotseDocument(
                iconName: iconMap[d.categoryId] ?? 'fileText'))
            .toList();
        final documents = activeFilters.isEmpty
            ? allDocs
            : allDocs
                .where((d) => activeFilters.contains(d.categoryId))
                .toList();

        final hasChips = filterCategories.isNotEmpty;
        return ListView.builder(
          key: const PageStorageKey<String>('docs'),
          padding: EdgeInsets.fromLTRB(
            0,
            0,
            0,
            bottomPadding + AppSpacing.lg,
          ),
          itemCount: documents.length + (hasChips ? 1 : 0),
          itemBuilder: (context, rawIndex) {
            if (hasChips && rawIndex == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    children: [
                      ...filterCategories.map((cat) => Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.sm),
                            child: LhotseFilterChip(
                              label: cat.label,
                              isActive: activeFilters.contains(cat.id),
                              onTap: () => onToggleFilter(cat.id),
                            ),
                          )),
                      if (activeFilters.isNotEmpty) ...[
                        GestureDetector(
                          onTap: onClearFilters,
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: PhosphorIcon(PhosphorIconsThin.x,
                                size: 14, color: AppColors.accentMuted),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                      ],
                    ],
                  ),
                ),
              );
            }
            final i = hasChips ? rawIndex - 1 : rawIndex;
            final doc = documents[i];
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  if (i > 0)
                    Container(
                      height: 0.5,
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                    ),
                  LhotseDocRow(
                    name: doc.name,
                    date: doc.date,
                    icon: docCategoryIconByKey(doc.iconName),
                    onTap: doc.fileUrl != null
                        ? () => openSupabaseDoc(
                              context,
                              fileUrl: doc.fileUrl!,
                              fileName: doc.name,
                              docId: doc.id,
                            )
                        : null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}


// Documents loaded from Supabase via documentsProvider
