import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';
import 'lhotse_bottom_sheet.dart';

/// Opens a bottom sheet with all gallery images in a vertical scroll.
void showAllGallery(
    BuildContext context, String title, List<String> images) {
  showLhotseBottomSheet(
    context: context,
    title: title,
    itemCount: images.length,

    listPadding: EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      MediaQuery.of(context).padding.bottom + AppSpacing.md,
    ),
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
    itemBuilder: (context, i) => GestureDetector(
      onTap: () => showFullImage(context, images[i]),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Image.network(
          images[i],
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(color: AppColors.surface),
        ),
      ),
    ),
  );
}

/// Opens a full-screen image viewer with InteractiveViewer (pinch to zoom).
void showFullImage(BuildContext context, String imageUrl) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        final topPadding = MediaQuery.of(context).padding.top;
        final bottomPadding = MediaQuery.of(context).padding.bottom;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Opacity(
            opacity: animation.value,
            child: child,
          ),
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        maxScale: 4.0,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            0,
                            topPadding + kToolbarHeight,
                            0,
                            bottomPadding + AppSpacing.lg,
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                Container(color: AppColors.surface),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: topPadding + AppSpacing.md,
                      right: AppSpacing.lg,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          color: AppColors.textPrimary
                              .withValues(alpha: 0.08),
                          child: const Icon(
                            LucideIcons.x,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
