import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(topPadding: topPadding),

          const SizedBox(height: AppSpacing.lg),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Nuestro equipo está disponible para ayudarte con cualquier consulta.',
              style: AppTypography.bodyReading.copyWith(
                color: AppColors.accentMuted,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Contact methods
          const _ContactRow(
            icon: PhosphorIconsThin.envelope,
            label: 'Email',
            value: 'soporte@lhotsegroup.com',
          ),
          const _ContactRow(
            icon: PhosphorIconsThin.phone,
            label: 'Teléfono',
            value: '+34 910 123 456',
          ),
          const _ContactRow(
            icon: PhosphorIconsThin.whatsappLogo,
            label: 'WhatsApp',
            value: '+34 612 345 678',
          ),

          const SizedBox(height: AppSpacing.xl),

          // Schedule
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HORARIO DE ATENCIÓN',
                  style: AppTypography.labelUppercaseMd.copyWith(
                    color: AppColors.accentMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Lunes a viernes: 9:00 — 18:00 (CET)',
                  style: AppTypography.bodyReading.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tiempo medio de respuesta: 24h',
                  style: AppTypography.annotation.copyWith(
                    color: AppColors.accentMuted,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Para cuestiones urgentes relacionadas con inversiones, contacta directamente por teléfono.',
              style: AppTypography.annotation.copyWith(
                color: AppColors.accentMuted,
              ),
            ),
          ),

          SizedBox(height: bottomPadding + AppSpacing.xl),
        ],
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
              'CONTACTO Y SOPORTE',
              style: AppTypography.titleUppercase.copyWith(
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
// Contact row
// ---------------------------------------------------------------------------

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          PhosphorIcon(
            icon,
            size: 20,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTypography.labelUppercaseSm.copyWith(
                  color: AppColors.accentMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyReading.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
