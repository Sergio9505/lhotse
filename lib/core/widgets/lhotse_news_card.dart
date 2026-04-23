import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'lhotse_image.dart';

/// Reusable news card. Two variants:
/// - **Default (full)**: minimal-luxury-modern captioned photograph. 1:1
///   image wrapped in a shared-element `Hero`, editorial hairlines framing
///   the caption, `displayHero` Light 48pt title, italic deck and textual
///   `POR {BRAND} · {DATE}` byline. Used in AllNews + NewsArchiveBody.
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
    this.hasPlayButton = false,
    this.isLeadStory = false,
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
        isLeadStory = false,
        heroTag = null;

  final String title;
  final String imageUrl;
  final String? heroTag;
  final String? brand;
  final String? subtitle;
  final String? date;
  final String? type;
  final double? width;
  final double? height;
  final bool hasPlayButton;
  final bool isLeadStory;
  final VoidCallback? onTap;

  bool get _isCompact => width != null;

  @override
  Widget build(BuildContext context) {
    return _isCompact ? _buildCompact() : _buildFull();
  }

  Widget _buildFull() {
    final deckMaxLines = isLeadStory ? 3 : 2;
    // Image stack hosts the optional play button + the type chip overlay.
    // The Hero wraps only the LhotseImage so the chip stays in the card and
    // doesn't travel during the shared-element transition. 1:1 aspect keeps
    // the full caption (title + deck + byline) visible without scroll —
    // critical for a scrollable catalogue where the user is scanning piece
    // to piece. Cover-magazine treatment lives in the news detail screen,
    // not in this listing tile.
    final image = AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (heroTag != null)
            Hero(tag: heroTag!, child: LhotseImage(imageUrl))
          else
            LhotseImage(imageUrl),
          if (hasPlayButton) _playButton(false),
          if (type != null && type!.isNotEmpty)
            Positioned(
              top: 20,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 0.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  type!.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
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
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title — Campton Light 48pt, mixed case, tight line-height.
                Text(
                  title,
                  style: AppTypography.displayHero.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  // Deck in italic — magazine pull-quote treatment.
                  Text(
                    subtitle!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.accentMuted,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: deckMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 24),
                _byline(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Byline — `POR {BRAND}  ·  {DATE}`. News keeps the textual treatment
  /// because the brand is an *author* (editorial publisher), not a maison.
  Widget _byline() {
    final hasBrand = brand != null && brand!.isNotEmpty;
    final hasDate = date != null && date!.isNotEmpty;
    if (!hasBrand && !hasDate) return const SizedBox.shrink();

    final children = <InlineSpan>[];
    if (hasBrand) {
      children.add(TextSpan(
        text: 'POR ',
        style: TextStyle(color: AppColors.accentMuted, letterSpacing: 1.5),
      ));
      children.add(TextSpan(
        text: brand!.toUpperCase(),
        style: TextStyle(color: AppColors.textPrimary, letterSpacing: 1.5),
      ));
    }
    if (hasBrand && hasDate) {
      children.add(TextSpan(
        text: '  ·  ',
        style: TextStyle(
          color: AppColors.textPrimary.withValues(alpha: 0.4),
        ),
      ));
    }
    if (hasDate) {
      children.add(TextSpan(
        text: date!.toUpperCase(),
        style: TextStyle(color: AppColors.accentMuted, letterSpacing: 1.2),
      ));
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: AppTypography.caption.copyWith(letterSpacing: 1.5),
        children: children,
      ),
    );
  }

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
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
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
    final style = AppTypography.captionSmall;
    return Row(
      children: [
        if (brand != null) ...[
          Text(
            brand!.toUpperCase(),
            style: style.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '·',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.4),
                ),
              ),
            ),
        ],
        if (subtitle != null)
          Flexible(
            child: Text(
              subtitle!.toUpperCase(),
              style: style.copyWith(
                color: AppColors.accentMuted,
                letterSpacing: 1.2,
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
