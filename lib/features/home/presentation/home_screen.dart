import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/brands_provider.dart';
import '../../../core/data/news_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_mark.dart';
import '../data/home_feed_provider.dart';
import '../data/home_scroll_offset_provider.dart';
import '../domain/feed_item.dart';
import 'widgets/feed_card.dart';

/// Home = SNKRS-inspired vertical feed, one content unit per viewport with
/// snap paging. No header — the media fills the screen edge-to-edge and the
/// notification bell floats over it as a frosted-glass chip (same rule as
/// `LhotseBackButton.onImage()`).
///
/// Archive-style browsing (catálogo, noticias) lives in the Search tab's idle
/// state — there are no "see all" exits from the feed itself.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pager;
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    _pager = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final snapshot = ref.read(homeFeedPositionProvider);
      if (isHomeFeedPositionFresh(snapshot) && _pager.hasClients) {
        _pager.jumpToPage(snapshot!.pageIndex);
        setState(() => _activePage = snapshot.pageIndex);
      }
    });
  }

  @override
  void dispose() {
    ref.read(homeFeedPositionProvider.notifier).state = HomeFeedPosition(
      pageIndex: _activePage,
      savedAt: DateTime.now(),
    );
    _pager.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(featuredProjectsProvider);
    ref.invalidate(newsProvider);
    ref.invalidate(projectsProvider);
    ref.invalidate(brandsProvider);
    ref.invalidate(opportunitiesProvider);
    ref.invalidate(homeFeedProvider);
    await ref.read(homeFeedProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(homeFeedProvider);
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Positioned.fill(
            child: feedAsync.when(
              data: (items) => _FeedPager(
                controller: _pager,
                items: items,
                cardHeight: mq.size.height,
                activePage: _activePage,
                onPageChanged: (i) => setState(() => _activePage = i),
                onRefresh: _refresh,
              ),
              loading: () => const _FeedLoading(),
              error: (_, _) => _FeedError(onRetry: _refresh),
            ),
          ),
          // Floating Lhotse mark — branding anchor on the immersive feed.
          // Positioned outside the PageView so it stays put while cards swap.
          Positioned(
            top: mq.padding.top + 12,
            right: 16,
            child: const LhotseMark(
              color: AppColors.textOnDark,
              height: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedPager extends StatelessWidget {
  const _FeedPager({
    required this.controller,
    required this.items,
    required this.cardHeight,
    required this.activePage,
    required this.onPageChanged,
    required this.onRefresh,
  });

  final PageController controller;
  final List<FeedItem> items;
  final double cardHeight;
  final int activePage;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'SIN CONTENIDO',
          style: AppTypography.labelLarge,
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.textOnDark,
      backgroundColor: Colors.black.withValues(alpha: 0.4),
      strokeWidth: 1.5,
      onRefresh: onRefresh,
      child: PageView.builder(
        controller: controller,
        scrollDirection: Axis.vertical,
        onPageChanged: onPageChanged,
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return KeyedSubtree(
            key: ValueKey(item.feedKey),
            child: FeedCard(
              item: item,
              height: cardHeight,
              isActive: i == activePage,
            ),
          );
        },
      ),
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 1.5,
        color: AppColors.textOnDark,
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NO SE PUDO CARGAR EL FEED',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textOnDark.withValues(alpha: 0.7),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'REINTENTAR',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textOnDark,
                letterSpacing: 1.8,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
