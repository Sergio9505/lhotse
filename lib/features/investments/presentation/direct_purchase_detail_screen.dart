import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/brands_provider.dart';
import '../../../core/data/document_categories_provider.dart';
import '../../../core/data/documents_provider.dart';
import '../../../core/domain/asset_info.dart' show AssetInfoEntry;
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/open_supabase_doc.dart';
import '../../../core/utils/strip_iso_suffix.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_tab_bar_delegate.dart';
import '../../../core/domain/media_item.dart';
import '../../../core/widgets/lhotse_gallery_helpers.dart';
import '../../../core/data/bunny_thumbnail.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_tab_scroll_wrapper.dart';
import '../../../core/data/playable_video_url_provider.dart';
import '../../../core/widgets/lhotse_video_player.dart';
import '../../home/presentation/widgets/fullscreen_video_player.dart';
import '../../../core/widgets/lhotse_doc_row.dart';
import '../../../core/widgets/lhotse_key_value_list.dart';
import '../../../core/widgets/lhotse_documents_section.dart';
import '../../../core/widgets/lhotse_filter_chip.dart';
import '../../../core/widgets/lhotse_section_label.dart';
import '../data/investments_provider.dart';
import '../domain/purchase_contract_data.dart';
import '../domain/purchase_mortgage_details.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');
final _dateFormat = DateFormat('MM/yyyy');

const _kHeroHeight = 200.0;
const _kMaxVisibleGallery = 5;

// Shell widget — prefers the contract passed via router extra (common path
// from L2), falls back to `purchaseContractByIdProvider` only on deep-link.
class DirectPurchaseDetailScreen extends ConsumerWidget {
  const DirectPurchaseDetailScreen({
    super.key,
    required this.contractId,
    this.brandName,
    this.contract,
  });

  final String contractId;

  /// Passed via router extra from L2 Strategy. Null on deep-link — screen
  /// falls back to `brandByIdProvider(contract.brandId)`.
  final String? brandName;

  /// Passed via router extra from L2 (normal path). When null, the shell
  /// refetches via `purchaseContractByIdProvider` for deep-link entries.
  final PurchaseContractData? contract;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = contract;
    if (c != null) {
      return _DirectPurchaseDetailContent(contract: c, brandName: brandName);
    }
    final contractAsync = ref.watch(purchaseContractByIdProvider(contractId));
    return contractAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
      ),
      error: (_, __) => const Scaffold(
        backgroundColor: AppColors.background,
        body: SizedBox.shrink(),
      ),
      data: (fetched) => fetched == null
          ? const Scaffold(backgroundColor: AppColors.background, body: SizedBox.shrink())
          : _DirectPurchaseDetailContent(contract: fetched, brandName: brandName),
    );
  }
}

// Content widget — receives contract synchronously, owns TabController
class _DirectPurchaseDetailContent extends ConsumerStatefulWidget {
  const _DirectPurchaseDetailContent({
    required this.contract,
    this.brandName,
  });

  final PurchaseContractData contract;
  final String? brandName;

  @override
  ConsumerState<_DirectPurchaseDetailContent> createState() =>
      _DirectPurchaseDetailContentState();
}

class _DirectPurchaseDetailContentState
    extends ConsumerState<_DirectPurchaseDetailContent>
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
    _tabController = TabController(
      length: widget.contract.hasFinancing ? 3 : 2,
      vsync: this,
    );
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

  Future<void> _openVideoPlayer(
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
    final c = widget.contract;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final brandName = widget.brandName ??
        ref.watch(brandByIdProvider(c.brandId)).valueOrNull?.name ??
        '';
    final assetDetail = ref
        .watch(purchaseAssetDetailProvider(c.assetId))
        .valueOrNull;
    final signedVideoUrl = assetDetail?.videoUrl?.isNotEmpty == true
        ? ref.watch(playableVideoUrlProvider(assetDetail!.videoUrl!)).valueOrNull
        : null;
    final videoPosterUrl = posterUrlFor(videoUrl: assetDetail?.videoUrl, fallback: c.assetImageUrl ?? '');
    // FINANCIACIÓN tab content is lazy — only fetched if the contract has
    // financing AND the tab is rendered.
    final mortgageDetail = c.hasFinancing
        ? ref.watch(purchaseMortgageDetailProvider(c.id)).valueOrNull
        : null;
    final projectName = c.assetName ?? '';
    final purchaseFormatted = _eurFormat.format(c.purchaseValue);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _heroGone ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: ExtendedNestedScrollView(
          controller: _outerController,
          onlyOneScrollInBody: true,
          pinnedHeaderSliverHeightBuilder: () =>
              MediaQuery.paddingOf(context).top + kToolbarHeight + kLhotseTabBarHeight,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                      useLightOverlay: assetDetail?.useLightOverlay ?? true,
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
                      '$purchaseFormatted€',
                      style: AppTypography.figureAmount.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      projectName.toUpperCase(),
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
                      ? () => _openVideoPlayer(
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projectName,
                      style: AppTypography.editorialTitle
                          .copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        // Brand stays UPPERCASE tracked across the whole app
                        // (wordmark convention — Hermès / Louis Vuitton / Prada
                        // editorial style). Same `labelUppercaseSm` token used
                        // in L1 brand row, L2 collapsed hero, brands list,
                        // brand detail, search, etc. Hierarchy vs the city is
                        // by color (textPrimary brand, accentMuted city).
                        Text(
                          brandName.toUpperCase(),
                          style: AppTypography.labelUppercaseSm.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (c.assetLocation != null) ...[
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
                              stripIsoSuffix(c.assetLocation!).toUpperCase(),
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
                      '$purchaseFormatted€',
                      style: AppTypography.figureHero.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Valor de compra',
                      style: AppTypography.bodyReading.copyWith(
                        color: AppColors.accentMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MetricColumn(
                          value: c.monthlyRent != null
                              ? '${_eurFormat.format(c.monthlyRent)}€'
                              : '—',
                          label: 'Alquiler',
                        ),
                        _MetricColumn(
                          value: c.rentalYieldPct != null
                              ? '${c.rentalYieldPct!.toStringAsFixed(1)}%'
                              : '—',
                          label: 'Yield',
                        ),
                        _MetricColumn(
                          value: c.assetRevaluationPct != null
                              ? '${c.assetRevaluationPct! > 0 ? '+' : ''}${c.assetRevaluationPct!.toStringAsFixed(1)}%'
                              : '—',
                          label: 'Revalorización',
                          // Directional color: green positive, muted red
                          // negative, default for zero/null. Matches
                          // _PurchaseRow in L2 — same signal across cards
                          // and detail.
                          valueColor: c.assetRevaluationPct == null ||
                                  c.assetRevaluationPct == 0
                              ? null
                              : c.assetRevaluationPct! > 0
                                  ? const Color(0xFF2D6A4F)
                                  : const Color(0xFF7F1D1D),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: LhotseTabBarDelegate(
                controller: _tabController,
                tabs: [
                  const Tab(text: 'Activo'),
                  if (c.hasFinancing) const Tab(text: 'Financiación'),
                  const Tab(text: 'Docs'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              LhotseTabScrollWrapper(
                bottomPadding: bottomPadding,
                child: _AssetTab(
                  assetInfo:
                      assetDetail?.assetInfo ?? const <AssetInfoEntry>[],
                  floorPlanUrl: assetDetail?.floorPlanUrl,
                  galleryMedia:
                      assetDetail?.galleryMedia ?? const <MediaItem>[],
                  cardWidth: screenWidth * 0.75,
                ),
              ),
              if (c.hasFinancing)
                LhotseTabScrollWrapper(
                  bottomPadding: bottomPadding,
                  child: _FinancingTab(
                    cashPayment: c.cashPayment,
                    mortgage: mortgageDetail,
                  ),
                ),
              _DocsTab(
                modelType: 'purchase',
                modelId: c.id,
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

/// Compact metric column for the L3 hero (figure 24pt + sentence-case label
/// 12pt accentMuted). Optional `valueColor` for directional metrics like
/// `revalorización` (green positive / muted red negative).
class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.value,
    required this.label,
    this.valueColor,
  });

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.figureAmount.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodyReading.copyWith(
            color: AppColors.accentMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── ASSET tab ─────────────────────────────────────────────────────────────────

class _AssetTab extends StatelessWidget {
  const _AssetTab({
    required this.assetInfo,
    required this.floorPlanUrl,
    required this.galleryMedia,
    required this.cardWidth,
  });

  final List<AssetInfoEntry> assetInfo;
  final String? floorPlanUrl;
  final List<MediaItem> galleryMedia;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (assetInfo.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const LhotseSectionLabel(label: 'INFORMACIÓN'),
          const SizedBox(height: AppSpacing.sm),
          LhotseKeyValueList(entries: assetInfo),
        ],
        if (floorPlanUrl != null) ...[
          const SizedBox(height: AppSpacing.xxl),
          const LhotseSectionLabel(label: 'PLANO'),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GestureDetector(
              onTap: () => _showFloorPlan(context, floorPlanUrl!),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                color: AppColors.background,
                child: Stack(
                  children: [
                    Center(
                      child: LhotseImage(floorPlanUrl!, fit: BoxFit.contain),
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
        if (galleryMedia.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'GALERÍA',
                  style: AppTypography.labelUppercaseMd.copyWith(
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
                      size: 16,
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

// ── FINANCING tab ─────────────────────────────────────────────────────────────

class _FinancingTab extends StatelessWidget {
  const _FinancingTab({
    required this.cashPayment,
    required this.mortgage,
  });

  final double? cashPayment;
  final PurchaseMortgageDetails? mortgage;

  @override
  Widget build(BuildContext context) {
    if (mortgage == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
      );
    }
    final m = mortgage!;
    final entries = <AssetInfoEntry>[];
    if (cashPayment != null) {
      entries.add(AssetInfoEntry(
          label: 'Contado', value: '${_eurFormat.format(cashPayment)}€'));
    }
    if (m.mortgagePrincipal != null) {
      entries.add(AssetInfoEntry(
          label: 'Hipoteca',
          value: '${_eurFormat.format(m.mortgagePrincipal)}€'));
    }
    if (m.mortgageConditions != null) {
      entries.add(
          AssetInfoEntry(label: 'Condiciones', value: m.mortgageConditions!));
    }
    if (m.mortgageMonthlyPayment != null) {
      entries.add(AssetInfoEntry(
          label: 'Cuota',
          value: '${_eurFormat.format(m.mortgageMonthlyPayment)}€/mes'));
    }
    if (m.mortgageEndDate != null) {
      entries.add(AssetInfoEntry(
          label: 'Finalización hipoteca',
          value: _dateFormat.format(m.mortgageEndDate!)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entries.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          LhotseKeyValueList(entries: entries),
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

        // Filter chips render inline as the first item — they scroll with the
        // docs (no sticky behaviour). Section tabs above already provide the
        // pinned chrome anchor.
        final hasChips = filterCategories.isNotEmpty;
        return ListView.builder(
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

// ── Floor plan fullscreen ─────────────────────────────────────────────────────

void _showFloorPlan(BuildContext context, String url) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) =>
              Opacity(opacity: animation.value, child: child),
          child: _FloorPlanView(url: url),
        );
      },
    ),
  );
}

class _FloorPlanView extends StatefulWidget {
  const _FloorPlanView({required this.url});

  final String url;

  @override
  State<_FloorPlanView> createState() => _FloorPlanViewState();
}

class _FloorPlanViewState extends State<_FloorPlanView> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(
        const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
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
                    child: Image.network(widget.url, fit: BoxFit.contain),
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
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                    child: const PhosphorIcon(
                      PhosphorIconsThin.x,
                      color: AppColors.textPrimary,
                      size: 24,
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

