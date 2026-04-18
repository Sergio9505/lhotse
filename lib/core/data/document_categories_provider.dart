import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/document_category_data.dart';
import 'supabase_provider.dart';

/// All document categories, ordered by sort_order.
/// Cached app-wide — fetch once, filter locally per screen.
final allDocumentCategoriesProvider =
    FutureProvider<List<DocumentCategoryData>>((ref) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('document_categories')
      .select()
      .order('sort_order', ascending: true);
  return (data as List<dynamic>)
      .map((e) => DocumentCategoryData.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Returns only the categories that appear in the given document category ids.
List<DocumentCategoryData> categoriesForIds(
  Iterable<String?> categoryIds,
  List<DocumentCategoryData> allCategories,
) {
  final presentIds = categoryIds.whereType<String>().toSet();
  return allCategories
      .where((c) => presentIds.contains(c.id))
      .toList();
}
