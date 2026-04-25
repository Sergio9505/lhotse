import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/data/document_categories_provider.dart';
import '../../../core/data/documents_provider.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_back_button.dart';
import '../../../core/widgets/lhotse_bottom_sheet.dart';
import '../../../core/widgets/lhotse_doc_row.dart';
import '../../../core/widgets/lhotse_documents_section.dart';
import '../../../core/widgets/lhotse_filter_chip.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../data/investments_provider.dart';
import '../domain/coinvestment_contract_data.dart';
import '../domain/completed_contract_data.dart';
import '../domain/fixed_income_contract_data.dart';
import '../domain/portfolio_entry.dart';
import '../domain/purchase_contract_data.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');

class BrandInvestmentsScreen extends ConsumerWidget {
  const BrandInvestmentsScreen({
    super.key,
    required this.brandId,
    this.heroContext,
  });

  final String brandId;

  /// Minimum context passed via router extra from the Strategy ledger.
  /// Avoids fetching `brands` when we already know name + business model.
  /// Null only on deep-link entries (push notifications, etc.).
  final ({String brandName, String businessModel})? heroContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Common path: heroContext is passed via router extra from Strategy.
    // Deep-link fallback: resolve from user_portfolio — the L2 is
    // semantically "my investments in brand X", so if the user has no entry
    // for this brand, the screen has nothing to show.
    final fallbackAsync = heroContext == null
        ? ref.watch(userPortfolioEntryProvider(brandId))
        : const AsyncValue<PortfolioEntry?>.data(null);
    final fallbackEntry = fallbackAsync.valueOrNull;

    final brandName = heroContext?.brandName ?? fallbackEntry?.brandName ?? '';
    final businessModelString =
        heroContext?.businessModel ?? fallbackEntry?.businessModel;
    final businessModel = businessModelString != null
        ? BusinessModelLabel.fromString(businessModelString)
        : null;

    if (businessModel == null) {
      // Deep-link still resolving, or user has no investments in this brand.
      if (heroContext == null && fallbackAsync.hasValue && fallbackEntry == null) {
        return _EmptyState(brandId: brandId);
      }
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
      );
    }

    // Only fetch the contract view for this brand's business model.
    final allPurchase = businessModel == BusinessModel.directPurchase
        ? (ref.watch(brandPurchaseContractsProvider(brandId)).valueOrNull ??
            const <PurchaseContractData>[])
        : const <PurchaseContractData>[];
    final allCoinvest = businessModel == BusinessModel.coinvestment
        ? (ref.watch(brandCoinvestmentContractsProvider(brandId)).valueOrNull ??
            const <CoinvestmentContractData>[])
        : const <CoinvestmentContractData>[];
    final allRf = businessModel == BusinessModel.fixedIncome
        ? (ref.watch(brandFixedIncomeContractsProvider(brandId)).valueOrNull ??
            const <FixedIncomeContractData>[])
        : const <FixedIncomeContractData>[];

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

    // Total = active capital (matches L1 user_portfolio aggregation).
    final totalAmount = isCompraDirecta
        ? activePurchase.fold(0.0, (s, c) => s + c.purchaseValue)
        : isRentaFija
            ? activeRf.fold(0.0, (s, c) => s + c.amount)
            : activeCoinvest.fold(0.0, (s, c) => s + c.amount);

    final avgReturn = isRentaFija
        ? (activeRf.isEmpty ? 0.0 : activeRf.map((c) => c.guaranteedRate).reduce((a, b) => a + b) / activeRf.length)
        : isCompraDirecta
            ? (activePurchase.isEmpty ? 0.0 : activePurchase.map((c) => c.rentalYieldPct ?? 0).reduce((a, b) => a + b) / activePurchase.length)
            : (activeCoinvest.isEmpty ? 0.0 : activeCoinvest.map((c) => c.estimatedReturnPct ?? 0).reduce((a, b) => a + b) / activeCoinvest.length);

    final heroTitle = isRentaFija
        ? 'Mis inversiones\na Renta Fija'
        : 'Mis inversiones\nen $brandName';
    final sectionLabel = isCompraDirecta ? 'MIS ACTIVOS' : 'ACTIVAS';
    final topPadding = MediaQuery.of(context).padding.top;
    final totalFormatted = _eurFormat.format(totalAmount);
    final collapsedHeight = topPadding + 64.0;
    final expandedHeight = topPadding + 230.0;

    // Sort RF by soonest maturity
    if (isRentaFija) {
      activeRf.sort((a, b) =>
          (a.maturityDate ?? DateTime(2099))
              .compareTo(b.maturityDate ?? DateTime(2099)));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 40,
                  left: AppSpacing.lg,
                  bottom: AppSpacing.md),
              child: Text(
                sectionLabel,
                style: AppTypography.labelUppercaseMd.copyWith(
                  color: AppColors.accentMuted,
                  letterSpacing: 1.8,
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
                    projectName: c.assetName ?? '',
                    location: c.assetLocation,
                    imageUrl: c.assetImageUrl,
                    amount: c.purchaseValue,
                    isLast: i == activePurchase.length - 1,
                    onTap: () => context.push(
                      '/investments/detail/purchase/${c.id}',
                      extra: (brandName: brandName, contract: c),
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
                  final pct = c.estimatedReturnPct?.toStringAsFixed(1) ?? '–';
                  return _AssetRow(
                    projectName: c.projectName,
                    imageUrl: c.projectImageUrl,
                    amount: c.amount,
                    returnLabel: '$months MESES  ·  $pct%*',
                    isLast: i == activeCoinvest.length - 1,
                    onTap: () => context.push(
                      '/investments/detail/coinvestment/${c.id}',
                      extra: (contract: c, brandName: brandName),
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
                  style: AppTypography.annotation.copyWith(
                    color: AppColors.accentMuted,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          // Completed section (all business models)
          SliverToBoxAdapter(
            child: Builder(builder: (context) {
              final completed = isCompraDirecta
                  ? completedPurchase
                  : isRentaFija
                      ? completedRf
                      : completedCoinvest;
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
                      style: AppTypography.labelUppercaseMd.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isCompraDirecta)
                    ...completedPurchase.indexed.map((e) {
                      final c = e.$2;
                      final hasResults = c.actualRoi != null;
                      final duration = c.actualDuration ?? 0;
                      final returnLabelSpans = hasResults
                          ? [
                              TextSpan(
                                text:
                                    '${_eurFormat.format(c.purchaseValue)}€  ·  $duration MESES  ·  ',
                              ),
                              TextSpan(
                                text:
                                    '+${c.actualRoi!.toStringAsFixed(1)}%',
                                style: AppTypography.labelUppercaseSm.copyWith(
                                  color: const Color(0xFF2D6A4F),
                                  fontSize: 12,
                                ),
                              ),
                            ]
                          : null;
                      return _AssetRow(
                        projectName: c.assetName ?? '',
                        location: c.assetLocation,
                        imageUrl: c.assetImageUrl,
                        amount: c.totalReturn ?? c.purchaseValue,
                        returnLabel: hasResults ? null : '–',
                        returnLabelSpans: returnLabelSpans,
                        isLast: e.$1 == completedPurchase.length - 1,
                        onTap: () => context.push(
                          '/investments/detail/completed/purchase/${c.id}',
                          extra: CompletedContractData.fromPurchase(
                            c,
                            brandName: brandName,
                          ),
                        ),
                      );
                    })
                  else if (isRentaFija)
                    ...completedRf.indexed.map((e) => _RentaFijaRow(
                          contract: e.$2,
                          isCompleted: true,
                          isLast: e.$1 == completedRf.length - 1,
                        ))
                  else
                    ...completedCoinvest.indexed.map((e) {
                      final c = e.$2;
                      final hasResults = c.actualRoi != null;
                      final greenStyle = AppTypography.labelUppercaseSm.copyWith(
                        color: const Color(0xFF2D6A4F),
                        fontSize: 12,
                      );
                      final returnLabelSpans = hasResults
                          ? [
                              TextSpan(
                                  text:
                                      '${_eurFormat.format(c.amount)}€  ·  '),
                              TextSpan(
                                text:
                                    '+${c.actualRoi!.toStringAsFixed(1)}%',
                                style: greenStyle,
                              ),
                              const TextSpan(text: '  ·  '),
                              TextSpan(
                                text:
                                    '+${c.actualTir?.toStringAsFixed(1) ?? '–'}%',
                                style: greenStyle,
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
                          extra: CompletedContractData.fromCoinvestment(
                            c,
                            brandName: brandName,
                          ),
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

    const expandedAmountY = 170.0;
    const collapsedAmountY = 20.0;
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
                  style: AppTypography.editorialTitle.copyWith(
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
                        fontFamily: AppTypography.fontFamily,
                        fontSize: amountSize,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.0,
                        height: 1.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    TextSpan(
                      text: '€',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
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
                style: AppTypography.labelUppercaseSm.copyWith(
                  color: AppColors.accentMuted,
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
                            text: '${averageReturn.toStringAsFixed(1)}%',
                            style: AppTypography.figureAmount.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(
                            text: '  rentabilidad',
                            style: AppTypography.annotation.copyWith(
                              color: AppColors.accentMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$activeCount activas${completedCount > 0 ? '  ·  $completedCount finalizadas' : ''}',
                      style: AppTypography.annotation
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
              horizontal: AppSpacing.lg, vertical: 24),
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
                width: 110,
                height: 88,
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
                        widget.projectName,
                        style: AppTypography.bodyEmphasis.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (widget.location != null) ...[
                      if (widget.projectName.isNotEmpty)
                        const SizedBox(height: 2),
                      Text(
                        widget.location!.toUpperCase(),
                        style: AppTypography.labelUppercaseSm.copyWith(
                          color: AppColors.accentMuted,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _eurFormat.format(widget.amount),
                            style: AppTypography.figureAmount.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: '€',
                            style: AppTypography.annotation.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.returnLabelSpans != null) ...[
                      const SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.labelUppercaseSm.copyWith(
                            color: AppColors.accentMuted,
                            fontSize: 12,
                          ),
                          children: widget.returnLabelSpans,
                        ),
                      ),
                    ] else if (widget.returnLabel != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.returnLabel!.toUpperCase(),
                        style: AppTypography.labelUppercaseSm.copyWith(
                          color: AppColors.accentMuted,
                          fontSize: 12,
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

  static const _kMaturityMonthFormat = 'MM/yy';

  /// Maps DB payment_frequency values to user-facing uppercase labels.
  /// Falls back to MENSUAL defensively (matches model default).
  static const _kFrequencyLabels = {
    'monthly': 'MENSUAL',
    'quarterly': 'TRIMESTRAL',
    'semi_annual': 'SEMESTRAL',
    'annual': 'ANUAL',
  };

  @override
  Widget build(BuildContext context) {
    final c = contract;
    // Unlike purchase/coinvestment (single payout at close), RF interest is
    // paid periodically. The "big" figure is always the invested capital;
    // accumulated interest lives in the subtitle.
    final mainAmount = c.amount;
    final badgeDate = c.startDate;
    final hasDocs = c.hasDocuments;
    final greenStyle = AppTypography.labelUppercaseSm.copyWith(
      color: const Color(0xFF2D6A4F),
      fontSize: 12,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: 24),
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
            width: 56,
            height: 56,
            color: AppColors.primary,
            alignment: Alignment.center,
            child: badgeDate != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _kMonths[badgeDate.month - 1],
                        style: AppTypography.labelUppercaseSm.copyWith(
                          color: AppColors.textOnDark,
                          fontSize: 12,
                          letterSpacing: 0.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${badgeDate.year % 100}',
                        style: AppTypography.figureAmount.copyWith(
                          color: AppColors.textOnDark,
                          fontSize: 18,
                          height: 1.0,
                        ),
                      ),
                    ],
                  )
                : Text(
                    '${index ?? 0}',
                    style: AppTypography.figureAmount.copyWith(
                      color: AppColors.textOnDark,
                      fontSize: 22,
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
                        text: _eurFormat.format(mainAmount),
                        style: AppTypography.figureAmount.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: '€',
                        style: AppTypography.annotation.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                if (isCompleted)
                  RichText(
                    text: TextSpan(
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: AppColors.accentMuted,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                            text:
                                'duración ${c.termMonths ?? '–'}m  ·  '),
                        TextSpan(
                          text: '+${_eurFormat.format(c.totalInterestEarned)}€',
                          style: greenStyle,
                        ),
                      ],
                    ),
                  )
                else ...[
                  // L2 — términos contractuales: rate + vencimiento
                  RichText(
                    text: TextSpan(
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: AppColors.accentMuted,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text:
                              '${c.guaranteedRate.toStringAsFixed(1)}% ANUAL',
                        ),
                        if (c.maturityDate != null) ...[
                          const TextSpan(text: '  ·  '),
                          TextSpan(
                            text:
                                'VENCE ${DateFormat(_kMaturityMonthFormat).format(c.maturityDate!)}',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // L3 — flujo de pagos: frecuencia + intereses cobrados
                  RichText(
                    text: TextSpan(
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: AppColors.accentMuted,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text:
                              'PAGO ${_kFrequencyLabels[c.paymentFrequency] ?? 'MENSUAL'}',
                        ),
                        if (c.interestPaidToDate > 0) ...[
                          const TextSpan(text: '  ·  '),
                          TextSpan(
                            text:
                                '+${_eurFormat.format(c.interestPaidToDate)}€',
                            style: greenStyle,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasDocs)
            GestureDetector(
              onTap: () => _showRentaFijaDocs(context, c.id),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: PhosphorIcon(
                  PhosphorIconsThin.fileText,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showRentaFijaDocs(BuildContext context, String contractId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) => _RentaFijaDocsSheet(contractId: contractId),
  );
}

class _RentaFijaDocsSheet extends ConsumerStatefulWidget {
  const _RentaFijaDocsSheet({required this.contractId});

  final String contractId;

  @override
  ConsumerState<_RentaFijaDocsSheet> createState() =>
      _RentaFijaDocsSheetState();
}

class _RentaFijaDocsSheetState extends ConsumerState<_RentaFijaDocsSheet> {
  final Set<String> _activeFilters = {};

  void _toggleFilter(String id) {
    setState(() {
      if (_activeFilters.contains(id)) {
        _activeFilters.remove(id);
      } else {
        _activeFilters.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rawDocs = ref
            .watch(documentsProvider(
                (type: 'fixed_income', id: widget.contractId)))
            .valueOrNull ??
        const [];
    final allCategories =
        ref.watch(allDocumentCategoriesProvider).valueOrNull ?? const [];
    final iconMap = {for (final c in allCategories) c.id: c.iconName};
    final filterCategories =
        categoriesForIds(rawDocs.map((d) => d.categoryId), allCategories);
    final docs = _activeFilters.isEmpty
        ? rawDocs
        : rawDocs.where((d) => _activeFilters.contains(d.categoryId)).toList();

    return LhotseBottomSheetBody(
      title: 'DOCUMENTOS',
      header: filterCategories.isEmpty
          ? null
          : SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  children: [
                    ...filterCategories.map((cat) => Padding(
                          padding:
                              const EdgeInsets.only(right: AppSpacing.sm),
                          child: LhotseFilterChip(
                            label: cat.label,
                            isActive: _activeFilters.contains(cat.id),
                            onTap: () => _toggleFilter(cat.id),
                          ),
                        )),
                    if (_activeFilters.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _activeFilters.clear()),
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: PhosphorIcon(PhosphorIconsThin.x,
                              size: 14, color: AppColors.accentMuted),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      bodyBuilder: (bottomPadding) => ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, bottomPadding + AppSpacing.md),
        itemCount: docs.length,
        separatorBuilder: (_, _) => Container(
          height: 0.5,
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
        itemBuilder: (context, i) {
          final doc = docs[i];
          final ui = doc.toLhotseDocument(
            iconName: iconMap[doc.categoryId] ?? 'fileText',
          );
          return LhotseDocRow(
            name: ui.name,
            date: ui.date,
            icon: docCategoryIconByKey(ui.iconName),
          );
        },
      ),
    );
  }
}

/// Shown when a deep-link lands on a brand the user has no investments in.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.brandId});

  final String brandId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [LhotseBackButton.onSurface()],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SIN INVERSIONES',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelUppercaseSm.copyWith(
                        color: AppColors.accentMuted,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Todavía no tienes inversiones en esta firma.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyReading.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GestureDetector(
                      onTap: () => context.push('/brand/$brandId'),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.textPrimary,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'VER LA FIRMA',
                          style: AppTypography.labelUppercaseMd.copyWith(
                            color: AppColors.textPrimary,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
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
