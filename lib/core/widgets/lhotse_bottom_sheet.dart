import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared bottom sheet body: drag handle + title + optional header + body.
/// Sizes dynamically to content, capped at 80% of screen height.
/// Used by [showLhotseBottomSheet] and other bottom sheets.
class LhotseBottomSheetBody extends StatelessWidget {
  const LhotseBottomSheetBody({
    super.key,
    required this.title,
    this.header,
    required this.bodyBuilder,
  });

  final String title;
  final Widget? header;
  final Widget Function(double bottomPadding) bodyBuilder;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.all(AppSpacing.lg),
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
          // Optional header (e.g. filter chips)
          if (header != null) header!,
          // Body — Flexible so it shrinks to content or scrolls if capped
          Flexible(child: bodyBuilder(bottomPadding)),
        ],
      ),
    );
  }
}

/// Reusable bottom sheet with drag handle + title + scrollable list.
/// Dynamic height based on content, capped at 80% of screen.
void showLhotseBottomSheet({
  required BuildContext context,
  required String title,
  required int itemCount,
  required IndexedWidgetBuilder itemBuilder,
  IndexedWidgetBuilder? separatorBuilder,
  EdgeInsetsGeometry? listPadding,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) => LhotseBottomSheetBody(
      title: title,
      bodyBuilder: (bottomPadding) => ListView.separated(
        shrinkWrap: true,
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
  );
}
