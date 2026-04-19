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

const _kPurchaseListSelect =
    'id, brand_id, asset_id, '
    'purchase_value, sold_date, status, is_completed, '
    'asset_name, asset_location, asset_thumbnail_image';

final brandPurchaseContractsProvider =
    FutureProvider.family<List<PurchaseContractData>, String>(
        (ref, brandId) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('user_direct_purchases')
      .select(_kPurchaseListSelect)
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
