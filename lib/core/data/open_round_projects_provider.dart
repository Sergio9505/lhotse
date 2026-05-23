import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/project_data.dart';
import 'supabase_provider.dart';

/// Projects currently accepting new investors (`is_fundraising_open = true`),
/// ordered most-recent first. Feeds the "Nuevas oportunidades" section of
/// the Strategy screen.
///
/// Same SELECT shape as [projectsProvider] so the rows hydrate via the
/// shared `ProjectData.fromSupabaseRow` parser — do not diverge from that
/// query without updating the parser too.
final openRoundProjectsProvider =
    FutureProvider<List<ProjectData>>((ref) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('projects')
      .select(
          '*, brands(name, logo_asset), assets(city, country, address, built_surface_m2, usable_surface_m2, bedrooms, bathrooms, floor, year_built, year_renovated, terrace_m2, parking_spots, storage_room, orientation, views, has_elevator, floor_plan_url)')
      .eq('is_fundraising_open', true)
      .order('created_at', ascending: false);
  return (data as List<dynamic>)
      .map((e) => ProjectData.fromSupabaseRow(e as Map<String, dynamic>))
      .toList();
});
