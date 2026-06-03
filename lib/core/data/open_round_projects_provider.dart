import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/project_data.dart';
import 'supabase_provider.dart';

/// Projects currently accepting new investors (`is_fundraising_open = true`)
/// **offered to the current user**, ordered by the operator's manual
/// `sort_order` (admin /projects/reorder), with `created_at DESC` as
/// tie-breaker. Feeds the "Nuevos proyectos" section of the Strategy screen.
/// The screen further filters out projects where the current user already has
/// a contract (see investments_screen.dart).
///
/// Reads the `user_open_round_projects` view (`security_invoker`, ADR-92), which
/// applies the per-user offer curation server-side: a project marked
/// `is_audience_restricted` is only returned to users listed in
/// `project_audience`; unrestricted ones are returned to everyone. The view
/// exposes `brands`/`assets` as nested jsonb so the rows hydrate via the shared
/// `ProjectData.fromSupabaseRow` parser unchanged — do not diverge from that
/// shape without updating the parser too.
///
/// NOTE: this curation is offer-only (it never gates *access*). The project
/// stays visible in the catalogue (Firmas→Proyectos), Buscar, its detail and
/// the investor's own firma — those read `projects` directly, not this view.
final openRoundProjectsProvider =
    FutureProvider<List<ProjectData>>((ref) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('user_open_round_projects')
      .select('*')
      .order('sort_order', ascending: true)
      .order('created_at', ascending: false);
  return (data as List<dynamic>)
      .map((e) => ProjectData.fromSupabaseRow(e as Map<String, dynamic>))
      .toList();
});
