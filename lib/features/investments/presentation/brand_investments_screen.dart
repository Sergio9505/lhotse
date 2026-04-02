import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/data/mock/mock_investments.dart';
import '../../../core/data/mock/mock_projects.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
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

    final topPadding = MediaQuery.of(context).padding.top;
    final totalFormatted = _eurFormat.format(summary.totalAmount);
    final isCompraDirecta = brand?.businessModel == BusinessModel.compraDirecta;
    final collapsedHeight = topPadding + 84.0;
    final expandedHeight = topPadding + 210.0;

    final sectionLabel = isCompraDirecta ? 'MIS ACTIVOS' : 'ACTIVAS';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero — collapses
          SliverPersistentHeader(
            pinned: true,
            delegate: _BrandHeroDelegate(
              expandedHeight: expandedHeight,
              collapsedHeight: collapsedHeight,
              topPadding: topPadding,
              brandName: brandName,
              totalFormatted: totalFormatted,
              averageReturn: summary.averageReturn,
              activeCount: summary.investments.length,
              completedCount: completed.length,
              isCompraDirecta: isCompraDirecta,
              onBack: () => context.pop(),
            ),
          ),

          // Section label — sticky
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyLabelDelegate(
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.only(
                    top: AppSpacing.md, left: AppSpacing.lg, bottom: AppSpacing.sm),
                alignment: Alignment.centerLeft,
                child: Text(
                  sectionLabel,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.accentMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
            ),
          ),

          // Investment rows
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final inv = summary.investments[i];
                final project = findProjectById(inv.projectId);
                if (isCompraDirecta) {
                  return _AssetRow(
                    projectName: inv.projectName,
                    location: project?.location,
                    imageUrl: project?.imageUrl,
                    amount: inv.amount,
                    isLast: i == summary.investments.length - 1,
                    onTap: () => context.push('/investments/detail/${inv.id}'),
                  );
                }
                return LhotseLedgerRow(
                  leading: _ProjectThumbnail(imageUrl: project?.imageUrl),
                  title: inv.projectName.toUpperCase(),
                  subtitle: showLocation ? project?.location.toUpperCase() : null,
                  amount: inv.amount,
                  returnLabel: '${inv.returnRate.toStringAsFixed(0)}% rent. estimada',
                  isLast: i == summary.investments.length - 1,
                  onTap: () => context.push('/investments/detail/${inv.id}'),
                );
              },
              childCount: summary.investments.length,
            ),
          ),

          // Completed section (not shown for compraDirecta)
          if (completed.isNotEmpty && !isCompraDirecta)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

// ---------------------------------------------------------------------------
// Project thumbnail — leading widget for investment rows
// ---------------------------------------------------------------------------

class _BrandHeroDelegate extends SliverPersistentHeaderDelegate {
  const _BrandHeroDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.topPadding,
    required this.brandName,
    required this.totalFormatted,
    required this.averageReturn,
    required this.activeCount,
    required this.completedCount,
    required this.isCompraDirecta,
    required this.onBack,
  });

  final double expandedHeight;
  final double collapsedHeight;
  final double topPadding;
  final String brandName;
  final String totalFormatted;
  final double averageReturn;
  final int activeCount;
  final int completedCount;
  final bool isCompraDirecta;
  final VoidCallback onBack;

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final expandRatio =
        (1 - shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return Container(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Header row (← logo) — always visible
          Positioned(
            top: topPadding + AppSpacing.md,
            left: AppSpacing.sm,
            right: AppSpacing.lg,
            child: Row(
              children: [
                LhotseBackButton.onSurface(onTap: onBack),
                const Spacer(),
                SvgPicture.asset(
                  'assets/images/lhotse_logo.svg',
                  width: 20,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),

          // Expanded: label + amount + metadata — fades out
          Positioned(
            top: topPadding + AppSpacing.md + 44 + AppSpacing.md, // below header row
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Opacity(
              opacity: expandRatio,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MI PATRIMONIO\nCON ${brandName.toUpperCase()}',
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: totalFormatted,
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
                  if (!isCompraDirecta) ...[
                    const SizedBox(height: AppSpacing.md),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${averageReturn.toStringAsFixed(0)}%',
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
                    Text(
                      '$activeCount activas${completedCount > 0 ? '  ·  $completedCount finalizadas' : ''}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Collapsed: centered amount + brand subtitle — fades in
          Positioned(
            top: topPadding + AppSpacing.md,
            left: 44 + AppSpacing.sm, // after back button
            right: 44 + AppSpacing.lg, // before logo
            child: Opacity(
              opacity: 1 - expandRatio,
              child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$totalFormatted€',
                              style: AppTypography.headingLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        brandName.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accentMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _BrandHeroDelegate oldDelegate) =>
      expandedHeight != oldDelegate.expandedHeight ||
      collapsedHeight != oldDelegate.collapsedHeight ||
      totalFormatted != oldDelegate.totalFormatted;
}

class _StickyLabelDelegate extends SliverPersistentHeaderDelegate {
  const _StickyLabelDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 40;

  @override
  double get maxExtent => 40;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyLabelDelegate oldDelegate) => false;
}

class _AssetRow extends StatefulWidget {
  const _AssetRow({
    required this.projectName,
    this.location,
    this.imageUrl,
    required this.amount,
    this.isLast = false,
    this.onTap,
  });

  final String projectName;
  final String? location;
  final String? imageUrl;
  final double amount;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  State<_AssetRow> createState() => _AssetRowState();
}

class _AssetRowState extends State<_AssetRow> {
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
            vertical: AppSpacing.md,
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
              // Thumbnail
              _ProjectThumbnail(imageUrl: widget.imageUrl),
              const SizedBox(width: 14),

              // Name + location + amount stacked
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.projectName.toUpperCase(),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (widget.location != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.location!.toUpperCase(),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accentMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _eurFormat.format(widget.amount),
                            style: AppTypography.headingMedium.copyWith(
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

class _ProjectThumbnail extends StatelessWidget {
  const _ProjectThumbnail({this.imageUrl, this.muted = false});

  final String? imageUrl;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: muted ? 0.5 : 1.0,
      child: SizedBox(
        width: 80,
        height: 60,
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
