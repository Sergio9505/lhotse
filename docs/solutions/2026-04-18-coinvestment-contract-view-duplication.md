---
date: 2026-04-18
tags: [supabase, views, coinvestment, purchase, schema-design, denormalization]
related_adrs: [ADR-35]
---

# Coinvestment contract view duplication (Allegro)

## Symptom
On the coinvestion detail screen (project Allegro), the ACTIVO tab showed renders + floor plan but **no asset info** (bedrooms, bathrooms, surface, etc.). Direct purchase contracts showed the same info correctly. The floor plan also looked "hardcoded" because the DB value happened to point to a local mock asset.

## Diagnosis
Three overlapping issues:

1. **Missing columns**: `coinvestment_contract_details` view already did `LEFT JOIN assets` but only selected `floor_plan_url`, `gallery_images`, `current_value`. The 15 typed asset fields (`bedrooms`, `bathrooms`, `surface_m2`, etc.) were joined but never selected.
2. **Dead floor plan code**: `coinversion_detail_screen.dart` lines 603-606 and 726-729 used `Image.asset('assets/images/mock_floor_plan.png')` instead of the `floorPlanUrl` it received.
3. **View architecture smell (the big one)**: the contract view shipped render_images, progress_images, 10 economics fields, and full asset metadata on **every row** — per-user, per-contract. For a coinvestion with N investors, the same project/asset data was duplicated N times in the response. Those heavy fields were only consumed inside detail tabs that already lazy-load.

After fixing 1+2, a deeper fix emerged: split the view into per-contract (minimal, user-filtered) + per-project (lazy, keyed by project_id). The same pattern applies to `purchase_contract_details`.

**Second-order bug**: in the first pass of the split, the new `coinvestment_project_details` view still carried `project_name`/`project_location` — fields the contract view already shipped for list rendering. Two co-loaded views with shared columns = waste that the user caught manually.

## Fix

**DB** (migrations applied in order):
- `coinvestment_views_split_contract_and_project_details` — created minimal contract view + new per-project view.
- `purchase_views_split_contract_and_asset_details` — mirrored pattern for purchase (asset detail separated by `asset_id`).
- `project_asset_detail_views_drop_duplicated_identity_fields` — removed `project_name`/`project_location` from coinvestment_project_details and `asset_name`/`asset_location` from purchase_asset_details (already in contract views).
- `db_cleanup_drop_dead_fields_and_rental_view` — dropped orphan `rental_contract_details` view, 6 dead fields from `fixed_income_contract_details`, `asset_current_value` from purchase_asset_details.

**Flutter**:
- `CoinvestmentContractData` + `PurchaseContractData`: stripped to list/hero fields only.
- New models: `CoinvestmentProjectDetails`, `PurchaseAssetDetails` with `assetInfo` / `economicAnalysis` getters.
- New providers: `coinvestmentProjectDetailProvider(projectId)`, `purchaseAssetDetailProvider(assetId)`.
- `CoinversionDetailScreen`, `DirectPurchaseDetailScreen`, `CompletedDetailScreen` updated to watch the new providers.
- Unhardcoded floor plan (LhotseImage handles both asset paths and URLs via its `startsWith('assets/')` check).

## Lesson
Views that ship heavy per-entity data (project, asset, economics) on every contract row are an anti-pattern when:
- Multiple contracts share the same entity (N investors, same project)
- The heavy fields are only consumed in detail tabs that already lazy-load

The correct pattern: **contract views per-row filtered by `user_id`, entity detail views per-entity loaded lazy**. See ADR-35.

The second-order lesson: **views loaded together on the same screen must be disjoint on columns**. DB alone can't detect co-loading — only the Flutter provider graph knows. This motivated the MIGRATION_CHECKLIST.md header block.

## How to avoid next time

1. Before creating any `<model>_*_details` view, open `docs/ARCHITECTURE.md` and apply principle #9 (contract/entity split) + #1 (single canonical source).
2. Fill the migration header per `docs/sql/MIGRATION_CHECKLIST.md` — the "Co-loaded pairs → disjoint verified" line forces the check.
3. Run `/backend-review` after any schema change touching co-loaded views. It cross-references `information_schema.view_column_usage` with Flutter providers and flags unjustified duplication.
4. The `~/.claude/rules/backend-architect.md` rule auto-activates on `*.sql` files — if you see it fire, the header is mandatory.
