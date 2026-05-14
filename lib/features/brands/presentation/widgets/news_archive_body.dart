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
import '../../../../core/widgets/lhotse_async_list_states.dart';
import '../../../../core/widgets/lhotse_brand_filter_row.dart';
import '../../../../core/widgets/lhotse_filter_chip.dart';
import '../../../../core/widgets/lhotse_news_card.dart';
import '../../../../core/widgets/lhotse_search_field.dart';
import '../../../../core/widgets/scroll_aware_filter_bar.dart';

enum _ActiveTool { none, brands, search }

class NewsArchiveBody extends ConsumerStatefulWidget {
  const NewsArchiveBody({super.key});

  @override
  ConsumerState<NewsArchiveBody> createState() => _NewsArchiveBodyState();
}

class _NewsArchiveBodyState extends ConsumerState<NewsArchiveBody> {
  NewsType? _activeType;
  _ActiveTool _activeTool = _ActiveTool.none;
  final Set<String> _selectedBrands = {};
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
    // Global exclusion: construction-progress news are scoped to the project's
    // L3 Avance tab and never surface in this archive — independent of any
    // other filter the user toggles.
    var result =
        news.where((n) => n.subtype != NewsSubtype.progress).toList();
    if (_activeType != null) {
      result = result.where((n) => n.type == _activeType).toList();
    }
    if (_selectedBrands.isNotEmpty) {
      result = result
          .where((n) => n.brand != null && _selectedBrands.contains(n.brand!))
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

  /// Returns null when subtitle looks like "City, XX" (location+country code
  /// placeholder) — interim guard until news.subtitle holds real editorial decks.
  static String? _editorialDeck(String? subtitle) {
    if (subtitle == null || subtitle.isEmpty) return null;
    final locationPattern = RegExp(r'^[\wÁÉÍÓÚÜÑáéíóúüñ\s]+,\s[A-Z]{2}$');
    return locationPattern.hasMatch(subtitle) ? null : subtitle;
  }

  void _setType(NewsType? type) {
    setState(() => _activeType = type);
  }

  void _toggleTool(_ActiveTool tool) {
    setState(() {
      _activeTool = _activeTool == tool ? _ActiveTool.none : tool;
      if (_activeTool != _ActiveTool.search) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _toggleBrand(String brandName) {
    // Single-select: tap the already-selected brand clears; tap a different
    // brand replaces. Mirrors ProjectsArchiveBody._toggleBrand.
    setState(() {
      if (_selectedBrands.contains(brandName)) {
        _selectedBrands.clear();
      } else {
        _selectedBrands
          ..clear()
          ..add(brandName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider);
    final brandsAsync = ref.watch(brandsProvider);
    final allNews = newsAsync.value ?? const [];
    final news = _applyFilters(allNews);

    final newsBrandNames = allNews
        .where((n) => n.subtype != NewsSubtype.progress)
        .map((n) => n.brand)
        .whereType<String>()
        .toSet();
    final allBrands = brandsAsync.value ?? const [];
    final brands =
        allBrands.where((b) => newsBrandNames.contains(b.name)).toList();
    final hasBrandSelection = _selectedBrands.isNotEmpty;

    // Defensive: if the brand pool collapses to empty (last non-progress
    // news of a brand removed while the user has it open), drop any stale
    // selection and close the tool so the user isn't left interacting with
    // a hidden trigger.
    if (brands.isEmpty &&
        (_selectedBrands.isNotEmpty || _activeTool == _ActiveTool.brands)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedBrands.clear();
          if (_activeTool == _ActiveTool.brands) {
            _activeTool = _ActiveTool.none;
          }
        });
      });
    }

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
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            LhotseFilterChip(
                              label: 'PROYECTOS',
                              isActive: _activeType == NewsType.project,
                              onTap: () => _setType(
                                _activeType == NewsType.project
                                    ? null
                                    : NewsType.project,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            LhotseFilterChip(
                              label: 'PRENSA',
                              isActive: _activeType == NewsType.press,
                              onTap: () => _setType(
                                _activeType == NewsType.press
                                    ? null
                                    : NewsType.press,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 16, color: AppColors.border),
                    if (brands.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.md),
                      GestureDetector(
                        onTap: () => _toggleTool(_ActiveTool.brands),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Center(
                                child: PhosphorIcon(
                                  PhosphorIconsThin.stack,
                                  size: 20,
                                  color: _activeTool == _ActiveTool.brands ||
                                          hasBrandSelection
                                      ? AppColors.textPrimary
                                      : AppColors.accentMuted,
                                ),
                              ),
                              if (hasBrandSelection)
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
                    ],
                    const SizedBox(width: AppSpacing.md),
                    GestureDetector(
                      onTap: () => _toggleTool(_ActiveTool.search),
                      child: PhosphorIcon(
                        PhosphorIconsThin.magnifyingGlass,
                        size: 20,
                        color: _activeTool == _ActiveTool.search
                            ? AppColors.textPrimary
                            : AppColors.accentMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (_activeTool == _ActiveTool.search)
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
                        onClose: () => _toggleTool(_ActiveTool.search),
                      ),
                    ),
                  ),
                )
              else if (_activeTool == _ActiveTool.brands)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: LhotseBrandFilterRow(
                    brands: brands,
                    selectedBrands: _selectedBrands,
                    onBrandTap: _toggleBrand,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: newsAsync.when(
            loading: () => const LhotseAsyncLoading(),
            error: (_, _) => LhotseAsyncError(
              message: 'No se pudieron cargar las noticias.',
              onRetry: () => ref.invalidate(newsProvider),
            ),
            data: (_) => news.isEmpty
                ? Center(
                    child: Text(
                      'SIN RESULTADOS',
                      style: AppTypography.labelUppercaseMd.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(
                        top: AppSpacing.md, bottom: AppSpacing.xxl),
                    itemCount: news.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.lg),
                    itemBuilder: (context, i) {
                      final item = news[i];
                      return LhotseNewsCard(
                        title: item.title,
                        imageUrl: item.imageUrl,
                        heroTag: 'news-hero-${item.id}',
                        brand: item.brand,
                        subtitle: _editorialDeck(item.subtitle),
                        date:
                            DateFormat('d MMM yyyy', 'es_ES').format(item.date),
                        videoUrl: item.videoUrl,
                        onTap: () =>
                            context.push('/news/${item.id}', extra: item),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
