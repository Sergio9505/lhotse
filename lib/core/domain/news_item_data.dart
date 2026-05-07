enum NewsType { project, press }

extension NewsTypeX on NewsType {
  static NewsType fromString(String value) => switch (value) {
        'project' => NewsType.project,
        'press' => NewsType.press,
        _ => NewsType.press,
      };

  /// Mixed-case label for inline bylines. Uppercase callers .toUpperCase().
  String get label => switch (this) {
        NewsType.project => 'Proyecto',
        NewsType.press => 'Prensa',
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
    this.imageUrl,
    this.videoUrl,
    required this.date,
    required this.type,
    this.body,
    this.useLightOverlay = true,
  });

  final String id;
  final String title;

  /// Canonical project reference when the news is tied to a specific project.
  /// Used by coinversion L3 to show news relevant to that project first.
  final String? projectId;

  /// Canonical asset reference when the news is tied to a specific asset
  /// (purchase / direct hold) rather than a coinversion project.
  final String? assetId;

  /// Brand inferred via the linked project (`projects.brand_id → brands.name`).
  /// `null` when the news has no `project_id` (asset-linked or standalone).
  final String? brandId;
  final String? brand;

  /// Region inferred from the directly linked asset or from the project's
  /// asset chain. `null` for news not linked to any asset.
  final String? region;

  final String? subtitle;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime date;
  final NewsType type;
  final String? body;
  final bool useLightOverlay;

  /// Whether to show a play-button overlay on the news media. Derived from
  /// the presence of a `video_url` rather than stored as a separate column —
  /// "has video" is a fact about the row, not a separate flag.
  bool get hasPlayButton => videoUrl != null && videoUrl!.isNotEmpty;

  static Map<String, dynamic>? _projectOf(Map<String, dynamic> row) =>
      row['project'] as Map<String, dynamic>?;

  static Map<String, dynamic>? _assetOf(Map<String, dynamic> row) =>
      row['asset'] as Map<String, dynamic>?;

  factory NewsItemData.fromSupabaseRow(Map<String, dynamic> row) {
    return NewsItemData(
      id: row['id'] as String,
      title: row['title'] as String,
      projectId: row['project_id'] as String?,
      assetId: row['asset_id'] as String?,
      brandId: _projectOf(row)?['brand_id'] as String?,
      brand: (_projectOf(row)?['brand'] as Map<String, dynamic>?)?['name']
          as String?,
      // The legacy `news.region` column was free-form (e.g. "Málaga"); the
      // closest field on `assets` is `city`, which is what the UI already
      // renders as the region filter ("MÁLAGA", "DUBAI"…).
      region: (_assetOf(row)?['city'] ??
          (_projectOf(row)?['projectAsset']
              as Map<String, dynamic>?)?['city']) as String?,
      subtitle: row['subtitle'] as String?,
      imageUrl: row['image_url'] as String?,
      videoUrl: row['video_url'] as String?,
      date: DateTime.parse(row['date'] as String),
      type: NewsTypeX.fromString(row['type'] as String? ?? ''),
      body: row['body'] as String?,
      useLightOverlay: row['use_light_overlay'] as bool? ?? true,
    );
  }
}
