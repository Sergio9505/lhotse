import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/brands_provider.dart';
import '../../../core/data/news_provider.dart';
import '../../../core/domain/news_item_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_app_header.dart';
import '../../../core/widgets/lhotse_brand_filter_row.dart';
import '../../../core/widgets/lhotse_filter_tab.dart';
import '../../../core/widgets/lhotse_news_card.dart';
import '../../../core/widgets/lhotse_search_field.dart';

enum _ActiveTool { none, firma, region, buscar }

class AllNewsScreen extends ConsumerStatefulWidget {
  const AllNewsScreen({super.key});

  @override
  ConsumerState<AllNewsScreen> createState() => _AllNewsScreenState();
}

class _AllNewsScreenState extends ConsumerState<AllNewsScreen> {
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
      final q = _searchQuery.toLowerCase();
      result = result
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              (n.brand ?? '').toLowerCase().contains(q) ||
              (n.subtitle ?? '').toLowerCase().contains(q))
          .toList();
    }
    return result;
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
    final allNews = ref.watch(newsProvider).valueOrNull ?? const [];
    final allBrands = ref.watch(brandsProvider).valueOrNull ?? const [];
    final news = _applyFilters(allNews);

    // Derive unique regions and brands from loaded news
    final regions = allNews
        .map((n) => n.region)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    // Brands that appear in news (matched against brand catalog for logos)
    final newsBrandNames =
        allNews.map((n) => n.brand).whereType<String>().toSet();
    final newsFilterBrands = allBrands
        .where((b) => newsBrandNames.contains(b.name))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const LhotseAppHeader(title: 'NOTICIAS'),

          // Filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                brands: newsFilterBrands,
                selectedBrands: _selectedBrands,
                onBrandTap: _toggleBrand,
                onClear: () => setState(() => _selectedBrands.clear()),
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

          // News list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(newsProvider);
                ref.invalidate(brandsProvider);
                await Future.wait([
                  ref.read(newsProvider.future).catchError((_) {}),
                  ref.read(brandsProvider.future).catchError((_) {}),
                ]);
              },
              child: news.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              allNews.isEmpty ? '' : 'SIN RESULTADOS',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.accentMuted,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      itemCount: news.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
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
          ),
        ],
      ),
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
                color: isActive ? AppColors.textPrimary : AppColors.accentMuted,
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
