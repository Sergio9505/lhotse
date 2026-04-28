import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/data/news_provider.dart';
import '../../../../core/domain/news_item_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/search_utils.dart';
import '../../../../core/widgets/lhotse_filter_chip.dart';
import '../../../../core/widgets/lhotse_news_card.dart';
import '../../../../core/widgets/lhotse_search_field.dart';
import '../../../../core/widgets/scroll_aware_filter_bar.dart';

class NewsArchiveBody extends ConsumerStatefulWidget {
  const NewsArchiveBody({super.key});

  @override
  ConsumerState<NewsArchiveBody> createState() => _NewsArchiveBodyState();
}

class _NewsArchiveBodyState extends ConsumerState<NewsArchiveBody> {
  NewsType? _activeType;
  bool _searchOpen = false;
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

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allNews = ref.watch(newsProvider).valueOrNull ?? const [];
    final news = _applyFilters(allNews);

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
                    const SizedBox(width: AppSpacing.md),
                    GestureDetector(
                      onTap: _toggleSearch,
                      child: PhosphorIcon(
                        PhosphorIconsThin.magnifyingGlass,
                        size: 20,
                        color: _searchOpen
                            ? AppColors.textPrimary
                            : AppColors.accentMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (_searchOpen)
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
                        onClose: _toggleSearch,
                      ),
                    ),
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
                      date: DateFormat('d MMM yyyy', 'es_ES').format(item.date),
                      hasPlayButton: item.hasPlayButton,
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
