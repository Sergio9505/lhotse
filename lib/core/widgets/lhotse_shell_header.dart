import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'lhotse_mark.dart';
import 'lhotse_notification_bell.dart';

/// Reusable header for shell-level screens (Brands, Search, Profile). Logo on
/// the left as brand anchor, notification bell on the right as action. No
/// title — the bottom nav already tells the user which tab they're on, and
/// the logo acts as the identity mark throughout the app.
///
/// Strategy doesn't use this widget: it places the same logo+bell manually
/// over its dark hero to keep the hero edge-to-edge.
class LhotseShellHeader extends StatelessWidget {
  const LhotseShellHeader({super.key});

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
          children: const [
            LhotseMark(color: AppColors.textPrimary, height: 20),
            Spacer(),
            LhotseNotificationBell(),
          ],
        ),
      ),
    );
  }
}
