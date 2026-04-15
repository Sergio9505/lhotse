import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/news_item_data.dart';
import 'supabase_provider.dart';

final newsProvider = FutureProvider<List<NewsItemData>>((ref) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('news')
      .select('*, brands(name)')
      .order('date', ascending: false);
  return (data as List<dynamic>)
      .map((e) => NewsItemData.fromSupabaseRow(e as Map<String, dynamic>))
      .toList();
});

final newsByIdProvider =
    FutureProvider.family<NewsItemData?, String>((ref, id) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('news')
      .select('*, brands(name)')
      .eq('id', id)
      .maybeSingle();
  return data != null ? NewsItemData.fromSupabaseRow(data) : null;
});
