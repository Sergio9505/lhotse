import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';

/// Distinguishes the icon shown when a thumbnail is missing or fails to load.
/// Defaults to [image]; pass [video] for entries that semantically represent
/// a video (project/news with `videoUrl`, video gallery items).
enum LhotseImagePlaceholder { image, video }

/// Smart image widget: uses `Image.asset` for paths starting with `assets/`,
/// and `Image(image: CachedNetworkImageProvider(...))` for URLs. Network
/// path goes through `PaintingBinding.imageCache` (Flutter's built-in
/// in-memory decoded cache) AND CNI's disk cache — best of both worlds:
/// disk persistence across restarts + synchronous render on warm-memory
/// cache hits via `frameBuilder.wasSynchronouslyLoaded`.
///
/// Render policy: **instant in every case, no fade-in**. The 180ms fade
/// pattern (Material 2015) reads as "generic app" in luxury/editorial
/// contexts. Refs: Sotheby's, Hermès, Apple Photos — images appear in
/// frame 1, no transition. The premium feel comes from the image itself,
/// not from animating its entrance.
///
/// Cold load (first-time, no cache) shows only the neutral `AppColors.surface`
/// background; the image replaces it directly when the first frame
/// arrives. When the source is missing or the load fails, a centered
/// Phosphor icon over the beige surface signals absence.
///
/// Supports a runtime [fallbacks] cascade: when [source] errors at load
/// time, the widget advances through each fallback in order before falling
/// back to the placeholder icon.
class LhotseImage extends StatefulWidget {
  const LhotseImage(
    this.source, {
    super.key,
    this.fit = BoxFit.cover,
    this.placeholder = LhotseImagePlaceholder.image,
    this.fallbacks = const [],
  });

  /// Poster builder for any entity that may have a video.
  ///
  /// Returns [imageUrl] directly — the admin-curated cover, denormalized
  /// from `hero_media[0]` on every save (news + projects). The [videoUrl]
  /// param only drives the placeholder glyph (`video` vs `image`) shown
  /// when [imageUrl] itself fails to load. No Bunny CDN thumbnail
  /// fallback: the curated hero gallery first image is the single source
  /// of truth for posters. The 2.5s inline autoplay on project detail
  /// (muted loop, `LhotseVideoPlayer`) stays unchanged — a small visual
  /// swap from poster → first video frame at autoplay time is acceptable.
  factory LhotseImage.poster({
    Key? key,
    required String? videoUrl,
    required String? imageUrl,
    BoxFit fit = BoxFit.cover,
  }) {
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    return LhotseImage(
      imageUrl,
      key: key,
      fit: fit,
      placeholder: hasVideo
          ? LhotseImagePlaceholder.video
          : LhotseImagePlaceholder.image,
    );
  }

  final String? source;
  final BoxFit fit;
  final LhotseImagePlaceholder placeholder;

  /// Ordered fallbacks tried at runtime when [source] (or a previous
  /// fallback) fails to load. Empty list = no cascade.
  final List<String> fallbacks;

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
  State<LhotseImage> createState() => _LhotseImageState();
}

class _LhotseImageState extends State<LhotseImage> {
  int _stage = 0;

  @override
  void didUpdateWidget(LhotseImage old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source ||
        old.fallbacks.length != widget.fallbacks.length ||
        !_sameList(old.fallbacks, widget.fallbacks)) {
      _stage = 0;
    }
  }

  bool _sameList(List<String> a, List<String> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String? _sourceAt(int stage) {
    if (stage == 0) return widget.source;
    final idx = stage - 1;
    return idx < widget.fallbacks.length ? widget.fallbacks[idx] : null;
  }

  bool get _canAdvance => _stage < widget.fallbacks.length;

  Widget _onError() {
    if (_canAdvance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _canAdvance) setState(() => _stage++);
      });
      return Container(color: AppColors.surface);
    }
    return _LhotseImagePlaceholder(kind: widget.placeholder);
  }

  @override
  Widget build(BuildContext context) {
    final src = _sourceAt(_stage);
    if (src == null || src.isEmpty) return _onError();
    if (src.startsWith('assets/')) {
      return Image.asset(
        src,
        fit: widget.fit,
        errorBuilder: (_, _, _) => _onError(),
      );
    }
    return Image(
      image: CachedNetworkImageProvider(src),
      fit: widget.fit,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        // Memory cache hit: child renders in this frame, no transition.
        // First frame decoded from disk/network: render directly when it
        // arrives (no fade). Otherwise show the neutral surface — no
        // spinner, no animation.
        if (wasSynchronouslyLoaded || frame != null) return child;
        return Container(color: AppColors.surface);
      },
      errorBuilder: (_, _, _) => _onError(),
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
