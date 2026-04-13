import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/mock/mock_notifications.dart';
import '../theme/app_theme.dart';
import '../widgets/lhotse_notification_badge.dart';
import '../../features/notifications/presentation/notifications_sheet.dart';

/// Notification bell icon with badge. Single source of truth.
/// Use in LhotseShellHeader (Row) or standalone in a Positioned (Strategy).
class LhotseNotificationBell extends StatelessWidget {
  const LhotseNotificationBell({
    super.key,
    this.color = AppColors.textPrimary,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        mockNotifications.where((n) => !n.isRead).length;

    return GestureDetector(
      onTap: () => showNotificationsSheet(context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: LhotseNotificationBadge(
            show: unreadCount > 0,
            count: unreadCount,
            child: PhosphorIcon(
              PhosphorIconsThin.bell,
              size: 24,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
