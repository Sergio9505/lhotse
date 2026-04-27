import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../domain/document_category_data.dart';
import '../theme/app_theme.dart';
import 'lhotse_bottom_sheet.dart';
import 'lhotse_doc_row.dart';
import 'lhotse_filter_chip.dart';

// ---------------------------------------------------------------------------
// Icon map — Phosphor thin icons keyed by icon_name from document_categories.
// Add entries here when new icon_name values are added in the DB.
// ---------------------------------------------------------------------------

const _kDocIcons = <String, IconData>{
  'scales': PhosphorIconsThin.scales,
  'money': PhosphorIconsThin.money,
  'hardHat': PhosphorIconsThin.hardHat,
  'receipt': PhosphorIconsThin.receipt,
  'fileText': PhosphorIconsThin.fileText,
  'certificate': PhosphorIconsThin.certificate,
  'chartBar': PhosphorIconsThin.chartBar,
  'folder': PhosphorIconsThin.folder,
  'houseLine': PhosphorIconsThin.houseLine,
  'bank': PhosphorIconsThin.bank,
  'notePencil': PhosphorIconsThin.notePencil,
  'stamp': PhosphorIconsThin.stamp,
  'handshake': PhosphorIconsThin.handshake,
  'buildings': PhosphorIconsThin.buildings,
  'key': PhosphorIconsThin.key,
};

/// Returns the Phosphor icon for the given icon_name key.
/// Falls back to a generic file icon if the key is unknown.
IconData docCategoryIconByKey(String iconName) =>
    _kDocIcons[iconName] ?? PhosphorIconsThin.file;

/// A single document entry.
class LhotseDocument {
  const LhotseDocument({
    required this.id,
    required this.name,
    required this.date,
    required this.categoryId,
    required this.iconName,
    this.fileUrl,
  });

  final String id;
  final String name;
  final String date;
  final String categoryId;
  final String iconName;

  /// Either a Supabase Storage path (will be converted to a signed URL by
  /// `openSupabaseDoc`) or a fully qualified URL (used directly).
  final String? fileUrl;
}

/// Inline documents section: shows first [maxVisible] docs + "Ver todos" link
/// that opens a bottom sheet with filters derived from the actual documents.
class LhotseDocumentsSection extends StatelessWidget {
  const LhotseDocumentsSection({
    super.key,
    required this.documents,
    required this.filterCategories,
    this.maxVisible = 3,
  });

  final List<LhotseDocument> documents;

  /// Only categories that appear in [documents] — derived by the caller.
  final List<DocumentCategoryData> filterCategories;
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
                  icon: docCategoryIconByKey(doc.iconName),
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
                filterCategories: filterCategories,
              ),
              child: Text(
                'Ver todos (${documents.length})',
                style: AppTypography.annotation.copyWith(
                  color: AppColors.accentMuted,
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
  required List<DocumentCategoryData> filterCategories,
}) {
  final activeFilters = <String>{};

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
                .where((d) => activeFilters.contains(d.categoryId))
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
                  ...filterCategories.map((cat) {
                    final active = activeFilters.contains(cat.id);
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: LhotseFilterChip(
                        label: cat.label,
                        isActive: active,
                        onTap: () => setState(() {
                          if (active) {
                            activeFilters.remove(cat.id);
                          } else {
                            activeFilters.add(cat.id);
                          }
                        }),
                      ),
                    );
                  }),
                  if (activeFilters.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => activeFilters.clear()),
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
            itemCount: filteredDocs.length,
            separatorBuilder: (_, _) => Container(
              height: 0.5,
              color: AppColors.textPrimary.withValues(alpha: 0.08),
            ),
            itemBuilder: (context, i) => LhotseDocRow(
              name: filteredDocs[i].name,
              date: filteredDocs[i].date,
              icon: docCategoryIconByKey(filteredDocs[i].iconName),
            ),
          ),
        );
      },
    ),
  );
}
