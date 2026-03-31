import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/data/mock/mock_investments.dart';
import '../../../core/data/mock/mock_projects.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/domain/investment_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_app_header.dart';
import '../../../core/widgets/lhotse_bottom_sheet.dart';
import '../../../core/widgets/lhotse_news_card.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');
final _dateFormat = DateFormat('MM/yyyy');

class InvestmentDetailScreen extends StatelessWidget {
  const InvestmentDetailScreen({super.key, required this.investmentId});

  final String investmentId;

  @override
  Widget build(BuildContext context) {
    final investment =
        mockInvestments.where((i) => i.id == investmentId).firstOrNull;

    if (investment == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Inversión no encontrada',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final brand =
        mockBrands.where((b) => b.name == investment.brandName).firstOrNull;
    final model = brand?.businessModel ?? BusinessModel.coinversion;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          LhotseAppHeader(
            title: investment.projectName.toUpperCase(),
            subtitle: model != BusinessModel.rentaFija
                ? findProjectById(investment.projectId)
                    ?.location
                    .toUpperCase()
                : null,
          ),

          const SizedBox(height: AppSpacing.md),

          // Model-specific content
          switch (model) {
            BusinessModel.compraDirecta =>
              _CompraDirectaDetail(investment: investment),
            BusinessModel.coinversion =>
              _CoinversionDetail(investment: investment),
            BusinessModel.ciclo => _CicloDetail(investment: investment),
            BusinessModel.rentaFija =>
              _RentaFijaDetail(investment: investment),
          },

          const SizedBox(height: AppSpacing.xl),

          // Documents
          _SectionLabel(label: 'DOCUMENTOS'),
          const SizedBox(height: AppSpacing.sm),
          _DocumentsList(),

          const SizedBox(height: AppSpacing.xl),

          // News — horizontal scroll, same visual language as Home
          _SectionLabel(label: 'NOTICIAS DEL PROYECTO'),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _mockNews.length > _kMaxVisibleNews
                  ? _kMaxVisibleNews + 1
                  : _mockNews.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                // "Ver todas" card at the end
                if (i == _kMaxVisibleNews && _mockNews.length > _kMaxVisibleNews) {
                  return _SeeAllNewsCard(
                    count: _mockNews.length,
                    onTap: () => _showAllNews(context),
                  );
                }
                return LhotseNewsCard.compact(
                  title: _mockNews[i].title,
                  imageUrl: _mockNews[i].imageUrl,
                  subtitle: _mockNews[i].date,
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // View project button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GestureDetector(
              onTap: () =>
                  context.push('/projects/${investment.projectId}'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: AppColors.primary,
                child: Center(
                  child: Text(
                    'VER PROYECTO',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textOnDark,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(
              height: MediaQuery.of(context).padding.bottom + AppSpacing.xl),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compra Directa — Andhy, Myttas
// ---------------------------------------------------------------------------

class _CompraDirectaDetail extends StatelessWidget {
  const _CompraDirectaDetail({required this.investment});

  final InvestmentData investment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main metrics — 2x2 grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricBlock(
                      value: investment.purchaseValue != null
                          ? '${_eurFormat.format(investment.purchaseValue)}€'
                          : '—',
                      label: 'Valor de compra',
                    ),
                  ),
                  Expanded(
                    child: _MetricBlock(
                      value: investment.rentalIncome != null
                          ? '${_eurFormat.format(investment.rentalIncome)}€'
                          : '—',
                      label: 'Alquiler mensual',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _MetricBlock(
                      value: '${investment.returnRate.toStringAsFixed(0)}%',
                      label: 'Rentabilidad',
                    ),
                  ),
                  Expanded(
                    child: _MetricBlock(
                      value: investment.revaluation != null
                          ? '${investment.revaluation!.toStringAsFixed(0)}%'
                          : '—',
                      label: 'Revalorización',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Financing section
        if (investment.cashPayment != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel(label: 'FINANCIACIÓN'),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                _DataRow(
                    label: 'Contado',
                    value:
                        '${_eurFormat.format(investment.cashPayment)}€'),
                if (investment.mortgage != null) ...[
                  _DataRow(
                      label: 'Hipoteca',
                      value:
                          '${_eurFormat.format(investment.mortgage)}€'),
                  if (investment.mortgageConditions != null)
                    _DataRow(
                        label: 'Condiciones',
                        value: investment.mortgageConditions!),
                  if (investment.monthlyPayment != null)
                    _DataRow(
                        label: 'Cuota',
                        value:
                            '${_eurFormat.format(investment.monthlyPayment)}€/mes'),
                  if (investment.mortgageEndDate != null)
                    _DataRow(
                        label: 'Finalización',
                        value: _dateFormat
                            .format(investment.mortgageEndDate!)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Coinversión — L&B, Vellte, NUVE, Domorato
// ---------------------------------------------------------------------------

class _CoinversionDetail extends StatelessWidget {
  const _CoinversionDetail({required this.investment});

  final InvestmentData investment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  value: '${_eurFormat.format(investment.amount)}€',
                  label: 'Participación',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  value: '${investment.returnRate.toStringAsFixed(0)}%',
                  label: 'Rentabilidad estimada',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  value: '${investment.durationMonths} meses',
                  label: 'Duración estimada',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  value: investment.expectedEndDate != null
                      ? _dateFormat.format(investment.expectedEndDate!)
                      : '—',
                  label: 'Fecha prevista',
                ),
              ),
            ],
          ),
          if (investment.constructionPhase != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _ConstructionStatus(
              phase: investment.constructionPhase!,
              isDelayed: investment.isDelayed,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ciclo — international
// ---------------------------------------------------------------------------

class _CicloDetail extends StatelessWidget {
  const _CicloDetail({required this.investment});

  final InvestmentData investment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  value: '${_eurFormat.format(investment.amount)}€',
                  label: 'Participación',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  value: '${investment.returnRate.toStringAsFixed(0)}%',
                  label: 'Rentabilidad estimada',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  value: '${investment.durationMonths} meses',
                  label: 'Duración estimada',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  value: investment.expectedEndDate != null
                      ? _dateFormat.format(investment.expectedEndDate!)
                      : '—',
                  label: 'Fecha prevista',
                ),
              ),
            ],
          ),
          if (investment.constructionPhase != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _ConstructionStatus(
              phase: investment.constructionPhase!,
              isDelayed: investment.isDelayed,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Renta Fija — simplest
// ---------------------------------------------------------------------------

class _RentaFijaDetail extends StatelessWidget {
  const _RentaFijaDetail({required this.investment});

  final InvestmentData investment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  value: '${_eurFormat.format(investment.amount)}€',
                  label: 'Capital invertido',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  value: '${investment.returnRate.toStringAsFixed(1)}%',
                  label: 'Rentabilidad fija',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  value: '${_eurFormat.format(investment.amount * investment.returnRate / 100 * investment.durationMonths / 12)}€',
                  label: 'Rendimiento estimado',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  value: '${investment.durationMonths} meses',
                  label: 'Duración',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  value: investment.expectedEndDate != null
                      ? _dateFormat.format(investment.expectedEndDate!)
                      : '—',
                  label: 'Vencimiento',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  value: investment.paymentFrequency ?? '—',
                  label: 'Frecuencia de pago',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared components
// ---------------------------------------------------------------------------

class _ConstructionStatus extends StatelessWidget {
  const _ConstructionStatus({
    required this.phase,
    required this.isDelayed,
  });

  final String phase;
  final bool isDelayed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              phase,
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              color: isDelayed
                  ? AppColors.danger.withValues(alpha: 0.1)
                  : AppColors.textPrimary.withValues(alpha: 0.06),
              child: Text(
                isDelayed ? 'Retrasado' : 'En plazo',
                style: AppTypography.caption.copyWith(
                  color: isDelayed ? AppColors.danger : AppColors.accentMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          'Estado de la obra',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.accentMuted,
          ),
        ),
      ],
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.headingSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.accentMuted,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        label,
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.accentMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.accentMuted,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum DocType { legal, financiero, obra, fiscal }

IconData _docTypeIcon(DocType type) => switch (type) {
      DocType.legal => LucideIcons.scale,
      DocType.financiero => LucideIcons.banknote,
      DocType.obra => LucideIcons.hardHat,
      DocType.fiscal => LucideIcons.receipt,
    };

final _mockDocs = [
  (name: 'Escritura de compraventa', date: '15 MAR. 2026', type: DocType.legal),
  (name: 'Contrato de arras', date: '28 FEB. 2026', type: DocType.legal),
  (name: 'Nota simple registral', date: '10 FEB. 2026', type: DocType.legal),
  (name: 'Certificado fiscal', date: '02 FEB. 2026', type: DocType.fiscal),
  (name: 'Factura notaría', date: '15 ENE. 2026', type: DocType.financiero),
  (name: 'Licencia urbanística', date: '20 DIC. 2025', type: DocType.obra),
  (name: 'Recibo hipoteca Q4', date: '01 DIC. 2025', type: DocType.financiero),
  (name: 'Planos definitivos', date: '15 NOV. 2025', type: DocType.obra),
  (name: 'Poder notarial', date: '01 NOV. 2025', type: DocType.legal),
  (name: 'Informe de tasación', date: '10 OCT. 2025', type: DocType.financiero),
];

const _kMaxVisibleDocs = 3;

class _DocumentsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final visibleDocs = _mockDocs.take(_kMaxVisibleDocs).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          ...visibleDocs.map((doc) => _DocumentRow(
                name: doc.name,
                date: doc.date,
                type: doc.type,
              )),
          if (_mockDocs.length > _kMaxVisibleDocs) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => _showAllDocs(context),
              child: Text(
                'Ver todos (${_mockDocs.length})',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.name,
    required this.date,
    this.type = DocType.legal,
  });

  final String name;
  final String date;
  final DocType type;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(_docTypeIcon(type),
              size: 18, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  date,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {}, // Preview — placeholder
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(LucideIcons.eye,
                  size: 16, color: AppColors.accentMuted),
            ),
          ),
          GestureDetector(
            onTap: () {}, // Download — placeholder
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(LucideIcons.download,
                  size: 16, color: AppColors.accentMuted),
            ),
          ),
        ],
      ),
    );
  }
}

void _showAllDocs(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) => const _DocsBottomSheet(),
  );
}

class _DocsBottomSheet extends StatefulWidget {
  const _DocsBottomSheet();

  @override
  State<_DocsBottomSheet> createState() => _DocsBottomSheetState();
}

class _DocsBottomSheetState extends State<_DocsBottomSheet> {
  final Set<DocType> _activeFilters = {};

  List<({String name, String date, DocType type})> get _filteredDocs {
    if (_activeFilters.isEmpty) return _mockDocs;
    return _mockDocs.where((d) => _activeFilters.contains(d.type)).toList();
  }

  void _toggleFilter(DocType type) {
    setState(() {
      if (_activeFilters.contains(type)) {
        _activeFilters.remove(type);
      } else {
        _activeFilters.add(type);
      }
    });
  }

  static const _filterLabels = {
    DocType.legal: 'Legal',
    DocType.financiero: 'Financiero',
    DocType.obra: 'Obra',
    DocType.fiscal: 'Fiscal',
  };

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final docs = _filteredDocs;
    final headerHeight = 120.0;
    final screenHeight = MediaQuery.of(context).size.height;
    // Size based on ALL docs, not filtered — stays stable when filtering
    final contentHeight = headerHeight + (_mockDocs.length * 64);
    final size = (contentHeight / screenHeight).clamp(0.4, 0.8);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: size,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) => Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'DOCUMENTOS',
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // Filter tabs — same underline pattern as rest of app
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: Row(
              children: DocType.values.map((type) {
                final active = _activeFilters.contains(type);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleFilter(type),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _filterLabels[type]!.toUpperCase(),
                          style: AppTypography.labelLarge.copyWith(
                            color: active
                                ? AppColors.textPrimary
                                : AppColors.accentMuted,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w400,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          height: 1.5,
                          width: active ? 24.0 : 0.0,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Documents list
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, bottomPadding + AppSpacing.md),
              itemCount: docs.length,
              separatorBuilder: (_, _) => Container(
                height: 0.5,
                color: AppColors.textPrimary.withValues(alpha: 0.08),
              ),
              itemBuilder: (context, i) => _DocumentRow(
                name: docs[i].name,
                date: docs[i].date,
                type: docs[i].type,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet for all news
// ---------------------------------------------------------------------------

void _showAllNews(BuildContext context) {
  showLhotseBottomSheet(
    context: context,
    title: 'NOTICIAS',
    itemCount: _mockNews.length,
    estimatedItemHeight: 84,
    itemBuilder: (context, i) {
      final news = _mockNews[i];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Image.network(
                news.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: AppColors.surface),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    news.date,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.accentMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// "See all" card for news carousel
// ---------------------------------------------------------------------------

class _SeeAllNewsCard extends StatelessWidget {
  const _SeeAllNewsCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        height: 160,
        child: Container(
          color: AppColors.primary,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VER TODAS',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count noticias',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mock news data
// ---------------------------------------------------------------------------

const _kNewsImages = [
  'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600&q=80',
  'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=600&q=80',
  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&q=80',
];

final _mockNews = [
  (
    title: 'Inicio de la fase 3',
    date: '12 MAR. 2026',
    imageUrl: _kNewsImages[0],
  ),
  (
    title: 'Informe trimestral Q1',
    date: '28 FEB. 2026',
    imageUrl: _kNewsImages[1],
  ),
  (
    title: 'Licencia urbanística aprobada',
    date: '15 ENE. 2026',
    imageUrl: _kNewsImages[2],
  ),
  (
    title: 'Avance de obra: estructura completada',
    date: '20 DIC. 2025',
    imageUrl: _kNewsImages[0],
  ),
  (
    title: 'Firma del contrato con constructora',
    date: '15 NOV. 2025',
    imageUrl: _kNewsImages[1],
  ),
  (
    title: 'Presentación del proyecto a inversores',
    date: '02 OCT. 2025',
    imageUrl: _kNewsImages[2],
  ),
  (
    title: 'Adquisición del terreno',
    date: '10 SEP. 2025',
    imageUrl: _kNewsImages[0],
  ),
  (
    title: 'Estudio de viabilidad aprobado',
    date: '01 AGO. 2025',
    imageUrl: _kNewsImages[1],
  ),
];

const _kMaxVisibleNews = 3;
