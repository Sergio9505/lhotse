import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/news_item_data.dart';
import 'supabase_provider.dart';

// `*` covers the new `gallery_media` jsonb column added by
// 20260520120000_news_gallery_media.sql — no manual list to maintain.
const _newsSelect = '''
  *,
  project:projects(brand_id, brand:brands(name), projectAsset:assets(city)),
  asset:assets(city)
''';

final newsProvider = FutureProvider<List<NewsItemData>>((ref) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('news')
      .select(_newsSelect)
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
      .select(_newsSelect)
      .eq('id', id)
      .maybeSingle();
  return data != null ? NewsItemData.fromSupabaseRow(data) : null;
});
