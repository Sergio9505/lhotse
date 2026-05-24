import 'package:flutter/material.dart';

import '../../../../core/domain/content_block.dart';
import '../../../../core/domain/media_item.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_gallery_helpers.dart';
import '../../../../core/widgets/lhotse_image.dart';

/// Renders a `ProjectData.content` body as a vertical stack of typed
/// editorial blocks. Tokens are fixed (typography, spacing, full-bleed) —
/// the admin only decides which blocks and in which order.
///
/// Token map (validated against the existing cascade in project_detail_screen):
///   heading → editorialSubtitle 24 w500 mixed (mid-level between the 48pt
///             hero name and the 14pt body; chosen over sectionLabel to
///             avoid collapsing with the UPPER zone-organisers "GALERÍA"
///             and "NOTICIAS RELEVANTES" later on the screen).
///   text    → bodyReading 14 w400 h1.7 (literally matches the previous
///             plain-description render at line 511 of project_detail_screen,
///             including the h:1.7 override — single-block projects look
///             identical post-migration).
///   image   → full-bleed 3:2 LhotseImage; tap → showMediaGallery.
///   gallery → full-bleed 3:2 PageView with dots indicator; tap → showMediaGallery.
///   video   → full-bleed 16:9 VideoThumbnailTile; tap → showMediaGallery.
///
/// Inter-block spacing: 24px (lg) by default, 48px (xxl) before any heading
/// that isn't the first block — gives the title-of-section more air.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _renderBlock(BuildContext context, ContentBlock block) {
    return switch (block) {
      HeadingBlock(:final text) => _HeadingView(text: text),
      TextBlock(:final text) => _BodyView(text: text),
      ImageBlock(:final url) => _SingleImageView(url: url),
      GalleryBlock(:final items) => _GalleryView(items: items),
      VideoBlock(:final url) => _VideoView(url: url),
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
        text,
        style: AppTypography.editorialSubtitle.copyWith(
          color: AppColors.textPrimary,
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
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => showMediaGallery(
        context,
        items: [MediaItem(type: MediaType.image, url: url)],
        initialIndex: 0,
      ),
      child: SizedBox(
        width: width,
        height: width * (2 / 3),
        child: LhotseImage(url),
      ),
    );
  }
}

class _GalleryView extends StatefulWidget {
  const _GalleryView({required this.items});
  final List<ImageItem> items;

  @override
  State<_GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<_GalleryView> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = width * (2 / 3);

    final mediaItems = widget.items
        .map((it) => MediaItem(type: MediaType.image, url: it.url))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: () => showMediaGallery(
                  context,
                  items: mediaItems,
                  initialIndex: i,
                ),
                child: LhotseImage(widget.items[i].url),
              );
            },
          ),
        ),
        if (widget.items.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          _Dots(count: widget.items.length, current: _index),
        ],
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: active ? 16 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active
                ? AppColors.textPrimary
                : AppColors.textPrimary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _VideoView extends StatelessWidget {
  const _VideoView({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => showMediaGallery(
        context,
        items: [MediaItem(type: MediaType.video, url: url)],
        initialIndex: 0,
      ),
      child: SizedBox(
        width: width,
        height: width * (9 / 16),
        child: VideoThumbnailTile(url: url),
      ),
    );
  }
}
