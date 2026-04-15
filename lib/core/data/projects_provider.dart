import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/project_data.dart';
import '../domain/user_role.dart';
import 'supabase_provider.dart';

final projectsProvider = FutureProvider<List<ProjectData>>((ref) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('projects')
      .select('*, brands(name, logo_asset)')
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
      .select('*, brands(name, logo_asset)')
      .eq('id', id)
      .maybeSingle();
  return data != null ? ProjectData.fromSupabaseRow(data) : null;
});

/// Featured projects carousel — curated per role, ordered by sort_order.
/// Each role has its own independent list (viewer / investor / investor_vip).
final featuredProjectsProvider =
    FutureProvider.family<List<ProjectData>, UserRole>((ref, role) async {
  final roleStr = switch (role) {
    UserRole.viewer => 'viewer',
    UserRole.investor => 'investor',
    UserRole.investorVip => 'investor_vip',
  };

  final data = await ref
      .watch(supabaseClientProvider)
      .from('featured_projects')
      .select('sort_order, projects(*, brands(name, logo_asset))')
      .eq('role', roleStr)
      .order('sort_order', ascending: true)
      .limit(5);

  return (data as List<dynamic>).map((e) {
    final row =
        (e as Map<String, dynamic>)['projects'] as Map<String, dynamic>;
    return ProjectData.fromSupabaseRow(row);
  }).toList();
});

/// Opportunities: projects the current user is NOT invested in.
/// Calls `get_opportunities(p_model, p_location)` RPC.
final opportunitiesProvider =
    FutureProvider.family<List<ProjectData>, Map<String, String?>>(
        (ref, params) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final rpcParams = <String, dynamic>{};
  if (params['model'] != null) rpcParams['p_model'] = params['model'];
  if (params['location'] != null) rpcParams['p_location'] = params['location'];
  final data = await ref
      .watch(supabaseClientProvider)
      .rpc('get_opportunities', params: rpcParams.isEmpty ? null : rpcParams);
  return (data as List<dynamic>)
      .map((e) => ProjectData.fromOpportunityRow(e as Map<String, dynamic>))
      .toList();
});
