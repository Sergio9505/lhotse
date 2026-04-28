import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/domain/asset_data.dart';
import '../../../../core/domain/brand_data.dart';
import '../../../../core/domain/news_item_data.dart';
import '../../../../core/domain/project_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_image.dart';
import '../../../../core/widgets/lhotse_video_player.dart';
import '../../domain/feed_item.dart';

/// Universal card for every [FeedItem] variant. Each card fills the full
/// viewport (minus the header) and splits into:
///
///   • media  ~65% — image or video, full-bleed, no overlay.
///   • caption ~35% — beige surface with title, meta row, and a textual CTA.
///
/// Stateful so we can precache the image in `didChangeDependencies` the first
/// time the card is built — PageView.builder constructs the active card and
/// its ±1 neighbours, so by the time the user swipes + taps, the decoded
/// bytes are already in `ImageCache`. That's what keeps the Hero flight
/// butter-smooth (Instagram / Pinterest / Unsplash pattern).
class FeedCard extends StatefulWidget {
  const FeedCard({
    super.key,
    required this.item,
    required this.height,
    required this.isActive,
  });

  final FeedItem item;
  final double height;

  /// True when this card is the dominant one on screen. Used to drive
  /// video playback (only the active card plays).
  final bool isActive;

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      final content = _contentFor(widget.item);
      // Fire-and-forget; if it fails the widget still renders via
      // CachedNetworkImage's own error path.
      LhotseImage.precache(content.imageUrl, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _contentFor(widget.item);
    final heroTag = _heroTagFor(widget.item);
    return GestureDetector(
      onTap: () => _navigate(context, widget.item),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: widget.height,
        child: Column(
          children: [
            // Media takes all remaining space — caption hugs its content so
            // the image dominates the viewport without a wall of empty beige.
            // Hero tag matches the archive cards so tapping a feed item
            // animates the image into the detail hero with shared-element
            // continuity (project-hero-{id}, news-hero-{id}). The explicit
            // flightShuttleBuilder renders the source's already-loaded media
            // during the flight so the destination screen never has a chance
            // to flash an empty placeholder if its own image subscription
            // hasn't produced a frame yet.
            Expanded(
              child: heroTag != null
                  ? Hero(
                      tag: heroTag,
                      flightShuttleBuilder: _flightShuttleBuilder,
                      child: _Media(
                        imageUrl: content.imageUrl,
                        videoUrl: content.videoUrl,
                        isActive: widget.isActive,
                      ),
                    )
                  : _Media(
                      imageUrl: content.imageUrl,
                      videoUrl: content.videoUrl,
                      isActive: widget.isActive,
                    ),
            ),
            _Caption(content: content),
          ],
        ),
      ),
    );
  }

  Widget _flightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final content = _contentFor(widget.item);
    final hasVideo =
        content.videoUrl != null && content.videoUrl!.isNotEmpty;
    // Video cards: the resting state (both in feed and detail) is either the
    // playing video or — during VideoPlayerController init — a plain dark
    // frame. Rendering the still poster as the Hero shuttle would flash an
    // image the user never otherwise sees on that card ("se ve
    // momentáneamente la imagen"), breaking the video↔video continuity.
    // Match the Home scaffold background instead.
    //
    // Image cards: the still poster IS the resting state, so LhotseImage as
    // shuttle is coherent. It's also precached by HomeScreen._precacheFeed
    // so resolution is instant.
    //
    // We can't mount FeedVideoPlayer inside the shuttle — Flutter would
    // create a new VideoPlayerController mid-flight and AVFoundation would
    // hit naturalSize synchronously, blocking the main thread.
    if (hasVideo) {
      return Container(color: AppColors.primary);
    }
    return LhotseImage(content.imageUrl);
  }

  String? _heroTagFor(FeedItem item) {
    switch (item) {
      case FeedProjectItem(:final project):
        return 'project-hero-${project.id}';
      case FeedNewsItem(:final news):
        return 'news-hero-${news.id}';
      case FeedAssetItem(:final asset):
        return 'asset-hero-${asset.id}';
      case FeedBrandItem():
        // Brand detail does not define a matching Hero yet; leaving null
        // skips the shared-element transition for that variant.
        return null;
    }
  }

  _FeedContent _contentFor(FeedItem item) {
    switch (item) {
      case FeedProjectItem(:final project):
        return _FeedContent.fromProject(project, cta: 'VER PROYECTO');
      case FeedNewsItem(:final news):
        return _FeedContent.fromNews(news);
      case FeedBrandItem(:final brand):
        return _FeedContent.fromBrand(brand);
      case FeedAssetItem(:final asset):
        return _FeedContent.fromAsset(asset);
    }
  }

  void _navigate(BuildContext context, FeedItem item) {
    // Pass the already-loaded domain object as `extra` so the detail screen
    // can render its Hero widget on the first frame — without waiting on the
    // remote provider to resolve. This is what keeps the shared-element
    // transition continuous (instead of: tap → spinner → land on final
    // position with no flight). See ADR-53 / ProjectDetailScreen docstring.
    switch (item) {
      case FeedProjectItem(:final project):
        context.push('/projects/${project.id}', extra: project);
      case FeedNewsItem(:final news):
        context.push('/news/${news.id}', extra: news);
      case FeedBrandItem(:final brand):
        context.push('/brands/${brand.id}', extra: brand);
      case FeedAssetItem(:final asset):
        context.push('/assets/${asset.id}', extra: asset);
    }
  }
}

// ── Media block ──────────────────────────────────────────────────────────────

class _Media extends StatelessWidget {
  const _Media({
    required this.imageUrl,
    required this.videoUrl,
    required this.isActive,
  });

  final String imageUrl;
  final String? videoUrl;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (videoUrl != null && videoUrl!.isNotEmpty) {
      return LhotseVideoPlayer(
        videoUrl: videoUrl!,
        posterUrl: imageUrl,
        isActive: isActive,
      );
    }
    return LhotseImage(imageUrl);
  }
}

// ── Caption block ────────────────────────────────────────────────────────────

class _Caption extends StatelessWidget {
  const _Caption({required this.content});
  final _FeedContent content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title — one step below archive's displayHero (48pt Light) to
          // stay a beat louder than archive while sharing the same Campton
          // Light (w300) tipographic family. Keeps Home's SNKRS character
          // in structure (one per viewport, media dominates) but aligns
          // tipografía with the rest of the system.
          Text(
            content.title,
            style: AppTypography.editorialHero.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetaWithCta(
            brand: content.brand,
            parts: content.metaParts,
            cta: content.cta,
          ),
        ],
      ),
    );
  }
}

/// Meta row (brand · city · date) with the CTA aligned to the right.
///
/// Brand renders as a `labelUppercaseSm` tracked uppercase span (brand-mark
/// role — same as byline in news_detail and archive cards). City/date keep
/// `annotation` mixed case for consistency with ProjectShowcaseCard in the
/// archive ("Málaga" not "MÁLAGA"). CTA uses `labelUppercaseMd` — its
/// documented role ("DESCARGAR FOLLETO", "VISITAR WEB").
class _MetaWithCta extends StatelessWidget {
  const _MetaWithCta({
    required this.brand,
    required this.parts,
    required this.cta,
  });

  final String? brand;
  final List<String> parts;
  final String cta;

  @override
  Widget build(BuildContext context) {
    final hasBrand = brand != null && brand!.isNotEmpty;
    final dotStyle = AppTypography.annotation.copyWith(
      color: AppColors.accentMuted.withValues(alpha: 0.5),
    );
    final metaStyle = AppTypography.annotation.copyWith(
      color: AppColors.accentMuted,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                if (hasBrand) ...[
                  TextSpan(
                    text: brand!.toUpperCase(),
                    style: AppTypography.labelUppercaseSm.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (parts.isNotEmpty)
                    TextSpan(text: '  ·  ', style: dotStyle),
                ],
                for (int i = 0; i < parts.length; i++) ...[
                  TextSpan(text: parts[i], style: metaStyle),
                  if (i < parts.length - 1)
                    TextSpan(text: '  ·  ', style: dotStyle),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          cta,
          style: AppTypography.labelUppercaseMd.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        const PhosphorIcon(
          PhosphorIconsThin.arrowUpRight,
          size: 14,
          color: AppColors.textPrimary,
        ),
      ],
    );
  }
}

// ── Content resolver ─────────────────────────────────────────────────────────

/// Normalized view of a [FeedItem] for the generic card renderer. Each
/// factory folds variant-specific fields into the shared caption grammar.
class _FeedContent {
  const _FeedContent({
    required this.title,
    required this.imageUrl,
    required this.videoUrl,
    required this.brand,
    required this.metaParts,
    required this.cta,
  });

  final String title;
  final String imageUrl;
  final String? videoUrl;

  /// Brand name rendered as uppercase tracked span — separate from [metaParts]
  /// so the renderer can apply `labelUppercaseSm` only to this segment while
  /// keeping city/date in `annotation` mixed case.
  final String? brand;

  /// Descriptive meta tokens (city, date, business model…) — mixed case,
  /// rendered with `annotation` style and muted ink.
  final List<String> metaParts;

  final String cta;

  factory _FeedContent.fromProject(ProjectData p, {required String cta}) {
    return _FeedContent(
      title: p.name,
      imageUrl: p.imageUrl,
      videoUrl: p.videoUrl,
      brand: p.brand.isNotEmpty ? p.brand : null,
      // City only (no country code): consistent with ProjectShowcaseCard in
      // archive — "Málaga" / "Dubai" / "Miami" read cleaner and more luxury
      // than "Málaga, ES" / "Dubai, AE".
      metaParts: [
        if (p.city.isNotEmpty) p.city,
      ],
      cta: cta,
    );
  }

  factory _FeedContent.fromNews(NewsItemData n) {
    final date = DateFormat('d MMM yyyy', 'es_ES').format(n.date);
    return _FeedContent(
      title: n.title,
      imageUrl: n.imageUrl,
      videoUrl: n.videoUrl,
      brand: (n.brand?.isNotEmpty ?? false) ? n.brand : null,
      metaParts: [date],
      cta: 'LEER',
    );
  }

  factory _FeedContent.fromBrand(BrandData b) {
    return _FeedContent(
      title: b.tagline ?? b.name,
      imageUrl: b.coverImageUrl,
      videoUrl: null,
      brand: b.name,
      metaParts: [b.businessModel.displayName],
      cta: 'EXPLORAR',
    );
  }

  factory _FeedContent.fromAsset(AssetData a) {
    final title = (a.address?.isNotEmpty ?? false) ? a.address! : a.location;
    return _FeedContent(
      title: title,
      imageUrl: a.thumbnailImage ?? '',
      videoUrl: null,
      brand: null,
      metaParts: [
        if (a.city?.isNotEmpty ?? false) a.city!,
        if (a.country?.isNotEmpty ?? false) a.country!,
      ],
      cta: 'EXPLORAR',
    );
  }
}
