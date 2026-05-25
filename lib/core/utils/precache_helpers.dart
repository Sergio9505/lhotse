import 'package:flutter/material.dart';

import '../widgets/lhotse_image.dart';

/// Fire-and-forget precache for a batch of image URLs.
///
/// Nulls and empty strings are skipped. `CachedNetworkImage` is
/// idempotent — repeat calls against an already-cached URL hit the
/// existing disk/memory entry without re-downloading. Use this when
/// entering a detail screen to warm the `ImageCache` for every piece
/// of media the user can navigate to without blocking the render.
///
/// The returned `Future` completes once every URL has been resolved
/// (cache hit or fresh download). Callers usually do not need to await
/// it — the cache warms in the background while the screen builds.
Future<void> precacheImageUrls(
  BuildContext context,
  Iterable<String?> urls,
) async {
  await Future.wait(
    urls
        .where((u) => u != null && u.isNotEmpty)
        .map((u) => LhotseImage.precache(u, context)),
  );
}
