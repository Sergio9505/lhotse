import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/data/news_provider.dart';
import '../../../core/domain/news_item_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lhotse_app_header.dart';
import '../../../core/widgets/lhotse_documents_section.dart';
import '../../../core/widgets/lhotse_image.dart';
import '../../../core/widgets/lhotse_bottom_sheet.dart';
import '../../../core/widgets/lhotse_metric_block.dart';
import '../../../core/widgets/lhotse_news_card.dart';
import '../../../core/widgets/lhotse_section_label.dart';
import '../data/investments_provider.dart';
import '../domain/fixed_income_contract_data.dart';

final _eurFormat = NumberFormat('#,##0', 'es_ES');
final _dateFormat = DateFormat('MM/yyyy');
const _kMaxVisibleNews = 3;

/// Detail screen for fixed income (renta fija) contracts.
/// Named InvestmentDetailScreen for GoRouter compatibility.
class InvestmentDetailScreen extends ConsumerWidget {
  const InvestmentDetailScreen({super.key, required this.investmentId});

  final String investmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allContracts = ref.watch(fixedIncomeContractsProvider).valueOrNull;
    final contract = allContracts?.where((c) => c.id == investmentId).firstOrNull;
    final allNews = ref.watch(newsProvider).valueOrNull ?? const [];

    if (allContracts == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
      );
    }

    if (contract == null) {
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

    final relatedNews = allNews
        .where((n) => n.brand == contract.brandName)
        .take(4)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          LhotseAppHeader(
            title: contract.offeringName.toUpperCase(),
            subtitle: null,
          ),

          const SizedBox(height: AppSpacing.md),

          _RentaFijaDetail(contract: contract),

          const SizedBox(height: AppSpacing.xl),

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

          if (relatedNews.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const LhotseSectionLabel(label: 'NOTICIAS DEL PROYECTO'),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: relatedNews.length > _kMaxVisibleNews
                    ? _kMaxVisibleNews + 1
                    : relatedNews.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  if (i == _kMaxVisibleNews &&
                      relatedNews.length > _kMaxVisibleNews) {
                    return _SeeAllNewsCard(
                      count: relatedNews.length,
                      onTap: () => _showAllNews(context, relatedNews),
                    );
                  }
                  final news = relatedNews[i];
                  return LhotseNewsCard.compact(
                    title: news.title,
                    imageUrl: news.imageUrl,
                    subtitle: DateFormat('d MMM yyyy').format(news.date),
                    onTap: () => context.push('/news/${news.id}'),
                  );
                },
              ),
            ),
          ],

          SizedBox(
              height: MediaQuery.of(context).padding.bottom + AppSpacing.xl),
        ],
      ),
    );
  }
}

// ── Renta Fija metrics ────────────────────────────────────────────────────────

class _RentaFijaDetail extends StatelessWidget {
  const _RentaFijaDetail({required this.contract});

  final FixedIncomeContractData contract;

  @override
  Widget build(BuildContext context) {
    final c = contract;
    final estimatedReturn =
        c.amount * c.guaranteedRate / 100 * (c.termMonths ?? 12) / 12;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LhotseMetricBlock(
                  value: '${_eurFormat.format(c.amount)}€',
                  label: 'Capital invertido',
                ),
              ),
              Expanded(
                child: LhotseMetricBlock(
                  value: '${c.guaranteedRate.toStringAsFixed(1)}%',
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
                  value: '${_eurFormat.format(estimatedReturn)}€',
                  label: 'Rendimiento estimado',
                ),
              ),
              Expanded(
                child: LhotseMetricBlock(
                  value: '${c.termMonths ?? '–'} meses',
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
                  value: c.maturityDate != null
                      ? _dateFormat.format(c.maturityDate!)
                      : '—',
                  label: 'Vencimiento',
                ),
              ),
              Expanded(
                child: LhotseMetricBlock(
                  value: c.paymentFrequency,
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

// ── Placeholder docs ──────────────────────────────────────────────────────────

final _investmentDocs = [
  LhotseDocument(
      name: 'Contrato de inversión',
      date: '15 MAR. 2026',
      category: DocCategory.legal),
  LhotseDocument(
      name: 'Certificado de depósito',
      date: '15 MAR. 2026',
      category: DocCategory.fiscal),
  LhotseDocument(
      name: 'Condiciones generales',
      date: '01 MAR. 2026',
      category: DocCategory.legal),
];

// ── All news bottom sheet ─────────────────────────────────────────────────────

void _showAllNews(BuildContext context, List<NewsItemData> news) {
  showLhotseBottomSheet(
    context: context,
    title: 'NOTICIAS',
    itemCount: news.length,
    itemBuilder: (context, i) {
      final item = news[i];
      return GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          context.push('/news/${item.id}');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: LhotseImage(item.imageUrl),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('d MMM yyyy').format(item.date),
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

// ── See-all card ──────────────────────────────────────────────────────────────

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
