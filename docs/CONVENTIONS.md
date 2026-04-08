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
