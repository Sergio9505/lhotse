import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/domain/investment_data.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_doc_row.dart';
import '../../../core/widgets/lhotse_documents_section.dart';
import '../../../core/widgets/lhotse_key_value_list.dart';
import '../../../core/widgets/lhotse_metric_block.dart';
import '../../../core/widgets/lhotse_section_label.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');

const _kHeroHeight = 200.0;
const _kTabBarHeight = 49.0;
const _kMaxVisibleGallery = 5;

// ===========================================================================
// Completed Investment Detail — 3 tabs: RESULTADO / ACTIVO / DOCS
// ===========================================================================

class CompletedDetailScreen extends StatefulWidget {
  const CompletedDetailScreen({
    super.key,
    required this.investment,
    this.project,
  });

  final InvestmentData investment;
  final ProjectData? project;

  @override
  State<CompletedDetailScreen> createState() => _CompletedDetailScreenState();
}

class _CompletedDetailScreenState extends State<CompletedDetailScreen>
    with SingleTickerProviderStateMixin {
  final _outerController = ScrollController();
  late final TabController _tabController;
  bool _heroGone = false;
  bool _showCollapsedTitle = false;
  int _tabIndex = 0;

  // Doc filter state
  static const _docFilterLabels = {
    DocCategory.legal: 'Escrituras',
    DocCategory.financiero: 'Facturas',
    DocCategory.obra: 'Licencias',
    DocCategory.fiscal: 'Certificados',
  };
  final Set<DocCategory> _activeDocFilters = {};

  List<LhotseDocument> get _filteredDocs {
    if (_activeDocFilters.isEmpty) return _completedDocs;
    return _completedDocs
        .where((d) => _activeDocFilters.contains(d.category))
        .toList();
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
    _tabController = TabController(length: 3, vsync: this)
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          controller: _outerController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // =========================================================
            // 1. HERO
            // =========================================================
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
                      '${_eurFormat.format(inv.totalReturn ?? inv.amount)}€',
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

            // =========================================================
            // 2. IDENTITY + AMOUNT
            // =========================================================
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
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                        if (project?.location != null) ...[
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
                    // Hero number — total return
                    Text(
                      '${_eurFormat.format(inv.totalReturn ?? inv.amount)}€',
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'MI PARTICIPACIÓN',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 2.0,
                      ),
                    ),
                    // Gain line
                    if (inv.netProfit != null && inv.actualRoi != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '+${_eurFormat.format(inv.netProfit)}€  (+${inv.actualRoi!.toStringAsFixed(1)}%)',
                        style: AppTypography.headingSmall.copyWith(
                          color: const Color(0xFF2D6A4F), // success green
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // =========================================================
            // 3. TABS
            // =========================================================
            SliverPersistentHeader(
              pinned: true,
              delegate: _CompletedTabBarDelegate(controller: _tabController),
            ),
          ],

          body: TabBarView(
            controller: _tabController,
            children: [
              _TabScrollWrapper(
                child: _ResultadoTab(investment: inv),
                bottomPadding: bottomPadding,
              ),
              _TabScrollWrapper(
                child: _ActivoTab(
                  investment: inv,
                  cardWidth: screenWidth * 0.75,
                ),
                bottomPadding: bottomPadding,
              ),
              _TabScrollWrapper(
                child: _DocsTab(
                  documents: _filteredDocs,
                  chips: _buildDocChips(),
                ),
                bottomPadding: bottomPadding,
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
                        fontWeight: FontWeight.w600,
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
                  child: Icon(LucideIcons.x, size: 14, color: AppColors.accentMuted),
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

// ===========================================================================
// Tab bar delegate
// ===========================================================================

class _CompletedTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _CompletedTabBarDelegate({required this.controller});
  final TabController controller;

  @override
  double get minExtent => _kTabBarHeight;
  @override
  double get maxExtent => _kTabBarHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Expanded(
            child: TabBar(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              labelPadding: EdgeInsets.zero,
              tabAlignment: TabAlignment.fill,
              isScrollable: false,
              labelStyle: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
              unselectedLabelStyle: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: 1.5,
              ),
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.accentMuted,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 1.5, color: AppColors.textPrimary),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: 'RESULTADO'),
                Tab(text: 'ACTIVO'),
                Tab(text: 'DOCS'),
              ],
            ),
          ),
          Container(
            height: 0.5,
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CompletedTabBarDelegate oldDelegate) =>
      controller != oldDelegate.controller;
}

// ===========================================================================
// TAB: RESULTADO
// ===========================================================================

class _ResultadoTab extends StatelessWidget {
  const _ResultadoTab({required this.investment});
  final InvestmentData investment;

  @override
  Widget build(BuildContext context) {
    final inv = investment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Resumen metrics ---
        const SizedBox(height: AppSpacing.xl),
        const LhotseSectionLabel(label: 'RESUMEN'),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: LhotseMetricBlock(
                      value: '${inv.actualRoi?.toStringAsFixed(1) ?? '-'}%',
                      label: 'ROI real',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: LhotseMetricBlock(
                      value: '+${_eurFormat.format(inv.netProfit ?? 0)}€',
                      label: 'Plusvalía',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: LhotseMetricBlock(
                      value: '${inv.actualTir?.toStringAsFixed(1) ?? '-'}%',
                      label: 'TIR real',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: LhotseMetricBlock(
                      value: '${inv.actualDuration ?? inv.durationMonths} meses',
                      label: 'Duración',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- Comparativa ---
        if (inv.projectedRoi != null) ...[
          const SizedBox(height: AppSpacing.xxl),
          const LhotseSectionLabel(label: 'PROYECTADO VS REAL'),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                _ComparisonRow(
                  label: 'ROI',
                  projected: '${inv.projectedRoi!.toStringAsFixed(1)}%',
                  actual: '${inv.actualRoi?.toStringAsFixed(1) ?? '-'}%',
                ),
                Container(
                  height: 0.5,
                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                ),
                _ComparisonRow(
                  label: 'Duración',
                  projected: '${inv.durationMonths} meses',
                  actual: '${inv.actualDuration ?? '-'} meses',
                ),
              ],
            ),
          ),
        ],

        // --- Análisis económico ---
        if (inv.economicAnalysis != null &&
            inv.economicAnalysis!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          const LhotseSectionLabel(label: 'ANÁLISIS ECONÓMICO'),
          const SizedBox(height: AppSpacing.sm),
          LhotseKeyValueList(
            entries: inv.economicAnalysis!,
            highlightLast: true,
          ),
        ],
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.projected,
    required this.actual,
  });
  final String label;
  final String projected;
  final String actual;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.accentMuted,
                )),
          ),
          Expanded(
            flex: 3,
            child: Text(projected,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.4),
                  decoration: TextDecoration.lineThrough,
                )),
          ),
          Expanded(
            flex: 3,
            child: Text(actual,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// TAB: ACTIVO
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
        if (inv.renderImages?.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.xxl),
          const LhotseSectionLabel(label: 'RENDERS'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: (inv.renderImages!.length > _kMaxVisibleGallery
                      ? _kMaxVisibleGallery
                      : inv.renderImages!.length),
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) => Container(
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
        ],
      ],
    );
  }
}

// ===========================================================================
// TAB: DOCS
// ===========================================================================

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

// ===========================================================================
// Mock docs for completed investments
// ===========================================================================

final _completedDocs = [
  LhotseDocument(name: 'Acta de liquidación', date: '15 FEB. 2026', category: DocCategory.legal),
  LhotseDocument(name: 'Certificado de retención fiscal', date: '15 FEB. 2026', category: DocCategory.fiscal),
  LhotseDocument(name: 'Escritura de compraventa', date: '10 ENE. 2026', category: DocCategory.legal),
  LhotseDocument(name: 'Informe final de rentabilidad', date: '12 FEB. 2026', category: DocCategory.financiero),
  LhotseDocument(name: 'Certificado de finalización de obra', date: '20 DIC. 2025', category: DocCategory.obra),
  LhotseDocument(name: 'Factura notaría cierre', date: '15 FEB. 2026', category: DocCategory.financiero),
];
