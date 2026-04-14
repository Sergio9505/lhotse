import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';

class KycScreen extends StatelessWidget {
  const KycScreen({super.key});

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

          // Status summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Estado de tu documentación para operar como inversor.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.accentMuted,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Document list
          const _DocumentRow(
            icon: PhosphorIconsThin.identificationCard,
            label: 'DNI / Pasaporte',
            status: _KycStatus.verified,
          ),
          const _DocumentRow(
            icon: PhosphorIconsThin.house,
            label: 'Justificante de domicilio',
            status: _KycStatus.pending,
          ),
          const _DocumentRow(
            icon: PhosphorIconsThin.bank,
            label: 'Origen de fondos',
            status: _KycStatus.required,
          ),
          const _DocumentRow(
            icon: PhosphorIconsThin.fileText,
            label: 'Contrato marco',
            status: _KycStatus.verified,
          ),

          const Spacer(),

          // Help note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Si necesitas ayuda con la documentación, contacta con nuestro equipo de soporte.',
              style: AppTypography.bodySmall.copyWith(
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
              'DOCUMENTACIÓN LEGAL',
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
// KYC status
// ---------------------------------------------------------------------------

enum _KycStatus {
  verified,
  pending,
  required;

  String get label => switch (this) {
        _KycStatus.verified => 'VERIFICADO',
        _KycStatus.pending => 'PENDIENTE',
        _KycStatus.required => 'REQUERIDO',
      };

  Color get color => switch (this) {
        _KycStatus.verified => const Color(0xFF2D6A4F),
        _KycStatus.pending => const Color(0xFFDAAC03),
        _KycStatus.required => AppColors.danger,
      };
}

// ---------------------------------------------------------------------------
// Document row
// ---------------------------------------------------------------------------

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.icon,
    required this.label,
    required this.status,
  });

  final IconData icon;
  final String label;
  final _KycStatus status;

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
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: status.color.withValues(alpha: 0.1),
            child: Text(
              status.label,
              style: AppTypography.caption.copyWith(
                color: status.color,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
