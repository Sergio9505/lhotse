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
    this.brandId,
    this.brand,
    this.projectId,
    this.region,
    this.subtitle,
    required this.imageUrl,
    this.videoUrl,
    required this.date,
    required this.type,
    this.hasPlayButton = false,
    this.body,
  });

  final String id;
  final String title;
  /// Canonical brand reference — use for programmatic filters (related news,
  /// news per brand, etc.). `brand` (name) is kept for user-facing filter chips
  /// on `all_news_screen` that display the brand name directly.
  final String? brandId;
  final String? brand;
  /// Canonical project reference when the news is tied to a specific project.
  /// Used by coinversion L3 to show news relevant to that project first.
  final String? projectId;
  final String? region;
  final String? subtitle;
  final String imageUrl;
  final String? videoUrl;
  final DateTime date;
  final NewsType type;
  final bool hasPlayButton;
  final String? body;

  factory NewsItemData.fromSupabaseRow(Map<String, dynamic> row) {
    final brands = row['brands'] as Map<String, dynamic>?;
    return NewsItemData(
      id: row['id'] as String,
      title: row['title'] as String,
      brandId: row['brand_id'] as String?,
      brand: brands?['name'] as String? ?? row['brand'] as String?,
      projectId: row['project_id'] as String?,
      region: row['region'] as String?,
      subtitle: row['subtitle'] as String?,
      imageUrl: row['image_url'] as String,
      videoUrl: row['video_url'] as String?,
      date: DateTime.parse(row['date'] as String),
      type: NewsTypeX.fromString(row['type'] as String? ?? ''),
      hasPlayButton: row['has_play_button'] as bool? ?? false,
      body: row['body'] as String?,
    );
  }
}
