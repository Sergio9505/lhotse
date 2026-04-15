import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/document_data.dart';
import 'supabase_provider.dart';

typedef DocumentParams = ({String type, String id});

final documentsProvider =
    FutureProvider.family<List<DocumentData>, DocumentParams>(
        (ref, params) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('documents')
      .select()
      .eq('model_type', params.type)
      .eq('model_id', params.id)
      .order('date', ascending: false);
  return (data as List<dynamic>)
      .map((e) => DocumentData.fromJson(e as Map<String, dynamic>))
      .toList();
});
