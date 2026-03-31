import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/mock/mock_news.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_app_header.dart';
import '../../../core/widgets/lhotse_brand_filter_row.dart';
import '../../../core/widgets/lhotse_news_card.dart';
import '../../../core/widgets/lhotse_search_field.dart';

enum _ActiveFilter { none, firma, region, buscar }

class AllNewsScreen extends StatefulWidget {
  const AllNewsScreen({super.key});

  @override
  State<AllNewsScreen> createState() => _AllNewsScreenState();
}

class _AllNewsScreenState extends State<AllNewsScreen> {
  _ActiveFilter _activeFilter = _ActiveFilter.none;
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

  void _toggleFilter(_ActiveFilter filter) {
    setState(() {
      if (_activeFilter == filter) {
        _activeFilter = _ActiveFilter.none;
      } else {
        _activeFilter = filter;
        if (filter == _ActiveFilter.buscar) {
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

          // Filter tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _FilterTab(
                    label: 'FIRMA',
                    isActive: _activeFilter == _ActiveFilter.firma,
                    hasSelection: _selectedBrands.isNotEmpty,
                    onTap: () => _toggleFilter(_ActiveFilter.firma),
                  ),
                ),
                Expanded(
                  child: _FilterTab(
                    label: 'REGIÓN',
                    isActive: _activeFilter == _ActiveFilter.region,
                    hasSelection: _selectedRegions.isNotEmpty,
                    onTap: () => _toggleFilter(_ActiveFilter.region),
                  ),
                ),
                Expanded(
                  child: _FilterTab(
                    label: 'BUSCAR',
                    isActive: _activeFilter == _ActiveFilter.buscar,
                    onTap: () => _toggleFilter(_ActiveFilter.buscar),
                  ),
                ),
              ],
            ),
          ),

          // Filter panels
          if (_activeFilter == _ActiveFilter.buscar)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: LhotseSearchField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _searchQuery = v),
                onClose: () => _toggleFilter(_ActiveFilter.buscar),
              ),
            )
          else if (_activeFilter == _ActiveFilter.firma)
            LhotseBrandFilterRow(
              selectedBrands: _selectedBrands,
              onBrandTap: _toggleBrand,
              onClear: () => setState(() => _selectedBrands.clear()),
            )
          else if (_activeFilter == _ActiveFilter.region)
            _RegionFilterRow(
              regions: newsRegions,
              selectedRegions: _selectedRegions,
              onTap: _toggleRegion,
              onClear: () => setState(() => _selectedRegions.clear()),
            ),

          // News list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
// Filter tab — same pattern as Opportunities
// ---------------------------------------------------------------------------

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.hasSelection = false,
  });

  final String label;
  final bool isActive;
  final bool hasSelection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlighted = isActive || hasSelection;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: highlighted
                      ? AppColors.textPrimary
                      : AppColors.accentMuted,
                  fontWeight: highlighted ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: 1.5,
                ),
              ),
              if (hasSelection) ...[
                const SizedBox(width: 5),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.textPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
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
// Region filter row — icon + text, same height as brand filter
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
                            fontWeight: FontWeight.w700,
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
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: AppColors.accentMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'LIMPIAR',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.accentMuted,
                        fontWeight: FontWeight.w700,
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
