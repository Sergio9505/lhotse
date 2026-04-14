import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Filter tab with full-width animated underline.
/// Caller decides layout — wrap in Expanded for equal-width tabs,
/// or use free-width with manual spacing for variable-width tabs.
class LhotseFilterTab extends StatelessWidget {
  const LhotseFilterTab({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.hasSelection = false,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  /// Shows a dot indicator when the filter has a selection but is not active.
  final bool hasSelection;

  @override
  Widget build(BuildContext context) {
    final highlighted = isActive || hasSelection;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Label
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: highlighted
                          ? AppColors.textPrimary
                          : AppColors.accentMuted,
                      fontWeight:
                          highlighted ? FontWeight.w500 : FontWeight.w400,
                      letterSpacing: 1.5,
                    ),
                  ),
                  // Selection dot — shown when filter has value but tab is not open
                  if (hasSelection && !isActive) ...[
                    const SizedBox(width: 5),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 24px centered underline — out of layout flow
            Positioned(
              bottom: -5,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: 1.5,
                  width: 24.0,
                  color: isActive
                      ? AppColors.textPrimary
                      : Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
