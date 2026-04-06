import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/data/mock/mock_investments.dart';
import '../../../core/data/mock/mock_projects.dart';
import '../../../core/domain/asset_info.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/domain/investment_data.dart';
import '../../../core/domain/profit_scenario.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/domain/project_phase.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_app_header.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_documents_section.dart';
import '../../../core/widgets/lhotse_bottom_sheet.dart';
import '../../../core/widgets/lhotse_news_card.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');
final _dateFormat = DateFormat('MM/yyyy');

class InvestmentDetailScreen extends StatelessWidget {
  const InvestmentDetailScreen({super.key, required this.investmentId});

  final String investmentId;

  @override
  Widget build(BuildContext context) {
    final investment =
        mockInvestments.where((i) => i.id == investmentId).firstOrNull;

    if (investment == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Inversión no encontrada',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final brand =
        mockBrands.where((b) => b.name == investment.brandName).firstOrNull;
    final model = brand?.businessModel ?? BusinessModel.coinversion;

    // Coinversion gets its own full layout with hero image
    if (model == BusinessModel.coinversion) {
      return _CoinversionDetailScreen(
        investment: investment,
        project: findProjectById(investment.projectId),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          LhotseAppHeader(
            title: investment.projectName.toUpperCase(),
            subtitle: model != BusinessModel.rentaFija
                ? findProjectById(investment.projectId)
                    ?.location
                    .toUpperCase()
                : null,
          ),

          const SizedBox(height: AppSpacing.md),

          // Model-specific content
          switch (model) {
            BusinessModel.compraDirecta =>
              _CompraDirectaDetail(investment: investment),
            BusinessModel.coinversion =>
              const SizedBox.shrink(), // handled above
            BusinessModel.rentaFija =>
              _RentaFijaDetail(investment: investment),
          },

          const SizedBox(height: AppSpacing.xl),

          // Documents
          _SectionLabel(label: 'DOCUMENTOS'),
          const SizedBox(height: AppSpacing.sm),
          LhotseDocumentsSection(
            documents: _investmentDocs,
            filterLabels: const {
              DocCategory.legal: 'Legal',
              DocCategory.financiero: 'Financiero',
              DocCategory.obra: 'Obra',
              DocCategory.fiscal: 'Fiscal',
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // News — horizontal scroll
          _SectionLabel(label: 'NOTICIAS DEL PROYECTO'),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _mockNews.length > _kMaxVisibleNews
                  ? _kMaxVisibleNews + 1
                  : _mockNews.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                if (i == _kMaxVisibleNews && _mockNews.length > _kMaxVisibleNews) {
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

          const SizedBox(height: AppSpacing.xl),

          // View project button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GestureDetector(
              onTap: () =>
                  context.push('/projects/${investment.projectId}'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: AppColors.primary,
                child: Center(
                  child: Text(
                    'VER PROYECTO',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textOnDark,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(
              height: MediaQuery.of(context).padding.bottom + AppSpacing.xl),
        ],
      ),
    );
  }
}

// ===========================================================================
// COINVERSION DETAIL — Full screen with hero image
// ===========================================================================

class _CoinversionDetailScreen extends StatefulWidget {
  const _CoinversionDetailScreen({
    required this.investment,
    this.project,
  });

  final InvestmentData investment;
  final ProjectData? project;

  @override
  State<_CoinversionDetailScreen> createState() =>
      _CoinversionDetailScreenState();
}

class _CoinversionDetailScreenState extends State<_CoinversionDetailScreen> {
  late final ScrollController _scrollController;
  bool _isCollapsed = false;
  int _selectedScenario = 1; // P50 by default
  int _galleryTab = 0; // 0 = renders, 1 = obra

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final expandedHeight = MediaQuery.of(context).size.height * 0.40;
    final collapsedHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    final threshold = expandedHeight - collapsedHeight - 40;
    final collapsed = _scrollController.offset >= threshold;
    if (collapsed != _isCollapsed) {
      setState(() => _isCollapsed = collapsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.investment;
    final project = widget.project;
    final screenHeight = MediaQuery.of(context).size.height;
    final expandedHeight = screenHeight * 0.40;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isCollapsed
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Hero image
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: expandedHeight,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: _isCollapsed ? 0.5 : 0,
              leading: _isCollapsed
                  ? const LhotseBackButton.onSurface()
                  : const LhotseBackButton.onImage(),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: SvgPicture.asset(
                    'assets/images/lhotse_logo.svg',
                    width: 20,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      _isCollapsed ? AppColors.primary : Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
              title: AnimatedOpacity(
                opacity: _isCollapsed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  inv.projectName.toUpperCase(),
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
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
                    // Gradient overlays
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
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [Color(0x99000000), Colors.transparent],
                        ),
                      ),
                    ),
                    // Overlay content
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (project?.location != null)
                            Text(
                              project!.location.toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 1.5,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            inv.projectName.toUpperCase(),
                            style: AppTypography.headingLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          if (inv.constructionPhase != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              color: inv.isDelayed
                                  ? AppColors.danger
                                  : Colors.white.withValues(alpha: 0.2),
                              child: Text(
                                '${inv.constructionPhase}${inv.isDelayed ? ' · Retrasado' : ''}',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),

                  // Metrics 2×2
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MetricBlock(
                                value: '${_eurFormat.format(inv.amount)}€',
                                label: 'Participación',
                              ),
                            ),
                            Expanded(
                              child: _MetricBlock(
                                value:
                                    '${inv.returnRate.toStringAsFixed(0)}%',
                                label: 'ROI Inversor',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricBlock(
                                value:
                                    '${inv.returnRate.toStringAsFixed(0)}%',
                                label: 'TIR Anualizada',
                              ),
                            ),
                            Expanded(
                              child: _MetricBlock(
                                value: '${inv.durationMonths} meses',
                                label: 'Duración',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Profitability scenarios
                  if (inv.profitScenarios != null &&
                      inv.profitScenarios!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _SectionLabel(label: 'ESCENARIOS DE RENTABILIDAD'),
                    const SizedBox(height: AppSpacing.md),
                    _ScenarioTabs(
                      scenarios: inv.profitScenarios!,
                      selectedIndex: _selectedScenario,
                      onSelected: (i) =>
                          setState(() => _selectedScenario = i),
                    ),
                  ],

                  // Timeline
                  if (inv.phases != null && inv.phases!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _SectionLabel(label: 'TIMELINE'),
                    const SizedBox(height: AppSpacing.lg),
                    _TimelineStepper(
                      phases: inv.phases!,
                      currentIndex: inv.currentPhaseIndex ?? 0,
                    ),
                  ],

                  // Gallery
                  if ((inv.renderImages?.isNotEmpty ?? false) ||
                      (inv.progressImages?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _SectionLabel(label: 'GALERÍA'),
                    const SizedBox(height: AppSpacing.md),
                    _GallerySection(
                      renderImages: inv.renderImages ?? [],
                      progressImages: inv.progressImages ?? [],
                      videoThumbnailUrl: inv.videoThumbnailUrl,
                      selectedTab: _galleryTab,
                      onTabChanged: (i) =>
                          setState(() => _galleryTab = i),
                    ),
                  ],

                  // Info del activo — expandable
                  if (inv.assetInfo != null) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _ExpandableTile(
                      label: 'INFORMACIÓN DEL ACTIVO',
                      entries: inv.assetInfo!.entries,
                    ),
                  ],

                  // Análisis económico — expandable
                  if (inv.economicAnalysis != null &&
                      inv.economicAnalysis!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ExpandableTile(
                      label: 'ANÁLISIS ECONÓMICO',
                      entries: inv.economicAnalysis!,
                    ),
                  ],

                  // Documents
                  const SizedBox(height: AppSpacing.xxl),
                  _SectionLabel(label: 'DOCUMENTOS'),
                  const SizedBox(height: AppSpacing.sm),
                  LhotseDocumentsSection(
                    documents: _investmentDocs,
                    filterLabels: const {
                      DocCategory.legal: 'Legal',
                      DocCategory.financiero: 'Financiero',
                      DocCategory.obra: 'Obra',
                      DocCategory.fiscal: 'Fiscal',
                    },
                  ),

                  // News
                  const SizedBox(height: AppSpacing.xl),
                  _SectionLabel(label: 'NOTICIAS DEL PROYECTO'),
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

                  // View project button
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: GestureDetector(
                      onTap: () => context
                          .push('/projects/${inv.projectId}'),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        color: AppColors.primary,
                        child: Center(
                          child: Text(
                            'VER PROYECTO',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.textOnDark,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: bottomPadding + AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scenario tabs — P90 / P50 / P10
// ---------------------------------------------------------------------------

class _ScenarioTabs extends StatelessWidget {
  const _ScenarioTabs({
    required this.scenarios,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ProfitScenario> scenarios;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scenario = scenarios[selectedIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Tab pills
          Row(
            children: scenarios.indexed.map((entry) {
              final i = entry.$1;
              final s = entry.$2;
              final isSelected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(i),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
          const SizedBox(height: AppSpacing.lg),

          // Scenario data
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  value: '${scenario.roiInvestor.toStringAsFixed(2)}%',
                  label: 'ROI Inversor',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  value: '${scenario.tirAnnualized.toStringAsFixed(2)}%',
                  label: 'TIR Anualizada',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  value: '${_eurFormat.format(scenario.estimatedSalePrice)}€',
                  label: 'Precio venta estimado',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  value: '${_eurFormat.format(scenario.netProfit)}€',
                  label: 'Beneficio neto',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline stepper — node-line
// ---------------------------------------------------------------------------

class _TimelineStepper extends StatelessWidget {
  const _TimelineStepper({
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
          // Line + nodes
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
                              : AppColors.textPrimary.withValues(alpha: 0.15),
                        ),
                      ),
                    Container(
                      width: isCurrent ? 14 : 8,
                      height: isCurrent ? 14 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
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
                              : AppColors.textPrimary.withValues(alpha: 0.15),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Labels + dates
          Row(
            children: phases.indexed.map((entry) {
              final i = entry.$1;
              final phase = entry.$2;
              final isCurrent = i == currentIndex;
              final month = DateFormat('MM/yy')
                  .format(phase.startDate);

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
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w400,
                        letterSpacing: 1.0,
                      ),
                    ),
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

// ---------------------------------------------------------------------------
// Gallery — unified carousel with tabs
// ---------------------------------------------------------------------------

class _GallerySection extends StatelessWidget {
  const _GallerySection({
    required this.renderImages,
    required this.progressImages,
    this.videoThumbnailUrl,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final List<String> renderImages;
  final List<String> progressImages;
  final String? videoThumbnailUrl;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final images = selectedTab == 0 ? renderImages : progressImages;
    final hasRenders = renderImages.isNotEmpty;
    final hasProgress = progressImages.isNotEmpty;

    return Column(
      children: [
        // Tabs
        if (hasRenders && hasProgress)
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.md),
            child: Row(
              children: [
                _GalleryTab(
                  label: 'RENDERS',
                  isActive: selectedTab == 0,
                  onTap: () => onTabChanged(0),
                ),
                const SizedBox(width: AppSpacing.lg),
                _GalleryTab(
                  label: 'AVANCE OBRA',
                  isActive: selectedTab == 1,
                  onTap: () => onTabChanged(1),
                ),
              ],
            ),
          ),

        // Image carousel
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount:
                images.length + (videoThumbnailUrl != null && selectedTab == 1 ? 1 : 0),
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              // Video thumbnail at the end of progress images
              if (i == images.length && videoThumbnailUrl != null) {
                return SizedBox(
                  width: 280,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        videoThumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Container(color: AppColors.surface),
                      ),
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Colors.black.withValues(alpha: 0.5),
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: const Icon(LucideIcons.play,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return SizedBox(
                width: 280,
                child: Image.network(
                  images[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: AppColors.surface),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GalleryTab extends StatelessWidget {
  const _GalleryTab({
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: isActive
                  ? AppColors.textPrimary
                  : AppColors.accentMuted,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: 1.5,
            width: isActive ? 24.0 : 0.0,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expandable tile — info activo, análisis económico
// ---------------------------------------------------------------------------

class _ExpandableTile extends StatefulWidget {
  const _ExpandableTile({
    required this.label,
    required this.entries,
  });

  final String label;
  final List<AssetInfoEntry> entries;

  @override
  State<_ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<_ExpandableTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    widget.label,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.accentMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: AppColors.accentMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: widget.entries.map((e) {
                final isLast = e == widget.entries.last;
                final isBold = isLast &&
                    widget.label.contains('ECONÓMICO');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          e.label,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.accentMuted,
                            fontWeight: isBold
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      Text(
                        e.value,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: isBold
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          Container(
            height: 0.5,
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compra Directa — Andhy, Myttas
// ---------------------------------------------------------------------------

class _CompraDirectaDetail extends StatelessWidget {
  const _CompraDirectaDetail({required this.investment});

  final InvestmentData investment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main metrics — 2x2 grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricBlock(
                      value: investment.purchaseValue != null
                          ? '${_eurFormat.format(investment.purchaseValue)}€'
                          : '—',
                      label: 'Valor de compra',
                    ),
                  ),
                  Expanded(
                    child: _MetricBlock(
                      value: investment.rentalIncome != null
                          ? '${_eurFormat.format(investment.rentalIncome)}€'
                          : '—',
                      label: 'Alquiler mensual',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _MetricBlock(
                      value: '${investment.returnRate.toStringAsFixed(0)}%',
                      label: 'Rentabilidad',
                    ),
                  ),
                  Expanded(
                    child: _MetricBlock(
                      value: investment.revaluation != null
                          ? '${investment.revaluation!.toStringAsFixed(0)}%'
                          : '—',
                      label: 'Revalorización',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Financing section
        if (investment.cashPayment != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel(label: 'FINANCIACIÓN'),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                _DataRow(
                    label: 'Contado',
                    value:
                        '${_eurFormat.format(investment.cashPayment)}€'),
                if (investment.mortgage != null) ...[
                  _DataRow(
                      label: 'Hipoteca',
                      value:
                          '${_eurFormat.format(investment.mortgage)}€'),
                  if (investment.mortgageConditions != null)
                    _DataRow(
                        label: 'Condiciones',
                        value: investment.mortgageConditions!),
                  if (investment.monthlyPayment != null)
                    _DataRow(
                        label: 'Cuota',
                        value:
                            '${_eurFormat.format(investment.monthlyPayment)}€/mes'),
                  if (investment.mortgageEndDate != null)
                    _DataRow(
                        label: 'Finalización',
                        value: _dateFormat
                            .format(investment.mortgageEndDate!)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Coinversión — L&B, Vellte, NUVE, Domorato
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Renta Fija — simplest
// ---------------------------------------------------------------------------

class _RentaFijaDetail extends StatelessWidget {
  const _RentaFijaDetail({required this.investment});

  final InvestmentData investment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  value: '${_eurFormat.format(investment.amount)}€',
                  label: 'Capital invertido',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  value: '${investment.returnRate.toStringAsFixed(1)}%',
                  label: 'Rentabilidad fija',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  value: '${_eurFormat.format(investment.amount * investment.returnRate / 100 * investment.durationMonths / 12)}€',
                  label: 'Rendimiento estimado',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  value: '${investment.durationMonths} meses',
                  label: 'Duración',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  value: investment.expectedEndDate != null
                      ? _dateFormat.format(investment.expectedEndDate!)
                      : '—',
                  label: 'Vencimiento',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  value: investment.paymentFrequency ?? '—',
                  label: 'Frecuencia de pago',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared components
// ---------------------------------------------------------------------------

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.value, required this.label});

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
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 3),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        label,
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.accentMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.accentMuted,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

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


// ---------------------------------------------------------------------------
// Bottom sheet for all news
// ---------------------------------------------------------------------------

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
              child: Image.network(
                news.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: AppColors.surface),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    news.date,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.accentMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// "See all" card for news carousel
// ---------------------------------------------------------------------------

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
                Text(
                  'VER TODAS',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count noticias',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mock news data
// ---------------------------------------------------------------------------

const _kNewsImages = [
  'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600&q=80',
  'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=600&q=80',
  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&q=80',
];

final _mockNews = [
  (
    title: 'Inicio de la fase 3',
    date: '12 MAR. 2026',
    imageUrl: _kNewsImages[0],
  ),
  (
    title: 'Informe trimestral Q1',
    date: '28 FEB. 2026',
    imageUrl: _kNewsImages[1],
  ),
  (
    title: 'Licencia urbanística aprobada',
    date: '15 ENE. 2026',
    imageUrl: _kNewsImages[2],
  ),
  (
    title: 'Avance de obra: estructura completada',
    date: '20 DIC. 2025',
    imageUrl: _kNewsImages[0],
  ),
  (
    title: 'Firma del contrato con constructora',
    date: '15 NOV. 2025',
    imageUrl: _kNewsImages[1],
  ),
  (
    title: 'Presentación del proyecto a inversores',
    date: '02 OCT. 2025',
    imageUrl: _kNewsImages[2],
  ),
  (
    title: 'Adquisición del terreno',
    date: '10 SEP. 2025',
    imageUrl: _kNewsImages[0],
  ),
  (
    title: 'Estudio de viabilidad aprobado',
    date: '01 AGO. 2025',
    imageUrl: _kNewsImages[1],
  ),
];

const _kMaxVisibleNews = 3;
