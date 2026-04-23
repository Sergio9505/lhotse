import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Editorial hero photograph — luxury interior from a Lhotse project
/// (Alberto Aguilera 58, salón). Deep red lacquered ceiling + dark wood +
/// neutral rug + designer pieces (Dior coffee-table books, Louis Vuitton
/// monograph) — says "your wealth is tangible matter" much better than
/// any abstract texture could. Openhouse / T Magazine editorial register.
const _heroImageUrl = 'assets/images/strategy_hero.webp';

/// One row of the asset-allocation table in the hero. Labels on the left,
/// percentages on the right with tabular figures — pattern borrowed from
/// Pictet / Julius Bär / Lombard Odier report PDFs.
class _AllocationSlice {
  const _AllocationSlice({
    required this.label,
    required this.amount,
    required this.percent,
  });

  final String label;
  final double amount;
  final double percent;
}

/// Canonical display order + labels for the asset-allocation breakdown.
/// Fixed order so the table doesn't shuffle as the portfolio changes.
const _allocationModels = <({String key, String label})>[
  (key: 'coinvestment', label: 'Coinversión'),
  (key: 'direct_purchase', label: 'Compra directa'),
  (key: 'fixed_income', label: 'Renta fija'),
  (key: 'rental', label: 'Rental'),
];

List<_AllocationSlice> _buildAllocationBreakdown(
    List<PortfolioEntry> summaries, double total) {
  if (total <= 0) return const [];
  final sums = <String, double>{};
  for (final s in summaries) {
    sums[s.businessModel] = (sums[s.businessModel] ?? 0) + s.totalAmount;
  }
  return _allocationModels
      .where((m) => (sums[m.key] ?? 0) > 0)
      .map((m) {
        final amount = sums[m.key]!;
        return _AllocationSlice(
          label: m.label,
          amount: amount,
          percent: amount / total,
        );
      })
      .toList();
}

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

    // European luxury convention: space as thousands separator instead of
    // the Spanish default dot. `6 870 000` reads cleaner than `6.870.000`
    // and matches Pictet / Julius Bär / Lombard Odier reporting style.
    // Non-breaking space ( ) prevents line breaks mid-amount.
    final totalFormatted =
        _eurFormat.format(total).replaceAll('.', ' ');
    // Breakdown by business model for the proportion bar in the hero.
    // Sums totalAmount per model, keeps fixed canonical ordering so the
    // stacked bar + legend stay consistent across renders even if the
    // portfolio entries come in any order from the view.
    final breakdown = _buildAllocationBreakdown(summaries, total);

    final collapsedHeight = topPadding + 80.0;
    // Editorial photo hero ~40% of a typical viewport. Title + amount
    // stack as a single block at the bottom over a strong warm scrim, so
    // legibility is guaranteed regardless of which region of the photo
    // the text overlaps. Smaller than 55% so the allocation table + brand
    // list breathe within the visible viewport.
    final expandedHeight = topPadding + 320.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Photo hero pushes the system status bar onto a dark zone — light
      // icons keep the chrome legible in the expanded state. When the
      // hero collapses, the photo fades to overlayWarm (#1F1916) so the
      // light icons still work.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
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

          // Allocation table — moved out of the hero (now beige page after
          // the photographic slab). Editorial wealth-report convention:
          // label left, % right, tabular figures, generous vertical aire.
          if (breakdown.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: _AllocationTable(slices: breakdown),
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

  static const _textShadow = Shadow(
    color: Color(0x66000000),
    blurRadius: 8,
    offset: Offset(0, 1),
  );

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final expandRatio =
        (1 - shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final amountSize = 24 + (24 * expandRatio);
    final euroSize = 13 + (9 * expandRatio);
    // Title fades faster than the amount so the chrome band reads clean
    // before the slab finishes collapsing.
    final titleOpacity = ((expandRatio - 0.4) / 0.4).clamp(0.0, 1.0);

    // Amount slides bottom-left (expanded, over the photo) to chrome-band
    // center (collapsed). Fixed-padding interpolation, no Align.bottomLeft
    // math that could overlap with the title above.
    final amountTopExpanded = expandedHeight - AppSpacing.lg - 56;
    final amountTopCollapsed = topPadding + 28;
    final amountTop = amountTopCollapsed +
        (amountTopExpanded - amountTopCollapsed) * expandRatio;
    // Title rides 16pt above the amount expanded — grouped editorial block
    // (title on top, cifra below) at the bottom of the photograph. The two
    // read as a single info package, not as separated extremes.
    final titleTop = amountTop - 80 - 16;

    return Container(
      // overlayWarm (#1F1916) revealed as the photo fades on collapse.
      // Warm dark, not the rejected pure-black hero from earlier iteration.
      color: AppColors.overlayWarm,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Editorial photograph: luxury material macro. Fades to overlayWarm
          // as the slab collapses so chrome stays legible without competing
          // with imagery.
          if (expandRatio > 0)
            Opacity(
              opacity: expandRatio,
              child: const LhotseImage(_heroImageUrl),
            ),
          // Warm gradient guarantees title + amount remain legible over any
          // region of the photo. Transparent at top (chrome reads on its own
          // with text shadow), dark at bottom (text zone).
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x331F1916),
                    Color(0xEE1F1916),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // Editorial cover opener. Sits just above the amount expanded;
          // fades out by ~40% collapse so the chrome band reads clean.
          Positioned(
            top: titleTop,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Opacity(
              opacity: titleOpacity,
              child: Text(
                'Mi estrategia\npatrimonial',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.w300,
                  height: 1.0,
                  shadows: const [_textShadow],
                ),
              ),
            ),
          ),
          // Patrimonio total — Campton Light XL. When expanded, the number
          // sits bottom-left inside a tall area with room for the hairline +
          // bar + legend below. When collapsed, the Positioned area shrinks
          // to match exactly the chrome band (topPadding+16 to +60) between
          // logo and bell, with horizontal padding that keeps the number
          // from overlapping either element.
          Positioned(
            // Fixed-padding approach instead of area+Align.bottomLeft math.
            // top expanded: 196 = chrome 16 + chrome band 44 + gap 24 +
            // title 2 lines 80 + gap 32 (fixed padding below the title).
            // top collapsed: 28 = chrome band center (16 + 44/2 - 24/2 = 28
            // approx, adjusted for Campton optical center).
            top: amountTop,
            // Symmetric horizontal interpolation so the collapsed area
            // spans the full viewport and Align.center finds true center.
            left: AppSpacing.lg * expandRatio,
            right: AppSpacing.lg * expandRatio,
            child: Align(
              // Horizontal: left (expanded editorial) → center (collapsed
              // chrome band). Vertical fixed — top-positioned, no alignment
              // math that could push the number into the title above.
              alignment: Alignment(-expandRatio, 0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: totalFormatted,
                      style: TextStyle(
                        fontFamily: 'Campton',
                        fontSize: amountSize,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textOnDark,
                        letterSpacing: -1.2,
                        height: 1.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        shadows: const [_textShadow],
                      ),
                    ),
                    TextSpan(
                      // Non-breaking space before € to keep unit attached
                      // to the figure when the line wraps, plus subordinate
                      // style (smaller + muted) so the number dominates.
                      text: ' €',
                      style: TextStyle(
                        fontFamily: 'Campton',
                        fontSize: euroSize,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textOnDark.withValues(alpha: 0.55),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Chrome: logo top-left, bell top-right. textOnDark (white) with
          // shadow on the logo, same pattern as Home feed (over imagery).
          Positioned(
            top: topPadding + 16,
            left: AppSpacing.lg,
            child: const SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: LhotseMark(
                  color: AppColors.textOnDark,
                  hasShadow: true,
                ),
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

/// Editorial asset-allocation table — one row per business model present
/// in the portfolio. Label on the left (accentMuted), percent on the right
/// (textPrimary, tabular figures). Pure tipografía, no bar/chips/chart:
/// the wealth report convention used by Pictet / Julius Bär / Lombard
/// Odier PDFs. Generous vertical spacing lets the table breathe as part
/// of the editorial hero.
class _AllocationTable extends StatelessWidget {
  const _AllocationTable({required this.slices});
  final List<_AllocationSlice> slices;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < slices.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                slices[i].label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.accentMuted,
                ),
              ),
              const Spacer(),
              Text(
                '${(slices[i].percent * 100).toStringAsFixed(0)}%',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
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
