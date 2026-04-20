import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/asset_data.dart';
import 'supabase_provider.dart';

/// Flat list of all assets. Used by the search screen to match by address /
/// city / country / cadastral reference. Public-read; no RLS scoping.
final assetsProvider = FutureProvider<List<AssetData>>((ref) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('assets')
      .select('id, address, city, country, cadastral_reference, thumbnail_image');
  return (data as List<dynamic>)
      .map((e) => AssetData.fromJson(e as Map<String, dynamic>))
      .toList();
});
