/// Returns the Bunny Stream **custom** thumbnail URL for a given video URL,
/// or null if [videoUrl] is not a Bunny CDN URL.
///
/// `thumbnail.jpg` is the file produced when a curator picks a frame with
/// "Set as thumbnail" in the Bunny dashboard. It only exists if someone
/// actually picked one — for videos without a curated thumbnail, this URL
/// returns 404. Pair with [bunnyAutoFrameUrlFor] as a fallback.
String? bunnyThumbnailUrlFor(String videoUrl) {
  final base = _bunnyBaseFor(videoUrl);
  return base != null ? '$base/thumbnail.jpg' : null;
}

/// Returns the URL of an **auto-generated** thumbnail frame for a Bunny
/// Stream video, or null if [videoUrl] is not a Bunny CDN URL.
///
/// Bunny produces `thumbnail_0.jpg`, `thumbnail_1.jpg`, ... for every
/// processed video — these always exist as long as encoding finished.
/// `frame: 1` (~50% of the clip) is a good universal poster.
String? bunnyAutoFrameUrlFor(String videoUrl, {int frame = 1}) {
  final base = _bunnyBaseFor(videoUrl);
  return base != null ? '$base/thumbnail_$frame.jpg' : null;
}

/// Returns `https://{host}/{guid}` for a Bunny Stream URL, else null.
String? _bunnyBaseFor(String videoUrl) {
  Uri uri;
  try {
    uri = Uri.parse(videoUrl);
  } catch (_) {
    return null;
  }
  if (!uri.host.endsWith('.b-cdn.net')) return null;
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return null;
  return 'https://${uri.host}/${segments.first}';
}
