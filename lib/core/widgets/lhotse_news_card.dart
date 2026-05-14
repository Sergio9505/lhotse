import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'lhotse_image.dart';
import 'lhotse_play_button.dart';

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
    this.imageUrl,
    required this.heroTag,
    this.brand,
    this.subtitle,
    this.date,
    this.type,
    this.videoUrl,
    this.onTap,
  })  : width = null,
        height = null;

  /// Compact card for horizontal carousels inside detail screens.
  const LhotseNewsCard.compact({
    super.key,
    required this.title,
    this.imageUrl,
    this.brand,
    this.subtitle,
    this.videoUrl,
    this.onTap,
  })  : width = 260,
        height = 160,
        date = null,
        type = null,
        heroTag = null;

  final String title;
  final String? imageUrl;
  final String? heroTag;
  final String? brand;
  final String? subtitle;
  final String? date;
  final String? type;
  /// Drives both the `LhotseImage.poster` thumbnail cascade and the
  /// play-button overlay. News video is "content to listen to" — listings show
  /// a play overlay; playback only happens in the fullscreen viewer where
  /// audio is on. Never autoplay-muted inline (see ADR-62).
  final String? videoUrl;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  bool get _isCompact => width != null;

  @override
  Widget build(BuildContext context) {
    return _isCompact ? _buildCompact() : _buildFull();
  }

  Widget _buildFull() {
    final hasVideo = videoUrl != null && videoUrl!.isNotEmpty;
    Widget poster() =>
        LhotseImage.poster(videoUrl: videoUrl, imageUrl: imageUrl);
    final image = AspectRatio(
      aspectRatio: 3 / 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (heroTag != null)
            Hero(tag: heroTag!, child: poster())
          else
            poster(),
          if (hasVideo) const LhotsePlayButton(),
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

  Widget _buildCompact() {
    final hasVideo = videoUrl != null && videoUrl!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width!,
        height: height!,
        child: Stack(
          fit: StackFit.expand,
          children: [
            LhotseImage.poster(videoUrl: videoUrl, imageUrl: imageUrl),
            if (hasVideo) const LhotsePlayButton(size: 40),
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
}
