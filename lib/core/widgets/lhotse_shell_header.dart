import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'lhotse_mark.dart';
import 'lhotse_notification_bell.dart';

/// Reusable header for shell-level screens (Brands, Search, Profile).
/// Row with [child] on the left and the Lhotse mark + notification bell on
/// the right. Handles safe area padding automatically.
class LhotseShellHeader extends StatelessWidget {
  const LhotseShellHeader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topPadding + 16,
        AppSpacing.md,
        16,
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: child,
              ),
            ),
            const LhotseMark(color: AppColors.textPrimary, height: 20),
            const SizedBox(width: AppSpacing.sm),
            const LhotseNotificationBell(),
          ],
        ),
      ),
    );
  }
}
