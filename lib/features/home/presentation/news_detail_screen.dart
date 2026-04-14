import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/mock/mock_news.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_news_card.dart';
import '../../../core/widgets/lhotse_section_label.dart';

const _kHeroHeight = 200.0;

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key, required this.newsId});

  final String newsId;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final _scrollController = ScrollController();
  bool _heroGone = false;
  bool _showCollapsedTitle = false;

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
    final heroThreshold = _kHeroHeight - kToolbarHeight;
    final heroGone = offset >= heroThreshold;
    final titleThreshold = _kHeroHeight + 50.0;
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
    final news = findNewsById(widget.newsId);

    if (news == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Noticia no encontrada',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final relatedNews = mockNews
        .where((n) => n.brand == news.brand && n.id != news.id)
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
              expandedHeight: _kHeroHeight,
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
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      news.brand.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 1.2,
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
                      LhotseImage(news.imageUrl),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [Color(0x66000000), Colors.transparent],
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
            // 2. IDENTITY
            // =========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.title.toUpperCase(),
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          news.brand.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 1.8,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '·',
                            style: AppTypography.caption.copyWith(
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        Text(
                          news.date,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accentMuted,
                            letterSpacing: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // =========================================================
            // 3. TYPE BADGE + LOCATION
            // =========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      color: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        news.type == NewsType.project ? 'PROYECTO' : 'PRENSA',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.textOnDark,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      news.subtitle.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =========================================================
            // 4. BODY
            // =========================================================
            if (news.body.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xxl,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Text(
                    news.body,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
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
                      label: 'MÁS DE ${news.brand.toUpperCase()}',
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
                            subtitle: relatedNews[i].date,
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
}

// ===========================================================================
// Fullscreen video player (placeholder until real URLs are connected)
// ===========================================================================

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
          child: _VideoPlayerScreen(news: news),
        );
      },
    ),
  );
}

class _VideoPlayerScreen extends StatelessWidget {
  const _VideoPlayerScreen({required this.news});

  final NewsItemData news;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background image (placeholder for video)
            LhotseImage(news.imageUrl),

            // Dark overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x99000000),
              ),
            ),

            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Play icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                    child: Text(
                      news.title.toUpperCase(),
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.textOnDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Subtitle (duration info)
                  Text(
                    news.subtitle.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textOnDark.withValues(alpha: 0.6),
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // "Coming soon" label
                  Text(
                    'PRÓXIMAMENTE',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textOnDark.withValues(alpha: 0.4),
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),

            // Close button
            Positioned(
              top: topPadding + AppSpacing.md,
              right: AppSpacing.lg,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  color: Colors.white.withValues(alpha: 0.1),
                  child: const PhosphorIcon(
                    PhosphorIconsThin.x,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),

            // Bottom safe area spacer
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(height: bottomPadding),
            ),
          ],
        ),
      ),
    );
  }
}
