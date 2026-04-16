import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/domain/project_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/lhotse_image.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
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
      onTap: isLocked
          ? () => _showVipLockSheet(context)
          : onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
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
          // Text below image
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 12, AppSpacing.lg, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  project.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      project.brand.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 1.8,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '•',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        project.location.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accentMuted,
                          letterSpacing: 1.35,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVipLockSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const _VipLockSheet(),
    );
  }
}

// ---------------------------------------------------------------------------
// VIP lock bottom sheet
// ---------------------------------------------------------------------------

class _VipLockSheet extends StatelessWidget {
  const _VipLockSheet();

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Lock icon
          const PhosphorIcon(
            PhosphorIconsThin.lock,
            size: 28,
            color: AppColors.textPrimary,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Lhotse Private',
              style: AppTypography.headingLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Description
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Este proyecto es de acceso exclusivo para Inversores VIP. Sigue invirtiendo con nosotros para desbloquear oportunidades privadas.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.accentMuted,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Separator
          Container(height: 0.5, color: AppColors.textPrimary.withValues(alpha: 0.15)),

          const SizedBox(height: AppSpacing.xl),

          // CTA
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SOLICITAR INVITACIÓN',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const PhosphorIcon(
                  PhosphorIconsThin.arrowRight,
                  size: 14,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
