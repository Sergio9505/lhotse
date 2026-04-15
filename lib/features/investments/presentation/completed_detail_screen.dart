import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/documents_provider.dart';
import '../../../core/domain/asset_info.dart';
import '../../../core/domain/document_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_tab_bar_delegate.dart';
import '../../../core/widgets/lhotse_gallery_helpers.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_doc_row.dart';
import '../../../core/widgets/lhotse_key_value_list.dart';
import '../../../core/widgets/lhotse_documents_section.dart';
import '../../../core/widgets/lhotse_metric_block.dart';
import '../../../core/widgets/lhotse_section_label.dart';
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
  late final TabController _tabController;
  bool _heroGone = false;
  bool _showCollapsedTitle = false;
  int _tabIndex = 0;

  static const _docFilterLabels = {
    DocCategory.legal: 'Escrituras',
    DocCategory.financiero: 'Facturas',
    DocCategory.obra: 'Licencias',
    DocCategory.fiscal: 'Certificados',
  };
  final Set<DocCategory> _activeDocFilters = {};

  List<LhotseDocument> _filteredDocs(List<DocumentData> docs) {
    final all = docs.map((d) => d.toLhotseDocument()).toList();
    if (_activeDocFilters.isEmpty) return all;
    return all.where((d) => _activeDocFilters.contains(d.category)).toList();
  }

  void _toggleDocFilter(DocCategory cat) {
    setState(() {
      if (_activeDocFilters.contains(cat)) {
        _activeDocFilters.remove(cat);
      } else {
        _activeDocFilters.add(cat);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _outerController.addListener(_onOuterScroll);
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tabController.index != _tabIndex) {
          setState(() => _tabIndex = _tabController.index);
        }
      });
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

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final returnAmount = d.totalReturn ?? d.amount;
    final docs = ref
        .watch(documentsProvider((type: d.modelType, id: d.id)))
        .valueOrNull ?? const [];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          controller: _outerController,
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
                      '${_eurFormat.format(returnAmount)}€',
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.projectName.toUpperCase(),
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
                    LhotseImage(d.imageUrl ?? ''),
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

            // Identity + metrics
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.projectName.toUpperCase(),
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      d.brandName.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${_eurFormat.format(returnAmount)}€',
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'RETORNO TOTAL',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 2.0,
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
                            value: '${d.actualDuration ?? '–'} meses',
                            label: 'Duración',
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
                  Tab(text: 'ACTIVO'),
                  Tab(text: 'DOCS'),
                ],
              ),
            ),
          ],

          body: TabBarView(
            controller: _tabController,
            children: [
              _TabScrollWrapper(
                bottomPadding: bottomPadding,
                child: _ActivoTab(
                  assetInfo: d.assetInfo,
                  galleryImages: d.galleryImages,
                  cardWidth: screenWidth * 0.75,
                ),
              ),
              _TabScrollWrapper(
                bottomPadding: bottomPadding,
                child: _DocsTab(
                  documents: _filteredDocs(docs),
                  chips: _buildDocChips(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocChips() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ..._docFilterLabels.entries.map((entry) {
              final active = _activeDocFilters.contains(entry.key);
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => _toggleDocFilter(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: active
                            ? AppColors.primary
                            : AppColors.textPrimary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      entry.value.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: active
                            ? AppColors.textOnDark
                            : AppColors.accentMuted,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (_activeDocFilters.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _activeDocFilters.clear()),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: PhosphorIcon(PhosphorIconsThin.x,
                      size: 14, color: AppColors.accentMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Tab scroll wrapper ────────────────────────────────────────────────────────

class _TabScrollWrapper extends StatelessWidget {
  const _TabScrollWrapper(
      {required this.child, required this.bottomPadding});
  final Widget child;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPadding + AppSpacing.lg),
      child: child,
    );
  }
}

// ── ACTIVO tab ────────────────────────────────────────────────────────────────

class _ActivoTab extends StatelessWidget {
  const _ActivoTab({
    required this.assetInfo,
    required this.galleryImages,
    required this.cardWidth,
  });

  final AssetInfo? assetInfo;
  final List<String> galleryImages;
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
        if (galleryImages.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'GALERÍA',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.accentMuted,
                    letterSpacing: 1.8,
                  ),
                ),
                if (galleryImages.length > _kMaxVisibleGallery) ...[
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () =>
                        showAllGallery(context, 'GALERÍA', galleryImages),
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
              itemCount: galleryImages.length > _kMaxVisibleGallery
                  ? _kMaxVisibleGallery
                  : galleryImages.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => showFullImage(context, galleryImages[i]),
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
                  child: LhotseImage(galleryImages[i]),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── DOCS tab ──────────────────────────────────────────────────────────────────

class _DocsTab extends StatelessWidget {
  const _DocsTab({required this.documents, required this.chips});
  final List<LhotseDocument> documents;
  final Widget chips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        chips,
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: documents.indexed.map((entry) {
              final i = entry.$1;
              final doc = entry.$2;
              return Column(
                children: [
                  if (i > 0)
                    Container(
                      height: 0.5,
                      color:
                          AppColors.textPrimary.withValues(alpha: 0.08),
                    ),
                  LhotseDocRow(
                    name: doc.name,
                    date: doc.date,
                    icon: docCategoryIcon(doc.category),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Documents loaded from Supabase via documentsProvider
