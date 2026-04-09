import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/domain/asset_info.dart';
import '../../../core/domain/investment_data.dart';
import '../../../core/domain/profit_scenario.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/domain/project_phase.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_bottom_sheet.dart';
import '../../../core/widgets/lhotse_documents_section.dart';
import '../../../core/widgets/lhotse_news_card.dart';
import '../../../core/widgets/lhotse_section_label.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');

// ---------------------------------------------------------------------------
// Coinversion Detail — NestedScrollView + TabBarView
// Hero full-bleed behind toolbar (Zara), data-first tabs (Revolut)
// headerSliverBuilder: SliverAppBar (hero) → identity (scrolls) → tabs (pin)
// ---------------------------------------------------------------------------

const _kHeroHeight = 200.0;
const _kMaxVisibleGallery = 5;
const _kTabBarHeight = 49.0;

class CoinversionDetailScreen extends StatefulWidget {
  const CoinversionDetailScreen({
    super.key,
    required this.investment,
    this.project,
  });

  final InvestmentData investment;
  final ProjectData? project;

  @override
  State<CoinversionDetailScreen> createState() =>
      _CoinversionDetailScreenState();
}

class _CoinversionDetailScreenState extends State<CoinversionDetailScreen> {
  final _outerController = ScrollController();
  bool _heroGone = false;
  bool _showCollapsedTitle = false;
  int _selectedScenario = 1; // P50
  @override
  void initState() {
    super.initState();
    _outerController.addListener(_onOuterScroll);
  }

  @override
  void dispose() {
    _outerController.dispose();
    super.dispose();
  }

  void _onOuterScroll() {
    final offset = _outerController.offset;

    // Hero gone = image scrolled out → switch back button + logo
    final heroThreshold = _kHeroHeight - kToolbarHeight;
    final heroGone = offset >= heroThreshold;

    // Show collapsed title when the amount exits the viewport
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
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            controller: _outerController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // =========================================================
              // 1. HERO — full-bleed image behind toolbar
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
                        '${_eurFormat.format(inv.amount)}€',
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ],
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
                            colors: [
                              Color(0x66000000),
                              Colors.transparent
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // =========================================================
              // 2. IDENTITY + AMOUNT (scrolls away)
              // =========================================================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
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
                      Text(
                        '${_eurFormat.format(inv.amount)}€',
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ],
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
                    ],
                  ),
                ),
              ),

              // =========================================================
              // 3. TABS — pinned, always accessible
              // =========================================================
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(),
              ),
            ],

            // ===========================================================
            // TAB CONTENT — each tab scrolls independently
            // ===========================================================
            body: TabBarView(
              children: [
                _TabScrollWrapper(
                  child: _AvanceTab(
                    investment: inv,
                    cardWidth: screenWidth * 0.75,
                  ),
                  bottomPadding: bottomPadding,
                ),
                _TabScrollWrapper(
                  child: _ProyectoTab(
                    investment: inv,
                    cardWidth: screenWidth * 0.75,
                  ),
                  bottomPadding: bottomPadding,
                ),
                _TabScrollWrapper(
                  child: _FinancieroTab(
                    investment: inv,
                    selectedScenario: _selectedScenario,
                    onScenarioSelected: (i) =>
                        setState(() => _selectedScenario = i),
                  ),
                  bottomPadding: bottomPadding,
                ),
                _TabScrollWrapper(
                  child: _DocumentosTab(investment: inv),
                  bottomPadding: bottomPadding,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Tab scroll wrapper — handles NestedScrollView overlap
// ===========================================================================

class _TabScrollWrapper extends StatelessWidget {
  const _TabScrollWrapper({
    required this.child,
    required this.bottomPadding,
  });

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
// Tab bar delegate — pinned below identity section
// ===========================================================================

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => _kTabBarHeight;
  @override
  double get maxExtent => _kTabBarHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Expanded(
            child: TabBar(
              padding: EdgeInsets.zero,
              labelPadding: EdgeInsets.zero,
              tabAlignment: TabAlignment.fill,
              isScrollable: false,
              labelStyle: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
              unselectedLabelStyle:
                  AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w400,
                letterSpacing: 1.5,
              ),
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.accentMuted,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              overlayColor:
                  WidgetStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: 'AVANCE'),
                Tab(text: 'PROYECTO'),
                Tab(text: 'FINANCIERO'),
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
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

// ===========================================================================
// TAB: FINANCIERO
// ===========================================================================

class _FinancieroTab extends StatelessWidget {
  const _FinancieroTab({
    required this.investment,
    required this.selectedScenario,
    required this.onScenarioSelected,
  });

  final InvestmentData investment;
  final int selectedScenario;
  final ValueChanged<int> onScenarioSelected;

  @override
  Widget build(BuildContext context) {
    final inv = investment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (inv.profitScenarios != null &&
            inv.profitScenarios!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const LhotseSectionLabel(
              label: 'ESCENARIOS'),
          const SizedBox(height: AppSpacing.md),
          _ScenarioPanel(
            scenarios: inv.profitScenarios!,
            selectedIndex: selectedScenario,
            onSelected: onScenarioSelected,
          ),
        ],
        if (inv.economicAnalysis != null &&
            inv.economicAnalysis!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _PremiumExpandableTile(
            label: 'ANÁLISIS ECONÓMICO',
            entries: inv.economicAnalysis!,
            highlightLast: true,
            collapsedPreview: inv.economicAnalysis!.last.value,
          ),
        ],
      ],
    );
  }
}

// ===========================================================================
// TAB: AVANCE — dynamic, why the investor comes back
// ===========================================================================

class _AvanceTab extends StatelessWidget {
  const _AvanceTab({
    required this.investment,
    required this.cardWidth,
  });

  final InvestmentData investment;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final inv = investment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (inv.phases != null && inv.phases!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const LhotseSectionLabel(label: 'TIEMPOS DEL PROYECTO'),
          const SizedBox(height: AppSpacing.lg),
          _InvestmentTimeline(
            phases: inv.phases!,
            currentIndex: inv.currentPhaseIndex ?? 0,
          ),
        ],
        if (inv.progressImages?.isNotEmpty ?? false) ...[
          const SizedBox(height: AppSpacing.xxl),
          _GallerySectionHeader(
            label: 'AVANCE DE OBRA',
            images: inv.progressImages!,
            title: 'AVANCE DE OBRA',
          ),
          const SizedBox(height: AppSpacing.md),
          _InvestmentGallery(
            renderImages: inv.progressImages!.length > _kMaxVisibleGallery
                ? inv.progressImages!.sublist(0, _kMaxVisibleGallery)
                : inv.progressImages!,
            progressImages: const [],
            videoThumbnailUrl: inv.videoThumbnailUrl,
            selectedTab: 0,
            onTabChanged: (_) {},
            cardWidth: cardWidth,
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        const LhotseSectionLabel(label: 'NOTICIAS DEL PROYECTO'),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg),
            itemCount: _mockNews.length > _kMaxVisibleNews
                ? _kMaxVisibleNews + 1
                : _mockNews.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              if (i == _kMaxVisibleNews &&
                  _mockNews.length > _kMaxVisibleNews) {
                return _SeeAllNewsCard(
                  count: _mockNews.length,
                  onTap: () => _showAllNews(context),
                );
              }
              return LhotseNewsCard.compact(
                title: _mockNews[i].title,
                imageUrl: _mockNews[i].imageUrl,
                subtitle: _mockNews[i].date,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// TAB: PROYECTO — static reference, what the property IS
// ===========================================================================

class _ProyectoTab extends StatelessWidget {
  const _ProyectoTab({
    required this.investment,
    required this.cardWidth,
  });

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
          _PremiumExpandableTile(
            label: 'INFORMACIÓN DEL ACTIVO',
            entries: inv.assetInfo!.entries,
          ),
        ],
        if (inv.floorPlanUrl != null) ...[
          const SizedBox(height: AppSpacing.xxl),
          const LhotseSectionLabel(label: 'PLANO DEL INMUEBLE'),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GestureDetector(
              onTap: () => _showFloorPlan(context, inv.floorPlanUrl!),
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
                      child: Icon(
                        LucideIcons.maximize2,
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
          _GallerySectionHeader(
            label: 'RENDERS',
            images: inv.renderImages!,
            title: 'RENDERS',
          ),
          const SizedBox(height: AppSpacing.md),
          _InvestmentGallery(
            renderImages: inv.renderImages!.length > _kMaxVisibleGallery
                ? inv.renderImages!.sublist(0, _kMaxVisibleGallery)
                : inv.renderImages!,
            progressImages: const [],
            videoThumbnailUrl: null,
            selectedTab: 0,
            onTabChanged: (_) {},
            cardWidth: cardWidth,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Gallery section header with ↗ action
// ---------------------------------------------------------------------------

class _GallerySectionHeader extends StatelessWidget {
  const _GallerySectionHeader({
    required this.label,
    required this.images,
    required this.title,
  });

  final String label;
  final List<String> images;
  final String title;

  @override
  Widget build(BuildContext context) {
    final hasMore = images.length > _kMaxVisibleGallery;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.accentMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          if (hasMore) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () => _showAllGallery(context, title, images),
              child: const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.arrowUpRight,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

void _showAllGallery(
    BuildContext context, String title, List<String> images) {
  showLhotseBottomSheet(
    context: context,
    title: title,
    itemCount: images.length,
    estimatedItemHeight: 160,
    listPadding: EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      MediaQuery.of(context).padding.bottom + AppSpacing.md,
    ),
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
    itemBuilder: (context, i) => GestureDetector(
      onTap: () => _showFullImage(context, images[i]),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              images[i],
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: AppColors.surface),
            ),
            Positioned(
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: Icon(
                LucideIcons.maximize2,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showFullImage(BuildContext context, String imageUrl) {
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
                            0,
                            topPadding + kToolbarHeight,
                            0,
                            bottomPadding + AppSpacing.lg,
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                Container(color: AppColors.surface),
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
                          child: const Icon(
                            LucideIcons.x,
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
                    // Image fills everything edge-to-edge
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
                    // Close button — respects safe area
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
                          child: Icon(
                            LucideIcons.x,
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
// TAB: DOCUMENTOS
// ===========================================================================

class _DocumentosTab extends StatelessWidget {
  const _DocumentosTab({required this.investment});
  final InvestmentData investment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        LhotseDocumentsSection(
          documents: _investmentDocs,
          maxVisible: _investmentDocs.length,
          filterLabels: const {
            DocCategory.legal: 'Legal',
            DocCategory.financiero: 'Financiero',
            DocCategory.obra: 'Obra',
            DocCategory.fiscal: 'Fiscal',
          },
        ),
      ],
    );
  }
}

// ===========================================================================
// Scenario panel
// ===========================================================================

class _ScenarioPanel extends StatelessWidget {
  const _ScenarioPanel({
    required this.scenarios,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ProfitScenario> scenarios;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: scenarios.indexed.map((entry) {
                final i = entry.$1;
                final s = entry.$2;
                final isSelected = i == selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelected(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      child: Center(
                        child: Text(
                          s.label,
                          style: AppTypography.labelLarge.copyWith(
                            color: isSelected
                                ? AppColors.textOnDark
                                : AppColors.accentMuted,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _ScenarioData(
              key: ValueKey(selectedIndex),
              scenario: scenarios[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioData extends StatelessWidget {
  const _ScenarioData({super.key, required this.scenario});
  final ProfitScenario scenario;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ScenarioRow(
          left: _ScenarioMetric(
            value: '${scenario.roiProject.toStringAsFixed(2)}%',
            label: 'ROI proyecto',
          ),
          right: _ScenarioMetric(
            value: '${scenario.roiInvestor.toStringAsFixed(2)}%',
            label: 'ROI inversor',
          ),
        ),
        _scenarioDivider(),
        _ScenarioRow(
          left: _ScenarioMetric(
            value: '${scenario.tirAnnualized.toStringAsFixed(2)}%',
            label: 'TIR anualizada',
          ),
          right: _ScenarioMetric(
            value: '${scenario.durationMonths} meses',
            label: 'Tiempo del proyecto',
          ),
        ),
        _scenarioDivider(),
        _ScenarioRow(
          left: _ScenarioMetric(
            value: '${_eurFormat.format(scenario.estimatedSalePrice)}€',
            label: 'Precio venta estimado',
          ),
          right: _ScenarioMetric(
            value: '${_eurFormat.format(scenario.netProfit)}€',
            label: 'Beneficio neto',
          ),
        ),
      ],
    );
  }

  Widget _scenarioDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Container(
          height: 0.5,
          color: AppColors.textPrimary.withValues(alpha: 0.10),
        ),
      );
}

class _ScenarioRow extends StatelessWidget {
  const _ScenarioRow({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Expanded(child: left), Expanded(child: right)],
    );
  }
}

class _ScenarioMetric extends StatelessWidget {
  const _ScenarioMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.headingSmall.copyWith(
            color: AppColors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.accentMuted,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Timeline
// ===========================================================================

class _InvestmentTimeline extends StatelessWidget {
  const _InvestmentTimeline({
    required this.phases,
    required this.currentIndex,
  });

  final List<ProjectPhase> phases;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: phases.indexed.map((entry) {
              final i = entry.$1;
              final isCurrent = i == currentIndex;
              final isPast = i < currentIndex;
              final isFuture = i > currentIndex;
              return Expanded(
                child: Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: isPast || isCurrent
                              ? AppColors.primary
                              : AppColors.textPrimary
                                  .withValues(alpha: 0.10),
                        ),
                      ),
                    isCurrent
                        ? _PulsingNode(size: 10)
                        : Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isFuture
                                  ? Colors.transparent
                                  : AppColors.primary,
                              border: isFuture
                                  ? Border.all(
                                      color: AppColors.textPrimary
                                          .withValues(alpha: 0.3),
                                      width: 1.5)
                                  : null,
                            ),
                          ),
                    if (i < phases.length - 1)
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: isPast
                              ? AppColors.primary
                              : AppColors.textPrimary
                                  .withValues(alpha: 0.10),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: phases.indexed.map((entry) {
              final i = entry.$1;
              final phase = entry.$2;
              final isCurrent = i == currentIndex;
              final month =
                  DateFormat('MM/yy').format(phase.startDate);
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      phase.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: (isCurrent
                              ? AppTypography.labelLarge
                              : AppTypography.caption)
                          .copyWith(
                        color: isCurrent
                            ? AppColors.textPrimary
                            : AppColors.accentMuted,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w400,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (isCurrent && phase.title != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        phase.title!,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      month.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PulsingNode extends StatefulWidget {
  const _PulsingNode({required this.size});
  final double size;
  @override
  State<_PulsingNode> createState() => _PulsingNodeState();
}

class _PulsingNodeState extends State<_PulsingNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ===========================================================================
// Gallery
// ===========================================================================

class _InvestmentGallery extends StatelessWidget {
  const _InvestmentGallery({
    required this.renderImages,
    required this.progressImages,
    this.videoThumbnailUrl,
    required this.selectedTab,
    required this.onTabChanged,
    required this.cardWidth,
  });

  final List<String> renderImages;
  final List<String> progressImages;
  final String? videoThumbnailUrl;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final images = selectedTab == 0 ? renderImages : progressImages;
    final hasRenders = renderImages.isNotEmpty;
    final hasProgress = progressImages.isNotEmpty;
    final totalItems = images.length +
        (videoThumbnailUrl != null && selectedTab == 1 ? 1 : 0);

    return Column(
      children: [
        if (hasRenders && hasProgress)
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.md),
            child: Row(
              children: [
                _ChipTab(
                  label: 'RENDERS',
                  isActive: selectedTab == 0,
                  onTap: () => onTabChanged(0),
                ),
                const SizedBox(width: AppSpacing.sm),
                _ChipTab(
                  label: 'AVANCE OBRA',
                  isActive: selectedTab == 1,
                  onTap: () => onTabChanged(1),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: totalItems,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              if (i == images.length && videoThumbnailUrl != null) {
                return _GalleryCard(
                    width: cardWidth,
                    imageUrl: videoThumbnailUrl!,
                    isVideo: true);
              }
              return _GalleryCard(
                  width: cardWidth, imageUrl: images[i]);
            },
          ),
        ),
      ],
    );
  }
}

class _ChipTab extends StatelessWidget {
  const _ChipTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : AppColors.textPrimary.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isActive
                ? AppColors.textOnDark
                : AppColors.accentMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({
    required this.width,
    required this.imageUrl,
    this.isVideo = false,
  });
  final double width;
  final String imageUrl;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: AppColors.surface)),
          if (isVideo)
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  border:
                      Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(LucideIcons.play,
                    color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Premium expandable tile
// ===========================================================================

class _PremiumExpandableTile extends StatefulWidget {
  const _PremiumExpandableTile({
    required this.label,
    required this.entries,
    this.highlightLast = false,
    this.collapsedPreview,
  });
  final String label;
  final List<AssetInfoEntry> entries;
  final bool highlightLast;
  final String? collapsedPreview;

  @override
  State<_PremiumExpandableTile> createState() =>
      _PremiumExpandableTileState();
}

class _PremiumExpandableTileState extends State<_PremiumExpandableTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animController.forward() : _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  Text(widget.label,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.accentMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      )),
                  const Spacer(),
                  if (widget.collapsedPreview != null && !_expanded)
                    Padding(
                      padding: const EdgeInsets.only(
                          right: AppSpacing.sm),
                      child: Text(widget.collapsedPreview!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Icon(LucideIcons.chevronDown,
                        size: 16, color: AppColors.accentMuted),
                  ),
                ],
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Column(
                      children:
                          widget.entries.indexed.map((entry) {
                        final i = entry.$1;
                        final e = entry.$2;
                        final isLast =
                            i == widget.entries.length - 1;
                        final isBold =
                            isLast && widget.highlightLast;
                        return Column(children: [
                          if (isBold)
                            Container(
                                height: 1,
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.2))
                          else if (i > 0)
                            Container(
                                height: 0.5,
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.08)),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical:
                                    isBold ? 14.0 : 10.0),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                Flexible(
                                    child: Text(e.label,
                                        style: AppTypography
                                            .bodySmall
                                            .copyWith(
                                          color: AppColors
                                              .accentMuted,
                                          fontWeight: isBold
                                              ? FontWeight
                                                  .w700
                                              : FontWeight
                                                  .w400,
                                        ))),
                                Text(e.value,
                                    style: AppTypography
                                        .bodyMedium
                                        .copyWith(
                                      color: AppColors
                                          .textPrimary,
                                      fontWeight: isBold
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    )),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Container(
              height: 0.5,
              color:
                  AppColors.textPrimary.withValues(alpha: 0.08)),
        ],
      ),
    );
  }
}

// ===========================================================================
// See all news
// ===========================================================================

class _SeeAllNewsCard extends StatelessWidget {
  const _SeeAllNewsCard({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        height: 160,
        child: Container(
          color: AppColors.primary,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('VER TODAS',
                    style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text('$count noticias',
                    style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 1.0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showAllNews(BuildContext context) {
  showLhotseBottomSheet(
    context: context,
    title: 'NOTICIAS',
    itemCount: _mockNews.length,
    estimatedItemHeight: 84,
    itemBuilder: (context, i) {
      final news = _mockNews[i];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
                width: 56,
                height: 56,
                child: Image.network(news.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(color: AppColors.surface))),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(news.title,
                      style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(news.date,
                      style: AppTypography.caption.copyWith(
                          color: AppColors.accentMuted,
                          letterSpacing: 1.0)),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ===========================================================================
// Mock data
// ===========================================================================

const _kNewsImages = [
  'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600&q=80',
  'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=600&q=80',
  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&q=80',
];

final _mockNews = [
  (title: 'Inicio de la fase 3', date: '12 MAR. 2026', imageUrl: _kNewsImages[0]),
  (title: 'Informe trimestral Q1', date: '28 FEB. 2026', imageUrl: _kNewsImages[1]),
  (title: 'Licencia urbanística aprobada', date: '15 ENE. 2026', imageUrl: _kNewsImages[2]),
  (title: 'Avance de obra: estructura completada', date: '20 DIC. 2025', imageUrl: _kNewsImages[0]),
  (title: 'Firma del contrato con constructora', date: '15 NOV. 2025', imageUrl: _kNewsImages[1]),
  (title: 'Presentación del proyecto a inversores', date: '02 OCT. 2025', imageUrl: _kNewsImages[2]),
  (title: 'Adquisición del terreno', date: '10 SEP. 2025', imageUrl: _kNewsImages[0]),
  (title: 'Estudio de viabilidad aprobado', date: '01 AGO. 2025', imageUrl: _kNewsImages[1]),
];

const _kMaxVisibleNews = 3;

final _investmentDocs = [
  LhotseDocument(name: 'Escritura de compraventa', date: '15 MAR. 2026', category: DocCategory.legal),
  LhotseDocument(name: 'Contrato de arras', date: '28 FEB. 2026', category: DocCategory.legal),
  LhotseDocument(name: 'Nota simple registral', date: '10 FEB. 2026', category: DocCategory.legal),
  LhotseDocument(name: 'Certificado fiscal', date: '02 FEB. 2026', category: DocCategory.fiscal),
  LhotseDocument(name: 'Factura notaría', date: '15 ENE. 2026', category: DocCategory.financiero),
  LhotseDocument(name: 'Licencia urbanística', date: '20 DIC. 2025', category: DocCategory.obra),
  LhotseDocument(name: 'Recibo hipoteca Q4', date: '01 DIC. 2025', category: DocCategory.financiero),
  LhotseDocument(name: 'Planos definitivos', date: '15 NOV. 2025', category: DocCategory.obra),
  LhotseDocument(name: 'Poder notarial', date: '01 NOV. 2025', category: DocCategory.legal),
  LhotseDocument(name: 'Informe de tasación', date: '10 OCT. 2025', category: DocCategory.financiero),
];
