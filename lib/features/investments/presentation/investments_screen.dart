import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_mark.dart';
import '../../../core/widgets/lhotse_notification_bell.dart';
import '../data/investments_provider.dart';
import '../domain/portfolio_entry.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final summariesAsync = ref.watch(userPortfolioProvider);

    final summaries = summariesAsync.valueOrNull ?? const [];
    final total = summaries.fold<double>(0, (acc, s) => acc + s.totalAmount);

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
    // Remap collapse range to actual available scroll so the animation
    // always completes — otherwise, when the list is short, the hero
    // freezes mid-collapse (maxScrollExtent < maxExtent-minExtent).
    final collapseRange = maxExtent - minExtent;
    final position = Scrollable.maybeOf(context)?.position;
    final maxScroll = (position != null && position.hasContentDimensions)
        ? position.maxScrollExtent
        : collapseRange;
    final effectiveRange =
        maxScroll < collapseRange ? maxScroll : collapseRange;
    final expandRatio = effectiveRange <= 0
        ? 1.0
        : (1 - shrinkOffset / effectiveRange).clamp(0.0, 1.0);
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

  static const _iconFilter =
      ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn);

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final icon = summary.brandIconAsset;
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
              // Brand marker — compact square 32×32 centered in a 48×32 slot.
              // Prefers the explicit `icon_asset` SVG when present (monochrome
              // `srcIn` so every brand tones to `textPrimary` regardless of
              // source colours), falls back to a thin-border initials monogram
              // when the brand has no icon yet (private-banker holdings-report
              // convention — every position gets a consistent marker).
              SizedBox(
                width: 48,
                height: 32,
                child: Center(
                  child: icon != null
                      ? SizedBox(
                          width: 32,
                          height: 32,
                          child: SvgPicture.network(
                            icon,
                            fit: BoxFit.contain,
                            colorFilter: _iconFilter,
                          ),
                        )
                      : Container(
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
                            summary.brandName
                                .split(' ')
                                .map((w) => w[0])
                                .join(),
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
                    // Tabular layout: amount column with fixed width
                    // (left-aligned so the first digit anchors with the
                    // brand name above) and % starting at the same X
                    // across all rows.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        SizedBox(
                          width: 140,
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
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
                                  text: ' €',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.accentMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${avgReturn.toStringAsFixed(1)}%',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.accentMuted,
                                ),
                              ),
                              if (widget.isEstimated)
                                TextSpan(
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
