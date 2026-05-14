import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/bunny_thumbnail.dart';
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
///
/// Supports a runtime [fallbacks] cascade: when [source] errors at load
/// time, the widget advances through each fallback in order before falling
/// back to the placeholder icon. Use the [LhotseImage.poster] factory for
/// the Bunny video poster pattern (`thumbnail.jpg` → `thumbnail_1.jpg` →
/// explicit DB `image_url` → placeholder).
class LhotseImage extends StatefulWidget {
  const LhotseImage(
    this.source, {
    super.key,
    this.fit = BoxFit.cover,
    this.placeholder = LhotseImagePlaceholder.image,
    this.fallbacks = const [],
  });

  /// Bunny-aware poster builder. Resolves a cascade for videos hosted on
  /// Bunny Stream:
  ///
  ///   1. `thumbnail.jpg` — curator-picked frame (only exists if someone
  ///      used "Set as thumbnail" in the Bunny dashboard).
  ///   2. `thumbnail_1.jpg` — auto-generated frame ~50% of the clip;
  ///      Bunny produces this for every processed video.
  ///   3. [imageUrl] — explicit `image_url` column from the DB.
  ///
  /// Each step is tried at load time; failure (404, network error) advances
  /// to the next. When all sources fail or are missing, the standard
  /// video-style placeholder icon is shown.
  factory LhotseImage.poster({
    Key? key,
    required String? videoUrl,
    required String? imageUrl,
    BoxFit fit = BoxFit.cover,
  }) {
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    final candidates = <String>[];
    if (hasVideo) {
      final custom = bunnyThumbnailUrlFor(videoUrl);
      final auto = bunnyAutoFrameUrlFor(videoUrl, frame: 1);
      if (custom != null) candidates.add(custom);
      if (auto != null) candidates.add(auto);
    }
    if (imageUrl != null && imageUrl.isNotEmpty) candidates.add(imageUrl);

    final primary = candidates.isNotEmpty ? candidates.first : null;
    final rest = candidates.length > 1
        ? candidates.sublist(1)
        : const <String>[];
    return LhotseImage(
      primary,
      key: key,
      fit: fit,
      placeholder: hasVideo
          ? LhotseImagePlaceholder.video
          : LhotseImagePlaceholder.image,
      fallbacks: rest,
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
    return CachedNetworkImage(
      imageUrl: src,
      fit: widget.fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => Container(color: AppColors.surface),
      errorWidget: (_, _, _) => _onError(),
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
