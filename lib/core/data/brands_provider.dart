import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/brand_data.dart';
import 'supabase_provider.dart';

final brandsProvider = FutureProvider<List<BrandData>>((ref) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('brands')
      .select()
      .order('name', ascending: true);
  return (data as List<dynamic>)
      .map((e) => BrandData.fromJson(e as Map<String, dynamic>))
      .toList();
});

final brandByIdProvider =
    FutureProvider.family<BrandData?, String>((ref, id) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('brands')
      .select()
      .eq('id', id)
      .maybeSingle();
  return data != null ? BrandData.fromJson(data) : null;
});
