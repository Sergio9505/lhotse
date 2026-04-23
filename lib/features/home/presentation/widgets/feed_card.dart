import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/domain/brand_data.dart';
import '../../../../core/domain/news_item_data.dart';
import '../../../../core/domain/project_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_image.dart';
import '../../domain/feed_item.dart';
import 'feed_video_player.dart';

/// Universal card for every [FeedItem] variant. Each card fills the full
/// viewport (minus the header) and splits into:
///
///   • media  ~65% — image or video, full-bleed, no overlay.
///   • caption ~35% — beige surface with title, meta row, and a textual CTA.
class FeedCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final content = _contentFor(item);
    final heroTag = _heroTagFor(item);
    return GestureDetector(
      onTap: () => _navigate(context, item),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            // Media takes all remaining space — caption hugs its content so
            // the image dominates the viewport without a wall of empty beige.
            // Hero tag matches the archive cards so tapping a feed item
            // animates the image into the detail hero with shared-element
            // continuity (project-hero-{id}, news-hero-{id}).
            Expanded(
              child: heroTag != null
                  ? Hero(
                      tag: heroTag,
                      child: _Media(
                        imageUrl: content.imageUrl,
                        videoUrl: content.videoUrl,
                        isActive: isActive,
                      ),
                    )
                  : _Media(
                      imageUrl: content.imageUrl,
                      videoUrl: content.videoUrl,
                      isActive: isActive,
                    ),
            ),
            _Caption(content: content),
          ],
        ),
      ),
    );
  }

  static String? _heroTagFor(FeedItem item) {
    switch (item) {
      case FeedProjectItem(:final project):
      case FeedOpportunityItem(:final project):
        return 'project-hero-${project.id}';
      case FeedNewsItem(:final news):
        return 'news-hero-${news.id}';
      case FeedBrandItem():
        // Brand detail does not define a matching Hero yet; leaving null
        // skips the shared-element transition for that variant.
        return null;
    }
  }

  static _FeedContent _contentFor(FeedItem item) {
    switch (item) {
      case FeedProjectItem(:final project):
        return _FeedContent.fromProject(project, cta: 'VER PROYECTO');
      case FeedOpportunityItem(:final project):
        return _FeedContent.fromProject(project, cta: 'VER OPORTUNIDAD');
      case FeedNewsItem(:final news):
        return _FeedContent.fromNews(news);
      case FeedBrandItem(:final brand):
        return _FeedContent.fromBrand(brand);
    }
  }

  static void _navigate(BuildContext context, FeedItem item) {
    switch (item) {
      case FeedProjectItem(:final project):
        context.push('/projects/${project.id}');
      case FeedOpportunityItem(:final project):
        context.push('/projects/${project.id}');
      case FeedNewsItem(:final news):
        context.push('/news/${news.id}');
      case FeedBrandItem(:final brand):
        context.push('/brands/${brand.id}');
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
      return FeedVideoPlayer(
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
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w300,
              height: 1.0,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetaWithCta(parts: content.metaParts, cta: content.cta),
        ],
      ),
    );
  }
}

/// Meta row (brand · location · date) with the CTA aligned to the right.
/// Keeping everything on the same line packs the caption tight so the reader
/// sees the full identity of the item at a glance without scanning.
class _MetaWithCta extends StatelessWidget {
  const _MetaWithCta({required this.parts, required this.cta});

  final List<String> parts;
  final String cta;

  @override
  Widget build(BuildContext context) {
    // Meta in mixed case for data consistency with the archive views
    // (project.city is rendered mixed case in ProjectShowcaseCard as a
    // descriptive subtitle; "Málaga" must read the same in Home and
    // archive, not "MÁLAGA" here and "Málaga" there).
    //
    // CTA keeps uppercase for UI convention consistency with the rest of
    // the app (filter chips, detail buttons like DESCARGAR FOLLETO, etc.).
    // The case contrast gives the CTA slightly more presence — acceptable
    // because it's the actionable element.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.accentMuted,
                letterSpacing: 0.2,
              ),
              children: [
                for (int i = 0; i < parts.length; i++) ...[
                  TextSpan(text: parts[i]),
                  if (i < parts.length - 1)
                    TextSpan(
                      text: '  ·  ',
                      style: TextStyle(
                        color: AppColors.accentMuted.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          cta,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 4),
        const PhosphorIcon(
          PhosphorIconsThin.arrowUpRight,
          size: 12,
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
    required this.metaParts,
    required this.cta,
  });

  final String title;
  final String imageUrl;
  final String? videoUrl;
  final List<String> metaParts;
  final String cta;

  factory _FeedContent.fromProject(ProjectData p, {required String cta}) {
    return _FeedContent(
      title: p.name,
      imageUrl: p.imageUrl,
      videoUrl: p.videoUrl,
      // City only (no country code): consistent with ProjectShowcaseCard in
      // archive — "Málaga" / "Dubai" / "Miami" read cleaner and more luxury
      // than "Málaga, ES" / "Dubai, AE". Same data, same treatment across
      // Home and archive so the project's location string is identical in
      // both views.
      metaParts: [
        if (p.brand.isNotEmpty) p.brand,
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
      metaParts: [
        if ((n.brand ?? '').isNotEmpty) n.brand!,
        date,
      ],
      cta: 'LEER',
    );
  }

  factory _FeedContent.fromBrand(BrandData b) {
    return _FeedContent(
      title: b.tagline ?? b.name,
      imageUrl: b.coverImageUrl,
      videoUrl: null,
      metaParts: [b.name, b.businessModel.displayName],
      cta: 'EXPLORAR',
    );
  }
}
