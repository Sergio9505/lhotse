import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/assets_provider.dart';
import '../../../core/data/brands_provider.dart';
import '../../../core/data/news_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_mark.dart';
import '../data/home_feed_provider.dart';
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
  final PageController _pager = PageController();
  int _activePage = 0;
  final Set<String> _precachedUrls = {};

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  /// Fires `precacheImage` for every feed image the first time we see it.
  /// Scheduled post-frame so `context` has a valid RenderObject. By the time
  /// the user taps any card, the decoded bytes are already in Flutter's
  /// `ImageCache` and the Hero flight lands on a warm image — no flicker.
  /// This is the Instagram / Pinterest pattern: precache ahead of intent.
  void _precacheFeed(List<FeedItem> items) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final item in items) {
        final url = item.imageUrl;
        if (url == null || url.isEmpty || _precachedUrls.contains(url)) continue;
        _precachedUrls.add(url);
        LhotseImage.precache(url, context);
      }
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(projectsProvider);
    ref.invalidate(newsProvider);
    ref.invalidate(brandsProvider);
    ref.invalidate(assetsProvider);
    ref.invalidate(homeFeedProvider);
    await ref.read(homeFeedProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(homeFeedProvider);
    final mq = MediaQuery.of(context);

    // Lhotse mark color follows the active feed item. Default (loading,
    // error, empty) is white — the scaffold background is black. Flip to
    // black only when the active media's top-left region is explicitly
    // tagged as light.
    final items = feedAsync.valueOrNull;
    final activeItem = (items != null && items.isNotEmpty)
        ? items[_activePage.clamp(0, items.length - 1)]
        : null;
    final markColor = (activeItem?.useLightOverlay ?? true)
        ? AppColors.textOnDark
        : AppColors.primary;

    return Scaffold(
      // Beige to match the caption + bottom nav, so the iOS bounce overscroll
      // (top pull-to-refresh and bottom flick) reveals a continuous tone
      // instead of a black band.
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: feedAsync.when(
              data: (items) {
                _precacheFeed(items);
                return _FeedPager(
                  controller: _pager,
                  items: items,
                  cardHeight: mq.size.height,
                  activePage: _activePage,
                  onPageChanged: (i) => setState(() => _activePage = i),
                  onRefresh: _refresh,
                );
              },
              loading: () => const _FeedLoading(),
              error: (_, _) => _FeedError(onRetry: _refresh),
            ),
          ),
          // Floating Lhotse mark — branding anchor on the immersive feed.
          // Positioned outside the PageView so it stays put while cards swap.
          // 44pt-tall band matches `LhotseShellHeader`'s height so the
          // optical Y of the mark aligns with the other shells. Color
          // animates with a 220ms cross-fade when the active page changes
          // (onPageChanged fires at snap, so the transition follows the
          // settle, not the drag — good enough, and free of per-frame cost).
          Positioned(
            top: mq.padding.top + 16,
            left: AppSpacing.lg,
            child: SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: markColor),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  builder: (context, color, _) =>
                      LhotseMark(color: color ?? markColor),
                ),
              ),
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
          style: AppTypography.labelUppercaseMd,
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
            style: AppTypography.labelUppercaseMd.copyWith(
              color: AppColors.textOnDark.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'REINTENTAR',
              style: AppTypography.labelUppercaseMd.copyWith(
                color: AppColors.textOnDark,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
