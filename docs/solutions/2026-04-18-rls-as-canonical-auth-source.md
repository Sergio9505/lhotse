---
date: 2026-04-18
tags: [supabase, rls, security, authorization, views]
related_adrs: [ADR-36]
---

# Redundant user_id filter masking RLS bugs

## Symptom
While auditing user-scoped views (`user_portfolio`, `user_direct_purchases`, etc.), the schema had `user_id` in every view + every client provider did `.eq('user_id', userId)`. Also: RLS policies on the base tables (`user_id = auth.uid()`). The filter was applied twice. Code felt defensive but was actually noise.

## Diagnosis
Two independent layers were enforcing the same rule:
- **RLS on base tables** (canonical, server-side, runs before the view sees any row).
- **Client filter `.eq('user_id', userId)`** (redundant, consumes bandwidth + parsing).

The client filter is marketed as "defense in depth" but in practice it's worse than useless because it **masks RLS bugs silently**. If someone deploys a broken RLS policy tomorrow, the client filter still returns 0 rows — the UI looks fine, no assertion fails, no user complains. Meanwhile, any code path that doesn't replicate the filter (new screens, SQL editors, admin tools) would leak.

The actual guardrail is a **test that asserts user A can't see user B's data**. Tests fail loud; redundant filters fail silent.

## Fix
- Dropped `user_id` column from 4 views: `user_portfolio`, `user_direct_purchases`, `user_coinvestments`, `user_fixed_income_contracts`.
- Dropped `.eq('user_id', userId)` from all 8 providers that read these views.
- Dropped `userId` field from `PurchaseContractData`, `FixedIncomeContractData` (already gone from coinvestment).
- Added `docs/sql/tests/rls_user_isolation.sql` — impersonates two users via `set_config('request.jwt.claims', …)`, asserts zero cross-user leakage for each view.
- Documented the decision: ADR-36 + new "Security model" section in ARCHITECTURE.md + principle #12 + checklist step 8 in MIGRATION_CHECKLIST.md.

## Lesson
**Redundant authorization filters don't add security; they hide bugs.** One canonical source per concept (principle #1 applied to auth): RLS decides access, the client trusts it. The compensation is a test that fails loud if RLS breaks.

Same failure mode applies to any duplicated validation/authorization logic across layers — if both layers "agree", the second one does nothing; if they disagree, you get silent inconsistency.

## How to avoid next time
1. Migrations touching user-scoped views must tick step 8 of `docs/sql/MIGRATION_CHECKLIST.md` (run `rls_user_isolation.sql`).
2. The backend-architect rule (auto-activated on `*.sql` edits) points to ARCHITECTURE.md Security model.
3. `/backend-review` flags any view that exposes `user_id` as a column on a user-scoped table as a deviation from ADR-36.
