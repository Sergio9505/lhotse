import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/supabase_provider.dart';
import '../../../core/domain/profit_scenario.dart';
import '../../../core/domain/project_phase.dart';
import '../domain/purchase_asset_details.dart';
import '../domain/purchase_contract_data.dart';
import '../domain/purchase_mortgage_details.dart';
import '../domain/coinvestment_contract_data.dart';
import '../domain/coinvestment_project_details.dart';
import '../domain/fixed_income_contract_data.dart';
import '../domain/portfolio_entry.dart';

// Authorization model: pure RLS (see docs/ARCHITECTURE.md Security model + ADR-36).
// User-scoped views do not expose user_id and providers do not filter by it.
// `currentUserIdProvider.distinct()` is still watched to force re-fetch on auth
// changes (logout + login as different user). Verified by
// docs/sql/tests/rls_user_isolation.sql.

// ── Purchase contracts ──────────────────────────────────────────────────────

final purchaseContractsProvider =
    FutureProvider<List<PurchaseContractData>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('user_direct_purchases')
      .select()
      .order('purchase_date', ascending: false);
  return (data as List<dynamic>)
      .map((e) => PurchaseContractData.fromJson(e as Map<String, dynamic>))
      .toList();
});

final brandPurchaseContractsProvider =
    FutureProvider.family<List<PurchaseContractData>, String>(
        (ref, brandId) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  // Full select: the L2 row uses a subset, but the contract is handed off to
  // the L3 `DirectPurchaseDetailScreen` via router extra (no refetch), so
  // the list must carry every field L3 renders (monthly_rent, yield, etc.).
  final data = await ref
      .watch(supabaseClientProvider)
      .from('user_direct_purchases')
      .select()
      .eq('brand_id', brandId);
  return (data as List<dynamic>)
      .map((e) => PurchaseContractData.fromJson(e as Map<String, dynamic>))
      .toList();
});

final purchaseContractByIdProvider =
    FutureProvider.family<PurchaseContractData?, String>((ref, id) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return null;
  final data = await ref
      .watch(supabaseClientProvider)
      .from('user_direct_purchases')
      .select()
      .eq('id', id)
      .maybeSingle();
  return data != null
      ? PurchaseContractData.fromJson(data)
      : null;
});

// ── Coinvestment contracts ──────────────────────────────────────────────────

final coinvestmentContractsProvider =
    FutureProvider<List<CoinvestmentContractData>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('user_coinvestments')
      .select()
      .order('created_at', ascending: false);
  return (data as List<dynamic>)
      .map((e) => CoinvestmentContractData.fromJson(e as Map<String, dynamic>))
      .toList();
});

final brandCoinvestmentContractsProvider =
    FutureProvider.family<List<CoinvestmentContractData>, String>(
        (ref, brandId) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('user_coinvestments')
      .select()
      .eq('brand_id', brandId);
  return (data as List<dynamic>)
      .map((e) => CoinvestmentContractData.fromJson(e as Map<String, dynamic>))
      .toList();
});

final purchaseMortgageDetailProvider =
    FutureProvider.family<PurchaseMortgageDetails, String>(
        (ref, purchaseContractId) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('purchase_mortgage_details')
      .select()
      .eq('purchase_contract_id', purchaseContractId)
      .single();
  return PurchaseMortgageDetails.fromJson(data);
});

final purchaseAssetDetailProvider =
    FutureProvider.family<PurchaseAssetDetails, String>(
        (ref, assetId) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('purchase_asset_details')
      .select()
      .eq('asset_id', assetId)
      .single();
  return PurchaseAssetDetails.fromJson(data);
});

final coinvestmentProjectDetailProvider =
    FutureProvider.family<CoinvestmentProjectDetails, String>(
        (ref, projectId) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('coinvestment_project_details')
      .select()
      .eq('project_id', projectId)
      .single();
  return CoinvestmentProjectDetails.fromJson(data);
});

// ── Fixed income contracts ──────────────────────────────────────────────────

final fixedIncomeContractsProvider =
    FutureProvider<List<FixedIncomeContractData>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('user_fixed_income_contracts')
      .select()
      .order('start_date', ascending: false);
  return (data as List<dynamic>)
      .map((e) => FixedIncomeContractData.fromJson(e as Map<String, dynamic>))
      .toList();
});

final brandFixedIncomeContractsProvider =
    FutureProvider.family<List<FixedIncomeContractData>, String>(
        (ref, brandId) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('user_fixed_income_contracts')
      .select()
      .eq('brand_id', brandId);
  return (data as List<dynamic>)
      .map((e) => FixedIncomeContractData.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Strategy screen aggregations ────────────────────────────────────────────

/// Single portfolio entry for a given brand — used as deep-link fallback on
/// the L2 "my investments in brand X" screen. Returns null if the user has
/// no investments in that brand (semantically: the L2 has nothing to show).
final userPortfolioEntryProvider =
    FutureProvider.family<PortfolioEntry?, String>((ref, brandId) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return null;
  final data = await ref
      .watch(supabaseClientProvider)
      .from('user_portfolio')
      .select()
      .eq('brand_id', brandId)
      .maybeSingle();
  return data != null ? PortfolioEntry.fromJson(data) : null;
});

final userPortfolioProvider =
    FutureProvider<List<PortfolioEntry>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('user_portfolio')
      .select()
      .order('total_amount', ascending: false);
  return (data as List<dynamic>)
      .map((e) => PortfolioEntry.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Set of `project_id` where the current user holds **any** contract —
/// coinvestment direct, or purchase resolved via `projects.asset_id`.
/// Status is ignored: signed, pending, cancelled and exited all count.
///
/// Fixed-income contracts are NOT included: their offerings are tied to a
/// brand, not to a project, so they never overlap with the
/// fundraising-open project set surfaced in "Nuevas oportunidades".
///
/// **Why query the base tables instead of the `user_*` views?** The views
/// (`user_coinvestments`, `user_direct_purchases`) rely on RLS to do the
/// per-user filtering, and the admin role has `is_admin() = true` which
/// grants read-all on contracts (intentional — that's how Strategy
/// surfaces platform-wide totals to operators logging into the investor
/// app, see DOMAIN.md § User Roles). For this provider we need a strictly
/// per-user set (we're filtering "Nuevas oportunidades" for THIS user, not
/// computing aggregates), so we hit the base tables with an explicit
/// `eq('user_id', userId)` to neutralise the admin read-all override.
///
/// Consumers: `_NewOpportunitiesSection` in `investments_screen.dart`
/// uses this to hide rows for projects the user already participates in.
final userContractedProjectIdsProvider =
    FutureProvider<Set<String>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return const {};
  final client = ref.watch(supabaseClientProvider);

  // (1) Coinvestment — project_id is on the contract row.
  final coinvRows = await client
      .from('coinvestment_contracts')
      .select('project_id')
      .eq('user_id', userId);
  final coinvIds = (coinvRows as List<dynamic>)
      .map((r) => (r as Map<String, dynamic>)['project_id'] as String?)
      .whereType<String>()
      .toSet();

  // (2) Purchase — only asset_id on the contract; resolve to project via
  // the projects.asset_id FK in a single follow-up batch query.
  final purchaseRows = await client
      .from('purchase_contracts')
      .select('asset_id')
      .eq('user_id', userId);
  final assetIds = (purchaseRows as List<dynamic>)
      .map((r) => (r as Map<String, dynamic>)['asset_id'] as String?)
      .whereType<String>()
      .toList(growable: false);

  final purchaseIds = assetIds.isEmpty
      ? <String>{}
      : ((await client
                  .from('projects')
                  .select('id')
                  .inFilter('asset_id', assetIds)) as List<dynamic>)
          .map((r) => (r as Map<String, dynamic>)['id'] as String)
          .toSet();

  return coinvIds.union(purchaseIds);
});

// ── Coinvestment sub-data (scenarios + phases) ───────────────────────────────

final projectScenariosProvider =
    FutureProvider.family<List<ProfitScenario>, String>((ref, projectId) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('project_scenarios')
      .select()
      .eq('project_id', projectId)
      .order('sort_order', ascending: true);
  return (data as List<dynamic>)
      .map((e) => ProfitScenario.fromJson(e as Map<String, dynamic>))
      .toList();
});

final projectPhasesProvider =
    FutureProvider.family<List<ProjectPhase>, String>((ref, projectId) async {
  final data = await ref
      .watch(supabaseClientProvider)
      .from('project_phases')
      .select()
      .eq('project_id', projectId)
      .order('sort_order', ascending: true);
  return (data as List<dynamic>)
      .map((e) => ProjectPhase.fromJson(e as Map<String, dynamic>))
      .toList();
});
