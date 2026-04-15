import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/brands_provider.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../data/investments_provider.dart';
import '../domain/completed_contract_data.dart';
import '../domain/fixed_income_contract_data.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');

class BrandInvestmentsScreen extends ConsumerWidget {
  const BrandInvestmentsScreen({super.key, required this.brandId});

  final String brandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandAsync = ref.watch(brandByIdProvider(brandId));
    final purchaseAsync = ref.watch(brandPurchaseContractsProvider(brandId));
    final coinvestAsync = ref.watch(brandCoinvestmentContractsProvider(brandId));
    final rfAsync = ref.watch(brandFixedIncomeContractsProvider(brandId));

    final brand = brandAsync.valueOrNull;
    final allPurchase = purchaseAsync.valueOrNull ?? const [];
    final allCoinvest = coinvestAsync.valueOrNull ?? const [];
    final allRf = rfAsync.valueOrNull ?? const [];

    if (brand == null && brandAsync.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
      );
    }

    final businessModel = brand?.businessModel;
    final isCompraDirecta = businessModel == BusinessModel.directPurchase;
    final isRentaFija = businessModel == BusinessModel.fixedIncome;

    final activePurchase = allPurchase.where((c) => !c.isCompleted).toList();
    final completedPurchase = allPurchase.where((c) => c.isCompleted).toList();
    final activeCoinvest = allCoinvest.where((c) => !c.isCompleted).toList();
    final completedCoinvest = allCoinvest.where((c) => c.isCompleted).toList();
    final activeRf = allRf.where((c) => c.isActive).toList();
    final completedRf = allRf.where((c) => c.isCompleted).toList();

    final activeCount = isCompraDirecta
        ? activePurchase.length
        : isRentaFija
            ? activeRf.length
            : activeCoinvest.length;
    final completedCount = isCompraDirecta
        ? completedPurchase.length
        : isRentaFija
            ? completedRf.length
            : completedCoinvest.length;

    final totalAmount = isCompraDirecta
        ? allPurchase.fold(0.0, (s, c) => s + c.purchaseValue)
        : isRentaFija
            ? allRf.fold(0.0, (s, c) => s + c.amount)
            : allCoinvest.fold(0.0, (s, c) => s + c.amount);

    final avgReturn = isRentaFija
        ? (allRf.isEmpty ? 0.0 : allRf.map((c) => c.guaranteedRate).reduce((a, b) => a + b) / allRf.length)
        : isCompraDirecta
            ? (activePurchase.isEmpty ? 0.0 : activePurchase.map((c) => c.rentalYieldPct ?? 0).reduce((a, b) => a + b) / activePurchase.length)
            : (allCoinvest.isEmpty ? 0.0 : allCoinvest.map((c) => c.estimatedReturnPct ?? 0).reduce((a, b) => a + b) / allCoinvest.length);

    final brandName = brand?.name ?? '';
    final heroTitle = isRentaFija
        ? 'MIS INVERSIONES\nA RENTA FIJA'
        : 'MIS INVERSIONES\nEN ${brandName.toUpperCase()}';
    final sectionLabel = isCompraDirecta ? 'MIS ACTIVOS' : 'ACTIVAS';
    final topPadding = MediaQuery.of(context).padding.top;
    final totalFormatted = _eurFormat.format(totalAmount);
    final collapsedHeight = topPadding + 64.0;
    final expandedHeight = topPadding + 210.0;

    // Sort RF by soonest maturity
    if (isRentaFija) {
      activeRf.sort((a, b) =>
          (a.maturityDate ?? DateTime(2099))
              .compareTo(b.maturityDate ?? DateTime(2099)));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(brandByIdProvider);
          ref.invalidate(brandPurchaseContractsProvider);
          ref.invalidate(brandCoinvestmentContractsProvider);
          ref.invalidate(brandFixedIncomeContractsProvider);
          await Future.wait([
            ref.read(brandByIdProvider(brandId).future).catchError((_) {}),
            ref.read(brandPurchaseContractsProvider(brandId).future).catchError((_) {}),
            ref.read(brandCoinvestmentContractsProvider(brandId).future).catchError((_) {}),
            ref.read(brandFixedIncomeContractsProvider(brandId).future).catchError((_) {}),
          ]);
        },
        child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _BrandHeroDelegate(
              expandedHeight: expandedHeight,
              collapsedHeight: collapsedHeight,
              topPadding: topPadding,
              brandName: brandName,
              totalFormatted: totalFormatted,
              averageReturn: avgReturn,
              activeCount: activeCount,
              completedCount: completedCount,
              isCompraDirecta: isCompraDirecta,
              isRentaFija: isRentaFija,
              heroTitle: heroTitle,
              onBack: () => context.pop(),
            ),
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyLabelDelegate(
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                    left: AppSpacing.lg,
                    bottom: AppSpacing.sm),
                alignment: Alignment.centerLeft,
                child: Text(
                  sectionLabel,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.accentMuted,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
            ),
          ),

          // Active investment rows
          if (isRentaFija)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _RentaFijaRow(
                  contract: activeRf[i],
                  index: i + 1,
                  isLast: i == activeRf.length - 1,
                ),
                childCount: activeRf.length,
              ),
            )
          else if (isCompraDirecta)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final c = activePurchase[i];
                  return _AssetRow(
                    projectName: c.assetUnitName ?? c.projectName ?? '',
                    location: c.projectLocation,
                    imageUrl: c.projectImageUrl,
                    amount: c.purchaseValue,
                    isLast: i == activePurchase.length - 1,
                    onTap: () => context.push(
                      '/investments/detail/purchase/${c.id}',
                      extra: c,
                    ),
                  );
                },
                childCount: activePurchase.length,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final c = activeCoinvest[i];
                  final months = c.estimatedDurationMonths ?? 0;
                  final pct = c.estimatedReturnPct?.toStringAsFixed(0) ?? '–';
                  return _AssetRow(
                    projectName: c.projectName,
                    imageUrl: c.projectImageUrl,
                    amount: c.amount,
                    returnLabel: '$months MESES  ·  $pct%*',
                    isLast: i == activeCoinvest.length - 1,
                    onTap: () => context.push(
                      '/investments/detail/coinvestment/${c.id}',
                      extra: c,
                    ),
                  );
                },
                childCount: activeCoinvest.length,
              ),
            ),

          // Footnote
          if (!isCompraDirecta && !isRentaFija)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: AppSpacing.lg, top: AppSpacing.md),
                child: Text(
                  '* Rentabilidad y duración estimadas',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          // Completed section
          if (!isCompraDirecta)
            SliverToBoxAdapter(
              child: Builder(builder: (context) {
                final completed =
                    isRentaFija ? completedRf : completedCoinvest;
                if (completed.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      child: Text(
                        'FINALIZADAS',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.accentMuted,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (isRentaFija)
                      ...completedRf.indexed.map((e) => _RentaFijaRow(
                            contract: e.$2,
                            isCompleted: true,
                            isLast: e.$1 == completedRf.length - 1,
                          ))
                    else
                      ...completedCoinvest.indexed.map((e) {
                        final c = e.$2;
                        final hasResults = c.actualRoi != null;
                        final duration = c.actualDuration ??
                            c.estimatedDurationMonths ??
                            0;
                        final returnLabelSpans = hasResults
                            ? [
                                TextSpan(
                                    text:
                                        '${_eurFormat.format(c.amount)}€  ·  $duration MESES  ·  '),
                                TextSpan(
                                  text:
                                      '+${c.actualRoi!.toStringAsFixed(1)}%',
                                  style: AppTypography.caption.copyWith(
                                    color: const Color(0xFF2D6A4F),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ]
                            : null;
                        return _AssetRow(
                          projectName: c.projectName,
                          imageUrl: c.projectImageUrl,
                          amount: c.totalReturn ?? c.amount,
                          returnLabel: hasResults ? null : '–',
                          returnLabelSpans: returnLabelSpans,
                          isLast: e.$1 == completedCoinvest.length - 1,
                          onTap: () => context.push(
                            '/investments/detail/completed/coinvestment/${c.id}',
                            extra: CompletedContractData.fromCoinvestment(c),
                          ),
                        );
                      }),
                  ],
                );
              }),
            ),

          SliverFillRemaining(
            hasScrollBody: false,
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Hero delegate ─────────────────────────────────────────────────────────────

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
    required this.isRentaFija,
    required this.heroTitle,
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
  final bool isRentaFija;
  final String heroTitle;
  final VoidCallback onBack;

  @override
  double get maxExtent => expandedHeight;
  @override
  double get minExtent => collapsedHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final collapseRange = maxExtent - minExtent;
    final position = Scrollable.maybeOf(context)?.position;
    final maxScroll = position != null && position.hasContentDimensions
        ? position.maxScrollExtent
        : null;
    final effectiveRange =
        (maxScroll != null && maxScroll > 0 && maxScroll < collapseRange)
            ? maxScroll
            : collapseRange;
    final expandRatio =
        (1 - shrinkOffset / effectiveRange).clamp(0.0, 1.0);

    final expandedOpacity = ((expandRatio - 0.5) / 0.5).clamp(0.0, 1.0);
    final collapsedOpacity = ((0.5 - expandRatio) / 0.5).clamp(0.0, 1.0);
    final amountSize = 24.0 + (18.0 * expandRatio);
    final euroSize = 16.0 + (12.0 * expandRatio);

    const expandedAmountY = 150.0;
    const collapsedAmountY = 16.0;
    final amountTop = topPadding +
        collapsedAmountY +
        ((expandedAmountY - collapsedAmountY) * expandRatio);
    final amountLeft = AppSpacing.lg +
        ((44 + AppSpacing.sm - AppSpacing.lg) * (1 - expandRatio));
    final amountRight = AppSpacing.lg + (44.0 * (1 - expandRatio));

    return Container(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: topPadding + AppSpacing.md,
            left: AppSpacing.sm,
            right: AppSpacing.lg,
            child: Row(
              children: [
                LhotseBackButton.onSurface(onTap: onBack),
                const Spacer(),
                const SizedBox(width: 44),
              ],
            ),
          ),
          Positioned(
            top: topPadding +
                AppSpacing.md +
                44 +
                AppSpacing.md -
                (shrinkOffset * 0.3),
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: IgnorePointer(
              child: Opacity(
                opacity: expandedOpacity,
                child: Text(
                  heroTitle,
                  style: AppTypography.headingLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: amountTop,
            left: amountLeft,
            right: amountRight,
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
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.0,
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
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: amountTop + amountSize + 2,
            left: amountLeft,
            right: amountRight,
            child: Opacity(
              opacity: collapsedOpacity,
              child: Text(
                brandName.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.accentMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          if (!isCompraDirecta && !isRentaFija)
            Positioned(
              top: topPadding + expandedAmountY + 42 + AppSpacing.md,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Opacity(
                opacity: expandedOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${averageReturn.toStringAsFixed(0)}%',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
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
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.accentMuted),
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
      totalFormatted != oldDelegate.totalFormatted;
}

class _StickyLabelDelegate extends SliverPersistentHeaderDelegate {
  const _StickyLabelDelegate({required this.child});
  final Widget child;

  @override
  double get minExtent => 74;
  @override
  double get maxExtent => 74;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(covariant _StickyLabelDelegate oldDelegate) => false;
}

// ── Asset row ─────────────────────────────────────────────────────────────────

class _AssetRow extends StatefulWidget {
  const _AssetRow({
    required this.projectName,
    this.location,
    this.imageUrl,
    required this.amount,
    this.isLast = false,
    this.onTap,
    this.returnLabel,
    this.returnLabelSpans,
  });

  final String projectName;
  final String? location;
  final String? imageUrl;
  final double amount;
  final bool isLast;
  final VoidCallback? onTap;
  final String? returnLabel;
  final List<TextSpan>? returnLabelSpans;

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
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
              SizedBox(
                width: 80,
                height: 60,
                child: widget.imageUrl != null
                    ? LhotseImage(widget.imageUrl!)
                    : Container(color: AppColors.surface),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.projectName.isNotEmpty)
                      Text(
                        widget.projectName.toUpperCase(),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    if (widget.location != null) ...[
                      if (widget.projectName.isNotEmpty)
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
                        ],
                      ),
                    ),
                    if (widget.returnLabelSpans != null) ...[
                      const SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accentMuted,
                            letterSpacing: 1.2,
                          ),
                          children: widget.returnLabelSpans,
                        ),
                      ),
                    ] else if (widget.returnLabel != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.returnLabel!.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accentMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.onTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: PhosphorIcon(
                    PhosphorIconsThin.caretRight,
                    size: 16,
                    color: AppColors.accentMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Renta Fija row ────────────────────────────────────────────────────────────

class _RentaFijaRow extends StatelessWidget {
  const _RentaFijaRow({
    required this.contract,
    this.index,
    this.isCompleted = false,
    this.isLast = false,
  });

  final FixedIncomeContractData contract;
  final int? index;
  final bool isCompleted;
  final bool isLast;

  static const _kMonths = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
  ];

  @override
  Widget build(BuildContext context) {
    final c = contract;
    final amount = isCompleted ? (c.amount) : c.amount;
    final badgeDate = c.startDate;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: 20),
      decoration: isLast
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
          Container(
            width: 42,
            height: 42,
            color: AppColors.primary,
            alignment: Alignment.center,
            child: badgeDate != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _kMonths[badgeDate.month - 1],
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${badgeDate.year % 100}',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                        ),
                      ),
                    ],
                  )
                : Text(
                    '${index ?? 0}',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _eurFormat.format(amount),
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      TextSpan(
                        text: '€',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                if (isCompleted)
                  RichText(
                    text: TextSpan(
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 1.2,
                      ),
                      children: [
                        TextSpan(
                            text:
                                '${_eurFormat.format(c.amount)}€  ·  ${c.termMonths ?? '–'} MESES'),
                      ],
                    ),
                  )
                else
                  Text(
                    '${c.termMonths ?? '–'} MESES  ·  ${c.guaranteedRate.toStringAsFixed(0)}%',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.accentMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
