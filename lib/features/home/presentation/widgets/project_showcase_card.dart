import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/domain/project_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_image.dart';
import 'vip_lock_sheet.dart';

/// Full-width showcase card for AllProjects + Search catálogo. Minimal-luxury-
/// modern territory (Céline / Jil Sander / Totême) delivered entirely with
/// Campton: Light w300 hero title at 48pt, italic tagline, hairline top/bottom
/// framing the caption, uniform SVG maison stamp in the byline, and shared-
/// element `Hero` transition into the project detail.
///
/// `isLeadStory` differentiates the first item only by extending the tagline
/// maxLines (3 vs 1) — ratio and title size remain identical across the list,
/// so rhythm comes from repetition, not altura variable.
class ProjectShowcaseCard extends StatelessWidget {
  const ProjectShowcaseCard({
    super.key,
    required this.project,
    this.isLeadStory = false,
    this.onTap,
    this.isLocked = false,
  });

  final ProjectData project;
  final bool isLeadStory;
  final VoidCallback? onTap;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final taglineMaxLines = isLeadStory ? 3 : 1;

    return GestureDetector(
      onTap: isLocked ? () => showVipLockSheet(context) : onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Shared-element Hero wraps the image so tapping the card animates
          // it into the detail screen's hero smoothly.
          Hero(
            tag: 'project-hero-${project.id}',
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LhotseImage(project.imageUrl),
                  if (project.isVip)
                    Positioned(
                      top: 20,
                      right: 12,
                      child: Container(
                        color: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        child: Text(
                          'PRIVATE',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textOnDark,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _EditorialHairline(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                // Title — Campton Light 48px, mixed case, tight line-height.
                // "Cover-of-magazine" treatment that separates archive-grade
                // editorial from generic premium real-estate listings.
                Text(
                  project.name,
                  style: AppTypography.displayHero.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Location subtitle (mixed case — no uppercase kicker).
                Text(
                  project.location,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.accentMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (project.tagline.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  // Tagline in italic — magazine convention for declarative
                  // descriptions / pull quotes.
                  Text(
                    project.tagline,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.accentMuted,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: taglineMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
          const _EditorialHairline(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              12,
              AppSpacing.lg,
              0,
            ),
            child: _BrandStamp(project: project),
          ),
        ],
      ),
    );
  }
}

/// Thin hairline used to "open" and "close" the caption block editorially.
/// Spans the card edge-to-edge at 0.5px with 15% alpha, barely visible but
/// enough to frame the typography like a magazine spread.
class _EditorialHairline extends StatelessWidget {
  const _EditorialHairline();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      color: AppColors.textPrimary.withValues(alpha: 0.15),
    );
  }
}

/// Byline — maison SVG logo (100×28 patrón Firmas) + fase label. Logo is
/// tinted `textPrimary` via `ColorFilter.mode` so heterogeneous brand marks
/// render uniformly monochrome black, flush-left inside a fixed frame. Falls
/// back to a textual wordmark when `brandLogoAsset` is absent.
class _BrandStamp extends StatelessWidget {
  const _BrandStamp({required this.project});

  final ProjectData project;

  static const _filter = ColorFilter.mode(
    AppColors.textPrimary,
    BlendMode.srcIn,
  );

  @override
  Widget build(BuildContext context) {
    final logo = project.brandLogoAsset;
    final hasLogo = logo != null && logo.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasLogo)
          SizedBox(
            width: 100,
            height: 28,
            child: logo.startsWith('http')
                ? SvgPicture.network(
                    logo,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    colorFilter: _filter,
                  )
                : SvgPicture.asset(
                    logo,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    colorFilter: _filter,
                  ),
          )
        else
          Text(
            project.brand.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '·',
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.4),
            ),
          ),
        ),
        Text(
          project.phase.label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
