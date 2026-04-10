import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';
import 'lhotse_bottom_sheet.dart';
import 'lhotse_doc_row.dart';

/// Document category for filtering.
enum DocCategory { legal, financiero, obra, fiscal, contrato, certificado, informe }

/// A single document entry.
class LhotseDocument {
  const LhotseDocument({
    required this.name,
    required this.date,
    required this.category,
  });

  final String name;
  final String date;
  final DocCategory category;
}

IconData docCategoryIcon(DocCategory cat) => switch (cat) {
      DocCategory.legal => LucideIcons.scale,
      DocCategory.financiero => LucideIcons.banknote,
      DocCategory.obra => LucideIcons.hardHat,
      DocCategory.fiscal => LucideIcons.receipt,
      DocCategory.contrato => LucideIcons.fileText,
      DocCategory.certificado => LucideIcons.fileBadge,
      DocCategory.informe => LucideIcons.fileBarChart,
    };

/// Inline documents section: shows first [maxVisible] docs + "Ver todos" link
/// that opens a bottom sheet with filters.
class LhotseDocumentsSection extends StatelessWidget {
  const LhotseDocumentsSection({
    super.key,
    required this.documents,
    required this.filterLabels,
    this.maxVisible = 3,
  });

  final List<LhotseDocument> documents;
  final Map<DocCategory, String> filterLabels;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final visibleDocs = documents.take(maxVisible).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...visibleDocs.indexed.map((entry) {
            final i = entry.$1;
            final doc = entry.$2;
            return Column(
              children: [
                if (i > 0)
                  Container(
                    height: 0.5,
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                  ),
                LhotseDocRow(
                  name: doc.name,
                  date: doc.date,
                  icon: docCategoryIcon(doc.category),
                ),
              ],
            );
          }),
          if (documents.length > maxVisible) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => showDocsBottomSheet(
                context: context,
                documents: documents,
                filterLabels: filterLabels,
              ),
              child: Text(
                'Ver todos (${documents.length})',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.accentMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Public helper — open documents bottom sheet from anywhere
// ---------------------------------------------------------------------------

void showDocsBottomSheet({
  required BuildContext context,
  required List<LhotseDocument> documents,
  required Map<DocCategory, String> filterLabels,
}) {
  final activeFilters = <DocCategory>{};

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final filteredDocs = activeFilters.isEmpty
            ? documents
            : documents
                .where((d) => activeFilters.contains(d.category))
                .toList();

        return LhotseBottomSheetBody(
          title: 'DOCUMENTOS',
          header: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  ...filterLabels.entries.map((entry) {
                    final active = activeFilters.contains(entry.key);
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          if (activeFilters.contains(entry.key)) {
                            activeFilters.remove(entry.key);
                          } else {
                            activeFilters.add(entry.key);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.textPrimary
                                      .withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            entry.value.toUpperCase(),
                            style: AppTypography.caption.copyWith(
                              color: active
                                  ? AppColors.textOnDark
                                  : AppColors.accentMuted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (activeFilters.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => activeFilters.clear()),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(LucideIcons.x,
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
            itemCount: filteredDocs.length,
            separatorBuilder: (_, _) => Container(
              height: 0.5,
              color: AppColors.textPrimary.withValues(alpha: 0.08),
            ),
            itemBuilder: (context, i) => LhotseDocRow(
              name: filteredDocs[i].name,
              date: filteredDocs[i].date,
              icon: docCategoryIcon(filteredDocs[i].category),
            ),
          ),
        );
      },
    ),
  );
}
