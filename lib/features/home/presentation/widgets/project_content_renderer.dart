import 'package:flutter/material.dart';

import '../../../../core/domain/content_block.dart';
import '../../../../core/domain/media_item.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_gallery_helpers.dart';
import '../../../../core/widgets/lhotse_image.dart';
import '../../../profile/presentation/embedded_webview_screen.dart';

/// Renders a `ProjectData.content` body as a vertical stack of typed
/// editorial blocks. Tokens are fixed (typography, spacing, padding) —
/// the admin only decides which blocks and in which order.
///
/// Token map (aligned with the existing language of project_detail_screen):
///   heading → sectionLabel 12 w400 ls 1.8 UPPER + accentMuted color.
///             Same token as "TOUR VIRTUAL" / "GALERÍA" / "NOTICIAS
///             RELEVANTES" so the body's section dividers read as part of
///             the same zone-organiser vocabulary. `.toUpperCase()` is
///             applied at render time so the admin types natural casing.
///   text    → bodyReading 14/w400 h1.7 (pixel-fidel to the previous
///             plain-description render).
///   image   → 3:2 LhotseImage with lateral padding `lg`; tap →
///             showMediaGallery.
///   gallery → horizontal carousel, cards at 75% screen width, infinite
///             loop when N≥2, no dots — same pattern as the post-cierre
///             gallery in project_detail_screen.dart and the L3 Avance
///             renders. Tap on any card opens the paged viewer at that
///             index.
///   video   → 16:9 VideoThumbnailTile with lateral padding `lg`; tap →
///             showMediaGallery (audio enabled in viewer).
///
/// Spacing:
///   - Initial gap before the first block: `xl` (32 px). Combined with the
///     `md` (16 px) bottom padding of the project header, total breath
///     between byline and content is 48 px — matches the gap before the
///     tour virtual / post-cierre gallery sections.
///   - Between blocks: `lg` (24 px) by default; `xxl` (48 px) before any
///     `heading` that isn't the first block — gives the section divider
///     air to read as a separator.
class ProjectContentRenderer extends StatelessWidget {
  const ProjectContentRenderer({super.key, required this.blocks});

  final List<ContentBlock> blocks;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (i > 0) {
        children.add(SizedBox(
          height: block is HeadingBlock ? AppSpacing.xxl : AppSpacing.lg,
        ));
      }
      children.add(_renderBlock(context, block));
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _renderBlock(BuildContext context, ContentBlock block) {
    return switch (block) {
      HeadingBlock(:final text) => _HeadingView(text: text),
      TextBlock(:final text) => _BodyView(text: text),
      ImageBlock(:final url) => _SingleImageView(url: url),
      GalleryBlock(:final items) => _GalleryView(items: items),
      VideoBlock(:final url) => _VideoView(url: url),
      CtaBlock(:final label, :final url) => _CtaView(label: label, url: url),
    };
  }
}

class _HeadingView extends StatelessWidget {
  const _HeadingView({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.sectionLabel.copyWith(
          color: AppColors.accentMuted,
        ),
      ),
    );
  }
}

class _BodyView extends StatelessWidget {
  const _BodyView({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        text,
        style: AppTypography.bodyReading.copyWith(
          color: AppColors.textPrimary,
          height: 1.7,
        ),
      ),
    );
  }
}

class _SingleImageView extends StatelessWidget {
  const _SingleImageView({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () => showMediaGallery(
          context,
          items: [MediaItem(type: MediaType.image, url: url)],
          initialIndex: 0,
        ),
        child: AspectRatio(
          aspectRatio: 3 / 2,
          child: LhotseImage(url),
        ),
      ),
    );
  }
}

class _VideoView extends StatelessWidget {
  const _VideoView({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () => showMediaGallery(
          context,
          items: [MediaItem(type: MediaType.video, url: url)],
          initialIndex: 0,
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoThumbnailTile(url: url),
        ),
      ),
    );
  }
}

/// In-flow CTA. Clones the visual of `_WebCta` in `brand_detail_screen.dart`
/// (full-width black bg + Campton uppercase white label, no radius). Tap
/// pushes `EmbeddedWebViewScreen` — same in-app webview used by the brand
/// CTA, the legal pages in Profile, and external news links. The URL is
/// constrained to `https://…` by the admin Zod schema; this widget assumes
/// it valid.
class _CtaView extends StatelessWidget {
  const _CtaView({required this.label, required this.url});
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EmbeddedWebViewScreen(url: url),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: AppColors.primary,
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: AppTypography.labelUppercaseMd.copyWith(
                color: AppColors.textOnDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal carousel cloned from the canonical pattern at
/// project_detail_screen.dart:531-608 (post-cierre gallery) and
/// _InvestmentGallery in coinversion_detail_screen.dart:1347-1414 (L3
/// Avance renders). Cards at 75% screen width with a peek of the next,
/// infinite loop when N≥2 (`itemCount * 1000` + modulo), no dots
/// indicator. Tap on any card opens `showMediaGallery` at that index.
///
/// Items are `MediaItem`s — image cards render `LhotseImage`, video cards
/// render `VideoThumbnailTile` (auto-shows the Bunny static thumbnail when
/// the URL is Bunny). The viewer (`showMediaGallery`) handles autoplay on
/// video items uniformly across all editorial galleries in the app.
class _GalleryView extends StatelessWidget {
  const _GalleryView({required this.items});
  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final screenWidth = MediaQuery.of(context).size.width;
    final count = items.length;
    final loop = count > 1;

    return SizedBox(
      height: 200,
      child: ListView.separated(
        key: PageStorageKey('content-gallery-${identityHashCode(items)}'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: loop ? count * 1000 : count,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final idx = i % count;
          final item = items[idx];
          return GestureDetector(
            onTap: () => showMediaGallery(
              context,
              items: items,
              initialIndex: idx,
            ),
            child: Container(
              width: screenWidth * 0.75,
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: item.type == MediaType.image
                  ? LhotseImage(item.url)
                  : VideoThumbnailTile(url: item.url),
            ),
          );
        },
      ),
    );
  }
}
