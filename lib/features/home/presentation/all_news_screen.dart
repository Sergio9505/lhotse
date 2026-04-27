import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/news_provider.dart';
import '../../../core/domain/news_item_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_app_header.dart';
import '../../../core/widgets/lhotse_filter_tab.dart';
import '../../../core/widgets/lhotse_news_card.dart';
import '../../../core/widgets/lhotse_search_field.dart';
import '../../../core/widgets/scroll_aware_filter_bar.dart';

class AllNewsScreen extends ConsumerStatefulWidget {
  const AllNewsScreen({super.key});

  @override
  ConsumerState<AllNewsScreen> createState() => _AllNewsScreenState();
}

class _AllNewsScreenState extends ConsumerState<AllNewsScreen> {
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
      final q = _searchQuery.toLowerCase();
      result = result
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              (n.brand ?? '').toLowerCase().contains(q) ||
              (n.subtitle ?? '').toLowerCase().contains(q) ||
              (n.region ?? '').toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  void _toggleType(NewsType type) {
    setState(() {
      _activeType = _activeType == type ? null : type;
    });
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const LhotseAppHeader(title: 'NOTICIAS'),

          // Filter bar — collapses to a compact pill while scrolling,
          // restores itself after ~2s of idle (premium reading-app UX).
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
                          size: 18,
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
                    child: LhotseSearchField(
                      controller: _searchController,
                      hint: 'Buscar noticias, firmas, regiones...',
                      autofocus: true,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      onClose: _toggleSearch,
                    ),
                  ),
              ],
            ),
          ),

          // News list
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
