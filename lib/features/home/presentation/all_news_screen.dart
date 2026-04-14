import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/mock/mock_news.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_app_header.dart';
import '../../../core/widgets/lhotse_brand_filter_row.dart';
import '../../../core/widgets/lhotse_filter_tab.dart';
import '../../../core/widgets/lhotse_news_card.dart';
import '../../../core/widgets/lhotse_search_field.dart';

enum _ActiveTool { none, firma, region, buscar }

class AllNewsScreen extends StatefulWidget {
  const AllNewsScreen({super.key});

  @override
  State<AllNewsScreen> createState() => _AllNewsScreenState();
}

class _AllNewsScreenState extends State<AllNewsScreen> {
  NewsType? _activeType;
  _ActiveTool _activeTool = _ActiveTool.none;
  final Set<String> _selectedBrands = {};
  final Set<String> _selectedRegions = {};
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NewsItemData> get _filteredNews {
    var news = mockNews;

    if (_activeType != null) {
      news = news.where((n) => n.type == _activeType).toList();
    }

    if (_selectedBrands.isNotEmpty) {
      news = news.where((n) => _selectedBrands.contains(n.brand)).toList();
    }

    if (_selectedRegions.isNotEmpty) {
      news = news.where((n) => _selectedRegions.contains(n.region)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      news = news
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.brand.toLowerCase().contains(q) ||
              n.subtitle.toLowerCase().contains(q))
          .toList();
    }

    return news;
  }

  void _toggleType(NewsType type) {
    setState(() {
      _activeType = _activeType == type ? null : type;
    });
  }

  void _toggleTool(_ActiveTool tool) {
    setState(() {
      if (_activeTool == tool) {
        _activeTool = _ActiveTool.none;
      } else {
        _activeTool = tool;
        if (tool == _ActiveTool.buscar) {
          _selectedBrands.clear();
          _selectedRegions.clear();
        } else {
          _searchQuery = '';
          _searchController.clear();
        }
      }
    });
  }

  void _toggleBrand(String brand) {
    setState(() {
      if (_selectedBrands.contains(brand)) {
        _selectedBrands.remove(brand);
      } else {
        _selectedBrands.add(brand);
      }
    });
  }

  void _toggleRegion(String region) {
    setState(() {
      if (_selectedRegions.contains(region)) {
        _selectedRegions.remove(region);
      } else {
        _selectedRegions.add(region);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final news = _filteredNews;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const LhotseAppHeader(title: 'NOTICIAS'),

          // Filter bar — type tabs left, tool icons right
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Content type tabs
                LhotseFilterTab(
                  label: 'PROYECTOS',
                  isActive: _activeType == NewsType.project,
                  onTap: () => _toggleType(NewsType.project),
                ),
                const SizedBox(width: AppSpacing.lg),
                LhotseFilterTab(
                  label: 'PRENSA',
                  isActive: _activeType == NewsType.press,
                  onTap: () => _toggleType(NewsType.press),
                ),

                const Spacer(),

                // Tool icons
                Container(width: 1, height: 16, color: AppColors.border),
                const SizedBox(width: AppSpacing.md),

                // Firma
                GestureDetector(
                  onTap: () => _toggleTool(_ActiveTool.firma),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: PhosphorIcon(
                            PhosphorIconsThin.stack,
                            size: 18,
                            color: _activeTool == _ActiveTool.firma ||
                                    _selectedBrands.isNotEmpty
                                ? AppColors.textPrimary
                                : AppColors.accentMuted,
                          ),
                        ),
                        if (_selectedBrands.isNotEmpty)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.textPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Región
                GestureDetector(
                  onTap: () => _toggleTool(_ActiveTool.region),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: PhosphorIcon(
                            PhosphorIconsThin.mapPin,
                            size: 18,
                            color: _activeTool == _ActiveTool.region ||
                                    _selectedRegions.isNotEmpty
                                ? AppColors.textPrimary
                                : AppColors.accentMuted,
                          ),
                        ),
                        if (_selectedRegions.isNotEmpty)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.textPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Buscar
                GestureDetector(
                  onTap: () => _toggleTool(_ActiveTool.buscar),
                  child: PhosphorIcon(
                    PhosphorIconsThin.magnifyingGlass,
                    size: 18,
                    color: _activeTool == _ActiveTool.buscar
                        ? AppColors.textPrimary
                        : AppColors.accentMuted,
                  ),
                ),
              ],
            ),
          ),

          // Tool panels
          if (_activeTool == _ActiveTool.buscar)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: LhotseSearchField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _searchQuery = v),
                onClose: () => _toggleTool(_ActiveTool.buscar),
              ),
            )
          else if (_activeTool == _ActiveTool.firma)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: LhotseBrandFilterRow(
                selectedBrands: _selectedBrands,
                onBrandTap: _toggleBrand,
                onClear: () => setState(() => _selectedBrands.clear()),
              ),
            )
          else if (_activeTool == _ActiveTool.region)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _RegionFilterRow(
                regions: newsRegions,
                selectedRegions: _selectedRegions,
                onTap: _toggleRegion,
                onClear: () => setState(() => _selectedRegions.clear()),
              ),
            ),

          // News list
          Expanded(
            child: news.isEmpty
                ? Center(
                    child: Text(
                      'SIN RESULTADOS',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: news.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) {
                      final item = news[i];
                      return LhotseNewsCard(
                        title: item.title,
                        imageUrl: item.imageUrl,
                        brand: item.brand,
                        subtitle: item.subtitle,
                        hasPlayButton: item.hasPlayButton,
                        onTap: () => context.push('/news/${item.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Region filter row — flag emoji + country name, equal-width cells
// ---------------------------------------------------------------------------

class _RegionFilterRow extends StatelessWidget {
  const _RegionFilterRow({
    required this.regions,
    required this.selectedRegions,
    required this.onTap,
    required this.onClear,
  });

  final List<String> regions;
  final Set<String> selectedRegions;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;

  static const _regionFlags = {
    'España': '🇪🇸',
    'México': '🇲🇽',
    'EE.UU.': '🇺🇸',
    'Portugal': '🇵🇹',
    'EAU': '🇦🇪',
  };

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedRegions.isNotEmpty;

    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            ...regions.map((region) {
              final isSelected = selectedRegions.contains(region);
              final double opacity =
                  hasSelection ? (isSelected ? 1.0 : 0.35) : 0.6;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(region),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: opacity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 32,
                          child: Center(
                            child: Text(
                              _regionFlags[region] ?? '📍',
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          region.toUpperCase(),
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (hasSelection)
              GestureDetector(
                onTap: onClear,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 32,
                      child: PhosphorIcon(
                        PhosphorIconsThin.x,
                        size: 16,
                        color: AppColors.accentMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'LIMPIAR',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
