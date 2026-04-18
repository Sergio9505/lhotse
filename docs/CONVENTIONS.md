# Conventions

## File Structure
- Feature-first: `lib/features/{name}/{data,domain,presentation}/`
- Shared code: `lib/core/` (data, domain, theme, widgets)
- Models: `lib/features/{name}/domain/{name}.dart` + `.freezed.dart` + `.g.dart`

## Naming
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- DB columns (future): `snake_case`
- Providers: `{name}Provider` (e.g. `projectsProvider`)
- Repositories: `{Name}Repository` (e.g. `ProjectRepository`)
- Controllers: `{Name}Controller` extends `StateNotifier`

## State Management (Riverpod)
- `ref.watch()` for reactive data, `ref.read()` for one-off actions (callbacks)
- `AsyncValue<T>` for async state: loading → data | error
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
- Typed property attributes (bedrooms, floor, orientation, surface_m2…): **individual `NUMERIC`/`INTEGER`/`TEXT` columns** — never JSONB
- Queryable child data (scenarios, phases, documents): **separate table** with FK

### Naming
- Tables: `snake_case`, **plural** (`brands`, `investments`, `documents`)
- Columns: `snake_case` (`brand_id`, `created_at`, `is_completed`)
- Views: `snake_case`, **plural, no prefix** — treat like tables (`portfolio_summaries`, `investment_details`). The Supabase dashboard already differentiates tables from views visually.
- Constraints: `chk_{column}` for CHECK, `idx_{table}_{column}` for indexes, `trg_{table}_{event}` for triggers
- Foreign keys: `{referenced_table_singular}_id` (`brand_id`, `user_id`, `project_id`)

### Views — mandatory rules
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
- Spanish display names go in Flutter extensions: `BusinessModel.directPurchase.displayName` → `"Compra Directa"`
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

### Supabase Client (Flutter SDK)
- Single client instance via provider: `Supabase.instance.client`
- Queries return `List<Map<String, dynamic>>` — always map to domain models in the repository, never pass raw maps to UI
- Error handling: catch `PostgrestException` in repositories, convert to domain errors
- `.order()` defaults to **descending** — always pass `ascending: true` explicitly for ASC
- Use `.select('*, brands(*)')` for JOINs via FK relationships — PostgREST resolves them automatically
- Prefer views over complex `.select()` with nested JOINs for readability

---

## Data Layer — Mock-First Pattern

### Repository Interface
Every feature defines an abstract repository:
```dart
abstract class ProjectRepository {
  Future<List<Project>> getProjects();
  Future<Project> getProjectById(String id);
}
```

### Mock Implementation
```dart
class MockProjectRepository implements ProjectRepository {
  @override
  Future<List<Project>> getProjects() async {
    await Future.delayed(const Duration(milliseconds: 300)); // simulate network
    return MockData.projects;
  }
}
```

### Mock Data
All mock data lives in `lib/core/data/mock/`:
- One file per domain: `mock_projects.dart`, `mock_brands.dart`, etc.
- Uses realistic data matching Figma designs
- Simulates network delay (300ms) to test loading states

### Provider Registration
```dart
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return MockProjectRepository(); // → SupabaseProjectRepository() later
});
```

### Transition to Supabase
When connecting Supabase:
1. Create `SupabaseProjectRepository implements ProjectRepository`
2. Swap the provider implementation — screens don't change
3. Delete mock files

### Rules
- **Never** import mock data directly in screens — always go through repository
- **Never** hardcode data in widgets — always receive via constructor or provider
- Keep mock data in dedicated files, not scattered across features
- Repository methods return domain models, not raw maps/JSON

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
