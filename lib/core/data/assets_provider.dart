import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/asset_data.dart';
import 'supabase_provider.dart';

/// List of assets the **current user has purchased directly** (via
/// `purchase_contracts`). Used exclusively by the global search to surface
/// direct-purchase properties the user owns.
///
/// Coinversion-investable assets are NOT returned here — they surface in
/// the search via `projectsProvider` (the coinversion project itself is
/// the canonical search result, and the asset's city / surface / etc.
/// come embedded in the project row).
///
/// After the RLS tightening in migration `20260521150000_assets_ownership_rls`,
/// the `assets` table is no longer publicly readable. Two policies decide
/// visibility: (a) the user owns a `purchase_contracts` row for the asset,
/// or (b) the asset is part of a coinversion project. This provider relies
/// on (a) and additionally constrains the query with an inner join +
/// `eq('purchase_contracts.user_id', userId)` so coinversion assets that
/// might pass policy (b) don't leak into the search-asset result set as
/// duplicates of their owning project.
final assetsProvider = FutureProvider<List<AssetData>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return const [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('assets')
      .select(
        'id, address, city, country, cadastral_reference, thumbnail_image, '
        'purchase_contracts!inner(user_id)',
      )
      .eq('purchase_contracts.user_id', userId);
  return (data as List<dynamic>)
      .map((e) => AssetData.fromJson(e as Map<String, dynamic>))
      .toList();
});
