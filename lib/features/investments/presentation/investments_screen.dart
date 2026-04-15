import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/domain/project_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_notification_bell.dart';
import '../data/investments_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../domain/investment_summary.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final summariesAsync = ref.watch(brandSummariesProvider);
    final portfolioAsync = ref.watch(portfolioSummaryProvider);
    final opportunitiesAsync =
        ref.watch(opportunitiesProvider(const {}));

    final summaries = summariesAsync.valueOrNull ?? const [];
    final total = portfolioAsync.valueOrNull?.totalInvested ?? 0.0;
    final opportunities = opportunitiesAsync.valueOrNull ?? const [];

    final totalFormatted = _eurFormat.format(total);
    final collapsedHeight = topPadding + 72.0;
    final expandedHeight = topPadding + 200.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(brandSummariesProvider);
          ref.invalidate(portfolioSummaryProvider);
          ref.invalidate(opportunitiesProvider);
          await Future.wait([
            ref.read(brandSummariesProvider.future).catchError((_) {}),
            ref.read(portfolioSummaryProvider.future).catchError((_) {}),
          ]);
        },
        child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeroDelegate(
              expandedHeight: expandedHeight,
              collapsedHeight: collapsedHeight,
              topPadding: topPadding,
              totalFormatted: totalFormatted,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // Brand rows
          if (summaries.isEmpty && summariesAsync.isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final summary = summaries[i];
                  final isEstimated = summary.businessModel != 'fixed_income';
                  return _BrandRow(
                    summary: summary,
                    isEstimated: isEstimated,
                    isLast: i == summaries.length - 1,
                    onTap: () =>
                        context.push('/investments/brand/${summary.brandId}'),
                  );
                },
                childCount: summaries.length,
              ),
            ),

          // Estimated footnote
          if (summaries.any((s) => s.businessModel != 'fixed_income'))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: AppSpacing.lg, top: AppSpacing.md),
                child: Text(
                  '* Rentabilidad estimada',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          // Opportunities
          if (opportunities.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: GestureDetector(
                      onTap: () =>
                          context.push('/investments/opportunities'),
                      child: Row(
                        children: [
                          Text(
                            'NUEVAS OPORTUNIDADES',
                            style: AppTypography.headingLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const PhosphorIcon(
                            PhosphorIconsThin.arrowUpRight,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      itemCount: opportunities.length.clamp(0, 4),
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, i) =>
                          _OpportunityCard(project: opportunities[i]),
                    ),
                  ),
                ],
              ),
            ),

          SliverToBoxAdapter(
            child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + AppSpacing.xl),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Hero delegate ─────────────────────────────────────────────────────────────

class _HeroDelegate extends SliverPersistentHeaderDelegate {
  const _HeroDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.topPadding,
    required this.totalFormatted,
  });

  final double expandedHeight;
  final double collapsedHeight;
  final double topPadding;
  final String totalFormatted;

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final expandRatio =
        (1 - shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final amountSize = 28 + (22 * expandRatio);
    final euroSize = 20 + (14 * expandRatio);

    return Container(
      color: AppColors.primary,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: topPadding + AppSpacing.md - (shrinkOffset * 0.3),
            left: AppSpacing.lg,
            right: AppSpacing.lg + 44,
            child: Opacity(
              opacity: ((expandRatio - 0.5) / 0.5).clamp(0.0, 1.0),
              child: Text(
                'MI ESTRATEGIA PATRIMONIAL',
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: AppSpacing.md,
            left: AppSpacing.lg,
            right: AppSpacing.lg + 44,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: totalFormatted,
                    style: TextStyle(
                      fontFamily: 'Campton',
                      fontSize: amountSize,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textOnDark,
                      letterSpacing: -1.2,
                      height: 1.0,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  TextSpan(
                    text: '€',
                    style: TextStyle(
                      fontFamily: 'Campton',
                      fontSize: euroSize,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textOnDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: topPadding + 16,
            right: AppSpacing.md,
            child: const LhotseNotificationBell(
              color: AppColors.textOnDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeroDelegate oldDelegate) =>
      expandedHeight != oldDelegate.expandedHeight ||
      collapsedHeight != oldDelegate.collapsedHeight ||
      totalFormatted != oldDelegate.totalFormatted;
}

// ── Brand row ─────────────────────────────────────────────────────────────────

class _BrandRow extends StatefulWidget {
  const _BrandRow({
    required this.summary,
    this.isEstimated = false,
    this.isLast = false,
    this.onTap,
  });

  final BrandInvestmentSummaryData summary;
  final bool isEstimated;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  State<_BrandRow> createState() => _BrandRowState();
}

class _BrandRowState extends State<_BrandRow> {
  bool _pressed = false;

  static const _svgFilter =
      ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn);

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final logo = summary.brandLogoAsset;
    final avgReturn = summary.avgReturnPct ?? 0.0;

    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _pressed = false)
          : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 20,
          ),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              SizedBox(
                width: 48,
                height: 32,
                child: logo != null
                    ? (logo.startsWith('http')
                        ? SvgPicture.network(logo,
                            fit: BoxFit.contain, colorFilter: _svgFilter)
                        : SvgPicture.asset(logo,
                            fit: BoxFit.contain, colorFilter: _svgFilter))
                    : Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.textPrimary,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            summary.brandName.split(' ').map((w) => w[0]).join(),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Name + amount · return
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.brandName.toUpperCase(),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentMuted,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _eurFormat.format(summary.totalAmount),
                            style: AppTypography.headingSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          TextSpan(
                            text: '€',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text:
                                '  ·  ${avgReturn.toStringAsFixed(0)}%${widget.isEstimated ? '*' : ''}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accentMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                PhosphorIcon(
                  PhosphorIconsThin.caretRight,
                  size: 16,
                  color: AppColors.accentMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Opportunity card ──────────────────────────────────────────────────────────

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.project});

  final ProjectData project;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/projects/${project.id}'),
      child: SizedBox(
        width: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            LhotseImage(project.imageUrl),
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
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                project.brand.toUpperCase(),
                                style: AppTypography.captionSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '•',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.textPrimary
                                        .withValues(alpha: 0.4),
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
                    PhosphorIcon(
                      PhosphorIconsThin.arrowUpRight,
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
    );
  }
}
