import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart' show rootNavigatorKey;
import '../../features/investments/data/investments_provider.dart';
import '../../features/investments/domain/coinvestment_contract_data.dart';
import '../../features/investments/domain/purchase_contract_data.dart';
import '../data/brands_provider.dart';
import '../domain/brand_data.dart';

/// Translates an admin-issued deep link (always shaped as `/<plural>/<id>`)
/// to the actual navigation target, applying smart routing for the two cases
/// where a user with a contract on the entity should land on their L3 detail
/// instead of the public-facing L1.
///
/// `/projects/{id}` resolves to `/investments/detail/coinvestment/{contract.id}`
/// when the user holds a coinvestment in that project; otherwise it stays at
/// `/projects/{id}`. `/assets/{id}` follows the same pattern against
/// purchase contracts. News and documents are routed verbatim.
Future<void> resolveAndNavigate(String path, WidgetRef ref) async {
  final segments = Uri.parse(path).pathSegments;
  if (segments.length == 2) {
    if (segments[0] == 'projects') {
      if (await _tryCoinvestmentL3(segments[1], ref)) return;
    } else if (segments[0] == 'assets') {
      if (await _tryPurchaseL3(segments[1], ref)) return;
    }
  }
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) {
    if (kDebugMode) debugPrint('[deep-link] no navigator yet for "$path"');
    return;
  }
  // The context comes from the root navigator key, not from a widget tree
  // observed during this async function — so the standard async-gap caveat
  // does not apply here.
  // ignore: use_build_context_synchronously
  ctx.go(path);
}

Future<bool> _tryCoinvestmentL3(String projectId, WidgetRef ref) async {
  try {
    final contracts = await ref.read(coinvestmentContractsProvider.future);
    CoinvestmentContractData? contract;
    for (final c in contracts) {
      if (c.projectId == projectId) {
        contract = c;
        break;
      }
    }
    if (contract == null) return false;
    final brandName = await _brandName(ref, contract.brandId);
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return false;
    // Root-navigator context — not subject to the async-gap rule.
    // ignore: use_build_context_synchronously
    ctx.go(
      '/investments/detail/coinvestment/${contract.id}',
      extra: (contract: contract, brandName: brandName),
    );
    return true;
  } catch (e) {
    if (kDebugMode) debugPrint('[deep-link] coinvestment lookup failed: $e');
    return false;
  }
}

Future<bool> _tryPurchaseL3(String assetId, WidgetRef ref) async {
  try {
    final contracts = await ref.read(purchaseContractsProvider.future);
    PurchaseContractData? contract;
    for (final c in contracts) {
      if (c.assetId == assetId) {
        contract = c;
        break;
      }
    }
    if (contract == null) return false;
    final brandName = await _brandName(ref, contract.brandId);
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return false;
    // Root-navigator context — not subject to the async-gap rule.
    // ignore: use_build_context_synchronously
    ctx.go(
      '/investments/detail/purchase/${contract.id}',
      extra: (contract: contract, brandName: brandName),
    );
    return true;
  } catch (e) {
    if (kDebugMode) debugPrint('[deep-link] purchase lookup failed: $e');
    return false;
  }
}

Future<String> _brandName(WidgetRef ref, String brandId) async {
  try {
    final brands = await ref.read(brandsProvider.future);
    for (final BrandData b in brands) {
      if (b.id == brandId) return b.name;
    }
  } catch (_) {/* fallthrough */}
  return '';
}
