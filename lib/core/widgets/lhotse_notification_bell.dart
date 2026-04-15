import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../features/notifications/data/notifications_provider.dart';
import '../../features/notifications/presentation/notifications_sheet.dart';
import '../theme/app_theme.dart';
import '../widgets/lhotse_notification_badge.dart';

/// Notification bell icon with badge. Single source of truth.
class LhotseNotificationBell extends ConsumerWidget {
  const LhotseNotificationBell({
    super.key,
    this.color = AppColors.textPrimary,
  });

  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount =
        ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

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
