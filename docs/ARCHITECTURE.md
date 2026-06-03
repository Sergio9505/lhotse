# Backend Architecture — Principles

Canonical reference for data layer decisions in this project (Flutter + Supabase, CTI pattern for investment contracts, views-as-API). Read before any schema change. Short by design — do not let it bloat.

## Security model

This project uses **pure RLS + RLS isolation tests** as the authorization model (see ADR-36).

- **User-scoped views do NOT expose `user_id`** — row isolation is enforced by the RLS policies on the base tables, amplified by `security_invoker = true` on every view.
- **Per-user *offer* curation via view** (`user_open_round_projects`, ADR-92): a `security_invoker` view filtering fundraising projects to those offered to `auth.uid()` — `is_fundraising_open AND (NOT is_audience_restricted OR EXISTS(project_audience WHERE user_id = auth.uid()))`. The boolean lives on `projects` (the view reads it freely); membership lives in `project_audience` (own-row RLS). This is **offer-only**, NOT an access boundary — `projects` carries no restrictive RLS, so the catalogue/Buscar/detail/firma stay visible to all (an investor with a contract never loses access). Inferring "restricted?" from the table alone would need a `SECURITY DEFINER` function (own-row RLS hides other users' rows), so the derived boolean is the clean fit.
- **Client code does NOT filter by `user_id`** — no `.eq('user_id', ...)` anywhere. Providers still watch `currentUserIdProvider.distinct()` to force re-fetch on auth change.
- **Row isolation is verified by `docs/sql/tests/rls_user_isolation.sql`** — run on every user-scoped migration. Fails loud (assertion error) if policies leak.
- **Admin role expansion**: the RLS policies on `purchase_contracts`, `coinvestment_contracts` and `fixed_income_contracts` evaluate `auth.uid() = user_id OR is_admin()`. Admins read every row platform-wide — deliberate, because the admin Server Action depends on it for audience resolution (see § Notifications). The investor app surfaces this as if it were the admin's own portfolio: Strategy renders the totals of the entire platform when the logged-in user is an admin. This is **not** a leak — it's the same `is_admin()` helper that gates storage writes and `user_requests` CRUD. The `rls_user_isolation.sql` test validates that **non-admin** users remain scoped.
- **Principle**: redundant client-side filters don't add security; they mask RLS bugs. The integration test is the real guardrail.
- **`auth.users` gotcha for views**: el rol `authenticated` NO tiene grant `SELECT` sobre `auth.users` (solo `postgres` lo tiene). Una view con `security_invoker = true` que haga `FROM auth.users` devolverá **0 filas** cuando la consulte el cliente Flutter, aunque la lógica de la view sea correcta. Cuando hace falta el `user_id` del caller dentro de una view, usar **`auth.uid()`** (función SQL, siempre accesible) en lugar de `FROM auth.users`. Bug histórico: `latest_user_consents` v1 devolvía null al cliente y causaba un loop infinito en el consent gate; fix en migración `20260520200000_latest_user_consents_self_only.sql` (ADR-73).
- **Append-only consent log + RPC para audit-grade IP**: para tablas auditadas tipo `consent_log` que necesitan capturar IP + user-agent del request HTTP, el patrón es **insertar via RPC `SECURITY DEFINER`** que lee `current_setting('request.headers', true)::json` para obtener esos campos server-side. El cliente nunca los envía (los podría falsificar). Ver `record_consent` en la migración 20260520180000.
- **Asset visibility — ownership OR coinversion-public** (migración `20260521150000_assets_ownership_rls.sql`): la tabla `assets` tiene dos políticas SELECT OR'd. Un asset es visible si: (a) `users_read_own_purchased_assets` — el user tiene un `purchase_contracts` row para él (compra directa, e.g. Andhy); o (b) `public_read_coinversion_assets` — el asset está referenciado por algún `projects` row (es parte de una oferta de coinversión, públicamente investable). Activos huérfanos (sin proyecto ni contrato) quedan invisibles a non-admin. Esto cierra el leak previo (`USING (true)`) que permitía a non-owners ver activos de compra directa en el buscador. La regla expresa el modelo de negocio — no hardcodea ninguna marca — así que cualquier brand futura de compra directa hereda automáticamente la privacidad. Los joins públicos (`projects_provider` → `assets`, `news_provider` → `projectAsset:assets(city)`) siguen funcionando porque sus assets siempre están vinculados a un projects row, cubiertos por la policy (b).

## Data principles

### 1. Single canonical source per concept
Every field has one owning table. Duplication across views is allowed only in two cases:
- **(a) Snapshot for immutability** — historical data that must NOT mutate when the source changes (e.g. `notifications.brand_name`, `notifications.project_name`).
- **(b) Display identity for lists** — small scalar fields the list row needs to render (e.g. `brand_name`, `brand_logo_asset`, `project_image_url` in `<model>_contract_details`; `news.image_url` and `projects.image_url` as denormalized covers for catalog grids alongside their `hero_media` jsonb).

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
No exceptions. RLS must apply to the calling user — including the admin policy (`is_admin()`), which **expands** what the user can read but does not bypass the RLS layer (see § Security model).

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
One `notifications` row per recipient per broadcast. Two boolean flags (`delivered_in_app`, `delivered_push`) describe which channels were used; CHECK forces at least one. The Flutter `notificationsProvider` filters `delivered_in_app = true` so push-only entries don't pollute the feed. OneSignal handles transport (binding via `OneSignal.login(userId)`). The admin Server Action talks to OneSignal REST directly — no Edge Function, no service-role key, no RPC for audience resolution (inline queries against `user_profiles` / contract tables are gated by the admin RLS policy).

Notification types are **object-shaped** (`project | asset | news | document`), composed server-side as `/<plural>/<entityId>` deep links — admin never types a raw URL. The Flutter side runs a smart resolver (`lib/core/notifications/deep_link_resolver.dart`) before navigating: `/projects/<id>` is rewritten to the user's L3 coinvestment detail if they hold one in that project (otherwise L1 commercial); `/assets/<id>` follows the same pattern against purchase contracts. `/news/<id>` is verbatim. `/documents/<id>` lands on a loader screen that downloads and `pushReplacement`s into `/document-preview`. Cold-start clicks are queued through `rootNavigatorKey` and flushed after the first frame. No Universal Links / AASA until they unlock a real use case (email CTAs, public shares).

## Extension protocol

When a new principle emerges from an incident:
1. Add it as principle #N here.
2. Reference it from the ADR that motivated it.
3. The next `/backend-review` will audit all existing views against it.

Do NOT let this doc grow past ~200 lines. If a principle gets too long, it becomes an ADR and stays as a one-line reference here.
