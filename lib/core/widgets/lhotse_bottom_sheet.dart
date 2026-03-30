import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reusable bottom sheet with drag handle + title + scrollable list.
/// Calculates initial height dynamically based on item count.
void showLhotseBottomSheet({
  required BuildContext context,
  required String title,
  required int itemCount,
  required double estimatedItemHeight,
  required IndexedWidgetBuilder itemBuilder,
  IndexedWidgetBuilder? separatorBuilder,
}) {
  final headerHeight = 60.0;
  final screenHeight = MediaQuery.of(context).size.height;
  final contentHeight = headerHeight + (itemCount * estimatedItemHeight);
  final initialSize = (contentHeight / screenHeight).clamp(0.3, 0.8);

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
        initialChildSize: initialSize,
        minChildSize: 0.3,
        maxChildSize: 0.8,
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
                padding: EdgeInsets.fromLTRB(
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
