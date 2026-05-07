import 'package:flutter/material.dart';

import '../../../../core/data/bunny_thumbnail.dart';
import '../../../../core/domain/project_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_image.dart';
import 'vip_lock_sheet.dart';

/// Full-width catalog card for the Search catálogo and Firmas/Proyectos sub-tab.
/// Grammar: escaparate curado (Sotheby's/Hermès catalog density) — image
/// dominant at 3:2, title editorial 36pt, tagline 1-line italic, byline
/// BRAND · City · Status matching project_detail_screen byline convention.
class ProjectShowcaseCard extends StatelessWidget {
  const ProjectShowcaseCard({
    super.key,
    required this.project,
    this.onTap,
    this.isLocked = false,
  });

  final ProjectData project;
  final VoidCallback? onTap;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? () => showVipLockSheet(context) : onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 3 / 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'project-hero-${project.id}',
                  flightShuttleBuilder: (_, _, _, _, _) =>
                      LhotseImage(
                        posterUrlFor(
                          videoUrl: project.videoUrl,
                          fallback: project.imageUrl,
                        ),
                      ),
                  child: _ProjectMedia(
                    imageUrl: project.imageUrl,
                    videoUrl: project.videoUrl,
                  ),
                ),
                if (project.isVip)
                  Positioned(
                    top: 16,
                    right: 12,
                    child: Container(
                      color: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      child: Text(
                        'PRIVATE',
                        style: AppTypography.wordmarkByline.copyWith(
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  project.name,
                  style: AppTypography.editorialTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (project.tagline.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    project.tagline,
                    style: AppTypography.editorialDeck.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                _ProjectByline(project: project),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectMedia extends StatelessWidget {
  const _ProjectMedia({required this.imageUrl, this.videoUrl});

  final String? imageUrl;
  final String? videoUrl;

  @override
  Widget build(BuildContext context) {
    return LhotseImage(
      posterUrlFor(videoUrl: videoUrl, fallback: imageUrl),
    );
  }
}

/// Single-line byline: BRAND · City · Status — mixed casing per token.
/// Mirrors the RichText pattern from project_detail_screen hero.
class _ProjectByline extends StatelessWidget {
  const _ProjectByline({required this.project});

  final ProjectData project;

  @override
  Widget build(BuildContext context) {
    final hasBrand = project.brand.isNotEmpty;
    final hasCity = project.city.isNotEmpty;
    final status = project.phase.label;

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          if (hasBrand) ...[
            TextSpan(
              text: project.brand.toUpperCase(),
              style: AppTypography.wordmarkByline.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (hasCity || status.isNotEmpty)
              TextSpan(
                text: '  ·  ',
                style: AppTypography.annotation.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.4),
                ),
              ),
          ],
          if (hasCity) ...[
            TextSpan(
              text: project.city,
              style: AppTypography.annotation.copyWith(
                color: AppColors.accentMuted,
              ),
            ),
            if (status.isNotEmpty)
              TextSpan(
                text: '  ·  ',
                style: AppTypography.annotation.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.4),
                ),
              ),
          ],
          if (status.isNotEmpty)
            TextSpan(
              text: status,
              style: AppTypography.annotation.copyWith(
                color: AppColors.accentMuted,
              ),
            ),
        ],
      ),
    );
  }
}
