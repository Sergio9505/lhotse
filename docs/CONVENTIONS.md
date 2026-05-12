# Conventions

## File Structure
- Feature-first: `lib/features/{name}/{data,domain,presentation}/`
- Shared code: `lib/core/` (data, domain, theme, widgets)
- Models: `lib/features/{name}/domain/{name}.dart` + `.freezed.dart` + `.g.dart`

## Naming
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables / functions: `camelCase`
- Providers: `{name}Provider` (e.g. `projectsProvider`)
- Repositories: `{Name}Repository` (e.g. `ProjectRepository`)
- Controllers: `{Name}Controller` extends `StateNotifier`
- **DB ↔ Dart boundary**: DB uses `snake_case` (tables, columns, views — see § Database below); Dart uses `camelCase`. Mapping happens in `fromJson` / model factories, never in the UI.

## State Management (Riverpod)
- `ref.watch()` for reactive data, `ref.read()` for one-off actions (callbacks)
- `AsyncValue<T>` for async state: loading → data | error
- **Primary content** (the list or section the user came to see) always uses `.when(loading, error, data)` — never `valueOrNull ?? []`. `LhotseAsyncLoading` + `LhotseAsyncError` in `core/widgets/lhotse_async_list_states.dart` provide the canonical UI for these states.
- **Decoration** (icon maps, subtitle enrichment, counters/badges, hero-transition-gap fallbacks) may use `valueOrNull` — graceful degradation is correct there.
- Invalidate providers on mutations: `ref.invalidate(provider)`
- Per-user providers: watch auth state stream when Supabase is connected

## Models (Freezed)
- `abstract class Foo with _$Foo`
- `@freezed` annotation
- Factory constructor + `fromJson`
- Run `dart run build_runner build --delete-conflicting-outputs` after changes

## Database (Supabase / PostgreSQL)

### Column types
- IDs: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
- Timestamps: `TIMESTAMPTZ NOT NULL DEFAULT NOW()` — always include `created_at`, `updated_at` on mutable tables
- Enum-like values: **`TEXT NOT NULL CHECK (col IN (...))`** — never `CREATE TYPE AS ENUM` (enums can't remove/rename values)
- Money: `NUMERIC(14,2)` — never `FLOAT`/`DOUBLE`
- Percentages: `NUMERIC(5,2)` or `NUMERIC(6,2)`
- Display-only arrays (galleries, freeform key-value extras): `JSONB DEFAULT '[]'`
- Typed property attributes (bedrooms, floor, orientation, built_surface_m2…): **individual `NUMERIC`/`INTEGER`/`TEXT` columns** — never JSONB
- Queryable child data (scenarios, phases, documents): **separate table** with FK

### Naming
- Tables: `snake_case`, **plural** (`brands`, `investments`, `documents`)
- Columns: `snake_case` (`brand_id`, `created_at`, `is_completed`)
- Views: `snake_case`, **plural, no prefix** — treat like tables (`portfolio_summaries`, `investment_details`). The Supabase dashboard already differentiates tables from views visually.
- Constraints: `chk_{column}` for CHECK, `idx_{table}_{column}` for indexes, `trg_{table}_{event}` for triggers
- Foreign keys: `{referenced_table_singular}_id` (`brand_id`, `user_id`, `project_id`)

### Views — mandatory rules
> Canonical principles in `ARCHITECTURE.md § Security model` + `§ Architectural patterns`. The list below is the operational checklist.

1. **Always** `ALTER VIEW {name} SET (security_invoker = true)` — ensures RLS applies to the calling user, not the view owner
2. **Always** `NOTIFY pgrst, 'reload schema'` after creating/altering views — flushes PostgREST cache
3. No `v_` or `_` prefix — views are first-class API endpoints
4. **Pluralization**: views are plural by default (like tables). Exception: when the scope is semantically singular per filter (one portfolio per user, one profile per user, etc.), singular is allowed if it reads better. Justify the exception in the migration header.

### RLS
- Enable on every table: `ALTER TABLE {name} ENABLE ROW LEVEL SECURITY`
- Public read tables (brands, projects, news): allow `SELECT` for `anon` and `authenticated`
- User-scoped tables (investments, notifications): `WHERE user_id = auth.uid()`
- Child tables (documents, phases, scenarios): ownership check via parent: `EXISTS (SELECT 1 FROM investments WHERE id = X.investment_id AND user_id = auth.uid())`
- Admin write operations (brands, projects, news): managed via Supabase dashboard or service_role key, not RLS
- **Pure RLS + isolation tests model** — user-scoped views don't expose `user_id`; clients don't filter by it. See ADR-36 + `docs/ARCHITECTURE.md` "Security model".

### Enum values — always English
- DB values use English snake_case: `direct_purchase`, `in_development`, `fixed_income`
- Flutter enum values use English camelCase: `directPurchase`, `inDevelopment`, `fixedIncome`
- Spanish display names go in Flutter extensions: `BusinessModel.directPurchase.displayName` → `"Adquisición"`
- `@JsonValue('direct_purchase')` on Flutter enums for automatic serialization

### Triggers
- `updated_at`: use shared `update_updated_at()` function on all mutable tables
- `handle_new_user()`: fires on `auth.users` INSERT — creates profile + preferences + KYC rows

### Migrations
- Name: `NN_snake_case_description` (e.g. `01_user_tables`, `07_rls_policies`)
- **Never modify** an applied migration — always create a new one
- One concern per migration (tables, then views, then RLS — not all mixed)
- Use `IF NOT EXISTS` / `IF EXISTS` where idempotency matters
- Always end with `NOTIFY pgrst, 'reload schema'` if the migration touches views, functions, or schema structure

### Timestamps
- **Always `TIMESTAMPTZ`** — never bare `TIMESTAMP` (loses timezone info)
- Store in UTC (PostgreSQL default)
- Format to local time in Flutter, never in SQL
- `created_at`: immutable, set on INSERT — never update
- `updated_at`: managed by `update_updated_at()` trigger

### Delete behavior
- **`ON DELETE CASCADE`**: parent → children that have no meaning without parent (investments → documents, investments → phases)
- **`ON DELETE SET NULL`**: optional references (notifications.investment_id — notification survives if investment is deleted)
- **`ON DELETE RESTRICT`** (or no action): prevent deleting referenced data (brands → projects — don't delete a brand that has projects)
- No soft deletes for now — hard delete is simpler. Add `deleted_at` only when audit trail is legally required.

### Pagination
- Use **range-based** pagination via Supabase `.range(from, to)` — maps to PostgreSQL `LIMIT/OFFSET`
- Default page size: 20 items
- For infinite scroll lists (news, notifications): use cursor-based with `created_at` + `id` as cursor for stable ordering
- Home screen carousels: `LIMIT 5`, no pagination

### JSONB rules
- **Use JSONB** when: data is display-only, variable-shape, never filtered/joined/aggregated individually (gallery_images, render_images, progress_images)
- **Use typed columns** when: the schema is known and stable, even if the fields are many (see `projects.purchase_price`, `built_sqm`, `itp_amount`, etc. — ex-`economic_analysis` JSONB, migrated to 10 typed columns + GENERATED `total_cost`. ADR-42)
- **Use a separate table** when: data needs individual filtering, sorting, or FK relationships (documents, phases, scenarios)
- JSONB arrays: always default to `'[]'`, never `NULL`
- JSONB objects: default to `NULL` when the whole block is optional

### Storage buckets
- Naming: `kebab-case` (Supabase convention)
- Public buckets (brand-assets, project-images): anyone can read, only service_role writes
- Private buckets (documents, kyc-documents, avatars): RLS-scoped read/write
- File paths: `{owner_id}/{filename}` — owner is brand_id, project_id, user_id, or investment_id
- Max file size: configure per bucket in Supabase dashboard
- Accepted MIME types: configure per bucket (images: `image/*`, documents: `application/pdf`)

### Video fields — contract
All video URL fields in this project (`projects.video_url`, `MediaItem.url` when `type == 'video'`) must satisfy:
- **Format**: MP4 progressive (H.264). HLS (`.m3u8`) is NOT supported — `video_player` handles it unreliably on Android.
- **DB value**: the raw canonical URL (e.g. `https://vz-…b-cdn.net/…/play_1080p.mp4`). Never store signed/expiring URLs in DB.
- **Resolution**: 1080p preferred; 720p / 480p accepted for lower-bandwidth content.
- **Origin**: Bunny Stream (Token Authentication ON, MP4 fallback enabled) or Supabase Storage private bucket (`project-videos`). The client resolves both through `playableVideoUrlProvider`.

**Playback contract — never pass a raw DB URL directly to `LhotseVideoPlayer` or `FullscreenVideoPlayer`:**
```dart
// Correct: resolve signed URL first
final signedVideoUrl = rawUrl?.isNotEmpty == true
    ? ref.watch(playableVideoUrlProvider(rawUrl!)).valueOrNull
    : null;
// signedVideoUrl is null while signing resolves → hero falls back to poster image
```
`playableVideoUrlProvider` (`lib/core/data/playable_video_url_provider.dart`) branches by URL shape:
- `https://vz-*` → Supabase Edge Function `sign_video_url` (Bunny HMAC-SHA256, TTL 1h)
- `http*` non-Bunny → passthrough (demo/staging only)
- relative path → `Supabase.instance.client.storage.from('project-videos').createSignedUrl(path, 3600)`

Detail views that expose `video_url` to investment L3 screens:
- `coinvestment_project_details.video_url` ← `projects.video_url`
- `purchase_asset_details.video_url` ← `projects.video_url` (correlated subquery via `projects.asset_id`)

### Edge Functions
- Naming: `snake_case` matching the function's action (`sign_video_url`, not `videoSigner`)
- Location: `supabase/functions/<name>/index.ts` (Deno)
- **Always** verify JWT at the start: create a `supabaseClient` with the `Authorization` header and call `.auth.getUser()`. Return 401 if missing or invalid.
- **Never** commit secret values — use `supabase secrets set KEY=value`. Reference via `Deno.env.get('KEY')`.
- Whitelist inputs explicitly (allowed hosts, IDs) — do not trust raw client input.

### Supabase Client (Flutter SDK)
- Single client instance via provider: `Supabase.instance.client`
- Queries return `List<Map<String, dynamic>>` — always map to domain models in the repository, never pass raw maps to UI
- Error handling: catch `PostgrestException` in repositories, convert to domain errors
- `.order()` defaults to **descending** — always pass `ascending: true` explicitly for ASC
- Use `.select('*, brands(*)')` for JOINs via FK relationships — PostgREST resolves them automatically
- Prefer views over complex `.select()` with nested JOINs for readability

---

## Data Layer

Supabase is fully connected. Providers read through `Supabase.instance.client` directly from `lib/core/data/` and map raw rows to Freezed domain models inside the provider / repository (never in the UI). The `lib/core/data/mock/` directory is a historical artefact of the mock-first phase (ADR-2, now **Superseded**); it is empty — do not reintroduce mocks.

Provider conventions:
- One provider file per domain (`projects_provider.dart`, `news_provider.dart`, …).
- Per-user providers watch `currentUserIdProvider` (`.distinct()`) — see **Auth Flow** below — to force a fresh fetch on auth change. Never read `supabaseAuthProvider.currentUser` directly for cache keys.
- Mutations call `ref.invalidate(provider)` to force re-fetch; UI reconciles via `AsyncValue`.
- **`documentsProvider`** (L3 Docs tab) loads multiple scopes per investment type: coinversión → investor + project; compra directa → investor + asset + rental (if exists); renta fija → investor only. Single OR query via PostgREST `.or()` after a PK sub-fetch of the contract's `project_id`/`asset_id`. Never add scope logic at the callsite — it lives inside `_fetchDocuments`.

## Navigation (GoRouter)
- Named routes with path params: `/brands/:id`
- Auth guard: redirect unauthenticated users to login
- Role guard: redirect viewers away from /investments
- Use `context.push()` / `context.go()` — never `Navigator.push()`

## Error Handling
- Repository methods return data directly, throw on error
- Controllers catch and set `AsyncValue.error()`
- UI shows 3 states: loading (skeleton), error (retry), data (content)

## Assets
- Images in `assets/images/`
- Icons in `assets/icons/` (prefer SVG)
- Fonts in `assets/fonts/`

## Scroll + Tabs Patterns

### When to use each pattern:
| Pattern | Use When | Example |
|---------|----------|---------|
| `ListView` / `CustomScrollView` | Simple vertical scroll, no tabs, no collapsing headers | AllProjects, Search results |
| `SliverAppBar` (pinned) | Collapsing hero image → pinned title on scroll. No tabs. | ProjectDetail |
| `SliverPersistentHeader` | A single sticky section header within a scroll | BrandInvestments sticky labels |
| **`NestedScrollView` + `SliverAppBar` + `TabBarView`** | Collapsing header + pinned tabs + independent scroll per tab | CoinversionDetail |

### NestedScrollView pattern (for tabbed detail screens):
```dart
DefaultTabController(
  length: tabCount,
  child: NestedScrollView(
    headerSliverBuilder: (context, innerBoxIsScrolled) => [
      SliverAppBar(
        pinned: true,
        expandedHeight: heroHeight,
        title: collapsedTitle,       // fades in natively on collapse
        bottom: TabBar(tabs: [...]), // always pinned
        flexibleSpace: FlexibleSpaceBar(
          background: headerContent, // hero + identity — scrolls away
        ),
      ),
    ],
    body: TabBarView(
      children: [tab1, tab2, tab3],  // each scrolls independently
    ),
  ),
)
```

### Rules:
- **Never manually track collapse state** with scroll listeners + hardcoded thresholds. Flutter's `SliverAppBar` handles title fade-in natively.
- **Never use `AnimatedSwitcher` for tab content** — it destroys and rebuilds widgets, losing state. Use `TabBarView` or `IndexedStack`.
- **Never put tabs in SliverAppBar `bottom` AND identity data in a separate sliver** — this creates duplicate-info states during scroll. Keep everything that collapses inside `flexibleSpace`.
- If a change requires hacking scroll offsets or managing multiple boolean flags (`_heroGone`, `_identityGone`), the architecture is wrong — restructure.

## Auth Flow

Supabase Auth via `AuthRepository` (`lib/features/auth/data/auth_repository.dart`). Email + password as primary credentials; phone (E.164) is **mandatory** at signup and used for SMS OTP — both as signup phone verification and as the password-recovery factor. SMS provider is **Twilio**, configured in Supabase dashboard (no OneSignal in this flow — see ADR-63).

### Screens
- `WelcomeScreen` — fullscreen video loop via `video_player` with a Ken Burns static-image fallback while the video loads (`AnimationController` 12s, scale 1.0 → 1.08, repeat). Velvet multi-stop gradient over 65% height, 44px logo, tagline 13px w400 white 75% letterSpacing 2.0, single outline CTA "INICIAR SESIÓN" (0.5px border).
- `LoginScreen` — beige background, header + `LhotseAuthField` for email/password + forgot-password link (routes to `/forgot-password`).
- `SignUpScreen` — name + email + **phone** + password. On submit, Supabase sends an SMS OTP; the screen pushes `/otp-verify` with `OtpPurpose.signupVerification`.
- `ForgotPasswordScreen` — phone input. Calls `sendPhoneOtp` and routes to `/otp-verify` with `OtpPurpose.passwordRecovery`.
- `OtpVerifyScreen` — single editorial 6-digit field (`LhotseOtpField`), 30s resend cooldown. On success: `signupVerification` → `/onboarding`; `passwordRecovery` → `/reset-password`.
- `ResetPasswordScreen` — new password + confirmation. Calls `updatePassword`, then `signOut`, then routes to `/login`.
- `LhotseAuthField` — underline-only border (0.5px inactive → 1px focused), Campton 18px w400, caption label above (accentMuted uppercase letterSpacing 1.8), optional eye toggle (PhosphorIconsThin 20px), error text below (danger).
- `LhotseSubmitButton`, `LhotseOtpField` — shared auth widgets in `presentation/widgets/`.

### Phone storage
`auth.users.phone` is the **single source of truth**. `user_profiles.phone` is a read-only mirror kept in sync by two triggers (`handle_new_user` on INSERT, `handle_user_updated` on UPDATE of `auth.users`). To change a phone number, always go through `auth.updateUser(phone: ...)` — which fires Supabase's verification SMS — never via `UPDATE user_profiles`.

### Router guard
GoRouter `redirect` sends unauthenticated users to `/welcome` and authenticated ones away from `/welcome` / `/login` / `/signup` / `/forgot-password` toward `/home`. `_kTransientAuthRoutes` (`/otp-verify`, `/reset-password`) bypass the guard entirely — the screen owns navigation because the session state flips mid-flow (verifyOTP creates a session). Role-based guards (e.g. blocking viewers from `/investments`) use the same mechanism.

### Per-user cache — `currentUserIdProvider.distinct()`
**Critical gotcha.** Riverpod's `FutureProvider`s keyed to the current user must watch `currentUserIdProvider` with `.distinct()`, not `supabaseAuthProvider.currentUser`.

Reason: Supabase reuses the same `User` object reference across a session; reading `currentUser` inside a provider returns the same identity even after `signOut() + signIn(otherUser)`, so Riverpod does not detect the change and serves stale data to the new user.

Pattern:
```dart
final currentUserIdProvider = StreamProvider<String?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((state) => state.session?.user.id)
      .distinct(); // <- mandatory
});

final myInvestmentsProvider = FutureProvider.autoDispose((ref) async {
  final userId = ref.watch(currentUserIdProvider).value;
  if (userId == null) return const <InvestmentData>[];
  // query here — cache is now keyed off a primitive that actually changes
});
```

`currentUserProfileProvider` exposes name / role / memberSince from `user_profiles`, wired the same way. `ProfileScreen` calls `AuthRepository.signOut()` on logout — the router guard takes it from there.
