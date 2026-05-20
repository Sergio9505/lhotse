/// Extract the ordered `image`-type URLs from a `hero_media` jsonb array.
///
/// Shape (mirrored from `assets.gallery_media` / `projects.gallery_media`,
/// per ADR-70 / ADR-71): `[{type:'image'|'video', url}, ...]`. Only
/// `type=='image'` entries are returned today — the multi-image hero
/// carousel does not mix video into the swipe sequence (per ADR-62,
/// `video_url` wins over the carousel in the hero).
///
/// Tolerates malformed rows (non-array root, non-object elements, missing
/// `type` / `url`, empty url) by skipping them. The CHECK constraint on the
/// column guards the happy path; this helper is the second line of
/// defense at the deserialization boundary.
List<String> parseHeroMediaImageUrls(Object? raw) {
  if (raw is! List) return const <String>[];
  final out = <String>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    if (entry['type'] != 'image') continue;
    final url = entry['url'];
    if (url is String && url.isNotEmpty) out.add(url);
  }
  return out;
}
