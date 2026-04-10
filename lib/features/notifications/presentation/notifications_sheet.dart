import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/mock/mock_notifications.dart';
import '../../../core/domain/app_notification.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_notification_badge.dart';
import '../../../core/widgets/lhotse_section_label.dart';

// ---------------------------------------------------------------------------
// Relative time helper
// ---------------------------------------------------------------------------

String _relativeTime(DateTime date, DateTime now) {
  final diff = now.difference(date);
  if (diff.inMinutes < 60) return 'HACE ${diff.inMinutes}MIN';
  if (diff.inHours < 24) return 'HACE ${diff.inHours}H';
  if (diff.inDays < 7) return 'HACE ${diff.inDays}D';
  if (diff.inDays < 30) return 'HACE ${diff.inDays ~/ 7}SEM';
  return DateFormat('d MMM').format(date).toUpperCase();
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

/// Shows the notification center as a bottom sheet.
void showNotificationsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => const _NotificationsSheetContent(),
  );
}

// ---------------------------------------------------------------------------
// Sheet content
// ---------------------------------------------------------------------------

class _NotificationsSheetContent extends StatelessWidget {
  const _NotificationsSheetContent();

  @override
  Widget build(BuildContext context) {
    final now = DateTime(2026, 4, 8, 18, 0); // Mock "today" (evening)
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

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final hasUnread = mockNotifications.any((n) => !n.isRead);

    // Dynamic sizing: fit content, cap at 80%
    final screenHeight = MediaQuery.of(context).size.height;
    const headerHeight = 80.0; // drag handle + title row + padding
    const dividerHeight = 0.5;
    const sectionHeaderHeight = 36.0; // padding + label
    const rowHeight = 64.0; // padding + icon + text
    final totalRows =
        sections.fold<int>(0, (sum, s) => sum + s.$2.length);
    final contentHeight = headerHeight +
        dividerHeight +
        (sections.length * sectionHeaderHeight) +
        (totalRows * rowHeight) +
        bottomPadding +
        AppSpacing.lg;
    final fitSize = (contentHeight / screenHeight).clamp(0.2, 0.8);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: fitSize,
      minChildSize: 0.2,
      maxChildSize: fitSize,
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
                  onTap: hasUnread
                      ? () {
                          // TODO: mark all as read
                        }
                      : null,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: LhotseNotificationBadge(
                        show: hasUnread,
                        child: PhosphorIcon(
                          PhosphorIconsThin.checks,
                          size: 20,
                          color: hasUnread
                              ? AppColors.textPrimary
                              : AppColors.accentMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 0.5,
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),

          // Content
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
                    Padding(
                      padding: EdgeInsets.only(
                        top: sectionIndex == 0
                            ? AppSpacing.md
                            : AppSpacing.lg,
                        bottom: AppSpacing.sm,
                      ),
                      child: LhotseSectionLabel(label: label),
                    ),
                    ...items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final n = entry.value;
                      return _NotificationRow(
                        notification: n,
                        now: now,
                        isLast: idx == items.length - 1,
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification row
// ---------------------------------------------------------------------------

class _NotificationRow extends StatefulWidget {
  const _NotificationRow({
    required this.notification,
    required this.now,
    required this.isLast,
  });

  final AppNotification notification;
  final DateTime now;
  final bool isLast;

  @override
  State<_NotificationRow> createState() => _NotificationRowState();
}

class _NotificationRowState extends State<_NotificationRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final isUnread = !n.isRead;
    final isDelay = n.type == NotificationType.delay;
    final timeStr = _relativeTime(n.date, widget.now);

    // Title color: delay → danger, unread → textPrimary, read → accentMuted
    final titleColor = isDelay
        ? AppColors.danger
        : isUnread
            ? AppColors.textPrimary
            : AppColors.accentMuted;

    final titleWeight = isUnread ? FontWeight.w600 : FontWeight.w400;

    final metaColor =
        isUnread ? AppColors.accentMuted : AppColors.textSecondary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        Navigator.of(context).pop();
        // TODO: navigate to investment detail with correct tab
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.5 : 1.0,
        child: Container(
          decoration: widget.isLast
              ? null
              : BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
                ),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 36,
                height: 36,
                color: isDelay
                    ? AppColors.danger.withValues(alpha: 0.1)
                    : AppColors.textPrimary.withValues(alpha: 0.06),
                child: Center(
                  child: PhosphorIcon(
                    _typeIcon(n.type),
                    size: 16,
                    color: isDelay ? AppColors.danger : AppColors.textPrimary,
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
                      n.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: titleColor,
                        fontWeight: titleWeight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${n.brandName} · ${n.projectName} · $timeStr',
                      style: AppTypography.caption.copyWith(
                        color: metaColor,
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
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  PhosphorIconData _typeIcon(NotificationType type) => switch (type) {
        NotificationType.document => PhosphorIconsThin.fileText,
        NotificationType.news => PhosphorIconsThin.newspaper,
        NotificationType.phase => PhosphorIconsThin.flag,
        NotificationType.financial => PhosphorIconsThin.trendUp,
        NotificationType.delay => PhosphorIconsThin.warning,
      };
}
