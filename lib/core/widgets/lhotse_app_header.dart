import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import 'lhotse_back_button.dart';

/// Standard app header for pushed screens.
/// Back button (left) + centered title (+ optional subtitle) + Lhotse logo (right).
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
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Align(
              alignment: Alignment.centerRight,
              child: SvgPicture.asset(
                'assets/images/lhotse_logo.svg',
                width: 20,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
