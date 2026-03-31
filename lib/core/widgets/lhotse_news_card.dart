import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
    this.height = 213,
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
    this.onTap,
  })  : width = 260,
        height = 160,
        hasPlayButton = false;

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
    final isCompact = height <= 180;
    final padding = isCompact ? 14.0 : 24.0;
    final titleStyle = isCompact
        ? AppTypography.bodySmall
        : AppTypography.headingSmall;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: AppColors.surface),
            ),

            // Play button (optional, above overlay)
            if (hasPlayButton)
              Center(
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
              ),

            // Beige overlay — same pattern as ProjectCard
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: isCompact ? 10 : 14,
                ),
                color: AppColors.surface.withValues(alpha: 0.75),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: titleStyle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (brand != null) ...[
                          Text(
                            brand!.toUpperCase(),
                            style: (isCompact
                                    ? AppTypography.captionSmall
                                    : AppTypography.caption)
                                .copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '·',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textPrimary
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                        ],
                        if (subtitle != null)
                          Flexible(
                            child: Text(
                              subtitle!.toUpperCase(),
                              style: (isCompact
                                      ? AppTypography.captionSmall
                                      : AppTypography.caption)
                                  .copyWith(
                                color: AppColors.accentMuted,
                                letterSpacing: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
