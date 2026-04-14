import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/data/mock/mock_brands.dart';
import '../../../core/data/mock/mock_investments.dart';
import '../../../core/data/mock/mock_news.dart';
import '../../../core/data/mock/mock_projects.dart';
import '../../../core/domain/brand_data.dart';
import 'completed_detail_screen.dart';
import 'compra_directa_detail_screen.dart';
import '../../../core/domain/investment_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_app_header.dart';
import '../../../core/widgets/lhotse_documents_section.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_bottom_sheet.dart';
import '../../../core/widgets/lhotse_metric_block.dart';
import '../../../core/widgets/lhotse_news_card.dart';
import '../../../core/widgets/lhotse_section_label.dart';
import 'coinversion_detail_screen.dart';

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
    final model = brand?.businessModel ?? BusinessModel.coinvestment;

    final project = findProjectById(investment.projectId);

    // Coinversion — completed vs active
    if (model == BusinessModel.coinvestment) {
      if (investment.isCompleted) {
        return CompletedDetailScreen(
          investment: investment,
          project: project,
        );
      }
      return CoinversionDetailScreen(
        investment: investment,
        project: project,
      );
    }

    // CompraDirecta — completed vs active
    if (model == BusinessModel.directPurchase) {
      if (investment.isCompleted) {
        return CompletedDetailScreen(
          investment: investment,
          project: project,
        );
      }
      return CompraDirectaDetailScreen(
        investment: investment,
        project: project,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          LhotseAppHeader(
            title: investment.projectName.toUpperCase(),
            subtitle: null,
          ),

          const SizedBox(height: AppSpacing.md),

          // Model-specific content (only rentaFija reaches here)
          _RentaFijaDetail(investment: investment),

          const SizedBox(height: AppSpacing.xl),

          // Documents
          const LhotseSectionLabel(label: 'DOCUMENTOS'),
          const SizedBox(height: AppSpacing.sm),
          LhotseDocumentsSection(
            documents: _investmentDocs,
            filterLabels: const {
              DocCategory.legal: 'Legal',
              DocCategory.financiero: 'Financiero',
              DocCategory.obra: 'Obra',
              DocCategory.fiscal: 'Fiscal',
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // News — horizontal scroll
          const LhotseSectionLabel(label: 'NOTICIAS DEL PROYECTO'),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: mockNews.length > _kMaxVisibleNews
                  ? _kMaxVisibleNews + 1
                  : mockNews.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                if (i == _kMaxVisibleNews && mockNews.length > _kMaxVisibleNews) {
                  return _SeeAllNewsCard(
                    count: mockNews.length,
                    onTap: () => _showAllNews(context),
                  );
                }
                return LhotseNewsCard.compact(
                  title: mockNews[i].title,
                  imageUrl: mockNews[i].imageUrl,
                  subtitle: mockNews[i].date,
                  onTap: () => context.push('/news/${mockNews[i].id}'),
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
// Renta Fija
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
                child: LhotseMetricBlock(
                  value: '${_eurFormat.format(investment.amount)}€',
                  label: 'Capital invertido',
                ),
              ),
              Expanded(
                child: LhotseMetricBlock(
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
                child: LhotseMetricBlock(
                  value: '${_eurFormat.format(investment.amount * investment.returnRate / 100 * investment.durationMonths / 12)}€',
                  label: 'Rendimiento estimado',
                ),
              ),
              Expanded(
                child: LhotseMetricBlock(
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
                child: LhotseMetricBlock(
                  value: investment.expectedEndDate != null
                      ? _dateFormat.format(investment.expectedEndDate!)
                      : '—',
                  label: 'Vencimiento',
                ),
              ),
              Expanded(
                child: LhotseMetricBlock(
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
// Mock data (shared across all investment detail models)
// ---------------------------------------------------------------------------

final _investmentDocs = [
  LhotseDocument(name: 'Escritura de compraventa', date: '15 MAR. 2026', category: DocCategory.legal),
  LhotseDocument(name: 'Contrato de arras', date: '28 FEB. 2026', category: DocCategory.legal),
  LhotseDocument(name: 'Nota simple registral', date: '10 FEB. 2026', category: DocCategory.legal),
  LhotseDocument(name: 'Certificado fiscal', date: '02 FEB. 2026', category: DocCategory.fiscal),
  LhotseDocument(name: 'Factura notaría', date: '15 ENE. 2026', category: DocCategory.financiero),
  LhotseDocument(name: 'Licencia urbanística', date: '20 DIC. 2025', category: DocCategory.obra),
  LhotseDocument(name: 'Recibo hipoteca Q4', date: '01 DIC. 2025', category: DocCategory.financiero),
  LhotseDocument(name: 'Planos definitivos', date: '15 NOV. 2025', category: DocCategory.obra),
  LhotseDocument(name: 'Poder notarial', date: '01 NOV. 2025', category: DocCategory.legal),
  LhotseDocument(name: 'Informe de tasación', date: '10 OCT. 2025', category: DocCategory.financiero),
];

const _kMaxVisibleNews = 3;

// ---------------------------------------------------------------------------
// Bottom sheet for all news
// ---------------------------------------------------------------------------

void _showAllNews(BuildContext context) {
  showLhotseBottomSheet(
    context: context,
    title: 'NOTICIAS',
    itemCount: mockNews.length,
    itemBuilder: (context, i) {
      final news = mockNews[i];
      return GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          context.push('/news/${news.id}');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: LhotseImage(news.imageUrl),
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
                        fontWeight: FontWeight.w500,
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
                    fontWeight: FontWeight.w500,
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
