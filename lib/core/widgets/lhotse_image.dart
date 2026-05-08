import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

/// Distinguishes the icon shown when a thumbnail is missing or fails to load.
/// Defaults to [image]; pass [video] for entries that semantically represent
/// a video (project/news with `videoUrl`, video gallery items).
enum LhotseImagePlaceholder { image, video }

/// Smart image widget: uses `Image.asset` for paths starting with `assets/`,
/// `CachedNetworkImage` (disk + memory cache) for URLs. The disk cache is
/// what keeps Hero transitions smooth — once an image has been loaded, it
/// renders instantly on subsequent views regardless of whether the app was
/// restarted in between. The shared `AppColors.surface` background + fade
/// keep the transition from ever flashing a white hole.
///
/// When the source is missing or the load fails, a centered Phosphor icon
/// over the beige surface signals absence. During an in-flight network load
/// the surface is rendered plain (no icon) so the icon doesn't flash before
/// the real image fades in.
class LhotseImage extends StatelessWidget {
  const LhotseImage(
    this.source, {
    super.key,
    this.fit = BoxFit.cover,
    this.placeholder = LhotseImagePlaceholder.image,
  });

  final String? source;
  final BoxFit fit;
  final LhotseImagePlaceholder placeholder;

  bool get _hasSource => source != null && source!.isNotEmpty;
  bool get _isAsset => _hasSource && source!.startsWith('assets/');

  /// Kick off a decode into Flutter's `ImageCache` before the image is
  /// actually mounted. Call this as soon as you know the user is *likely* to
  /// view the image — e.g. when a feed card enters the PageView's build
  /// range. By the time the user taps the card, the Hero flight lands on a
  /// widget whose bytes are already decoded → zero flicker.
  ///
  /// Mirrors the URL-vs-asset branching of `build` so callers don't have to
  /// duplicate the decision. Null/empty sources are a no-op.
  static Future<void> precache(String? source, BuildContext context) {
    if (source == null || source.isEmpty) return Future.value();
    if (source.startsWith('assets/')) {
      return precacheImage(AssetImage(source), context);
    }
    return precacheImage(CachedNetworkImageProvider(source), context);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasSource) {
      return _LhotseImagePlaceholder(kind: placeholder);
    }
    if (_isAsset) {
      return Image.asset(
        source!,
        fit: fit,
        errorBuilder: (_, _, _) => _LhotseImagePlaceholder(kind: placeholder),
      );
    }
    return CachedNetworkImage(
      imageUrl: source!,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => Container(color: AppColors.surface),
      errorWidget: (_, _, _) => _LhotseImagePlaceholder(kind: placeholder),
    );
  }
}

class _LhotseImagePlaceholder extends StatelessWidget {
  const _LhotseImagePlaceholder({required this.kind});

  final LhotseImagePlaceholder kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size =
              (constraints.biggest.shortestSide * 0.28).clamp(20.0, 64.0);
          return Center(
            child: PhosphorIcon(
              kind == LhotseImagePlaceholder.video
                  ? PhosphorIconsThin.filmSlate
                  : PhosphorIconsThin.image,
              size: size,
              color: AppColors.textPrimary.withValues(alpha: 0.18),
            ),
          );
        },
      ),
    );
  }
}
