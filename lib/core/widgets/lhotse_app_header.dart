import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'lhotse_back_button.dart';

/// Standard app header for pushed screens.
/// Back button (left) + centered title (+ optional subtitle) + balanced spacer (right).
class LhotseAppHeader extends StatelessWidget {
  const LhotseAppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  final String title;
  final String? subtitle;

  /// Custom back action. Defaults to `context.pop()` via LhotseBackButton.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.sm, topPadding + AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          LhotseBackButton.onSurface(onTap: onBack),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleUppercaseLg.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}
