import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import 'lhotse_back_button.dart';

/// Standard app header for pushed screens.
/// Back button (left) + centered title + Lhotse logo (right).
class LhotseAppHeader extends StatelessWidget {
  const LhotseAppHeader({
    super.key,
    required this.title,
    this.onBack,
  });

  final String title;

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
              child: Text(
                title,
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
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
