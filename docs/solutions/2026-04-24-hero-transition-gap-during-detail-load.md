---
date: 2026-04-24
tags: [flutter, navigation, hero, shared-element, riverpod, async]
related_adrs: [ADR-53]
---

# Hero transition "jumps" when detail screen loads async data

## Symptom

Tapping a card with a shared-element `Hero` (Home feed card, Firmas grid, archive lists) briefly showed a loading spinner and the destination "landed" at its final position with **no flight animation**. Subsequent taps on the same card looked smoother because the Riverpod provider was already warm, but the first tap was always a visible jump. Users described it as "me sale el círculo de carga y ya aparece en la posición final, no hay transición".

## Diagnosis

The destination screen watched a Riverpod provider (e.g. `projectByIdProvider`, `newsByIdProvider`, `brandByIdProvider`) for the full domain object. While the fetch was in flight, the screen returned an early `Scaffold` with a `CircularProgressIndicator` and **no Hero widget in the tree**.

```dart
final project = projectAsync.valueOrNull;
if (project == null) {
  return Scaffold(body: Center(child: CircularProgressIndicator()));  // ← no Hero here
}
```

When Flutter begins a Hero push, it walks the destination's element tree looking for a widget with the matching tag. If the tag isn't present (because the tree is still the loading-state scaffold), the Hero simply has no target to animate toward — no flight happens at all. When the provider resolves ~300-800ms later, the Hero tag finally appears in the tree, but by then the navigation transition is over and the user is already on the detail screen with nothing to animate.

Notable misleads:
- `cached_network_image` + `precacheImage` reduce image latency but don't fix this — the problem isn't image decode, it's that the **widget tree** is missing the Hero.
- Custom `flightShuttleBuilder` can't help either — Flutter doesn't even start a flight when the destination has no matching tag.

## Fix

Pass the already-loaded domain object from caller to detail via GoRouter's `extra`, and let the detail screen fall back to it while the provider refreshes in the background. The Hero widget is therefore in the first frame of the destination.

### Layer 1 — detail screens accept an optional snapshot

`lib/features/home/presentation/project_detail_screen.dart`, `news_detail_screen.dart`, and `lib/features/brands/presentation/brand_detail_screen.dart` now accept `initialProject` / `initialNews` / `initialBrand`:

```dart
class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.initialProject,
  });

  final String projectId;
  final ProjectData? initialProject;
  ...
}
```

And in build:

```dart
final project = projectAsync.valueOrNull ?? widget.initialProject;
if (project == null) { /* deeplink / cold load fallback */ }
```

The provider still runs and, on resolve, overrides the snapshot with the authoritative server copy.

### Layer 2 — router reads `state.extra` typed

`lib/app/router.dart`:

```dart
GoRoute(
  path: AppRoutes.projectDetail,
  pageBuilder: (context, state) {
    final id = state.pathParameters['id']!;
    final initialProject = state.extra is ProjectData
        ? state.extra as ProjectData
        : null;
    return _fadePage(
      key: state.pageKey,
      child: ProjectDetailScreen(
        projectId: id,
        initialProject: initialProject,
      ),
    );
  },
),
```

### Layer 3 — every call site passes the object

Every place that pushes into a detail screen and already has the full object passes it as `extra`:

- `feed_card.dart` → `context.push('/projects/${project.id}', extra: project)` (and variants)
- `all_projects_screen.dart` + `projects_archive_body.dart` → `ProjectShowcaseCard.onTap`
- `all_news_screen.dart` + `news_archive_body.dart` → `LhotseNewsCard.onTap`
- `brands_screen.dart._BrandCard` → `context.push('/brands/${brand.id}', extra: brand)`
- `search_screen.dart` → project and brand result rows

Deep links that only have an ID (search doc results keyed by `modelId`, URL shares, notifications) skip `extra` and fall through to the loading-spinner path — these don't originate from a Hero source anyway, so there's no shared-element animation to preserve.

## Lesson

If you use `Hero` with a remote-data destination, the destination must have the Hero widget **in its first build frame**. Provider-gated early returns (`if (data == null) return CircularProgressIndicator()`) silently break shared-element transitions.

The canonical Flutter pattern is to pass the list-row snapshot forward as navigation data (`Navigator.push` → `RouteSettings.arguments`, or `GoRouter` → `state.extra`) and let the detail screen use it as an initial paint while the definitive fetch happens in parallel. Unsplash, Pinterest, Apple Photos, and Instagram all do this; a disk image cache alone does not.

Related: ADR-53 (shell UX polish, Hero transition fix history).

## Refinement — video Hero shuttle

A follow-up tweak: the `flightShuttleBuilder` in `feed_card.dart` used to always render `LhotseImage(posterUrl)` during the flight. Once `FeedVideoPlayer` stopped painting a static poster underneath the video (to kill the brief image-to-video flash on Home), the shuttle's still image became a visible artefact during the flight from a video card — "se ve momentáneamente la imagen". Fix: if the source card has a `videoUrl`, the shuttle now returns a solid `Container(color: AppColors.primary)` matching the Home scaffold background. Image-only cards keep `LhotseImage`. We still can't mount `FeedVideoPlayer` inside the shuttle (it would re-instantiate a `VideoPlayerController` mid-flight → AVFoundation `naturalSize` synchronous access → main-thread jank).

## How to avoid next time

- Rule of thumb: **if a screen has a `Hero`, it must not gate that Hero behind an async loading state.** Either (a) render the Hero-bearing tree on the first frame with a snapshot fallback, or (b) accept that the transition will be a fade, not a shared-element flight, and remove the Hero entirely.
- Checklist for any new detail screen that uses a Hero:
  1. Does the matching list screen already have the domain object? → Add an `initialX` parameter, pass via `extra`.
  2. Is there a deep-link / notification entry that has only an ID? → Document that those entries are fade-only, no Hero.
  3. Is the Hero widget inside the `when(data:)` branch of an `AsyncValue`? → That's the bug. Hoist it.
- When grepping for this symptom, try: `if.*== null.*Scaffold.*CircularProgressIndicator`, `Hero(tag:`, `state.extra`.
