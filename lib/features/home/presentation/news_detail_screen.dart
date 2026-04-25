import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/data/news_provider.dart';
import '../../../core/domain/news_item_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_news_card.dart';
import '../../../core/widgets/lhotse_section_label.dart';
import 'widgets/feed_video_player.dart';
import 'widgets/fullscreen_video_player.dart';

class NewsDetailScreen extends ConsumerStatefulWidget {
  const NewsDetailScreen({
    super.key,
    required this.newsId,
    this.initialNews,
  });

  final String newsId;

  /// Pre-loaded snapshot from the caller (e.g. Home feed) so the Hero tag is
  /// in the widget tree on the first frame. See `ProjectDetailScreen` for the
  /// full rationale.
  final NewsItemData? initialNews;

  @override
  ConsumerState<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends ConsumerState<NewsDetailScreen> {
  final _scrollController = ScrollController();
  bool _heroGone = false;
  bool _showCollapsedTitle = false;
  double _heroHeight = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final heroThreshold = _heroHeight - kToolbarHeight;
    final heroGone = offset >= heroThreshold;
    final titleThreshold = _heroHeight + 50.0;
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
    final newsAsync = ref.watch(newsByIdProvider(widget.newsId));
    // Prefer the caller-supplied snapshot on the first frame so the Hero
    // tag exists when Flutter starts the flight.
    final allNews = ref.watch(newsProvider).valueOrNull ?? const [];
    final news = newsAsync.valueOrNull ?? widget.initialNews;

    if (news == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: newsAsync.isLoading
              ? const CircularProgressIndicator(strokeWidth: 1.5)
              : Text(
                  'Noticia no encontrada',
                  style: AppTypography.bodyReading.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
        ),
      );
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    _heroHeight = MediaQuery.of(context).size.height * 0.55;

    final relatedNews = allNews
        .where((n) => n.brandId == news.brandId && n.id != news.id)
        .take(3)
        .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _heroGone
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // =========================================================
            // 1. HERO
            // =========================================================
            SliverAppBar(
              pinned: true,
              expandedHeight: _heroHeight,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
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
                      news.title.toUpperCase(),
                      style: AppTypography.titleUppercase.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ((news.brand ?? '')).toUpperCase(),
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),
                  ],
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: GestureDetector(
                  onTap: news.hasPlayButton
                      ? () => _openVideoPlayer(context, news)
                      : null,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'news-hero-${news.id}',
                        child: (news.videoUrl != null &&
                                news.videoUrl!.isNotEmpty)
                            ? FeedVideoPlayer(
                                videoUrl: news.videoUrl!,
                                posterUrl: news.imageUrl,
                                isActive: true,
                              )
                            : LhotseImage(news.imageUrl),
                      ),
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
                            begin: Alignment(0, 0.2),
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0x8C1F1916),
                            ],
                          ),
                        ),
                      ),
                      if (news.hasPlayButton)
                        Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x40000000),
                                  blurRadius: 25,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // =========================================================
            // 2. IDENTITY — lookbook editorial (kicker · title · deck · byline)
            // =========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.type == NewsType.project ? 'PROYECTO' : 'PRENSA',
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      news.title,
                      style: AppTypography.editorialHero.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if ((news.subtitle ?? '').isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        news.subtitle!,
                        style: AppTypography.annotation.copyWith(
                          color: AppColors.accentMuted,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildByline(news),
                  ],
                ),
              ),
            ),

            // =========================================================
            // 4. BODY
            // =========================================================
            if (news.body?.isNotEmpty == true)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xxl,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Text(
                    news.body!,
                    style: AppTypography.bodyReading.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),

            // =========================================================
            // 5. RELACIONADAS
            // =========================================================
            if (relatedNews.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    LhotseSectionLabel(
                      label: 'MÁS DE ${((news.brand ?? '')).toUpperCase()}',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        itemCount: relatedNews.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, i) => GestureDetector(
                          onTap: () =>
                              context.push('/news/${relatedNews[i].id}'),
                          child: LhotseNewsCard.compact(
                            title: relatedNews[i].title,
                            imageUrl: relatedNews[i].imageUrl,
                            subtitle: DateFormat('d MMM yyyy').format(relatedNews[i].date),
                            hasPlayButton: relatedNews[i].hasPlayButton,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom spacing
            SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxl + bottomPadding),
            ),
          ],
        ),
      ),
    );
  }

  /// Byline: `POR {BRAND}  ·  {DATE}`. Brand keeps primary ink; date mutes.
  Widget _buildByline(NewsItemData news) {
    final brand = news.brand;
    final hasBrand = brand != null && brand.isNotEmpty;
    final dateStr = DateFormat('d MMM yyyy', 'es_ES').format(news.date);
    final children = <InlineSpan>[];
    if (hasBrand) {
      children.add(TextSpan(
        text: 'POR ',
        style: TextStyle(color: AppColors.accentMuted, letterSpacing: 1.5),
      ));
      children.add(TextSpan(
        text: brand.toUpperCase(),
        style: TextStyle(color: AppColors.textPrimary, letterSpacing: 1.5),
      ));
      children.add(TextSpan(
        text: '  ·  ',
        style: TextStyle(
          color: AppColors.textPrimary.withValues(alpha: 0.4),
        ),
      ));
    }
    children.add(TextSpan(
      text: dateStr.toUpperCase(),
      style: TextStyle(color: AppColors.accentMuted, letterSpacing: 1.2),
    ));
    return RichText(
      text: TextSpan(
        style: AppTypography.labelUppercaseSm.copyWith(letterSpacing: 1.5),
        children: children,
      ),
    );
  }
}

void _openVideoPlayer(BuildContext context, NewsItemData news) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Opacity(
            opacity: animation.value,
            child: child,
          ),
          child: FullscreenVideoPlayer(
            videoUrl: news.videoUrl!,
            posterUrl: news.imageUrl,
          ),
        );
      },
    ),
  );
}
