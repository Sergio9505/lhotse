import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/mock/mock_notifications.dart';
import '../../../core/domain/app_notification.dart';
import '../../../core/theme/app_theme.dart';

/// Shows the notification center as a bottom sheet.
void showNotificationsSheet(BuildContext context) {
  final now = DateTime(2026, 4, 8); // Mock "today"
  final weekAgo = now.subtract(const Duration(days: 7));

  final today = <AppNotification>[];
  final thisWeek = <AppNotification>[];
  final earlier = <AppNotification>[];

  for (final n in mockNotifications) {
    if (n.date.year == now.year &&
        n.date.month == now.month &&
        n.date.day == now.day) {
      today.add(n);
    } else if (n.date.isAfter(weekAgo)) {
      thisWeek.add(n);
    } else {
      earlier.add(n);
    }
  }

  final sections = <(String, List<AppNotification>)>[
    if (today.isNotEmpty) ('HOY', today),
    if (thisWeek.isNotEmpty) ('ESTA SEMANA', thisWeek),
    if (earlier.isNotEmpty) ('ANTERIORES', earlier),
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) {
      final bottomPadding = MediaQuery.of(context).padding.bottom;

      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.3,
        maxChildSize: 0.75,
        builder: (context, scrollController) => Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    'NOTIFICACIONES',
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Marcar todas',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // List
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                    0, 0, 0, bottomPadding + AppSpacing.md),
                itemCount: sections.length,
                itemBuilder: (context, sectionIndex) {
                  final (label, items) = sections[sectionIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section label
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          sectionIndex == 0 ? 0 : AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          label,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.accentMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                      // Items
                      ...items.map((n) => _NotificationRow(notification: n)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final dateStr = DateFormat('d MMM')
        .format(notification.date)
        .toUpperCase();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        // TODO: navigate to investment detail with correct tab
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 36,
              height: 36,
              color: notification.type == NotificationType.delay
                  ? AppColors.danger.withValues(alpha: 0.1)
                  : AppColors.textPrimary.withValues(alpha: 0.06),
              child: Center(
                child: Icon(
                  _typeIcon(notification.type),
                  size: 16,
                  color: notification.type == NotificationType.delay
                      ? AppColors.danger
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${notification.projectName} · $dateStr',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.accentMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (isUnread)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 6),
                child: Container(
                  width: 6,
                  height: 6,
                  color: AppColors.danger,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(NotificationType type) => switch (type) {
        NotificationType.document => LucideIcons.fileText,
        NotificationType.news => LucideIcons.newspaper,
        NotificationType.phase => LucideIcons.flag,
        NotificationType.financial => LucideIcons.trendingUp,
        NotificationType.delay => LucideIcons.alertTriangle,
      };
}
