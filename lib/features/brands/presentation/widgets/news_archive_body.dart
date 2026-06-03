import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/news_provider.dart';
import '../../../../core/domain/news_item_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_async_list_states.dart';
import '../../../../core/widgets/lhotse_filter_chip.dart';
import '../../../../core/widgets/lhotse_news_card.dart';

/// News archive (Firmas › NOTICIAS sub-tab). Single filter strip: a segmented
/// **type** set `[TODAS] [GRUPO] [PRENSA]` (single-select, default TODAS). No
/// brand filter, no text search (search lives in the global Buscar tab) —
/// coherent with the Proyectos sub-tab's single clean filter strip.
class NewsArchiveBody extends ConsumerStatefulWidget {
  const NewsArchiveBody({super.key});

  @override
  ConsumerState<NewsArchiveBody> createState() => _NewsArchiveBodyState();
}

class _NewsArchiveBodyState extends ConsumerState<NewsArchiveBody> {
  /// `null` = TODAS (no type filter).
  NewsType? _activeType;

  List<NewsItemData> _applyFilters(List<NewsItemData> news) {
    // Global exclusion: construction-progress news are scoped to the project's
    // L3 Avance tab and never surface in this archive.
    var result = news.where((n) => n.subtype != NewsSubtype.progress).toList();
    if (_activeType != null) {
      result = result.where((n) => n.type == _activeType).toList();
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

  void _setType(NewsType? type) => setState(() => _activeType = type);

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider);
    final news = _applyFilters(newsAsync.value ?? const []);

    return Column(
      // start: the filter strip's SingleChildScrollView shrinks to its content
      // width, so without this the Column would center it (chips drift right,
      // misaligned with the header logo). start pins it left at lg=24.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls zone: fixed height (BrandsLayout.controlsHeight) so the
        // content starts at the same Y as Proyectos/Firmas → no jump when
        // switching sub-tabs. Chips left-aligned (lg) and vertically centered.
        SizedBox(
          width: double.infinity,
          height: BrandsLayout.controlsHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    LhotseFilterChip(
                      label: 'TODAS',
                      large: true,
                      isActive: _activeType == null,
                      onTap: () => _setType(null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    LhotseFilterChip(
                      label: 'GRUPO',
                      large: true,
                      isActive: _activeType == NewsType.project,
                      onTap: () => _setType(NewsType.project),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    LhotseFilterChip(
                      label: 'PRENSA',
                      large: true,
                      isActive: _activeType == NewsType.press,
                      onTap: () => _setType(NewsType.press),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
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
                    // top 0: the controls zone + its bottom gap already set the
                    // content start (BrandsLayout.contentTop).
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
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
                        date: DateFormat(
                          'd MMM yyyy',
                          'es_ES',
                        ).format(item.date),
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
