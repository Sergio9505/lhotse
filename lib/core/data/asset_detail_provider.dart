import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/asset_detail_data.dart';
import 'supabase_provider.dart';

/// Fetches full asset detail by asset ID, joining the owning project and its
/// brand. Returns null if the asset has no owning project (orphan edge case).
///
/// Query direction: FROM projects WHERE asset_id = $assetId, embedding assets
/// and brands. This traverses the FK in the natural direction (projects.asset_id
/// → assets.id) so PostgREST returns `assets` as a single embedded object.
final assetByIdProvider =
    FutureProvider.family<AssetDetailData?, String>((ref, assetId) async {
  final client = ref.watch(supabaseClientProvider);

  final row = await client
      .from('projects')
      .select(
        'brands(name), assets!inner(id, thumbnail_image, address, city, gallery_images, floor_plan_url, use_light_overlay)',
      )
      .eq('asset_id', assetId)
      .maybeSingle();

  if (row == null) return null;
  return AssetDetailData.fromProjectRow(row);
});
