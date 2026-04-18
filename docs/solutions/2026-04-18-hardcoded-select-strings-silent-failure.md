---
date: 2026-04-18
tags: [supabase, providers, postgrest, silent-failures]
related_adrs: [ADR-35]
---

# Hardcoded `.select()` string kept asking for dropped column — silent empty list

## Symptom
After dropping `brand_name` from `user_direct_purchases`, the L2 Strategy → "mis compras directas" section rendered empty rows (no asset name, location, thumbnail). No Dart compile error, no console exception.

## Diagnosis
`investments_provider.dart` had `const _kPurchaseListSelect = 'id, brand_id, asset_id, brand_name, purchase_value, sold_date, asset_name, ...'` — a hardcoded field list used by `brandPurchaseContractsProvider` for narrower payload on the L2 list. The constant still included `brand_name`, a column that no longer existed on the view.

PostgREST returned an error response that Riverpod surfaced as an empty list (the `.select()` call errored inside the async chain; the provider's error state wasn't displayed to the user because L2 uses `valueOrNull ?? const []`).

## Fix
Removed `brand_name` from `_kPurchaseListSelect` in `lib/features/investments/data/investments_provider.dart`.

## Lesson
**Hardcoded `.select('field1, field2, …')` strings are a silent-failure surface** that models don't catch. When a column is dropped from a view:

- **Model `fromJson`** fails loud at runtime if the reader expects the column and it's missing — easy to catch (null fields, assertion).
- **Hardcoded select strings** fail silent — PostgREST rejects the query, the provider returns `AsyncError` wrapped, and UIs that fall back to `const []` hide the problem completely.

**The sweep after any view change must include**:
1. All model `fromJson` readers (already covered by the flutter-analyzer + runtime crashes).
2. All `.from('<view>')` targets (covered — they're caught if the view is renamed).
3. **All hardcoded field lists in `.select('...')`** — grep for `\.select\('[^*]` (any select that's not `select()` or `select('*')`).

## How to avoid next time
- Prefer `.select()` (all columns) or `.select('*, brands(...)')` over hardcoded field lists. The savings from selecting fewer fields are marginal at this app's scale; the fragility cost is high.
- If a hardcoded list is justified (e.g. heavy jsonb columns we want to exclude from list payload), include a code comment referencing the view it targets so future edits notice the coupling.
- When editing a migration that drops columns: `grep -rn "<column_name>" lib/` before applying. The sweep must cover models AND provider select strings.
- The `backend-architect` rule has been updated to include this check in the mandatory sweep.
