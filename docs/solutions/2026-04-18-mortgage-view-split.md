---
date: 2026-04-18
tags: [supabase, views, purchase, mortgage, lazy-loading]
related_adrs: [ADR-35]
---

# Mortgage fields leaking into the L2 list view

## Symptom
The 4 mortgage columns (`mortgage_principal`, `mortgage_monthly_payment`, `mortgage_end_date`, `mortgage_conditions`) were part of `user_direct_purchases`, so every L2 list row carried them. These fields are only rendered inside the L3 FINANCIACIÓN tab — never in the L2 row nor in the L3 hero.

## Diagnosis
Same anti-pattern that motivated ADR-35 (the asset physical characteristics split). The principle "always visible → main view; click-gated → lazy view" was partially applied (asset physical data moved to `purchase_asset_details`) but not extended to mortgage.

Root reason for the oversight: the `_FinancingTab` gate (`if (c.hasFinancing)`) was computed from `c.mortgagePrincipal != null`, which meant keeping the field on the contract data to know whether to show the tab at all. Easy trap.

## Fix

- New DB view `purchase_mortgage_details` keyed by `purchase_contract_id`, carrying the 4 mortgage fields. `security_invoker = true`; RLS inherits from the `mortgages` policy that checks ownership via `purchase_contracts.user_id`.
- `user_direct_purchases` rebuilt without the 4 fields, but now carries a lightweight `has_financing BOOLEAN` computed as `m.principal IS NOT NULL` — so the L3 can decide whether to show the FINANCIACIÓN tab without any extra query.
- `PurchaseContractData` drops the 4 fields; `hasFinancing` becomes a real `bool` field (no longer computed).
- New `PurchaseMortgageDetails` model + `purchaseMortgageDetailProvider(contractId)` lazy provider.
- `_FinancingTab` now accepts `PurchaseMortgageDetails?` — renders a spinner while loading, then the 4 entries. Only fetched when the contract has financing AND the user navigates into the L3.

## Lesson
When splitting tab-specific data into a lazy view, keep a **boolean "does this exist?" flag** in the main view to gate tab visibility. That costs 1 byte per row and saves a full query per hero open when the user never visits the tab. The flag is the mental trick that avoids the "but I need to know if the tab should appear" trap that kept us from splitting earlier.

## How to avoid next time
- Before committing any new field to a main contract view, ask: "is this rendered on the hero or list? If only inside a tab, it belongs in a lazy view."
- Prefer a boolean `has_<feature>` field for gating over inlining the feature's full data.
- The `backend-architect` rule now lists this explicitly under principle #2 application.
