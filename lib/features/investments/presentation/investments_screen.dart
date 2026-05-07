import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/supabase_provider.dart';
import '../../../core/domain/user_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_async_list_states.dart';
import '../../../core/widgets/lhotse_mark.dart';
import '../../../core/widgets/lhotse_notification_bell.dart';
import '../data/investments_provider.dart';
import '../domain/portfolio_entry.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    if (role == UserRole.viewer) {
      return const _ViewerEmptyState();
    }

    final topPadding = MediaQuery.of(context).padding.top;
    final summariesAsync = ref.watch(userPortfolioProvider);

    final summaries = summariesAsync.valueOrNull ?? const [];
    final total = summaries.fold<double>(0, (acc, s) => acc + s.totalAmount);

    final totalFormatted =
        _eurFormat.format(total);
    final collapsedHeight = topPadding + HeroLayout.collapsedHeight;
    final expandedHeight = topPadding +
        HeroLayout.expandedHeight(titleHeight: 88, amountMax: 46);

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
          if (summariesAsync.hasError)
            SliverToBoxAdapter(
              child: LhotseAsyncError(
                message: 'No se pudo cargar tu cartera.',
                onRetry: () => ref.invalidate(userPortfolioProvider),
              ),
            )
          else if (summaries.isEmpty && summariesAsync.isLoading)
            const SliverToBoxAdapter(child: LhotseAsyncLoading())
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
    // Hero collapse logic. Two protections:
    //
    // 1. Lock to expanded (`expandRatio = 1.0`) when there's no scrollable
    //    content. iOS `BouncingScrollPhysics` produces a non-zero
    //    `shrinkOffset` during overscroll bounce even when there's nothing
    //    to scroll to — without this lock, bounce would visually collapse
    //    the hero for no good reason.
    //
    // 2. When scroll exists, interpolate `expandRatio` against the **full**
    //    `collapseRange` (not against `maxScrollExtent`). Pre-existing code
    //    used to remap `effectiveRange = min(maxScroll, collapseRange)` so
    //    the animation always "completed" — that was an anti-pattern. The
    //    sliver's physical extent is dictated by Flutter and only shrinks
    //    by `min(scroll, collapseRange)`; remapping the visuals to complete
    //    in less scroll desynchronizes them from the physical state, which
    //    on lists that barely overflow renders a hero that's physically
    //    big but visually empty (title invisible, amount minimal). UIKit
    //    `prefersLargeTitles` and `SliverAppBar` (Flutter's built-in)
    //    interpolate proportionally to actual collapse — same as we do
    //    here without remap.
    final collapseRange = maxExtent - minExtent;
    final position = Scrollable.maybeOf(context)?.position;
    final maxScroll = position != null && position.hasContentDimensions
        ? position.maxScrollExtent
        : null;
    final hasScrollableContent = maxScroll != null && maxScroll > 0;
    final expandRatio = hasScrollableContent
        ? (1 - shrinkOffset / collapseRange).clamp(0.0, 1.0)
        : 1.0;
    final amountSize = 28 + (18 * expandRatio);
    final euroSize = 13 + (8 * expandRatio);
    // Title fades out gently across the first 60% of the collapse so the
    // chrome band reads clean before the slab finishes collapsing.
    final titleOpacity = ((expandRatio - 0.4) / 0.6).clamp(0.0, 1.0);

    // Amount slides from bottom-left (expanded) to chrome-band center
    // (collapsed). Fixed-padding interpolation keeps the collapsed cifra
    // optically centred between logo and bell.
    final amountTopExpanded = topPadding +
        HeroLayout.expandedAmountY(titleHeight: 88, amountMax: 46);
    final amountTopCollapsed = topPadding + HeroLayout.collapsedAmountY;
    final amountTop = amountTopCollapsed +
        (amountTopExpanded - amountTopCollapsed) * expandRatio;
    // Title is 2 lines × 44pt × line-height 1.0 = 88pt tall; sits one
    // `titleAmountGap` above the amount so the pair reads as a grouped
    // editorial block.
    final titleTop = amountTop - 88 - HeroLayout.titleAmountGap;

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
                style: AppTypography.editorialHero.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 44,
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
                        fontFamily: AppTypography.fontFamily,
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
                        fontFamily: AppTypography.fontFamily,
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
            vertical: 28,
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
              // Brand marker — 48×48 stamp/mark, presence editorial luxury
              // (T Magazine / Openhouse). Prefers the explicit `icon_asset`
              // SVG when present (monochrome `srcIn` so every brand tones to
              // `textPrimary` regardless of source colours), falls back to a
              // thin-border initials monogram when the brand has no icon yet.
              SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: icon != null
                      ? SizedBox(
                          width: 44,
                          height: 44,
                          child: SvgPicture.network(
                            icon,
                            fit: BoxFit.contain,
                            colorFilter: _iconFilter,
                          ),
                        )
                      : Container(
                          width: 44,
                          height: 44,
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
                            style: AppTypography.labelUppercaseSm.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 14,
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
                      style: AppTypography.labelUppercaseMd.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Tabular layout: amount column with fixed width
                    // (left-aligned so the first digit anchors with the
                    // brand name above) and % starting at the same X
                    // across all rows.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      _eurFormat.format(summary.totalAmount),
                                  style: AppTypography.figureAmount.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: ' €',
                                  style: AppTypography.annotation.copyWith(
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
                                style: AppTypography.annotation.copyWith(
                                  color: AppColors.accentMuted,
                                ),
                              ),
                              if (widget.isEstimated)
                                TextSpan(
                                  text: ' est.',
                                  style: AppTypography.annotation.copyWith(
                                    color: AppColors.accentMuted,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 10,
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
                  size: 18,
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

// ── Viewer empty state ────────────────────────────────────────────────────────

class _ViewerEmptyState extends StatelessWidget {
  const _ViewerEmptyState();

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          topPadding + 16,
          AppSpacing.lg,
          AppSpacing.lg + bottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const LhotseMark(color: AppColors.textPrimary),
                const Spacer(),
                const LhotseNotificationBell(color: AppColors.textPrimary),
              ],
            ),
            const Spacer(flex: 2),
            Text(
              'Tu estrategia comienza con tu primera inversión.',
              style: AppTypography.editorialHero.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Esta sección se activa cuando formas parte del grupo de inversores de Lhotse.',
              style: AppTypography.annotationParagraph.copyWith(
                color: AppColors.accentMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Spacer(flex: 3),
            const _ContactButton(),
          ],
        ),
      ),
    );
  }
}

// ── Contact CTA button ────────────────────────────────────────────────────────

class _ContactButton extends StatefulWidget {
  const _ContactButton();

  @override
  State<_ContactButton> createState() => _ContactButtonState();
}

class _ContactButtonState extends State<_ContactButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        // TODO: navigate to contact (destination TBD by product)
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.6 : 1.0,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          color: AppColors.primary,
          child: Text(
            'CONTACTAR',
            style: AppTypography.labelUppercaseMd.copyWith(
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
