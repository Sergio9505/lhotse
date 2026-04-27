import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/supabase_provider.dart';
import '../../../core/domain/asset_data.dart';
import '../../../core/domain/brand_data.dart';
import '../../../core/domain/news_item_data.dart';
import '../../../core/domain/project_data.dart';
import '../domain/feed_item.dart';

/// Server-side curated Home feed. Reads `home_feed_items` ordered by
/// `sort_order` and hydrates each row with its source row via 4 batch
/// fetches (one per source_type). The feed is identical for every role —
/// VIP gating is per-project (`showVipLockSheet`), not per-feed.
final homeFeedProvider = FutureProvider<List<FeedItem>>((ref) async {
  final client = ref.watch(supabaseClientProvider);

  final rowsRaw = await client
      .from('home_feed_items')
      .select()
      .order('sort_order', ascending: true);
  final rows = (rowsRaw as List<dynamic>).cast<Map<String, dynamic>>();
  if (rows.isEmpty) return const [];

  // Group source IDs by type.
  final idsByType = <String, List<String>>{};
  for (final r in rows) {
    final t = r['source_type'] as String;
    idsByType.putIfAbsent(t, () => []).add(r['source_id'] as String);
  }

  // Batch-fetch each type in parallel.
  final projectsF = (idsByType['project']?.isNotEmpty ?? false)
      ? client
          .from('projects')
          .select(
              '*, use_light_overlay, brands(name, logo_asset), assets(city, country, address, surface_m2, bedrooms, bathrooms, floor, year_built, year_renovated, terrace_m2, parking_spots, storage_room, orientation, views, plot_m2, has_pool, floor_plan_url)')
          .inFilter('id', idsByType['project']!)
      : Future.value(const <Map<String, dynamic>>[]);

  final newsF = (idsByType['news']?.isNotEmpty ?? false)
      ? client
          .from('news')
          .select('*, use_light_overlay')
          .inFilter('id', idsByType['news']!)
      : Future.value(const <Map<String, dynamic>>[]);

  final brandsF = (idsByType['brand']?.isNotEmpty ?? false)
      ? client.from('brands').select('*, use_light_overlay').inFilter('id', idsByType['brand']!)
      : Future.value(const <Map<String, dynamic>>[]);

  final assetsF = (idsByType['asset']?.isNotEmpty ?? false)
      ? client.from('assets').select('*, use_light_overlay').inFilter('id', idsByType['asset']!)
      : Future.value(const <Map<String, dynamic>>[]);

  final fetched = await Future.wait([projectsF, newsF, brandsF, assetsF]);

  // Index each source by id for O(1) lookup while preserving sort_order.
  final rawProjects = (fetched[0] as List).cast<Map<String, dynamic>>();
  final rawNews     = (fetched[1] as List).cast<Map<String, dynamic>>();
  final rawBrands   = (fetched[2] as List).cast<Map<String, dynamic>>();
  final rawAssets   = (fetched[3] as List).cast<Map<String, dynamic>>();

  final projectsById = <String, ProjectData>{
    for (final r in rawProjects) r['id'] as String: ProjectData.fromSupabaseRow(r)
  };
  final newsById = <String, NewsItemData>{
    for (final r in rawNews) r['id'] as String: NewsItemData.fromSupabaseRow(r)
  };
  final brandsById = <String, BrandData>{
    for (final r in rawBrands) r['id'] as String: BrandData.fromJson(r)
  };
  final assetsById = <String, AssetData>{
    for (final r in rawAssets) r['id'] as String: AssetData.fromJson(r)
  };

  // use_light_overlay lives on the source row, not the slot.
  bool lightOverlay(List<Map<String, dynamic>> rows, String id) =>
      rows.firstWhere((r) => r['id'] == id, orElse: () => {})['use_light_overlay'] as bool? ?? true;

  // Rebuild in sort_order, dropping any orphan (source row deleted but
  // feed row still pointing to it — trigger prevents this on write, but
  // nothing blocks a manual DELETE on the source table).
  final out = <FeedItem>[];
  for (final r in rows) {
    final type = r['source_type'] as String;
    final id = r['source_id'] as String;
    final item = switch (type) {
      'project' => projectsById[id] != null
          ? FeedProjectItem(projectsById[id]!, useLightOverlay: lightOverlay(rawProjects, id))
          : null,
      'news' => newsById[id] != null
          ? FeedNewsItem(newsById[id]!, useLightOverlay: lightOverlay(rawNews, id))
          : null,
      'brand' => brandsById[id] != null
          ? FeedBrandItem(brandsById[id]!, useLightOverlay: lightOverlay(rawBrands, id))
          : null,
      'asset' => assetsById[id] != null
          ? FeedAssetItem(assetsById[id]!, useLightOverlay: lightOverlay(rawAssets, id))
          : null,
      _ => null,
    };
    if (item != null) out.add(item);
  }
  return out;
});
