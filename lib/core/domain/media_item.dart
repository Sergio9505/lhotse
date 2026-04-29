enum MediaType { image, video }

class MediaItem {
  final MediaType type;
  final String url;

  const MediaItem({required this.type, required this.url});

  factory MediaItem.fromJson(Map<String, dynamic> j) => MediaItem(
        type: j['type'] == 'video' ? MediaType.video : MediaType.image,
        url: j['url'] as String,
      );

  Map<String, dynamic> toJson() => {
        'type': type == MediaType.video ? 'video' : 'image',
        'url': url,
      };
}
