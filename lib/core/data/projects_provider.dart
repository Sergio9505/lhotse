import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/project_data.dart';
import 'supabase_provider.dart';

final projectsProvider = FutureProvider<List<ProjectData>>((ref) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('projects')
      .select('*, brands(name, logo_asset), assets(city, country, address, built_surface_m2, usable_surface_m2, bedrooms, bathrooms, floor, year_built, year_renovated, terrace_m2, parking_spots, storage_room, orientation, views, has_elevator, floor_plan_url)')
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
