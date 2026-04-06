import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reusable bottom sheet with drag handle + title + scrollable list.
/// Fixed height adapted to content (capped at 80% of screen).
/// Drag down to dismiss; tap outside to dismiss.
void showLhotseBottomSheet({
  required BuildContext context,
  required String title,
  required int itemCount,
  required double estimatedItemHeight,
  required IndexedWidgetBuilder itemBuilder,
  IndexedWidgetBuilder? separatorBuilder,
  EdgeInsetsGeometry? listPadding,
}) {
  final headerHeight = 80.0; // drag handle + title + padding
  final screenHeight = MediaQuery.of(context).size.height;
  final bottomPadding = MediaQuery.of(context).padding.bottom;
  final contentHeight =
      headerHeight + (itemCount * estimatedItemHeight) + bottomPadding + AppSpacing.lg;
  final fitSize = (contentHeight / screenHeight).clamp(0.2, 0.8);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) {
      final bottomPadding = MediaQuery.of(context).padding.bottom;

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: fitSize,
        minChildSize: 0.2,
        maxChildSize: fitSize,
        builder: (context, scrollController) => Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            // List
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: listPadding ??
                    EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, bottomPadding + AppSpacing.md),
                itemCount: itemCount,
                separatorBuilder: separatorBuilder ??
                    (_, _) => Container(
                          height: 0.5,
                          color: AppColors.textPrimary.withValues(alpha: 0.08),
                        ),
                itemBuilder: itemBuilder,
              ),
            ),
          ],
        ),
      );
    },
  );
}
