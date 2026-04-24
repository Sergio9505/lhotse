import '../../../core/domain/asset_data.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/domain/news_item_data.dart';
import '../../../core/domain/project_data.dart';

/// Unified item rendered by the Home feed. One item = one full viewport.
///
/// Each variant wraps a domain model but carries feed-specific metadata
/// (`logoOnDarkMedia`, navigation target) that comes from the
/// `home_feed_items` table — the server-side curation source.
sealed class FeedItem {
  const FeedItem({required this.logoOnDarkMedia});

  /// Stable key for Flutter's list diffing.
  String get feedKey;

  /// URL/asset of the hero image rendered in the feed card. Exposed on the
  /// base class so the screen can precache everything at feed-data-arrival
  /// time (Instagram / Pinterest pattern — decode ahead of tap).
  String get imageUrl;

  /// `true` when the top-left region of the media is dark enough for a white
  /// Lhotse mark to read well. Driven per-slot from
  /// `home_feed_items.logo_on_dark_media`, not from the source table.
  final bool logoOnDarkMedia;
}

enum FeedMediaType { image, video }

class FeedProjectItem extends FeedItem {
  const FeedProjectItem(this.project, {required super.logoOnDarkMedia});
  final ProjectData project;

  @override
  String get feedKey => 'project_${project.id}';

  @override
  String get imageUrl => project.imageUrl;
}

class FeedNewsItem extends FeedItem {
  const FeedNewsItem(this.news, {required super.logoOnDarkMedia});
  final NewsItemData news;

  @override
  String get feedKey => 'news_${news.id}';

  @override
  String get imageUrl => news.imageUrl;
}

class FeedBrandItem extends FeedItem {
  const FeedBrandItem(this.brand, {required super.logoOnDarkMedia});
  final BrandData brand;

  @override
  String get feedKey => 'brand_${brand.id}';

  @override
  String get imageUrl => brand.coverImageUrl;
}

class FeedAssetItem extends FeedItem {
  const FeedAssetItem(this.asset, {required super.logoOnDarkMedia});
  final AssetData asset;

  @override
  String get feedKey => 'asset_${asset.id}';

  @override
  String get imageUrl => asset.thumbnailImage ?? '';
}
