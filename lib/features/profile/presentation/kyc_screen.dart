import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../data/kyc_provider.dart';

class KycScreen extends ConsumerWidget {
  const KycScreen({super.key});

  static IconData _iconFor(String docType) => switch (docType) {
        'dni_pasaporte' => PhosphorIconsThin.identificationCard,
        'justificante_domicilio' => PhosphorIconsThin.house,
        'origen_fondos' => PhosphorIconsThin.bank,
        'contrato_marco' => PhosphorIconsThin.fileText,
        _ => PhosphorIconsThin.file,
      };

  static _KycStatus _statusFor(String status) => switch (status) {
        'verified' => _KycStatus.verified,
        'pending' => _KycStatus.pending,
        _ => _KycStatus.required,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final kycAsync = ref.watch(kycDocumentsProvider);

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
              'Estado de tu documentación para operar como inversor.',
              style: AppTypography.bodyReading.copyWith(
                color: AppColors.accentMuted,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Document list
          kycAsync.when(
            data: (docs) => Column(
              children: docs.map((doc) => _DocumentRow(
                    icon: _iconFor(doc.docType),
                    label: doc.displayName,
                    status: _statusFor(doc.status),
                  )).toList(),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('$e',
                  style: AppTypography.annotation
                      .copyWith(color: AppColors.danger)),
            ),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Si necesitas ayuda con la documentación, contacta con nuestro equipo de soporte.',
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
              'DOCUMENTACIÓN LEGAL',
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

// ── KYC status enum ───────────────────────────────────────────────────────────

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

// ── Document row ──────────────────────────────────────────────────────────────

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
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          PhosphorIcon(icon, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyReading.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: status.color.withValues(alpha: 0.1),
            child: Text(
              status.label,
              style: AppTypography.badgePill.copyWith(
                color: status.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
