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
import '../../../core/widgets/lhotse_section_label.dart';
import '../domain/purchase_contract_data.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');
final _dateFormat = DateFormat('MM/yyyy');

const _kHeroHeight = 200.0;
const _kMaxVisibleGallery = 5;

class CompraDirectaDetailScreen extends ConsumerStatefulWidget {
  const CompraDirectaDetailScreen({
    super.key,
    required this.contract,
  });

  final PurchaseContractData contract;

  @override
  ConsumerState<CompraDirectaDetailScreen> createState() =>
      _CompraDirectaDetailScreenState();
}

class _CompraDirectaDetailScreenState
    extends ConsumerState<CompraDirectaDetailScreen>
    with SingleTickerProviderStateMixin {
  final _outerController = ScrollController();
  late final TabController _tabController;
  bool _heroGone = false;
  bool _showCollapsedTitle = false;

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

  @override
  Widget build(BuildContext context) {
    final c = widget.contract;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final docs = ref
        .watch(documentsProvider((type: 'purchase', id: c.id)))
        .valueOrNull ?? const [];
    final projectName = c.projectName ?? '';
    final purchaseFormatted = _eurFormat.format(c.purchaseValue);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _heroGone ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
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
                      '$purchaseFormatted€',
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      projectName.toUpperCase(),
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
                    LhotseImage(c.projectImageUrl ?? ''),
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

            // Identity + purchase value + secondary metrics
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projectName.toUpperCase(),
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          c.brandName.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.8,
                          ),
                        ),
                        if (c.projectLocation != null) ...[
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
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
                              c.projectLocation!.toUpperCase(),
                              style: AppTypography.caption.copyWith(
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
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'VALOR DE COMPRA',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // 3-col secondary metrics
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.monthlyRent != null
                                    ? '${_eurFormat.format(c.monthlyRent)}€'
                                    : '—',
                                style: AppTypography.headingLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ALQUILER',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.accentMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.rentalYieldPct != null
                                    ? '${c.rentalYieldPct!.toStringAsFixed(1)}%'
                                    : '—',
                                style: AppTypography.headingLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'RENTABILIDAD',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.accentMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.assetRevaluationPct != null
                                    ? '${c.assetRevaluationPct!.toStringAsFixed(0)}%'
                                    : '—',
                                style: AppTypography.headingLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'REVALORIZACIÓN',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.accentMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
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
                tabs: [
                  const Tab(text: 'ACTIVO'),
                  if (c.hasFinancing) const Tab(text: 'FINANCIACIÓN'),
                  const Tab(text: 'DOCS'),
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
                  assetInfo: c.assetInfo,
                  floorPlanUrl: c.assetFloorPlanUrl,
                  galleryImages: c.assetGalleryImages,
                  cardWidth: screenWidth * 0.75,
                ),
              ),
              if (c.hasFinancing)
                _TabScrollWrapper(
                  bottomPadding: bottomPadding,
                  child: _FinanzasTab(
                    cashPayment: c.cashPayment,
                    mortgage: c.mortgagePrincipal,
                    mortgageConditions: c.mortgageConditions,
                    monthlyPayment: c.mortgageMonthlyPayment,
                    mortgageEndDate: c.mortgageEndDate,
                  ),
                ),
              _TabScrollWrapper(
                bottomPadding: bottomPadding,
                child: _DocumentosTab(
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
    required this.floorPlanUrl,
    required this.galleryImages,
    required this.cardWidth,
  });

  final AssetInfo? assetInfo;
  final String? floorPlanUrl;
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

// ── FINANCIACIÓN tab ──────────────────────────────────────────────────────────

class _FinanzasTab extends StatelessWidget {
  const _FinanzasTab({
    required this.cashPayment,
    required this.mortgage,
    required this.mortgageConditions,
    required this.monthlyPayment,
    required this.mortgageEndDate,
  });

  final double? cashPayment;
  final double? mortgage;
  final String? mortgageConditions;
  final double? monthlyPayment;
  final DateTime? mortgageEndDate;

  @override
  Widget build(BuildContext context) {
    final entries = <AssetInfoEntry>[];
    if (cashPayment != null) {
      entries.add(AssetInfoEntry(
          label: 'Contado',
          value: '${_eurFormat.format(cashPayment)}€'));
    }
    if (mortgage != null) {
      entries.add(AssetInfoEntry(
          label: 'Hipoteca',
          value: '${_eurFormat.format(mortgage)}€'));
    }
    if (mortgageConditions != null) {
      entries.add(AssetInfoEntry(
          label: 'Condiciones', value: mortgageConditions!));
    }
    if (monthlyPayment != null) {
      entries.add(AssetInfoEntry(
          label: 'Cuota',
          value: '${_eurFormat.format(monthlyPayment)}€/mes'));
    }
    if (mortgageEndDate != null) {
      entries.add(AssetInfoEntry(
          label: 'Finalización hipoteca',
          value: _dateFormat.format(mortgageEndDate!)));
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

class _DocumentosTab extends StatelessWidget {
  const _DocumentosTab(
      {required this.documents, required this.chips});
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
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
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

// ── Floor plan fullscreen ─────────────────────────────────────────────────────

void _showFloorPlan(BuildContext context, String url) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        final topPadding = MediaQuery.of(context).padding.top;
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) =>
              Opacity(opacity: animation.value, child: child),
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

// Documents are now loaded from Supabase via documentsProvider
