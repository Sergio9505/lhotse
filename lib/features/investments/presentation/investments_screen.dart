import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/domain/project_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_mark.dart';
import '../../../core/widgets/lhotse_notification_bell.dart';
import '../data/investments_provider.dart';
import '../../../core/data/projects_provider.dart';
import '../domain/portfolio_entry.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final summariesAsync = ref.watch(userPortfolioProvider);
    final opportunitiesAsync =
        ref.watch(opportunitiesProvider(const {}));

    final summaries = summariesAsync.valueOrNull ?? const [];
    final total = summaries.fold<double>(0, (acc, s) => acc + s.totalAmount);
    final opportunities = opportunitiesAsync.valueOrNull ?? const [];

    final totalFormatted =
        _eurFormat.format(total).replaceAll('.', ' ');
    final collapsedHeight = topPadding + 80.0;
    final expandedHeight = topPadding + 260.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
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


          // Hairline separator — closes the allocation block and marks
          // the transition to the holdings detail (brand rows). Pictet
          // / Julius Bär reporting convention between allocation summary
          // and holdings list.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Container(
                height: 0.5,
                color: AppColors.textPrimary.withValues(alpha: 0.15),
              ),
            ),
          ),

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
                    onTap: () => context.push(
                      '/investments/brand/${summary.brandId}',
                      extra: (
                        brandName: summary.brandName,
                        businessModel: summary.businessModel,
                      ),
                    ),
                  );
                },
                childCount: summaries.length,
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
    final amountSize = 28 + (20 * expandRatio);
    final euroSize = 13 + (9 * expandRatio);
    // Title fades out gently across the first 60% of the collapse so the
    // chrome band reads clean before the slab finishes collapsing.
    final titleOpacity = ((expandRatio - 0.4) / 0.6).clamp(0.0, 1.0);

    // Amount slides from bottom-left (expanded) to chrome-band center
    // (collapsed). Fixed-padding interpolation keeps the collapsed cifra
    // optically centred between logo and bell.
    final amountTopExpanded = expandedHeight - AppSpacing.lg - 56;
    final amountTopCollapsed = topPadding + 28;
    final amountTop = amountTopCollapsed +
        (amountTopExpanded - amountTopCollapsed) * expandRatio;
    // Title sits ~96pt above the amount expanded so the two lines have
    // room and the pair reads as a grouped editorial block.
    final titleTop = amountTop - 96;

    return Container(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: titleTop,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Opacity(
              opacity: titleOpacity,
              child: Text(
                'Mi estrategia\npatrimonial',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w300,
                  height: 1.0,
                ),
              ),
            ),
          ),
          Positioned(
            top: amountTop,
            left: AppSpacing.lg * expandRatio,
            right: AppSpacing.lg * expandRatio,
            child: Align(
              alignment: Alignment(-expandRatio, 0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: totalFormatted,
                      style: TextStyle(
                        fontFamily: 'Campton',
                        fontSize: amountSize,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.2,
                        height: 1.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    TextSpan(
                      text: ' €',
                      style: TextStyle(
                        fontFamily: 'Campton',
                        fontSize: euroSize,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary.withValues(alpha: 0.55),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: topPadding + 16,
            left: AppSpacing.lg,
            child: const SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: LhotseMark(color: AppColors.textPrimary),
              ),
            ),
          ),
          Positioned(
            top: topPadding + 16,
            right: AppSpacing.md,
            child: const LhotseNotificationBell(
              color: AppColors.textPrimary,
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

  final PortfolioEntry summary;
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
                            // European luxury format: space separators +
                            // Campton w400 Book (not bold) so the list
                            // matches the hero's tipography family —
                            // Pictet / Julius Bär / Lombard Odier reports.
                            text: _eurFormat
                                .format(summary.totalAmount)
                                .replaceAll('.', ' '),
                            style: AppTypography.headingSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w400,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          TextSpan(
                            // € subordinate: muted color + non-breaking
                            // space before, same treatment as the hero.
                            text: ' €',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accentMuted,
                            ),
                          ),
                          TextSpan(
                            text:
                                '   ·   ${avgReturn.toStringAsFixed(1)}%',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accentMuted,
                            ),
                          ),
                          if (widget.isEstimated)
                            TextSpan(
                              // "est." inline replaces the cryptic "*".
                              // Auto-explanatory for a financial reader;
                              // lets us drop the footnote entirely. Italic
                              // + smaller + muted so it reads as an
                              // editorial annotation, not extra data.
                              text: ' est.',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.accentMuted,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.3,
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
                  size: 12,
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
