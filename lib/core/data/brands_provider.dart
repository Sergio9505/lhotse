import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/brand_data.dart';
import 'supabase_provider.dart';

/// Public brand catalog. Only visible brands. Consumers (Firmas list, search,
/// news + project filter chips) must not expose brands the admin has toggled
/// off.
///
/// `brandByIdProvider` deliberately does NOT filter — investors with
/// contracts in a hidden brand must still see its name in L3 screens.
final brandsProvider = FutureProvider<List<BrandData>>((ref) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('brands')
      .select()
      .eq('is_visible', true)
      .order('sort_order', ascending: true)
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
