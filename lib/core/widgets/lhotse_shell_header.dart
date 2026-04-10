import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'lhotse_notification_bell.dart';

/// Reusable header for shell-level screens (Home, Brands, Search).
/// Row with [child] on the left and notification bell on the right.
/// Handles safe area padding automatically.
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
        AppSpacing.sm,
        16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: child),
          const LhotseNotificationBell(),
        ],
      ),
    );
  }
}
