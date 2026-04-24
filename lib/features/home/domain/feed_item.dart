import '../../../core/domain/brand_data.dart';
import '../../../core/domain/news_item_data.dart';
import '../../../core/domain/project_data.dart';

/// Unified item rendered by the Home feed. One item = one full viewport.
///
/// Each variant maps 1:1 to a domain model but carries feed-specific accessors
/// (`mediaUrl`, `mediaType`, navigation target) so `FeedCard` can stay dumb.
sealed class FeedItem {
  const FeedItem();

  /// Stable key for Flutter's list diffing.
  String get feedKey;

  /// URL/asset of the hero image rendered in the feed card. Exposed on the
  /// base class so the screen can precache everything at feed-data-arrival
  /// time (Instagram/Pinterest pattern — decode ahead of tap).
  String get imageUrl;
}

enum FeedMediaType { image, video }

class FeedProjectItem extends FeedItem {
  const FeedProjectItem(this.project);
  final ProjectData project;

  @override
  String get feedKey => 'project_${project.id}';

  @override
  String get imageUrl => project.imageUrl;
}

class FeedOpportunityItem extends FeedItem {
  const FeedOpportunityItem(this.project);
  final ProjectData project;

  @override
  String get feedKey => 'opportunity_${project.id}';

  @override
  String get imageUrl => project.imageUrl;
}

class FeedNewsItem extends FeedItem {
  const FeedNewsItem(this.news);
  final NewsItemData news;

  @override
  String get feedKey => 'news_${news.id}';

  @override
  String get imageUrl => news.imageUrl;
}

class FeedBrandItem extends FeedItem {
  const FeedBrandItem(this.brand);
  final BrandData brand;

  @override
  String get feedKey => 'brand_${brand.id}';

  @override
  String get imageUrl => brand.coverImageUrl;
}
