import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tab with an animated underline. Two modes driven by [fullWidth]:
///
/// - `fullWidth: false` (default) — **filter tab**: sizes to its label and
///   draws a label-width underline. Use in left-aligned filter rows that
///   cohabit with utility icons (status, type, brand, region filters).
///
/// - `fullWidth: true` — **nav tab**: stretches to its parent's width and
///   draws a full-cell underline. Wrap the caller in `Expanded` (or equal
///   constraint) for peer-equal distribution. Use for first-level navigation
///   inside a screen (Firmas sub-tabs, L3 detail tabs).
class LhotseFilterTab extends StatelessWidget {
  const LhotseFilterTab({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.hasSelection = false,
    this.fullWidth = false,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  /// Shows a dot indicator when the filter has a selection but is not active.
  final bool hasSelection;

  /// When true, the tab fills its parent's width and the underline spans the
  /// full cell. When false, the tab sizes to its label and the underline
  /// matches the label width.
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final highlighted = isActive || hasSelection;

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelUppercaseMd.copyWith(
                  color: highlighted
                      ? AppColors.textPrimary
                      : AppColors.accentMuted,
                  fontWeight:
                      highlighted ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
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
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 1.5,
          color: isActive ? AppColors.textPrimary : Colors.transparent,
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: fullWidth ? column : IntrinsicWidth(child: column),
        ),
      ),
    );
  }
}
