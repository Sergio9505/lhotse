import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/domain/project_data.dart';
import '../../../../core/theme/app_theme.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
  });

  final ProjectData project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          Image.network(
            project.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: AppColors.surface),
          ),

          // Bottom overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              color: AppColors.surface.withValues(alpha: 0.75),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left column: name + brand/location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AutoSizeText(
                          project.name.toUpperCase(),
                          maxLines: 1,
                          minFontSize: 24,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.displayLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Text(
                              project.brand.toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.8,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '•',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textPrimary
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                            Text(
                              project.location.toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.accentMuted,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    LucideIcons.arrowUpRight,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),

          // VIP badge
          if (project.isVip)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  'VIP',
                  style: AppTypography.captionSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
