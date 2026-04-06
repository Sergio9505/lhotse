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
import '../../../core/widgets/lhotse_documents_section.dart';

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
    final isRentaFija = brand?.businessModel == BusinessModel.rentaFija;
    final collapsedHeight = topPadding + 64.0;
    final expandedHeight = topPadding + 210.0;

    final sectionLabel = isCompraDirecta
        ? 'MIS ACTIVOS'
        : isRentaFija
            ? 'MIS OPERACIONES'
            : 'ACTIVAS';

    final heroTitle = isRentaFija
        ? 'MIS INVERSIONES\nA RENTA FIJA'
        : 'MIS INVERSIONES\nEN ${brandName.toUpperCase()}';

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
              isRentaFija: isRentaFija,
              heroTitle: heroTitle,
              onBack: () => context.pop(),
            ),
          ),

          // Section label — sticky
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyLabelDelegate(
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
                final allInvestments = summary.investments;
                final inv = allInvestments[i];
                final project = findProjectById(inv.projectId);
                if (isCompraDirecta || isRentaFija) {
                  String? subtitle;
                  if (isRentaFija) {
                    final startStr = inv.startDate != null
                        ? '${inv.startDate!.day.toString().padLeft(2, '0')}/${inv.startDate!.month.toString().padLeft(2, '0')}/${inv.startDate!.year}'
                        : '—';
                    subtitle = '$startStr  ·  ${inv.durationMonths} meses';
                  }
                  final docs = isRentaFija
                      ? _rfDocsByInvestment[inv.id]
                      : null;
                  return _AssetRow(
                    projectName: isRentaFija ? '' : inv.projectName,
                    location: isRentaFija ? subtitle : (showLocation ? project?.location : null),
                    imageUrl: project?.imageUrl,
                    amount: inv.amount,
                    showThumbnail: !isRentaFija,
                    index: isRentaFija ? i + 1 : null,
                    isLast: i == allInvestments.length - 1,
                    onTap: isRentaFija
                        ? null
                        : () => context.push('/investments/detail/${inv.id}'),
                    onDocsTap: docs != null && docs.isNotEmpty
                        ? () => _showOperationDocs(context, docs)
                        : null,
                  );
                }
                return _AssetRow(
                  projectName: inv.projectName,
                  imageUrl: project?.imageUrl,
                  amount: inv.amount,
                  returnLabel: '${inv.returnRate.toStringAsFixed(0)}% rentabilidad estimada',
                  isLast: i == allInvestments.length - 1,
                  onTap: () => context.push('/investments/detail/${inv.id}'),
                );
              },
              childCount: summary.investments.length,
            ),
          ),

          // Completed section (not shown for compraDirecta)
          if (completed.isNotEmpty && !isCompraDirecta && !isRentaFija)
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
                    return Opacity(
                      opacity: 0.5,
                      child: _AssetRow(
                        projectName: inv.projectName,
                        imageUrl: project?.imageUrl,
                        amount: inv.amount,
                        returnLabel: '${inv.returnRate.toStringAsFixed(0)}% rentabilidad',
                        isLast: entry.$1 == completed.length - 1,
                        onTap: () => context.push('/investments/detail/${inv.id}'),
                      ),
                    );
                  }),
                ],
              ),
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

// ---------------------------------------------------------------------------
// Bottom sheet — operation documents
// ---------------------------------------------------------------------------

void _showOperationDocs(
  BuildContext context,
  List<LhotseDocument> docs,
) {
  showDocsBottomSheet(
    context: context,
    documents: docs,
    filterLabels: const {
      DocCategory.contrato: 'Contrato',
      DocCategory.certificado: 'Certificado',
      DocCategory.informe: 'Informe',
      DocCategory.fiscal: 'Fiscal',
    },
  );
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

    // Sequential fade — no overlap
    final expandedOpacity = ((expandRatio - 0.5) / 0.5).clamp(0.0, 1.0);
    final collapsedOpacity = ((0.5 - expandRatio) / 0.5).clamp(0.0, 1.0);

    // Amount size interpolation (42→24 / 28→16)
    final amountSize = 24.0 + (18.0 * expandRatio);
    final euroSize = 16.0 + (12.0 * expandRatio);

    // Amount vertical position: expanded (below title) → collapsed (top bar)
    const expandedAmountY = 150.0; // md(16) + backBtn(44) + md(16) + title(~58) + md(16)
    const collapsedAmountY = 16.0; // md(16), aligned with back button
    final amountTop =
        topPadding + collapsedAmountY + ((expandedAmountY - collapsedAmountY) * expandRatio);

    // Amount horizontal: full-width → centered between back button and logo
    final amountLeft =
        AppSpacing.lg + ((44 + AppSpacing.sm - AppSpacing.lg) * (1 - expandRatio));
    final amountRight =
        AppSpacing.lg + (44.0 * (1 - expandRatio));

    return Container(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          // Back button + logo — always visible
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

          // Title — fades out first half, slides up
          Positioned(
            top: topPadding + AppSpacing.md + 44 + AppSpacing.md -
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

          // Amount — always visible, interpolates position + size
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
                        fontWeight: FontWeight.w700,
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

          // Brand subtitle — fades in second half (below amount)
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

          // "8% anual" — fades with title (rentaFija only)
          if (isRentaFija)
            Positioned(
              top: topPadding + expandedAmountY + 12,
              right: AppSpacing.lg,
              child: Opacity(
                opacity: expandedOpacity,
                child: Text(
                  '8% anual',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.accentMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Metadata — fades with title (coinversión only)
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
  double get minExtent => 74;

  @override
  double get maxExtent => 74;

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
    this.showThumbnail = true,
    this.index,
    this.isLast = false,
    this.onTap,
    this.onDocsTap,
    this.returnLabel,
  });

  final String projectName;
  final String? location;
  final String? imageUrl;
  final double amount;
  final bool showThumbnail;
  final int? index;
  final bool isLast;
  final VoidCallback? onTap;
  final VoidCallback? onDocsTap;
  final String? returnLabel;

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
              // Leading: thumbnail or index badge
              if (widget.showThumbnail) ...[
                _ProjectThumbnail(imageUrl: widget.imageUrl),
                const SizedBox(width: 14),
              ] else if (widget.index != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  color: AppColors.primary,
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.index}',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],

              // Content stacked
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.projectName.isNotEmpty) ...[
                      Text(
                        widget.projectName.toUpperCase(),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
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
                    if (widget.projectName.isNotEmpty || widget.location != null)
                      const SizedBox(height: 4),
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
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.returnLabel != null) ...[
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

              if (widget.onDocsTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: widget.onDocsTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      LucideIcons.fileText,
                      size: 16,
                      color: AppColors.accentMuted,
                    ),
                  ),
                ),
              ],

              if (widget.onTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Icon(
                    LucideIcons.chevronRight,
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

// ---------------------------------------------------------------------------
// Renta Fija documents
// ---------------------------------------------------------------------------

final _rfDocsByInvestment = <String, List<LhotseDocument>>{
  'inv-7': [
    LhotseDocument(name: 'Contrato de inversión', date: '15 MAR. 2026', category: DocCategory.contrato),
    LhotseDocument(name: 'Certificado de depósito', date: '15 MAR. 2026', category: DocCategory.certificado),
    LhotseDocument(name: 'Condiciones generales', date: '01 MAR. 2026', category: DocCategory.contrato),
  ],
  'inv-8': [
    LhotseDocument(name: 'Contrato de inversión', date: '15 JUN. 2026', category: DocCategory.contrato),
    LhotseDocument(name: 'Certificado de depósito', date: '15 JUN. 2026', category: DocCategory.certificado),
  ],
  'inv-8b': [
    LhotseDocument(name: 'Contrato de inversión', date: '01 ENE. 2026', category: DocCategory.contrato),
    LhotseDocument(name: 'Certificado fiscal', date: '02 ENE. 2026', category: DocCategory.fiscal),
    LhotseDocument(name: 'Informe trimestral Q1', date: '01 ABR. 2026', category: DocCategory.informe),
  ],
  'inv-8c': [
    LhotseDocument(name: 'Contrato de inversión', date: '01 SEP. 2025', category: DocCategory.contrato),
    LhotseDocument(name: 'Certificado fiscal', date: '02 ENE. 2026', category: DocCategory.fiscal),
  ],
  'inv-8d': [
    LhotseDocument(name: 'Contrato de inversión', date: '01 MAR. 2025', category: DocCategory.contrato),
    LhotseDocument(name: 'Certificado de depósito', date: '01 MAR. 2025', category: DocCategory.certificado),
    LhotseDocument(name: 'Informe trimestral Q1', date: '01 ABR. 2026', category: DocCategory.informe),
    LhotseDocument(name: 'Certificado fiscal', date: '02 ENE. 2026', category: DocCategory.fiscal),
  ],
};

class _ProjectThumbnail extends StatelessWidget {
  const _ProjectThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }
}

