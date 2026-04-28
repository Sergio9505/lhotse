import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tab with an animated underline. Three layers of configuration:
///
/// - **`fullWidth`** controls layout: when false (default), the tab sizes to
///   its label (filter chip / editorial nav). When true, it stretches to its
///   parent's width — wrap caller in `Expanded` for peer-equal distribution.
///
/// - **`editorial`** controls typography case + tracking:
///   - `false` (default) — `labelUppercaseMd` 12pt with native tracking.
///     Use for filter chips passing `UPPERCASE` strings (catalog/archive
///     filters, brand/region selectors).
///   - `true` — `bodyEmphasis` 14pt sentence case, no tracking. Use for
///     primary navigation tabs passing `Title Case` strings — Firmas
///     sub-tabs (Firmas / Proyectos / Noticias), detail screen sub-navs.
///
/// - **`hasSelection`** shows a dot indicator when the filter has a value
///   selected but is not the active tab.
class LhotseFilterTab extends StatelessWidget {
  const LhotseFilterTab({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.hasSelection = false,
    this.fullWidth = false,
    this.editorial = false,
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

  /// When true, uses `bodyEmphasis` 16pt sentence-case (Firmas sub-tabs,
  /// detail screen sub-navs). When false, uses `labelUppercaseMd` 12pt
  /// uppercase tracked (filter chip / archive selector style).
  final bool editorial;

  @override
  Widget build(BuildContext context) {
    final highlighted = isActive || hasSelection;
    final baseStyle = editorial
        ? AppTypography.bodyEmphasis
        : AppTypography.labelUppercaseMd;

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
                style: baseStyle.copyWith(
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
