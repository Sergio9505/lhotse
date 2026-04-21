import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/brands_provider.dart';
import '../../../core/data/news_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../../../core/data/supabase_provider.dart';
import '../../../core/domain/user_role.dart';
import '../domain/feed_item.dart';

/// Composes the Home feed from existing domain providers, applying a fixed
/// curation recipe that interleaves featured projects, news, opportunities,
/// and one rotating brand spotlight.
///
/// Recipe v2 — first three slots are fixed editorial openers
/// (`featured[0] · news[0] · featured[1]`) so the most curated projects lead,
/// then the stream interleaves opportunities, news, and a brand spotlight.
final homeFeedProvider = FutureProvider<List<FeedItem>>((ref) async {
  final role = ref.watch(currentUserRoleProvider);
  final isInvestor =
      role == UserRole.investor || role == UserRole.investorVip;

  final featured = await ref.watch(featuredProjectsProvider(role).future);
  final news = await ref.watch(newsProvider.future);
  final brands = await ref.watch(brandsProvider.future);
  final opportunities = isInvestor
      ? await ref.watch(
          opportunitiesProvider(const {'model': null, 'location': null}).future,
        )
      : const [];

  // Rotate the brand spotlight once per day for ambient variety without
  // recomputing on every rebuild.
  final seed = DateTime.now().day;
  final spotlightBrand =
      brands.isEmpty ? null : brands[seed % brands.length];

  final items = <FeedItem>[];

  void pushFeatured(int index) {
    if (index < featured.length) {
      items.add(FeedProjectItem(featured[index]));
    }
  }

  void pushNews(int index) {
    if (index < news.length) {
      items.add(FeedNewsItem(news[index]));
    }
  }

  void pushOpportunity(int index) {
    if (index < opportunities.length) {
      items.add(FeedOpportunityItem(opportunities[index]));
    }
  }

  // Editorial opener — no interleaving for the first three slots so the
  // most curated pair of projects leads the feed.
  pushFeatured(0);
  pushNews(0);
  pushFeatured(1);

  // Body — interleave opportunities, news, and one brand spotlight.
  pushOpportunity(0);
  pushNews(1);
  if (spotlightBrand != null) items.add(FeedBrandItem(spotlightBrand));
  pushOpportunity(1);
  pushFeatured(2);
  pushNews(2);
  pushFeatured(3);
  pushNews(3);
  pushOpportunity(2);

  return items;
});
