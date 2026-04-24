import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/data/brands_provider.dart';
import '../../../../core/data/news_provider.dart';
import '../../../../core/domain/news_item_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/search_utils.dart';
import '../../../../core/widgets/lhotse_brand_filter_row.dart';
import '../../../../core/widgets/lhotse_filter_chip.dart';
import '../../../../core/widgets/lhotse_news_card.dart';
import '../../../../core/widgets/lhotse_search_field.dart';
import '../../../../core/widgets/scroll_aware_filter_bar.dart';

enum _ActiveTool { none, firma, region, buscar }

/// Reusable news archive body (filter bar + card list). Hosted today by
/// `AllNewsScreen` (route `/news`) and by the Search tab's idle state as the
/// "ARCHIVO DE NOTICIAS" section.
class NewsArchiveBody extends ConsumerStatefulWidget {
  const NewsArchiveBody({super.key});

  @override
  ConsumerState<NewsArchiveBody> createState() => _NewsArchiveBodyState();
}

class _NewsArchiveBodyState extends ConsumerState<NewsArchiveBody> {
  NewsType? _activeType;
  _ActiveTool _activeTool = _ActiveTool.none;
  final Set<String> _selectedBrands = {};
  final Set<String> _selectedRegions = {};
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<NewsItemData> _applyFilters(List<NewsItemData> news) {
    var result = news;
    if (_activeType != null) {
      result = result.where((n) => n.type == _activeType).toList();
    }
    if (_selectedBrands.isNotEmpty) {
      result = result
          .where((n) => _selectedBrands.contains(n.brand ?? ''))
          .toList();
    }
    if (_selectedRegions.isNotEmpty) {
      result = result
          .where((n) => _selectedRegions.contains(n.region ?? ''))
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = normalizeForSearch(_searchQuery);
      result = result.where((n) {
        final haystack = [
          n.title,
          n.brand,
          n.subtitle,
          n.body,
          n.region,
        ].map(normalizeForSearch).join(' ');
        return haystack.contains(q);
      }).toList();
    }
    return result;
  }

  void _setType(NewsType? type) {
    setState(() => _activeType = type);
  }

  void _toggleTool(_ActiveTool tool) {
    setState(() {
      _activeTool = _activeTool == tool ? _ActiveTool.none : tool;
    });
  }

  void _toggleBrand(String brand) {
    // Single-select: tapping another brand replaces the selection. Matches
    // the projects archive for consistency across the catalog.
    setState(() {
      if (_selectedBrands.contains(brand)) {
        _selectedBrands.clear();
      } else {
        _selectedBrands
          ..clear()
          ..add(brand);
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
    final allNews = ref.watch(newsProvider).valueOrNull ?? const [];
    final allBrands = ref.watch(brandsProvider).valueOrNull ?? const [];
    final news = _applyFilters(allNews);

    final regions = allNews
        .map((n) => n.region)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    final newsBrandNames =
        allNews.map((n) => n.brand).whereType<String>().toSet();
    final newsFilterBrands =
        allBrands.where((b) => newsBrandNames.contains(b.name)).toList();

    return Column(
      children: [
        ScrollAwareFilterBar(
          scrollController: _scrollController,
          expanded: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    LhotseFilterChip(
                      label: 'TODAS',
                      isActive: _activeType == null,
                      onTap: () => _setType(null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    LhotseFilterChip(
                      label: 'PROYECTOS',
                      isActive: _activeType == NewsType.project,
                      onTap: () => _setType(NewsType.project),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    LhotseFilterChip(
                      label: 'PRENSA',
                      isActive: _activeType == NewsType.press,
                      onTap: () => _setType(NewsType.press),
                    ),
                    const Spacer(),
                    Container(width: 1, height: 16, color: AppColors.border),
                    const SizedBox(width: AppSpacing.md),
                    _ToolIcon(
                      icon: PhosphorIconsThin.stack,
                      isActive: _activeTool == _ActiveTool.firma ||
                          _selectedBrands.isNotEmpty,
                      hasDot: _selectedBrands.isNotEmpty,
                      onTap: () => _toggleTool(_ActiveTool.firma),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _ToolIcon(
                      icon: PhosphorIconsThin.mapPin,
                      isActive: _activeTool == _ActiveTool.region ||
                          _selectedRegions.isNotEmpty,
                      hasDot: _selectedRegions.isNotEmpty,
                      onTap: () => _toggleTool(_ActiveTool.region),
                    ),
                    const SizedBox(width: AppSpacing.md),
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
              if (_activeTool == _ActiveTool.buscar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: SizedBox(
                    height: 52,
                    child: Center(
                      child: LhotseSearchField(
                        controller: _searchController,
                        hint: 'Buscar noticias, firmas, regiones...',
                        autofocus: true,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        onClose: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                            _activeTool = _ActiveTool.none;
                          });
                        },
                      ),
                    ),
                  ),
                )
              else if (_activeTool == _ActiveTool.firma)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: LhotseBrandFilterRow(
                    brands: newsFilterBrands,
                    selectedBrands: _selectedBrands,
                    onBrandTap: _toggleBrand,
                  ),
                )
              else if (_activeTool == _ActiveTool.region)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _RegionFilterRow(
                    regions: regions,
                    selectedRegions: _selectedRegions,
                    onTap: _toggleRegion,
                    onClear: () => setState(() => _selectedRegions.clear()),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: news.isEmpty
              ? Center(
                  child: Text(
                    allNews.isEmpty ? '' : 'SIN RESULTADOS',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.accentMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  itemCount: news.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 32),
                  itemBuilder: (context, i) {
                    final item = news[i];
                    return LhotseNewsCard(
                      title: item.title,
                      imageUrl: item.imageUrl,
                      heroTag: 'news-hero-${item.id}',
                      brand: item.brand,
                      subtitle: item.subtitle,
                      date: DateFormat('d MMM yyyy', 'es_ES').format(item.date),
                      type: item.type == NewsType.press ? 'PRENSA' : 'PROYECTO',
                      hasPlayButton: item.hasPlayButton,
                      isLeadStory: i == 0,
                      onTap: () =>
                          context.push('/news/${item.id}', extra: item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({
    required this.icon,
    required this.isActive,
    required this.hasDot,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final bool hasDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 22,
        height: 22,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: PhosphorIcon(
                icon,
                size: 18,
                color:
                    isActive ? AppColors.textPrimary : AppColors.accentMuted,
              ),
            ),
            if (hasDot)
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
    );
  }
}

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
      height: 52,
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
                          height: 22,
                          child: Center(
                            child: Text(
                              _regionFlags[region] ?? '📍',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
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
                      height: 22,
                      child: PhosphorIcon(
                        PhosphorIconsThin.x,
                        size: 14,
                        color: AppColors.accentMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
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
