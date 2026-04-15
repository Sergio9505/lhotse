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
    this.brand,
    this.region,
    this.subtitle,
    required this.imageUrl,
    required this.date,
    required this.type,
    this.hasPlayButton = false,
    this.body,
  });

  final String id;
  final String title;
  final String? brand;
  final String? region;
  final String? subtitle;
  final String imageUrl;
  final DateTime date;
  final NewsType type;
  final bool hasPlayButton;
  final String? body;

  factory NewsItemData.fromSupabaseRow(Map<String, dynamic> row) {
    final brands = row['brands'] as Map<String, dynamic>?;
    return NewsItemData(
      id: row['id'] as String,
      title: row['title'] as String,
      brand: brands?['name'] as String? ?? row['brand'] as String?,
      region: row['region'] as String?,
      subtitle: row['subtitle'] as String?,
      imageUrl: row['image_url'] as String,
      date: DateTime.parse(row['date'] as String),
      type: NewsTypeX.fromString(row['type'] as String? ?? ''),
      hasPlayButton: row['has_play_button'] as bool? ?? false,
      body: row['body'] as String?,
    );
  }
}
