import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock toggle state — will be replaced by provider
  final Map<String, bool> _toggles = {
    'investment_updates': true,
    'new_opportunities': true,
    'documents': false,
    'group_news': true,
    'events': false,
    'push': true,
    'email': true,
  };

  void _onToggle(String key, bool value) {
    setState(() => _toggles[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

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
              value: _toggles['investment_updates']!,
              onChanged: (v) => _onToggle('investment_updates', v),
            ),
            _ToggleRow(
              label: 'Nuevas oportunidades',
              value: _toggles['new_opportunities']!,
              onChanged: (v) => _onToggle('new_opportunities', v),
            ),
            _ToggleRow(
              label: 'Documentos disponibles',
              value: _toggles['documents']!,
              onChanged: (v) => _onToggle('documents', v),
            ),

            const SizedBox(height: AppSpacing.xl),

            const _SectionLabel(title: 'GENERAL'),
            const SizedBox(height: AppSpacing.xs),
            _ToggleRow(
              label: 'Noticias del grupo',
              value: _toggles['group_news']!,
              onChanged: (v) => _onToggle('group_news', v),
            ),
            _ToggleRow(
              label: 'Eventos y novedades',
              value: _toggles['events']!,
              onChanged: (v) => _onToggle('events', v),
            ),

            const SizedBox(height: AppSpacing.xl),

            const _SectionLabel(title: 'CANALES'),
            const SizedBox(height: AppSpacing.xs),
            _ToggleRow(
              label: 'Notificaciones push',
              value: _toggles['push']!,
              onChanged: (v) => _onToggle('push', v),
            ),
            _ToggleRow(
              label: 'Correo electrónico',
              value: _toggles['email']!,
              onChanged: (v) => _onToggle('email', v),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        topPadding + 16,
        AppSpacing.lg,
        16,
      ),
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

// ---------------------------------------------------------------------------
// Section label (same pattern as profile screen)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Toggle row
// ---------------------------------------------------------------------------

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
          horizontal: AppSpacing.lg,
          vertical: 18,
        ),
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

// ---------------------------------------------------------------------------
// Checkbox — rectangular, sharp edges, consistent with design system
// ---------------------------------------------------------------------------

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
              child: Icon(
                Icons.check,
                size: 13,
                color: AppColors.textOnDark,
              ),
            )
          : null,
    );
  }
}
