import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/document_data.dart';
import 'supabase_provider.dart';

typedef DocumentParams = ({String type, String id});

Future<List<Map<String, dynamic>>> _fetchDocuments(
  SupabaseClient supabase,
  DocumentParams params,
  String userId,
) async {
  switch (params.type) {
    case 'coinvestment':
      final row = await supabase
          .from('coinvestment_contracts')
          .select('project_id')
          .eq('id', params.id)
          .maybeSingle();
      final projectId = row?['project_id'] as String?;
      if (projectId == null) {
        return supabase
            .from('documents')
            .select()
            .eq('scope', 'investor')
            .eq('related_coinvestment_id', params.id)
            .order('date', ascending: false);
      }
      return supabase
          .from('documents')
          .select()
          .or(
            'and(scope.eq.investor,related_coinvestment_id.eq.${params.id}),'
            'and(scope.eq.project,project_id.eq.$projectId)',
          )
          .order('date', ascending: false);

    case 'purchase':
      final row = await supabase
          .from('purchase_contracts')
          .select('asset_id')
          .eq('id', params.id)
          .maybeSingle();
      final assetId = row?['asset_id'] as String?;
      final rentalRow = assetId == null
          ? null
          : await supabase
              .from('rental_contracts')
              .select('id')
              .eq('asset_id', assetId)
              .eq('user_id', userId)
              .maybeSingle();
      final rentalId = rentalRow?['id'] as String?;
      final clauses = [
        'and(scope.eq.investor,related_purchase_id.eq.${params.id})',
        if (assetId != null) 'and(scope.eq.asset,asset_id.eq.$assetId)',
        if (rentalId != null)
          'and(scope.eq.investor,related_rental_id.eq.$rentalId)',
      ];
      if (clauses.length == 1) {
        return supabase
            .from('documents')
            .select()
            .eq('scope', 'investor')
            .eq('related_purchase_id', params.id)
            .order('date', ascending: false);
      }
      return supabase
          .from('documents')
          .select()
          .or(clauses.join(','))
          .order('date', ascending: false);

    case 'fixed_income':
      return supabase
          .from('documents')
          .select()
          .eq('scope', 'investor')
          .eq('related_fixed_income_id', params.id)
          .order('date', ascending: false);

    case 'rental':
      final row = await supabase
          .from('rental_contracts')
          .select('asset_id')
          .eq('id', params.id)
          .maybeSingle();
      final assetId = row?['asset_id'] as String?;
      if (assetId == null) {
        return supabase
            .from('documents')
            .select()
            .eq('scope', 'investor')
            .eq('related_rental_id', params.id)
            .order('date', ascending: false);
      }
      return supabase
          .from('documents')
          .select()
          .or(
            'and(scope.eq.investor,related_rental_id.eq.${params.id}),'
            'and(scope.eq.asset,asset_id.eq.$assetId)',
          )
          .order('date', ascending: false);

    case 'project':
      return supabase
          .from('documents')
          .select()
          .eq('scope', 'project')
          .eq('project_id', params.id)
          .order('date', ascending: false);

    case 'asset':
      return supabase
          .from('documents')
          .select()
          .eq('scope', 'asset')
          .eq('asset_id', params.id)
          .order('date', ascending: false);

    default:
      return supabase
          .from('documents')
          .select()
          .eq('scope', params.type)
          .order('date', ascending: false);
  }
}

final documentsProvider =
    FutureProvider.family<List<DocumentData>, DocumentParams>(
        (ref, params) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final supabase = ref.watch(supabaseClientProvider);
  final data = await _fetchDocuments(supabase, params, userId);
  return data.map((e) => DocumentData.fromJson(e)).toList();
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
  return data.map((e) => DocumentData.fromJson(e)).toList();
});
