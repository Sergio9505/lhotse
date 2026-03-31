import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/data/mock/mock_investments.dart';
import '../../../core/data/mock/mock_projects.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_app_header.dart';
import '../../../core/widgets/lhotse_ledger_row.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');

class BrandInvestmentsScreen extends StatelessWidget {
  const BrandInvestmentsScreen({super.key, required this.brandName});

  final String brandName;

  @override
  Widget build(BuildContext context) {
    final summary = activeBrandSummaries
        .where((s) => s.brandName == brandName)
        .firstOrNull;
    final completed = completedInvestments
        .where((i) => i.brandName == brandName)
        .toList();
    final brand =
        mockBrands.where((b) => b.name == brandName).firstOrNull;
    final showLocation = brand?.businessModel != BusinessModel.rentaFija;
    if (summary == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'No se encontraron inversiones',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          LhotseAppHeader(title: brandName.toUpperCase()),

          const SizedBox(height: AppSpacing.md),

          // Total + return + operations — three tiers of information
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tier 1: Amount
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _eurFormat.format(summary.totalAmount),
                        style: const TextStyle(
                          fontFamily: 'Campton',
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -1.0,
                          height: 1.0,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const TextSpan(
                        text: '€',
                        style: TextStyle(
                          fontFamily: 'Campton',
                          fontSize: 28,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Tier 2: Return
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${summary.averageReturn.toStringAsFixed(0)}%',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '  rentabilidad',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accentMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                // Tier 3: Operations count
                Text(
                  '${summary.investments.length} activas${completed.isNotEmpty ? '  ·  ${completed.length} finalizadas' : ''}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accentMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Active section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'ACTIVAS',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.accentMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...summary.investments.indexed.map((entry) {
            final inv = entry.$2;
            final project = findProjectById(inv.projectId);
            return LhotseLedgerRow(
              leading: _ProjectThumbnail(imageUrl: project?.imageUrl),
              title: inv.projectName.toUpperCase(),
              subtitle: showLocation ? project?.location.toUpperCase() : null,
              amount: inv.amount,
              returnLabel: '${inv.returnRate.toStringAsFixed(0)}% rent. estimada',
              isLast: entry.$1 == summary.investments.length - 1,
              onTap: () => context.push('/investments/detail/${inv.id}'),
            );
          }),

          // Completed section
          if (completed.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'FINALIZADAS',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.accentMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...completed.indexed.map((entry) {
              final inv = entry.$2;
              final project = findProjectById(inv.projectId);
              return LhotseLedgerRow(
                leading: _ProjectThumbnail(
                    imageUrl: project?.imageUrl, muted: true),
                title: inv.projectName.toUpperCase(),
                subtitle: showLocation ? project?.location.toUpperCase() : null,
                amount: inv.amount,
                returnLabel:
                    '${inv.returnRate.toStringAsFixed(0)}% rentabilidad',
                muted: true,
                isLast: entry.$1 == completed.length - 1,
                onTap: () => context.push('/investments/detail/${inv.id}'),
              );
            }),
          ],

          SizedBox(
              height: MediaQuery.of(context).padding.bottom + AppSpacing.xl),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Project thumbnail — leading widget for investment rows
// ---------------------------------------------------------------------------

class _ProjectThumbnail extends StatelessWidget {
  const _ProjectThumbnail({this.imageUrl, this.muted = false});

  final String? imageUrl;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: muted ? 0.5 : 1.0,
      child: SizedBox(
        width: 44,
        height: 44,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: AppColors.surface),
              )
            : Container(color: AppColors.surface),
      ),
    );
  }
}
