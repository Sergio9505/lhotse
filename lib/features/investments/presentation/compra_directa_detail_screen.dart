import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/domain/asset_info.dart';
import '../../../core/domain/investment_data.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_tab_bar_delegate.dart';
import '../../../core/widgets/lhotse_gallery_helpers.dart';
import '../../../core/widgets/lhotse_doc_row.dart';
import '../../../core/widgets/lhotse_key_value_list.dart';
import '../../../core/widgets/lhotse_documents_section.dart';
import '../../../core/widgets/lhotse_section_label.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');
final _dateFormat = DateFormat('MM/yyyy');

const _kHeroHeight = 200.0;

const _kMaxVisibleGallery = 5;

// ===========================================================================
// CompraDirecta Detail — NestedScrollView + 3 tabs
// ===========================================================================

class CompraDirectaDetailScreen extends StatefulWidget {
  const CompraDirectaDetailScreen({
    super.key,
    required this.investment,
    this.project,
  });

  final InvestmentData investment;
  final ProjectData? project;

  @override
  State<CompraDirectaDetailScreen> createState() =>
      _CompraDirectaDetailScreenState();
}

class _CompraDirectaDetailScreenState extends State<CompraDirectaDetailScreen>
    with SingleTickerProviderStateMixin {
  final _outerController = ScrollController();
  late final TabController _tabController;
  bool _heroGone = false;
  bool _showCollapsedTitle = false;

  // Doc filter state
  static const _docFilterLabels = {
    DocCategory.legal: 'Escrituras',
    DocCategory.financiero: 'Facturas',
    DocCategory.obra: 'Licencias',
    DocCategory.fiscal: 'Certificados',
  };
  final Set<DocCategory> _activeDocFilters = {};

  List<LhotseDocument> get _filteredDocs {
    if (_activeDocFilters.isEmpty) return _docs;
    return _docs.where((d) => _activeDocFilters.contains(d.category)).toList();
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _outerController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onOuterScroll() {
    final offset = _outerController.offset;
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
    final inv = widget.investment;
    final project = widget.project;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final purchaseFormatted = inv.purchaseValue != null
        ? _eurFormat.format(inv.purchaseValue)
        : _eurFormat.format(inv.amount);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          controller: _outerController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // =============================================================
            // 1. HERO — full-bleed asset image
            // =============================================================
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
                      inv.projectName.toUpperCase(),
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
                    Image.network(
                      project?.imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: AppColors.surface),
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
                  ],
                ),
              ),
            ),

            // =============================================================
            // 2. IDENTITY + PURCHASE VALUE + SECONDARY METRICS
            // =============================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.projectName.toUpperCase(),
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          inv.brandName.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.8,
                          ),
                        ),
                        if (project?.location != null) ...[
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
                              project!.location.toUpperCase(),
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
                    // Hero number — purchase value
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
                                inv.rentalIncome != null
                                    ? '${_eurFormat.format(inv.rentalIncome)}€'
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
                                '${inv.returnRate.toStringAsFixed(0)}%',
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
                                inv.revaluation != null
                                    ? '${inv.revaluation!.toStringAsFixed(0)}%'
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

            // =============================================================
            // 3. TABS — pinned
            // =============================================================
            SliverPersistentHeader(
              pinned: true,
              delegate: LhotseTabBarDelegate(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'ACTIVO'),
                    Tab(text: 'FINANCIACIÓN'),
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
                  investment: inv,
                  cardWidth: screenWidth * 0.75,
                ),
              ),
              _TabScrollWrapper(
                bottomPadding: bottomPadding,
                child: _FinanzasTab(investment: inv),
              ),
              _TabScrollWrapper(
                bottomPadding: bottomPadding,
                child: _DocumentosTab(
                  documents: _filteredDocs,
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
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          active ? AppColors.primary : Colors.transparent,
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

// ===========================================================================
// Tab scroll wrapper
// ===========================================================================

class _TabScrollWrapper extends StatelessWidget {
  const _TabScrollWrapper({required this.child, required this.bottomPadding});
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

// (Tab bar delegate extracted to core/widgets/lhotse_tab_bar_delegate.dart)

// ===========================================================================
// TAB: ACTIVO — property info + gallery
// ===========================================================================

class _ActivoTab extends StatelessWidget {
  const _ActivoTab({required this.investment, required this.cardWidth});
  final InvestmentData investment;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final inv = investment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (inv.assetInfo != null) ...[
          const SizedBox(height: AppSpacing.xl),
          const LhotseSectionLabel(label: 'INFORMACIÓN'),
          const SizedBox(height: AppSpacing.sm),
          LhotseKeyValueList(entries: inv.assetInfo!.entries),
        ],
        if (inv.floorPlanUrl != null) ...[
          const SizedBox(height: AppSpacing.xxl),
          const LhotseSectionLabel(label: 'PLANO'),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GestureDetector(
              onTap: () => _showFloorPlan(context, inv.floorPlanUrl!),
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
        if (inv.renderImages?.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.xxl),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'GALERÍA',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.accentMuted,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.8,
                  ),
                ),
                if (inv.renderImages!.length > _kMaxVisibleGallery) ...[
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => showAllGallery(
                        context, 'GALERÍA', inv.renderImages!),
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
              itemCount: inv.renderImages!.length > _kMaxVisibleGallery
                  ? _kMaxVisibleGallery
                  : inv.renderImages!.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () =>
                    showFullImage(context, inv.renderImages![i]),
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
                  child: Image.network(
                    inv.renderImages![i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(color: AppColors.surface),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ===========================================================================
// TAB: FINANZAS — financing details
// ===========================================================================

class _FinanzasTab extends StatelessWidget {
  const _FinanzasTab({required this.investment});
  final InvestmentData investment;

  @override
  Widget build(BuildContext context) {
    final inv = investment;
    final entries = <AssetInfoEntry>[];

    if (inv.cashPayment != null) {
      entries.add(AssetInfoEntry(
        label: 'Contado',
        value: '${_eurFormat.format(inv.cashPayment)}€',
      ));
    }
    if (inv.mortgage != null) {
      entries.add(AssetInfoEntry(
        label: 'Hipoteca',
        value: '${_eurFormat.format(inv.mortgage)}€',
      ));
    }
    if (inv.mortgageConditions != null) {
      entries.add(AssetInfoEntry(
        label: 'Condiciones',
        value: inv.mortgageConditions!,
      ));
    }
    if (inv.monthlyPayment != null) {
      entries.add(AssetInfoEntry(
        label: 'Cuota',
        value: '${_eurFormat.format(inv.monthlyPayment)}€/mes',
      ));
    }
    if (inv.mortgageEndDate != null) {
      entries.add(AssetInfoEntry(
        label: 'Finalización hipoteca',
        value: _dateFormat.format(inv.mortgageEndDate!),
      ));
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

// ===========================================================================
// TAB: DOCS — filterable documents
// ===========================================================================

class _DocumentosTab extends StatelessWidget {
  const _DocumentosTab({required this.documents, required this.chips});
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

// ===========================================================================
// Mock docs
// ===========================================================================

final _docs = [
  LhotseDocument(
      name: 'Escritura de compraventa',
      date: '15 MAR. 2025',
      category: DocCategory.legal),
  LhotseDocument(
      name: 'Contrato de arrendamiento',
      date: '01 ABR. 2025',
      category: DocCategory.legal),
  LhotseDocument(
      name: 'Certificado energético',
      date: '10 FEB. 2025',
      category: DocCategory.obra),
  LhotseDocument(
      name: 'Nota simple registral',
      date: '12 MAR. 2025',
      category: DocCategory.legal),
  LhotseDocument(
      name: 'Certificado de retención fiscal',
      date: '02 ENE. 2026',
      category: DocCategory.fiscal),
  LhotseDocument(
      name: 'Recibo IBI 2025',
      date: '15 SEP. 2025',
      category: DocCategory.fiscal),
];
