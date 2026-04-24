import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Smart image widget: uses `Image.asset` for paths starting with `assets/`,
/// `CachedNetworkImage` (disk + memory cache) for URLs. The disk cache is
/// what keeps Hero transitions smooth — once an image has been loaded, it
/// renders instantly on subsequent views regardless of whether the app was
/// restarted in between. The shared `AppColors.surface` placeholder + fade
/// keep the transition from ever flashing a white hole.
class LhotseImage extends StatelessWidget {
  const LhotseImage(
    this.source, {
    super.key,
    this.fit = BoxFit.cover,
  });

  final String source;
  final BoxFit fit;

  bool get _isAsset => source.startsWith('assets/');

  /// Kick off a decode into Flutter's `ImageCache` before the image is
  /// actually mounted. Call this as soon as you know the user is *likely* to
  /// view the image — e.g. when a feed card enters the PageView's build
  /// range. By the time the user taps the card, the Hero flight lands on a
  /// widget whose bytes are already decoded → zero flicker.
  ///
  /// Mirrors the URL-vs-asset branching of `build` so callers don't have to
  /// duplicate the decision.
  static Future<void> precache(String source, BuildContext context) {
    if (source.startsWith('assets/')) {
      return precacheImage(AssetImage(source), context);
    }
    return precacheImage(CachedNetworkImageProvider(source), context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isAsset) {
      return Image.asset(
        source,
        fit: fit,
        errorBuilder: (_, _, _) => Container(color: AppColors.surface),
      );
    }
    return CachedNetworkImage(
      imageUrl: source,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => Container(color: AppColors.surface),
      errorWidget: (_, _, _) => Container(color: AppColors.surface),
    );
  }
}
