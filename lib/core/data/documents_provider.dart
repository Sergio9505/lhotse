import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/document_data.dart';
import 'supabase_provider.dart';

typedef DocumentParams = ({String type, String id});

// Translates legacy (type, id) params to the new scope + typed FK query.
PostgrestFilterBuilder<List<Map<String, dynamic>>> _scopedQuery(
  SupabaseClient supabase,
  DocumentParams params,
) {
  final q = supabase.from('documents').select();
  switch (params.type) {
    case 'coinvestment':
      return q
          .eq('scope', 'investor')
          .eq('related_coinvestment_id', params.id);
    case 'purchase':
      return q
          .eq('scope', 'investor')
          .eq('related_purchase_id', params.id);
    case 'fixed_income':
      return q
          .eq('scope', 'investor')
          .eq('related_fixed_income_id', params.id);
    case 'rental':
      return q
          .eq('scope', 'investor')
          .eq('related_rental_id', params.id);
    case 'project':
      return q.eq('scope', 'project').eq('project_id', params.id);
    case 'asset':
      return q.eq('scope', 'asset').eq('asset_id', params.id);
    default:
      // Unsupported type — return empty by filtering on an impossible value.
      return q.eq('scope', params.type);
  }
}

final documentsProvider =
    FutureProvider.family<List<DocumentData>, DocumentParams>(
        (ref, params) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final supabase = ref.watch(supabaseClientProvider);
  final data = await _scopedQuery(supabase, params)
      .order('date', ascending: false);
  return (data as List<dynamic>)
      .map((e) => DocumentData.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Every document the authenticated user can access (RLS does the filtering).
/// Used by the search screen for both direct name matches and the contextual
/// DOCUMENTOS section (docs linked to matched brands/projects/assets).
final allUserDocumentsProvider =
    FutureProvider<List<DocumentData>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('documents')
      .select()
      .order('date', ascending: false);
  return (data as List<dynamic>)
      .map((e) => DocumentData.fromJson(e as Map<String, dynamic>))
      .toList();
});
