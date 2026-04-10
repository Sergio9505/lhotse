import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'lhotse_image.dart';

/// Reusable news card with image background + beige overlay (same as ProjectCard).
/// Supports two sizes:
/// - Full (Home, AllNews): 320×213px
/// - Compact (investment detail): 260×160px
class LhotseNewsCard extends StatelessWidget {
  /// Full-size card.
  const LhotseNewsCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.brand,
    this.subtitle,
    this.width = 320,
    this.height = 208,
    this.hasPlayButton = false,
    this.onTap,
  });

  /// Compact card for project context.
  const LhotseNewsCard.compact({
    super.key,
    required this.title,
    required this.imageUrl,
    this.brand,
    this.subtitle,
    this.hasPlayButton = false,
    this.onTap,
  })  : width = 260,
        height = 160;

  final String title;
  final String imageUrl;
  final String? brand;
  final String? subtitle;
  final double width;
  final double height;
  final bool hasPlayButton;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = height <= 210;

    if (isCompact) return _buildCompact();
    return _buildFull();
  }

  /// Full-size: Zara-style — image pure + text below on beige
  Widget _buildFull() {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LhotseImage(imageUrl),
                  if (hasPlayButton) _playButton(false),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _subtitle(false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact: overlay on image (carousels)
  Widget _buildCompact() {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
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
                    _subtitle(true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subtitle(bool isCompact) {
    final style = isCompact ? AppTypography.captionSmall : AppTypography.caption;
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
