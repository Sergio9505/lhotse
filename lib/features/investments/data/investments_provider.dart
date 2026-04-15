import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/supabase_provider.dart';
import '../../../core/domain/profit_scenario.dart';
import '../../../core/domain/project_phase.dart';
import '../domain/purchase_contract_data.dart';
import '../domain/coinvestment_contract_data.dart';
import '../domain/fixed_income_contract_data.dart';
import '../domain/investment_summary.dart';

// ── Purchase contracts ──────────────────────────────────────────────────────

final purchaseContractsProvider =
    FutureProvider<List<PurchaseContractData>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('purchase_contract_details')
      .select()
      .eq('user_id', userId)
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
  final data = await ref
      .watch(supabaseClientProvider)
      .from('purchase_contract_details')
      .select()
      .eq('user_id', userId)
      .eq('brand_id', brandId);
  return (data as List<dynamic>)
      .map((e) => PurchaseContractData.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Coinvestment contracts ──────────────────────────────────────────────────

final coinvestmentContractsProvider =
    FutureProvider<List<CoinvestmentContractData>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('coinvestment_contract_details')
      .select()
      .eq('user_id', userId)
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
      .from('coinvestment_contract_details')
      .select()
      .eq('user_id', userId)
      .eq('brand_id', brandId);
  return (data as List<dynamic>)
      .map((e) => CoinvestmentContractData.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Fixed income contracts ──────────────────────────────────────────────────

final fixedIncomeContractsProvider =
    FutureProvider<List<FixedIncomeContractData>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('fixed_income_contract_details')
      .select()
      .eq('user_id', userId)
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
      .from('fixed_income_contract_details')
      .select()
      .eq('user_id', userId)
      .eq('brand_id', brandId);
  return (data as List<dynamic>)
      .map((e) => FixedIncomeContractData.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ── Strategy screen aggregations ────────────────────────────────────────────

final brandSummariesProvider =
    FutureProvider<List<BrandInvestmentSummaryData>>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return [];
  final data = await ref
      .watch(supabaseClientProvider)
      .from('brand_investment_summaries')
      .select()
      .eq('user_id', userId)
      .order('total_amount', ascending: false);
  return (data as List<dynamic>)
      .map((e) => BrandInvestmentSummaryData.fromJson(e as Map<String, dynamic>))
      .toList();
});

final portfolioSummaryProvider =
    FutureProvider<PortfolioSummary?>((ref) async {
  final userId = ref.watch(currentUserIdProvider).valueOrNull;
  if (userId == null) return null;
  final data = await ref
      .watch(supabaseClientProvider)
      .from('portfolio_summaries')
      .select()
      .eq('user_id', userId)
      .maybeSingle();
  return data != null ? PortfolioSummary.fromJson(data) : null;
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
