# Backend Architecture — Principles

Canonical reference for data layer decisions in this project (Flutter + Supabase, CTI pattern for investment contracts, views-as-API). Read before any schema change. Short by design — do not let it bloat.

## Security model

This project uses **pure RLS + RLS isolation tests** as the authorization model (see ADR-36).

- **User-scoped views do NOT expose `user_id`** — row isolation is enforced by the RLS policies on the base tables, amplified by `security_invoker = true` on every view.
- **Client code does NOT filter by `user_id`** — no `.eq('user_id', ...)` anywhere. Providers still watch `currentUserIdProvider.distinct()` to force re-fetch on auth change.
- **Row isolation is verified by `docs/sql/tests/rls_user_isolation.sql`** — run on every user-scoped migration. Fails loud (assertion error) if policies leak.
- **Principle**: redundant client-side filters don't add security; they mask RLS bugs. The integration test is the real guardrail.

## Data principles

### 1. Single canonical source per concept
Every field has one owning table. Duplication across views is allowed only in two cases:
- **(a) Snapshot for immutability** — historical data that must NOT mutate when the source changes (e.g. `notifications.brand_name`, `notifications.project_name`).
- **(b) Display identity for lists** — small scalar fields the list row needs to render (e.g. `brand_name`, `brand_logo_asset`, `project_image_url` in `<model>_contract_details`).

Any other duplication requires an explicit justification comment in the migration header.

### 2. Request size ∝ screen needs
- Lists never carry detail-tab fields.
- Detail views never carry per-tab lazy content (phases, scenarios, payments).
- Tabs load lazily via `FutureProvider.family` when opened.

### 3. Computed > stored
Derived values (ROI, duration, yield_pct, is_sold flags) are computed in the view. Store only when the compute cost is significant AND the field is written from an external system (e.g. `coinvestment_contracts.actual_tir` comes from an external IRR calc, not a simple expression).

### 4. No speculative fields
A column that isn't rendered today is a dead column. Add fields when the consumer exists, not in anticipation. If a payment-tracking feature needs `accumulated_interest`, add the column when the UI is shipped — not before.

### 5. Schema evolution matches feature evolution
One feature → one migration. No "prepárate-para-después" batch migrations. If a view acquires fields across multiple features, each migration names the consumer that motivated the new field.

## Naming & consistency

### 6. Unified contract status
All contract tables use `status TEXT NOT NULL DEFAULT 'signed' CHECK (status IN ('pending','signed','cancelled'))` — only human-driven state on the contract document. "Finalizado" is a **UI projection** derived per domain in the view as `is_completed BOOLEAN` (from `sold_date` for purchase, `completion_date` for coinvestment, `maturity_date < CURRENT_DATE` for fixed income, `end_date < CURRENT_DATE` for rental). See ADR-44.

### 7. Column naming
`snake_case` in DB, `camelCase` in Dart, mapping in `fromJson`. Never expose two names for the same concept across the stack.

### 8. Views are first-class endpoints
No `_v` / `vw_` / `v_` prefixes. Views are API resources — name them like tables: plural, descriptive, no decoration.

## Architectural patterns

### 9. Contract/entity-details split (see ADR-35)
When a contract view is read in a list AND another view is read on the detail screen:
- `<model>_contract_details` (per-row, filtered by `user_id`, minimal)
- `<model>_<entity>_details` (per-project or per-asset, lazy, no user filter)

The two views must be **disjoint on columns** — identity fields live in contract only.

### 10. 1:N relationships never inline
Phases, scenarios, payments, documents are always loaded via separate providers (`projectPhasesProvider(projectId)`, etc.). Never materialized as JSONB arrays inside contract or project views.

### 11. Security invoker + schema reload
Every `CREATE/ALTER VIEW` ends with:
```sql
ALTER VIEW <name> SET (security_invoker = true);
NOTIFY pgrst, 'reload schema';
```
No exceptions. RLS must apply to the calling user.

### 12. Authorization canonical source is RLS (see ADR-36)
User-scoped views do NOT expose `user_id` as a column. Client code does NOT filter by `user_id`. Isolation is verified via `docs/sql/tests/rls_user_isolation.sql` on every user-scoped migration. Redundant client filters mask RLS bugs silently — don't add them.

## Anti-patterns (do NOT do)

- **JSONB for typed attributes** — use real columns (see ADR-33).
- **Denormalization beyond principles 1a/1b** — if you can't cite the principle, don't duplicate.
- **Orphan views** — no view without a documented Flutter consumer. Dropping them is cheaper than keeping them.
- **Renaming columns via REPLACE VIEW** — Postgres rejects this silently. Always `DROP VIEW + CREATE VIEW`.

Operational column-type rules (money as `NUMERIC(14,2)`, timestamps as `TIMESTAMPTZ`, enum-likes as `TEXT CHECK (...)`, etc.) are the implementer's checklist — see `CONVENTIONS.md § Column types` rather than duplicating them here.

### 13. Protected media: canonical URLs in DB, signed at read time (ADR-56)
Video URLs stored in DB (`projects.video_url`, `MediaItem.url`) are the raw canonical path — never signed/expiring. Before playback, clients call `playableVideoUrlProvider` (`lib/core/data/playable_video_url_provider.dart`) which routes to: (a) `sign_video_url` Edge Function for Bunny Stream URLs (HMAC-SHA256, TTL 1h, JWT verification — secret never leaves the function); (b) `createSignedUrl` for Supabase Storage relative paths. Never store a signed/expiring URL in the DB.

### 14. Push + in-app notifications: single row, dual channels, internal deep links
One `notifications` row per recipient per broadcast. Two boolean flags (`delivered_in_app`, `delivered_push`) describe which channels were used; CHECK forces at least one. The Flutter `notificationsProvider` filters `delivered_in_app = true` so push-only entries don't pollute the feed. OneSignal handles transport (binding via `OneSignal.login(userId)`). The admin Server Action talks to OneSignal REST directly — no Edge Function, no service-role key, no RPC for audience resolution (inline queries against `user_profiles` / contract tables are gated by the admin RLS policy). Deep links are internal GoRouter paths stored as a snapshot (`deep_link` column) — no Universal Links / AASA until they actually unlock a use case (email CTAs, public shares). The click handler in `lib/core/notifications/onesignal_service.dart` resolves the path via `appRouter.go()`; cold-start clicks are queued through `rootNavigatorKey` and flushed after the first frame.

## Extension protocol

When a new principle emerges from an incident:
1. Add it as principle #N here.
2. Reference it from the ADR that motivated it.
3. The next `/backend-review` will audit all existing views against it.

Do NOT let this doc grow past ~200 lines. If a principle gets too long, it becomes an ADR and stays as a one-line reference here.
