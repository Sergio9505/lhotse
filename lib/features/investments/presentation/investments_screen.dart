import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/data/mock/mock_investments.dart';
import '../../../core/data/mock/mock_projects.dart';
import '../../../core/domain/investment_data.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_ledger_row.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');

double _avgReturn(List<BrandInvestmentSummary> summaries) {
  if (summaries.isEmpty) return 0;
  return summaries.fold(0.0, (sum, s) => sum + s.averageReturn) /
      summaries.length;
}

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final summaries = activeBrandSummaries
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final total = summaries.fold(0.0, (sum, s) => sum + s.totalAmount);

    final investedProjectIds =
        mockInvestments.map((i) => i.projectId).toSet();
    final availableProjects =
        mockProjects.where((p) => !investedProjectIds.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Hero section — navy background
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, topPadding + AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header — same size as all other screens
                Row(
                  children: [
                    Text(
                      'MI PATRIMONIO',
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const Spacer(),
                    SvgPicture.asset(
                      'assets/images/lhotse_logo.svg',
                      width: 20,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textOnDark,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Amount
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _eurFormat.format(total),
                        style: const TextStyle(
                          fontFamily: 'Campton',
                          fontSize: 50,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnDark,
                          letterSpacing: -1.2,
                          height: 1.0,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const TextSpan(
                        text: '€',
                        style: TextStyle(
                          fontFamily: 'Campton',
                          fontSize: 34,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textOnDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Return
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${_avgReturn(summaries).toStringAsFixed(1)}%',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '  rentabilidad media',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textOnDark.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Brand breakdown
          ...summaries.indexed.map((entry) {
            final brandName = entry.$2.brandName;
            final totalOps = mockInvestments
                .where((i) => i.brandName == brandName)
                .length;
            return LhotseLedgerRow(
                leading: _BrandLeading(brandName: brandName),
                title: brandName.toUpperCase(),
                subtitle: '$totalOps operaciones',
                amount: entry.$2.totalAmount,
                returnLabel: '${entry.$2.averageReturn.toStringAsFixed(0)}% rentabilidad',
                isLast: entry.$1 == summaries.length - 1,
                onTap: () => context.push(
                    '/investments/brand/${Uri.encodeComponent(brandName)}'),
              );
          }),

          const SizedBox(height: AppSpacing.xxl),

          // New opportunities
          if (availableProjects.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GestureDetector(
                onTap: () => context.push('/investments/opportunities'),
                child: Row(
                  children: [
                    Text(
                      'NUEVAS OPORTUNIDADES',
                      style: AppTypography.headingLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      LucideIcons.arrowUpRight,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: availableProjects.length.clamp(0, 4),
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final project = availableProjects[i];
                  return _OpportunityCard(project: project);
                },
              ),
            ),
          ],

          SizedBox(
              height: MediaQuery.of(context).padding.bottom + AppSpacing.xl),
        ],
      ),
    );
  }
}

class _BrandLeading extends StatelessWidget {
  const _BrandLeading({required this.brandName});

  final String brandName;

  @override
  Widget build(BuildContext context) {
    final brand = mockBrands.where((b) => b.name == brandName).firstOrNull;

    if (brand?.logoAsset != null) {
      return SizedBox(
        width: 36,
        height: 28,
        child: SvgPicture.asset(
          brand!.logoAsset!,
          colorFilter: const ColorFilter.mode(
            AppColors.textPrimary,
            BlendMode.srcIn,
          ),
        ),
      );
    }

    return SizedBox(
      width: 36,
      height: 28,
      child: Center(
        child: Text(
          brandName[0],
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Opportunity card — compact image card with financial overlay
// ---------------------------------------------------------------------------

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.project});

  final ProjectData project;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/projects/${project.id}'),
      child: SizedBox(
        width: 180,
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                project.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: AppColors.surface),
              ),
              // Beige overlay — same pattern as ProjectCard in Home, scaled down
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  color: AppColors.surface.withValues(alpha: 0.75),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              project.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.headingSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  project.brand.toUpperCase(),
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    '•',
                                    style: AppTypography.captionSmall.copyWith(
                                      color: AppColors.textPrimary.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    project.location.toUpperCase(),
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.captionSmall.copyWith(
                                      color: AppColors.accentMuted,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.arrowUpRight,
                        size: 14,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
