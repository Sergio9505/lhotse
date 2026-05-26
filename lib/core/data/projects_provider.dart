import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/project_data.dart';
import 'supabase_provider.dart';

final projectsProvider = FutureProvider<List<ProjectData>>((ref) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('projects')
      .select('*, brands(name, logo_asset), assets(city, country, address, built_surface_m2, usable_surface_m2, bedrooms, bathrooms, floor, year_built, year_renovated, terrace_m2, parking_spots, storage_room, orientation, views, has_elevator, floor_plan_url)')
      // Manual order set by the operator from admin /projects/reorder.
      // created_at DESC as tie-breaker for rows with equal sort_order (e.g.
      // rows created before the migration backfill collapses ties to default).
      .order('sort_order', ascending: true)
      .order('created_at', ascending: false);
  return (data as List<dynamic>)
      .map((e) => ProjectData.fromSupabaseRow(e as Map<String, dynamic>))
      .toList();
});

final projectByIdProvider =
    FutureProvider.family<ProjectData?, String>((ref, id) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('projects')
      .select('*, brands(name, logo_asset), assets(city, country, address, built_surface_m2, usable_surface_m2, bedrooms, bathrooms, floor, year_built, year_renovated, terrace_m2, parking_spots, storage_room, orientation, views, has_elevator, floor_plan_url)')
      .eq('id', id)
      .maybeSingle();
  return data != null ? ProjectData.fromSupabaseRow(data) : null;
});
