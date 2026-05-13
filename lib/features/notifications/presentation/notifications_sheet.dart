import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/domain/app_notification.dart';
import '../../../core/notifications/onesignal_service.dart';
import '../../../core/notifications/push_permission_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_async_list_states.dart';
import '../../../core/widgets/lhotse_notification_badge.dart';
import '../../../core/widgets/lhotse_section_label.dart';
import '../data/notifications_provider.dart';
import 'push_soft_ask_sheet.dart';

String _relativeTime(DateTime date, DateTime now) {
  final diff = now.difference(date);
  if (diff.inMinutes < 60) return 'HACE ${diff.inMinutes}MIN';
  if (diff.inHours < 24) return 'HACE ${diff.inHours}H';
  if (diff.inDays < 7) return 'HACE ${diff.inDays}D';
  if (diff.inDays < 30) return 'HACE ${diff.inDays ~/ 7}SEM';
  return DateFormat('d MMM').format(date).toUpperCase();
}

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

class _NotificationsSheetContent extends ConsumerStatefulWidget {
  const _NotificationsSheetContent();

  @override
  ConsumerState<_NotificationsSheetContent> createState() =>
      _NotificationsSheetContentState();
}

class _NotificationsSheetContentState
    extends ConsumerState<_NotificationsSheetContent> {
  bool _deniedBannerVisible = false;
  bool _notDeterminedBannerDismissedThisSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapPermission());
  }

  Future<void> _bootstrapPermission() async {
    final shouldShowDenied = await OneSignalService.shouldShowDeniedBanner();
    if (mounted) {
      setState(() => _deniedBannerVisible = shouldShowDenied);
    }
    if (await OneSignalService.canShowSoftAsk()) {
      if (!mounted) return;
      await showPushSoftAsk(context);
    }
  }

  Future<void> _handleDeniedTap() async {
    await OneSignalService.openSystemPushSettings();
  }

  Future<void> _handleDeniedDismiss() async {
    await OneSignalService.markDeniedBannerDismissed();
    if (!mounted) return;
    setState(() => _deniedBannerVisible = false);
  }

  Future<void> _handleNotDeterminedTap() async {
    final canShow = await OneSignalService.canShowSoftAsk();
    if (!mounted) return;
    if (canShow) {
      await showPushSoftAsk(context);
    } else {
      await OneSignalService.openSystemPushSettings();
    }
  }

  void _handleNotDeterminedDismiss() {
    setState(() => _notDeterminedBannerDismissedThisSession = true);
  }

  @override
  Widget build(BuildContext context) {
    final notifAsync = ref.watch(notificationsProvider);
    final permission = ref.watch(pushPermissionProvider);
    final notifications = notifAsync.value ?? const [];
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final today = <AppNotification>[];
    final thisWeek = <AppNotification>[];
    final earlier = <AppNotification>[];

    for (final n in notifications) {
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
    final screenHeight = MediaQuery.of(context).size.height;
    final hasUnread = notifications.any((n) => !n.isRead);

    const headerHeight = 80.0;
    const dividerHeight = 0.5;
    const sectionHeaderHeight = 36.0;
    const rowHeight = 64.0;
    final totalRows = sections.fold<int>(0, (sum, s) => sum + s.$2.length);
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
            child: Row(
              children: [
                Text(
                  'NOTIFICACIONES',
                  style: AppTypography.titleUppercaseLg.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: hasUnread
                      ? () => markNotificationsRead(ref)
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
          Container(
            height: 0.5,
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
          _PermissionBanner(
            permission: permission,
            deniedVisible: _deniedBannerVisible,
            notDeterminedDismissed: _notDeterminedBannerDismissedThisSession,
            onTapDenied: _handleDeniedTap,
            onDismissDenied: _handleDeniedDismiss,
            onTapNotDetermined: _handleNotDeterminedTap,
            onDismissNotDetermined: _handleNotDeterminedDismiss,
          ),
          Expanded(
            child: notifAsync.when(
              loading: () => const LhotseAsyncLoading(),
              error: (_, _) => LhotseAsyncError(
                message: 'No se pudieron cargar las notificaciones.',
                onRetry: () => ref.invalidate(notificationsProvider),
              ),
              data: (_) => sections.isEmpty
                  ? Center(
                      child: Text(
                        'SIN NOTIFICACIONES',
                        style: AppTypography.labelUppercaseMd.copyWith(
                          color: AppColors.accentMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
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
          ),
        ],
      ),
    );
  }
}

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
    final timeStr = _relativeTime(n.date, widget.now);

    final titleColor =
        isUnread ? AppColors.textPrimary : AppColors.accentMuted;
    final titleWeight = isUnread ? FontWeight.w600 : FontWeight.w400;
    final metaColor =
        isUnread ? AppColors.accentMuted : AppColors.textSecondary;

    final meta = [
      if (n.brandName != null) n.brandName!,
      if (n.projectName != null) n.projectName!,
      timeStr,
    ].join(' · ');

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => Navigator.of(context).pop(),
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
              Container(
                width: 36,
                height: 36,
                color: AppColors.textPrimary.withValues(alpha: 0.06),
                child: Center(
                  child: PhosphorIcon(
                    _typeIcon(n.type),
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: AppTypography.bodyReading.copyWith(
                        color: titleColor,
                        fontWeight: titleWeight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (n.body != null && n.body!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        n.body!,
                        style: AppTypography.bodyReading.copyWith(
                          color: AppColors.accentMuted,
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: metaColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
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
        NotificationType.project => PhosphorIconsThin.buildings,
        NotificationType.asset => PhosphorIconsThin.houseLine,
        NotificationType.news => PhosphorIconsThin.newspaper,
        NotificationType.document => PhosphorIconsThin.fileText,
      };
}

/// Discreet row above the notifications list. Visible only when the OS
/// permission state warrants it. Dismissable; never blocking.
class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.permission,
    required this.deniedVisible,
    required this.notDeterminedDismissed,
    required this.onTapDenied,
    required this.onDismissDenied,
    required this.onTapNotDetermined,
    required this.onDismissNotDetermined,
  });

  final OSNotificationPermission permission;
  final bool deniedVisible;
  final bool notDeterminedDismissed;
  final VoidCallback onTapDenied;
  final VoidCallback onDismissDenied;
  final VoidCallback onTapNotDetermined;
  final VoidCallback onDismissNotDetermined;

  @override
  Widget build(BuildContext context) {
    if (permission == OSNotificationPermission.denied && deniedVisible) {
      return _BannerRow(
        text: 'Notificaciones en pausa · Active en Ajustes →',
        onTap: onTapDenied,
        onDismiss: onDismissDenied,
      );
    }
    if (permission == OSNotificationPermission.notDetermined &&
        !notDeterminedDismissed &&
        !OneSignalService.softAskShownThisSession) {
      // Only shows up after the cap is hit (the soft-ask already auto-fires
      // on open). Acts as the passive re-entry point.
      return _BannerRow(
        text: 'Active las notificaciones →',
        onTap: onTapNotDetermined,
        onDismiss: onDismissNotDetermined,
      );
    }
    return const SizedBox.shrink();
  }
}

class _BannerRow extends StatelessWidget {
  const _BannerRow({
    required this.text,
    required this.onTap,
    required this.onDismiss,
  });

  final String text;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.textPrimary.withValues(alpha: 0.04),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm + 2,
                ),
                child: Text(
                  text,
                  style: AppTypography.labelUppercaseSm.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 44,
              height: 32,
              child: Center(
                child: PhosphorIcon(
                  PhosphorIconsThin.x,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
