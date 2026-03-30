import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reusable news card with image background + navy gradient overlay.
/// Supports two layouts:
/// - Full (Home): brand badge top-left, title + subtitle bottom
/// - Compact (investment detail): title + date bottom, no badge
class LhotseNewsCard extends StatelessWidget {
  /// Full-size card with brand badge (for Home).
  const LhotseNewsCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.subtitle,
    this.badge,
    this.width = 320,
    this.height = 213,
    this.hasPlayButton = false,
    this.onTap,
  });

  /// Compact card for project context (no badge).
  const LhotseNewsCard.compact({
    super.key,
    required this.title,
    required this.imageUrl,
    this.subtitle,
    this.onTap,
  })  : badge = null,
        width = 260,
        height = 160,
        hasPlayButton = false;

  final String title;
  final String imageUrl;
  final String? subtitle;
  final String? badge;
  final double width;
  final double height;
  final bool hasPlayButton;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final padding = height > 180 ? 24.0 : 16.0;
    final titleStyle = height > 180
        ? AppTypography.headingSmall
        : AppTypography.bodySmall;

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

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Badge (optional)
            if (badge != null)
              Positioned(
                top: padding,
                left: padding,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  color: AppColors.primary,
                  child: Text(
                    badge!.toUpperCase(),
                    style: AppTypography.captionSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            // Title + subtitle
            Positioned(
              left: padding,
              right: padding,
              bottom: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: titleStyle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Play button (optional)
            if (hasPlayButton)
              Center(
                child: Container(
                  width: 56,
                  height: 56,
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
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
