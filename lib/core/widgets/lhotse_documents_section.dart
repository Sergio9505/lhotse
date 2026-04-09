import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';
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
              onTap: () => _showAllDocs(context),
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

  void _showAllDocs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => _DocsBottomSheet(
        documents: documents,
        filterLabels: filterLabels,
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) => _DocsBottomSheet(
      documents: documents,
      filterLabels: filterLabels,
    ),
  );
}

// ---------------------------------------------------------------------------
// Bottom sheet with filters
// ---------------------------------------------------------------------------

class _DocsBottomSheet extends StatefulWidget {
  const _DocsBottomSheet({
    required this.documents,
    required this.filterLabels,
  });

  final List<LhotseDocument> documents;
  final Map<DocCategory, String> filterLabels;

  @override
  State<_DocsBottomSheet> createState() => _DocsBottomSheetState();
}

class _DocsBottomSheetState extends State<_DocsBottomSheet> {
  final Set<DocCategory> _activeFilters = {};

  List<LhotseDocument> get _filteredDocs {
    if (_activeFilters.isEmpty) return widget.documents;
    return widget.documents
        .where((d) => _activeFilters.contains(d.category))
        .toList();
  }

  void _toggleFilter(DocCategory cat) {
    setState(() {
      if (_activeFilters.contains(cat)) {
        _activeFilters.remove(cat);
      } else {
        _activeFilters.add(cat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final docs = _filteredDocs;
    final headerHeight = 120.0;
    final screenHeight = MediaQuery.of(context).size.height;
    final contentHeight = headerHeight + (widget.documents.length * 64);
    final size = (contentHeight / screenHeight).clamp(0.4, 0.8);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: size,
      minChildSize: 0.2,
      maxChildSize: size,
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

          // Filter tabs — scrollable
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: widget.filterLabels.entries.map((entry) {
                  final active = _activeFilters.contains(entry.key);
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: GestureDetector(
                      onTap: () => _toggleFilter(entry.key),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.value.toUpperCase(),
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
              itemBuilder: (context, i) => LhotseDocRow(
                name: docs[i].name,
                date: docs[i].date,
                icon: docCategoryIcon(docs[i].category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
