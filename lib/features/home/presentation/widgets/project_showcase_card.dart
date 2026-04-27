import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/domain/project_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_image.dart';
import 'vip_lock_sheet.dart';

/// Full-width showcase card for AllProjects + Search catálogo. Minimal-luxury-
/// modern territory (Céline / Jil Sander / Totême) delivered entirely with
/// Campton: Light w300 hero title at 48pt, italic tagline, a compact SVG
/// maison logo byline (72×20, same monochrome pattern as `_BrandCard` in
/// Firmas), and shared-element `Hero` transition into the project detail.
///
/// Project phase and VIP status live as chips on top of the image (Sotheby's /
/// Engel & Völkers convention — operational state as a badge, not as byline
/// text). PRIVATE uses a filled black chip; phase uses an outline chip so the
/// two coexist with clear visual hierarchy when both are present.
///
/// `isLeadStory` differentiates the first item only by extending the tagline
/// maxLines (3 vs 1) — ratio and title size stay identical across the list.
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
          // Shared-element Hero wraps only the image so tapping the card
          // animates it into the detail hero. The chips stay out of the Hero
          // so they don't travel with the image during the transition.
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'project-hero-${project.id}',
                  child: LhotseImage(project.imageUrl),
                ),
                // Phase chip — outline style, top-left. Subordinated to
                // PRIVATE when both coexist.
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
                    ),
                    child: Text(
                      project.phase.label,
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
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
                        style: AppTypography.labelUppercaseSm.copyWith(
                          color: AppColors.textOnDark,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title — Campton Light 48pt, mixed case, tight line-height.
                Text(
                  project.name,
                  style: AppTypography.editorialHero.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Location — city only. Codes like "Dubai, AE" read dry /
                // uncertain; a single city name ("Dubai", "Madrid") is more
                // luxury and screenshot-universal.
                Text(
                  project.city,
                  style: AppTypography.bodyReading.copyWith(
                    color: AppColors.accentMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (project.tagline.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  // Tagline in italic — magazine convention for declarative
                  // captions / pull quotes.
                  Text(
                    project.tagline,
                    style: AppTypography.annotation.copyWith(
                      color: AppColors.accentMuted,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: taglineMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 24),
                _BrandStamp(project: project),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Byline — maison SVG logo rendered monochrome black via `ColorFilter.mode`
/// inside a fixed 72×20 box (same pattern as `_BrandCard` in the Firmas
/// screen, shrunk to fit a byline context). Falls back to a textual wordmark
/// when `brandLogoAsset` is absent. Phase lives on the image as a chip, not
/// here — this widget is the "editorial credit" slot only.
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

    if (!hasLogo) {
      return Text(
        project.brand.toUpperCase(),
        style: AppTypography.labelUppercaseSm.copyWith(
          color: AppColors.textPrimary,
          letterSpacing: 1.5,
        ),
      );
    }
    return SizedBox(
      width: 72,
      height: 20,
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
    );
  }
}
