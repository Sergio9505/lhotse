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

/// Returns the best poster URL for a video-bearing item:
/// Bunny static thumbnail when [videoUrl] is a Bunny CDN URL,
/// or [fallback] otherwise (non-Bunny URL, null, or empty).
///
/// Returns `null` when neither a Bunny thumbnail nor a usable fallback is
/// available — let the consumer (typically `LhotseImage`) render its own
/// placeholder for that case.
///
/// Use this wherever a video player or image needs a poster that matches
/// the actual first frame of the video — keeps poster → playback seamless.
String? posterUrlFor({required String? videoUrl, required String? fallback}) {
  if (videoUrl == null || videoUrl.isEmpty) return fallback;
  return bunnyThumbnailUrlFor(videoUrl) ?? fallback;
}
