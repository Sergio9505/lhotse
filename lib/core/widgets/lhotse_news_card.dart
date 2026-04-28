import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'lhotse_image.dart';
import 'lhotse_video_player.dart';

/// Reusable news card. Two variants:
/// - **Default (full)**: catalog-grammar tile (escaparate curado). 3:2 image
///   wrapped in a shared-element `Hero`, `editorialTitle` 36pt title, italic
///   deck (1 line), 2-token byline `{BRAND} · {DATE}`. Used in
///   NewsArchiveBody.
/// - **Compact**: 260×160 with beige overlay on image — unchanged, for
///   horizontal carousels inside detail screens.
class LhotseNewsCard extends StatelessWidget {
  const LhotseNewsCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.heroTag,
    this.brand,
    this.subtitle,
    this.date,
    this.type,
    this.videoUrl,
    this.hasPlayButton = false,
    this.onTap,
  })  : width = null,
        height = null;

  /// Compact card for horizontal carousels inside detail screens.
  const LhotseNewsCard.compact({
    super.key,
    required this.title,
    required this.imageUrl,
    this.brand,
    this.subtitle,
    this.hasPlayButton = false,
    this.onTap,
  })  : width = 260,
        height = 160,
        date = null,
        type = null,
        videoUrl = null,
        heroTag = null;

  final String title;
  final String imageUrl;
  final String? heroTag;
  final String? brand;
  final String? subtitle;
  final String? date;
  final String? type;
  final String? videoUrl;
  final double? width;
  final double? height;
  final bool hasPlayButton;
  final VoidCallback? onTap;

  bool get _isCompact => width != null;

  @override
  Widget build(BuildContext context) {
    return _isCompact ? _buildCompact() : _buildFull();
  }

  Widget _buildFull() {
    final hasVideo = videoUrl != null && videoUrl!.isNotEmpty;
    final image = AspectRatio(
      aspectRatio: 3 / 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (heroTag != null)
            Hero(
              tag: heroTag!,
              flightShuttleBuilder:
                  hasVideo ? _videoFlightShuttle : null,
              child: _newsMedia(),
            )
          else
            _newsMedia(),
          if (hasPlayButton && !hasVideo) _playButton(false),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          image,
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.editorialTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtitle!,
                    style: AppTypography.annotationParagraph.copyWith(
                      color: AppColors.accentMuted,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                _byline(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3-token byline mirroring ProjectShowcaseCard: only the brand wordmark
  /// is uppercase (identity); date and type are mixed case (descriptive meta).
  Widget _byline() {
    final hasBrand = brand != null && brand!.isNotEmpty;
    final hasDate = date != null && date!.isNotEmpty;
    final hasType = type != null && type!.isNotEmpty;
    if (!hasBrand && !hasDate && !hasType) return const SizedBox.shrink();

    final separator = TextSpan(
      text: '  ·  ',
      style: AppTypography.annotation.copyWith(
        color: AppColors.textPrimary.withValues(alpha: 0.4),
      ),
    );

    final children = <InlineSpan>[];
    if (hasBrand) {
      children.add(TextSpan(
        text: brand!.toUpperCase(),
        style: AppTypography.wordmarkByline.copyWith(
          color: AppColors.textPrimary,
        ),
      ));
      if (hasDate || hasType) children.add(separator);
    }
    if (hasDate) {
      children.add(TextSpan(
        text: date!,
        style: AppTypography.annotation.copyWith(
          color: AppColors.accentMuted,
        ),
      ));
      if (hasType) children.add(separator);
    }
    if (hasType) {
      children.add(TextSpan(
        text: type!,
        style: AppTypography.annotation.copyWith(
          color: AppColors.accentMuted,
        ),
      ));
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: children),
    );
  }

  Widget _newsMedia() {
    if (videoUrl != null && videoUrl!.isNotEmpty) {
      return LhotseVideoPlayer(
        videoUrl: videoUrl!,
        posterUrl: imageUrl,
        isActive: true,
      );
    }
    return LhotseImage(imageUrl);
  }

  static Widget _videoFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) =>
      Container(color: AppColors.primary);

  Widget _buildCompact() {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width!,
        height: height!,
        child: Stack(
          fit: StackFit.expand,
          children: [
            LhotseImage(imageUrl),
            if (hasPlayButton) _playButton(true),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                color: AppColors.surface.withValues(alpha: 0.75),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _compactSubtitle(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactSubtitle() {
    return Row(
      children: [
        if (brand != null) ...[
          Text(
            brand!.toUpperCase(),
            style: AppTypography.badgeMicro.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '·',
                style: AppTypography.badgeMicro.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.4),
                ),
              ),
            ),
        ],
        if (subtitle != null)
          Flexible(
            child: Text(
              subtitle!.toUpperCase(),
              style: AppTypography.badgeMicro.copyWith(
                color: AppColors.accentMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _playButton(bool isCompact) {
    return Center(
      child: Container(
        width: isCompact ? 40 : 56,
        height: isCompact ? 40 : 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 25,
            ),
          ],
        ),
        child: Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: isCompact ? 20 : 28,
        ),
      ),
    );
  }
}
