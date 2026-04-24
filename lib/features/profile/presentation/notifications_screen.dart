import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../data/notification_preferences_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationPreferences? _local; // optimistic local state

  NotificationPreferences get _prefs =>
      _local ??
      ref.read(notificationPreferencesProvider).valueOrNull ??
      const NotificationPreferences();

  Future<void> _toggle(NotificationPreferences updated) async {
    setState(() => _local = updated);
    await updateNotificationPreferences(ref, updated);
  }

  @override
  Widget build(BuildContext context) {
    // Load on first render
    ref.watch(notificationPreferencesProvider).whenData((prefs) {
      if (_local == null && prefs != null) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => setState(() => _local = prefs));
      }
    });

    final topPadding = MediaQuery.of(context).padding.top;
    final p = _prefs;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(topPadding: topPadding),
            const SizedBox(height: AppSpacing.xl),

            const _SectionLabel(title: 'INVERSIONES'),
            const SizedBox(height: AppSpacing.xs),
            _ToggleRow(
              label: 'Actualizaciones de inversión',
              value: p.investmentUpdates,
              onChanged: (v) => _toggle(p.copyWith(investmentUpdates: v)),
            ),
            _ToggleRow(
              label: 'Documentos disponibles',
              value: p.documents,
              onChanged: (v) => _toggle(p.copyWith(documents: v)),
            ),

            const SizedBox(height: AppSpacing.xl),
            const _SectionLabel(title: 'GENERAL'),
            const SizedBox(height: AppSpacing.xs),
            _ToggleRow(
              label: 'Noticias del grupo',
              value: p.groupNews,
              onChanged: (v) => _toggle(p.copyWith(groupNews: v)),
            ),
            _ToggleRow(
              label: 'Eventos y novedades',
              value: p.events,
              onChanged: (v) => _toggle(p.copyWith(events: v)),
            ),

            const SizedBox(height: AppSpacing.xl),
            const _SectionLabel(title: 'CANALES'),
            const SizedBox(height: AppSpacing.xs),
            _ToggleRow(
              label: 'Notificaciones push',
              value: p.pushEnabled,
              onChanged: (v) => _toggle(p.copyWith(pushEnabled: v)),
            ),
            _ToggleRow(
              label: 'Correo electrónico',
              value: p.emailEnabled,
              onChanged: (v) => _toggle(p.copyWith(emailEnabled: v)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.topPadding});
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.sm, topPadding + 16, AppSpacing.lg, 16),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            const LhotseBackButton.onSurface(),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'NOTIFICACIONES',
              style: AppTypography.headingLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.accentMuted,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              height: 0.5,
              color: AppColors.textPrimary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle row ────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            _Checkbox(value: value),
          ],
        ),
      ),
    );
  }
}

// ── Checkbox ──────────────────────────────────────────────────────────────────

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: value ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: value
              ? AppColors.primary
              : AppColors.textPrimary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: value
          ? const Center(
              child: Icon(Icons.check, size: 13, color: AppColors.textOnDark))
          : null,
    );
  }
}
