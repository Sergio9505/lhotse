/// Returns the Bunny Stream static thumbnail URL for a given video URL,
/// or null if [videoUrl] is not a Bunny CDN URL.
///
/// Bunny Stream auto-generates a thumbnail.jpg per video, served from the
/// same pull-zone host. The thumbnail second is configured in the Bunny
/// dashboard (default = 50% of the clip).
String? bunnyThumbnailUrlFor(String videoUrl) {
  Uri uri;
  try {
    uri = Uri.parse(videoUrl);
  } catch (_) {
    return null;
  }
  final host = uri.host;
  if (!host.endsWith('.b-cdn.net')) return null;
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return null;
  final guid = segments.first;
  return 'https://$host/$guid/thumbnail.jpg';
}
