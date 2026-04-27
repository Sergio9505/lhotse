import '../../../core/domain/asset_data.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/domain/news_item_data.dart';
import '../../../core/domain/project_data.dart';

/// Unified item rendered by the Home feed. One item = one full viewport.
///
/// Each variant wraps a domain model but carries feed-specific metadata
/// (`useLightOverlay`, navigation target) sourced from the entity table
/// (assets/projects/news/brands).
sealed class FeedItem {
  const FeedItem({required this.useLightOverlay});

  /// Stable key for Flutter's list diffing.
  String get feedKey;

  /// URL/asset of the hero image rendered in the feed card. Exposed on the
  /// base class so the screen can precache everything at feed-data-arrival
  /// time (Instagram / Pinterest pattern — decode ahead of tap).
  String get imageUrl;

  /// `true` when overlaid chrome (Lhotse wordmark, back button, etc.) should
  /// be rendered in light/white. Set via admin per source entity alongside its
  /// thumbnail — flip to `false` when the top-left of the image is light.
  final bool useLightOverlay;
}

enum FeedMediaType { image, video }

class FeedProjectItem extends FeedItem {
  const FeedProjectItem(this.project, {required super.useLightOverlay});
  final ProjectData project;

  @override
  String get feedKey => 'project_${project.id}';

  @override
  String get imageUrl => project.imageUrl;
}

class FeedNewsItem extends FeedItem {
  const FeedNewsItem(this.news, {required super.useLightOverlay});
  final NewsItemData news;

  @override
  String get feedKey => 'news_${news.id}';

  @override
  String get imageUrl => news.imageUrl;
}

class FeedBrandItem extends FeedItem {
  const FeedBrandItem(this.brand, {required super.useLightOverlay});
  final BrandData brand;

  @override
  String get feedKey => 'brand_${brand.id}';

  @override
  String get imageUrl => brand.coverImageUrl;
}

class FeedAssetItem extends FeedItem {
  const FeedAssetItem(this.asset, {required super.useLightOverlay});
  final AssetData asset;

  @override
  String get feedKey => 'asset_${asset.id}';

  @override
  String get imageUrl => asset.thumbnailImage ?? '';
}
