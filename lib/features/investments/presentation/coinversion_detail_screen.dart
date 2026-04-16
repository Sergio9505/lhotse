import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/document_categories_provider.dart';
import '../../../core/data/documents_provider.dart';
import '../../../core/domain/document_category_data.dart';
import '../../../core/data/news_provider.dart';
import '../../../core/domain/document_data.dart';
import '../../../core/domain/asset_info.dart';
import '../../../core/domain/news_item_data.dart';
import '../../../core/domain/profit_scenario.dart';
import '../../../core/domain/project_phase.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_tab_bar_delegate.dart';
import '../../../core/widgets/lhotse_gallery_helpers.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_doc_row.dart';
import '../../../core/widgets/lhotse_key_value_list.dart';
import '../../../core/widgets/lhotse_documents_section.dart';
import '../../../core/widgets/lhotse_news_card.dart';
import '../../../core/widgets/lhotse_section_label.dart';
import '../data/investments_provider.dart';
import '../domain/coinvestment_contract_data.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');

// ---------------------------------------------------------------------------
// Coinversion Detail — NestedScrollView + TabBarView
// Hero full-bleed behind toolbar (Zara), data-first tabs (Revolut)
// headerSliverBuilder: SliverAppBar (hero) → identity (scrolls) → tabs (pin)
// ---------------------------------------------------------------------------

const _kHeroHeight = 200.0;
const _kMaxVisibleGallery = 5;


class CoinversionDetailScreen extends ConsumerStatefulWidget {
  const CoinversionDetailScreen({
    super.key,
    required this.contract,
  });

  final CoinvestmentContractData contract;

  @override
  ConsumerState<CoinversionDetailScreen> createState() =>
      _CoinversionDetailScreenState();
}

class _CoinversionDetailScreenState
    extends ConsumerState<CoinversionDetailScreen>
    with SingleTickerProviderStateMixin {
  final _outerController = ScrollController();
  late final TabController _tabController;
  bool _heroGone = false;
  bool _showCollapsedTitle = false;
  int _selectedScenario = 1; // P50
  int _tabIndex = 0;

  // Doc filter state (lives here so the pinned header can access it)
  final Set<String> _activeDocFilters = {};

  List<LhotseDocument> _toLhotseDocuments(
      List<DocumentData> docs, List<DocumentCategoryData> allCategories) {
    final iconMap = {for (var c in allCategories) c.key: c.iconName};
    return docs
        .map((d) => d.toLhotseDocument(iconName: iconMap[d.category] ?? 'fileText'))
        .toList();
  }

  List<LhotseDocument> _filteredDocs(
      List<DocumentData> docs, List<DocumentCategoryData> allCategories) {
    final all = _toLhotseDocuments(docs, allCategories);
    if (_activeDocFilters.isEmpty) return all;
    return all.where((d) => _activeDocFilters.contains(d.categoryKey)).toList();
  }

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
    _tabController = TabController(length: 4, vsync: this)
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
    final c = widget.contract;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Load sub-data from Supabase
    final scenarios = ref
        .watch(projectScenariosProvider(c.projectId))
        .valueOrNull ?? const [];
    final phases = ref
        .watch(projectPhasesProvider(c.projectId))
        .valueOrNull ?? const [];
    final relatedNews = (ref.watch(newsProvider).valueOrNull ?? const [])
        .where((n) => n.brand == c.brandName)
        .take(4)
        .toList();

    final projectLocation = c.projectLocation;
    final projectImageUrl = c.projectImageUrl;
    // inv alias for fields used in collapsed title (same type now)
    final inv = c;
    final docs = ref
        .watch(documentsProvider((type: 'coinvestment', id: c.id)))
        .valueOrNull ?? const [];
    final allCategories =
        ref.watch(allDocumentCategoriesProvider).valueOrNull ?? const [];
    final filterCategories =
        categoriesForKeys(docs.map((d) => d.category), allCategories);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _heroGone ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
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
                      LhotseImage(projectImageUrl ?? ''),
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
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.8,
                            ),
                          ),
                          if (projectLocation != null) ...[
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
                                projectLocation.toUpperCase(),
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
                delegate: LhotseTabBarDelegate(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'AVANCE'),
                    Tab(text: 'ACTIVO'),
                    Tab(text: 'FINANZAS'),
                    Tab(text: 'DOCS'),
                  ],
                ),
              ),
            ],

            // ===========================================================
            // TAB CONTENT — each tab scrolls independently
            // ===========================================================
            body: TabBarView(
              controller: _tabController,
              children: [
                _TabScrollWrapper(
                  child: _AvanceTab(
                    phases: phases,
                    currentPhaseIndex: c.currentPhaseIndex ?? 0,
                    progressImages: c.progressImages,
                    videoThumbnailUrl: c.videoThumbnailUrl,
                    news: relatedNews,
                    cardWidth: screenWidth * 0.75,
                  ),
                  bottomPadding: bottomPadding,
                ),
                _TabScrollWrapper(
                  child: _ProyectoTab(
                    floorPlanUrl: c.assetFloorPlanUrl,
                    renderImages: c.renderImages,
                    cardWidth: screenWidth * 0.75,
                  ),
                  bottomPadding: bottomPadding,
                ),
                _TabScrollWrapper(
                  child: _FinancieroTab(
                    economicAnalysis: c.economicAnalysis,
                    scenarios: scenarios,
                    selectedScenario: _selectedScenario,
                    onScenarioSelected: (i) =>
                        setState(() => _selectedScenario = i),
                  ),
                  bottomPadding: bottomPadding,
                ),
                _TabScrollWrapper(
                  child: _DocumentosTab(
                    documents: _filteredDocs(docs, allCategories),
                    chips: _buildDocChips(filterCategories),
                  ),
                  bottomPadding: bottomPadding,
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildDocChips(List<DocumentCategoryData> categories) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...categories.map((cat) {
              final active = _activeDocFilters.contains(cat.key);
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => _toggleDocFilter(cat.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: active
                            ? AppColors.primary
                            : AppColors.textPrimary
                                .withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      cat.label.toUpperCase(),
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
                  child: PhosphorIcon(
                    PhosphorIconsThin.x,
                    size: 14,
                    color: AppColors.accentMuted,
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

// (Tab bar delegate extracted to core/widgets/lhotse_tab_bar_delegate.dart)


// ===========================================================================
// TAB: FINANCIERO
// ===========================================================================

class _FinancieroTab extends StatelessWidget {
  const _FinancieroTab({
    required this.economicAnalysis,
    required this.scenarios,
    required this.selectedScenario,
    required this.onScenarioSelected,
  });

  final List<AssetInfoEntry>? economicAnalysis;
  final List<ProfitScenario> scenarios;
  final int selectedScenario;
  final ValueChanged<int> onScenarioSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (economicAnalysis != null && economicAnalysis!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const LhotseSectionLabel(label: 'ANÁLISIS ECONÓMICO'),
          const SizedBox(height: AppSpacing.sm),
          LhotseKeyValueList(entries: economicAnalysis!, highlightLast: true),
        ],
        if (scenarios.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          const LhotseSectionLabel(label: 'ESCENARIOS'),
          const SizedBox(height: AppSpacing.md),
          _ScenarioPanel(
            scenarios: scenarios,
            selectedIndex: selectedScenario,
            onSelected: onScenarioSelected,
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
    required this.phases,
    required this.currentPhaseIndex,
    required this.progressImages,
    required this.videoThumbnailUrl,
    required this.news,
    required this.cardWidth,
  });

  final List<ProjectPhase> phases;
  final int currentPhaseIndex;
  final List<String> progressImages;
  final String? videoThumbnailUrl;
  final List<NewsItemData> news;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (phases.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const LhotseSectionLabel(label: 'TIEMPOS DEL PROYECTO'),
          const SizedBox(height: AppSpacing.lg),
          _InvestmentTimeline(phases: phases, currentIndex: currentPhaseIndex),
        ],
        if (progressImages.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          _GallerySectionHeader(
            label: 'AVANCE DE OBRA',
            images: progressImages,
            title: 'AVANCE DE OBRA',
          ),
          const SizedBox(height: AppSpacing.md),
          _InvestmentGallery(
            renderImages: progressImages.length > _kMaxVisibleGallery
                ? progressImages.sublist(0, _kMaxVisibleGallery)
                : progressImages,
            progressImages: const [],
            videoThumbnailUrl: videoThumbnailUrl,
            selectedTab: 0,
            onTabChanged: (_) {},
            cardWidth: cardWidth,
          ),
        ],
        if (news.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xxl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'NOTICIAS DEL PROYECTO',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.accentMuted,
              letterSpacing: 1.8,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: news.length > _kMaxVisibleNews
                ? _kMaxVisibleNews
                : news.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) => LhotseNewsCard.compact(
              title: news[i].title,
              imageUrl: news[i].imageUrl,
              subtitle: DateFormat('d MMM').format(news[i].date),
              onTap: () => context.push('/news/${news[i].id}'),
            ),
          ),
        ),
        ],
      ],
    );
  }
}

// ===========================================================================
// TAB: PROYECTO — static reference, what the property IS
// ===========================================================================

class _ProyectoTab extends StatelessWidget {
  const _ProyectoTab({
    required this.floorPlanUrl,
    required this.renderImages,
    required this.cardWidth,
  });

  final String? floorPlanUrl;
  final List<String> renderImages;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (floorPlanUrl != null) ...[
          const SizedBox(height: AppSpacing.xxl),
          const LhotseSectionLabel(label: 'PLANO DEL INMUEBLE'),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GestureDetector(
              onTap: () => _showFloorPlan(context, floorPlanUrl!),
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
        if (renderImages.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          _GallerySectionHeader(
            label: 'RENDERS',
            images: renderImages,
            title: 'RENDERS',
          ),
          const SizedBox(height: AppSpacing.md),
          _InvestmentGallery(
            renderImages: renderImages.length > _kMaxVisibleGallery
                ? renderImages.sublist(0, _kMaxVisibleGallery)
                : renderImages,
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
              letterSpacing: 1.8,
            ),
          ),
          if (hasMore) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () => showAllGallery(context, title, images),
              child: const PhosphorIcon(
                PhosphorIconsThin.arrowUpRight,
                size: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
// TAB: DOCUMENTOS
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
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                    ),
                  LhotseDocRow(
                    name: doc.name,
                    date: doc.date,
                    icon: docCategoryIconByKey(doc.iconName),
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
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: right),
      ],
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
          // --- Track: single row, perfectly aligned ---
          SizedBox(
            height: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int i = 0; i < phases.length; i++) ...[
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i <= currentIndex
                            ? AppColors.primary
                            : AppColors.textPrimary
                                .withValues(alpha: 0.08),
                      ),
                    ),
                  if (i == currentIndex)
                    _PulsingNode(size: 10)
                  else
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i < currentIndex
                            ? AppColors.primary
                            : Colors.transparent,
                        border: i > currentIndex
                            ? Border.all(
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.15),
                                width: 1.5)
                            : null,
                      ),
                    ),
                ],
              ],
            ),
          ),
          // --- Labels ---
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: phases.indexed.map((entry) {
              final i = entry.$1;
              final phase = entry.$2;
              final isCurrent = i == currentIndex;
              final isPast = i < currentIndex;
              final month =
                  DateFormat('MM/yy').format(phase.startDate).toUpperCase();
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      phase.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: isCurrent
                            ? AppColors.textPrimary
                            : isPast
                                ? AppColors.accentMuted
                                : AppColors.textPrimary
                                    .withValues(alpha: 0.25),
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
                          color: AppColors.accentMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      month,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: isCurrent
                            ? AppColors.accentMuted
                            : AppColors.textPrimary
                                .withValues(alpha: 0.2),
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
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.4).animate(
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
    return SizedBox(
      width: widget.size + 8,
      height: widget.size + 8,
      child: Center(
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) => Transform.scale(
            scale: _scale.value,
            child: child,
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            color: AppColors.primary,
          ),
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
            fontWeight: FontWeight.w500,
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
    return GestureDetector(
      onTap: isVideo ? null : () => showFullImage(context, imageUrl),
      child: Container(
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
            LhotseImage(imageUrl),
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
                child: const PhosphorIcon(PhosphorIconsThin.play,
                    color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
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
  });
  final String label;
  final List<AssetInfoEntry> entries;

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
                        letterSpacing: 1.8,
                      )),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: PhosphorIcon(PhosphorIconsThin.caretDown,
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
                        return Column(children: [
                          if (i > 0)
                            Container(
                                height: 0.5,
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.08)),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical:
                                    10.0),
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
                                          fontWeight: FontWeight.w400,
                                        ))),
                                Text(e.value,
                                    style: AppTypography
                                        .bodyMedium
                                        .copyWith(
                                      color: AppColors
                                          .textPrimary,
                                      fontWeight: FontWeight.w500,
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

// _showAllNews removed — news is now passed as a parameter from the parent widget

const _kMaxVisibleNews = 3;

// Documents loaded from Supabase via documentsProvider
