enum NewsType { project, press }

extension NewsTypeX on NewsType {
  static NewsType fromString(String value) => switch (value) {
        'project' => NewsType.project,
        'press' => NewsType.press,
        _ => NewsType.press,
      };
}

class NewsItemData {
  const NewsItemData({
    required this.id,
    required this.title,
    this.projectId,
    this.assetId,
    this.brandId,
    this.brand,
    this.region,
    this.subtitle,
    required this.imageUrl,
    this.videoUrl,
    required this.date,
    required this.type,
    this.body,
  });

  final String id;
  final String title;

  /// Canonical project reference when the news is tied to a specific project.
  /// Used by coinversion L3 to show news relevant to that project first.
  final String? projectId;

  /// Canonical asset reference when the news is tied to a specific asset
  /// (purchase / direct hold) rather than a coinversion project.
  final String? assetId;

  /// Brand inferred via the linked project (`projects.brand_id`). Always
  /// `null` when the news has no `project_id` (asset-linked or standalone).
  /// Compat shim: news no longer carries a direct brand FK after the
  /// 2026-04 schema change — kept on the model for downstream consumers
  /// (byline, related-news filter) until they're migrated to project-aware
  /// equivalents. Currently always null because the query no longer joins
  /// the brand chain.
  final String? brandId;
  final String? brand;

  /// Region/city inferred via the linked project's asset or the linked asset
  /// directly. Always `null` until queries are extended to fetch the chain.
  /// Compat shim — see `brand`.
  final String? region;

  final String? subtitle;
  final String imageUrl;
  final String? videoUrl;
  final DateTime date;
  final NewsType type;
  final String? body;

  /// Whether to show a play-button overlay on the news media. Derived from
  /// the presence of a `video_url` rather than stored as a separate column —
  /// "has video" is a fact about the row, not a separate flag.
  bool get hasPlayButton => videoUrl != null && videoUrl!.isNotEmpty;

  factory NewsItemData.fromSupabaseRow(Map<String, dynamic> row) {
    return NewsItemData(
      id: row['id'] as String,
      title: row['title'] as String,
      projectId: row['project_id'] as String?,
      assetId: row['asset_id'] as String?,
      // brandId / brand / region come from project + asset relations when
      // the query joins them. Until the consumers are updated, the queries
      // don't fetch these joins and these fields stay null.
      brandId: null,
      brand: null,
      region: null,
      subtitle: row['subtitle'] as String?,
      imageUrl: row['image_url'] as String,
      videoUrl: row['video_url'] as String?,
      date: DateTime.parse(row['date'] as String),
      type: NewsTypeX.fromString(row['type'] as String? ?? ''),
      body: row['body'] as String?,
    );
  }
}
