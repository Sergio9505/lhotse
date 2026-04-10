import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/data/mock/mock_investments.dart';
import '../../../core/data/mock/mock_projects.dart';
import '../../../core/domain/project_data.dart';
import '../../../core/widgets/lhotse_notification_bell.dart';
import '../../../core/theme/app_theme.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');

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

    final totalFormatted = _eurFormat.format(total);
    final collapsedHeight = topPadding + 72.0;
    final expandedHeight = topPadding + 200.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero — collapses from full to compact
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeroDelegate(
              expandedHeight: expandedHeight,
              collapsedHeight: collapsedHeight,
              topPadding: topPadding,
              totalFormatted: totalFormatted,
            ),
          ),

          // "RENTABILIDAD" sticky header
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.7, 1.0],
                    colors: [AppColors.background, Color(0x00E5E2DC)],
                  ),
                ),
                padding: const EdgeInsets.only(
                    top: AppSpacing.md, right: AppSpacing.lg, bottom: AppSpacing.sm),
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 76,
                  child: Text(
                    'RENTABILIDAD',
                    textAlign: TextAlign.right,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.accentMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Brand rows
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final summary = summaries[i];
                return _BrandRow(
                  brandName: summary.brandName,
                  amount: summary.totalAmount,
                  averageReturn: summary.averageReturn,
                  isLast: i == summaries.length - 1,
                  onTap: () => context.push(
                      '/investments/brand/${Uri.encodeComponent(summary.brandName)}'),
                );
              },
              childCount: summaries.length,
            ),
          ),

          // Opportunities
          if (availableProjects.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
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

    // Amount font size: 50 expanded → 28 collapsed
    final amountSize = 28 + (22 * expandRatio);
    final euroSize = 20 + (14 * expandRatio);

    return Container(
      color: AppColors.primary,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Title — fades out first half, slides up
          Positioned(
            top: topPadding + AppSpacing.md - (shrinkOffset * 0.3),
            left: AppSpacing.lg,
            right: AppSpacing.lg + 44, // leave room for bell
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

          // Amount — anchored to bottom, always visible
          Positioned(
            bottom: AppSpacing.md,
            left: AppSpacing.lg,
            right: AppSpacing.lg + 44, // leave room for bell
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: totalFormatted,
                    style: TextStyle(
                      fontFamily: 'Campton',
                      fontSize: amountSize,
                      fontWeight: FontWeight.w700,
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

          // Bell — fixed top-right, independent of collapse
          Positioned(
            top: topPadding + 16,
            right: AppSpacing.lg,
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

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StickyHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 70;

  @override
  double get maxExtent => 70;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) => false;
}

class _BrandRow extends StatefulWidget {
  const _BrandRow({
    required this.brandName,
    required this.amount,
    required this.averageReturn,
    this.isLast = false,
    this.onTap,
  });

  final String brandName;
  final double amount;
  final double averageReturn;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  State<_BrandRow> createState() => _BrandRowState();
}

class _BrandRowState extends State<_BrandRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
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
              _BrandLeading(brandName: widget.brandName),
              const SizedBox(width: 14),

              // Left col: name (label) + amount (value)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.brandName.toUpperCase(),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _eurFormat.format(widget.amount),
                            style: AppTypography.headingSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          TextSpan(
                            text: '€',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Return %
              Text(
                '${widget.averageReturn.toStringAsFixed(0)}%',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),

              if (widget.onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  LucideIcons.chevronRight,
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

class _BrandLeading extends StatelessWidget {
  const _BrandLeading({required this.brandName});

  final String brandName;

  @override
  Widget build(BuildContext context) {
    final brand = mockBrands.where((b) => b.name == brandName).firstOrNull;

    if (brand?.logoAsset != null) {
      return SizedBox(
        width: 36,
        height: 36,
        child: SvgPicture.asset(
          brand!.logoAsset!,
          colorFilter: const ColorFilter.mode(
            AppColors.textPrimary,
            BlendMode.srcIn,
          ),
        ),
      );
    }

    final initials = brandName.split(' ').map((w) => w[0]).join();

    return Container(
      width: 36,
      height: 36,
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w700,
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

