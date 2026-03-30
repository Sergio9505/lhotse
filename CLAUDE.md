# Lhotse Group — Investor App

## Overview
Mobile app for Lhotse Group, a holding company specializing in wealth management through strategic real estate investments. Investors track their portfolio across the group's brands.

## Links
- **Figma**: https://www.figma.com/design/qIqzt6kAKBLDGrAvm6Zr4v/Lhotse--Isma---Copy-?node-id=0-1
- **Supabase**: TBD (mock-first approach — connect later)

## Stack
Flutter 3.x + Dart, Riverpod, GoRouter, Freezed. Supabase planned (not connected yet).

## Commands
```bash
export PATH="$PATH:/Users/sergiosanchezmartin/dev/flutter/bin"
flutter run --dart-define-from-file=.env          # Run app (dev)
flutter analyze                                    # Lint
flutter test                                       # Test
dart run build_runner build --delete-conflicting-outputs  # Code gen (freezed)
```

## Architecture
```
lib/
├── app/            → Router, theme, shell (bottom nav)
├── core/
│   ├── data/       → Mock data layer (→ Supabase later)
│   ├── domain/     → Shared models
│   ├── theme/      → AppTheme, colors, typography
│   └── widgets/    → Reusable components
├── features/
│   ├── auth/       → Login, register, onboarding
│   ├── home/       → Featured projects + news feed
│   ├── brands/     → Firmas: brand list + brand detail
│   ├── search/     → Global search
│   ├── investments/→ Portfolio view (investor + VIP only)
│   └── profile/    → User profile + settings
└── main.dart
```

Data flow: Screen → Controller → Repository (mock) → Model
When Supabase connects: only Repository layer changes.

## Navigation
5 bottom tabs: Inicio, Firmas, Buscar, Estrategia, Perfil

## User Roles
- **Viewer** (mirón): registered, browses projects/brands/news — no investment data
- **Investor**: views own investments across group brands
- **Investor VIP**: investor + premium features (TBD)

## Docs (read on demand)
- `docs/CONVENTIONS.md` — Code patterns, data layer rules, naming (read before writing code)
- `docs/DOMAIN.md` — Business glossary, features, roles (read before new feature)
- `docs/VOICE.md` — Copy rules (read before writing UI text)
- `docs/DESIGN_SYSTEM.md` — Tokens, components, screen patterns (read before building screens)
- `docs/DECISIONS.md` — ADRs: why X over Y (read when questioning a pattern)

## Post-task Checklist
After completing any task that changes code:
1. `flutter analyze` — must pass
2. Evaluate docs: update any section affected by the change
3. Do NOT skip or defer — update docs in the same conversation

## Status
Home screen with project carousel (5 projects max) + news. Project detail with SliverAppBar + LhotseBackButton (frosted/surface variants). Firmas screen with brand cards + SVG logos (nullable logoAsset, Text initial fallback). AllProjects screen with centered title, status filters, brand filter (multi-select), and search. Search screen with trending tags, collections grid, project results, documents placeholder. Navbar: all Lucide icons, labels always visible, "ESTRATEGIA" tab. Strategy screen: navy hero (total patrimony + return), brand ledger rows (sorted desc), opportunity cards. Opportunities screen with brand/location/search text-tab filters. Mock data: 20 projects, 8 brands (5 with SVG + 3 with initial fallback), 17 investments.

## TODO
- [x] Flutter project scaffold (pubspec, theme, router, shell)
- [x] Mock data layer (projects + brands, no repository interfaces yet)
- [x] Home screen (project carousel + news section)
- [x] Project detail screen (SliverAppBar, hero image, content panel)
- [x] Firmas screen (brand list with SVG logos)
- [x] All projects screen (status filters, brand filter, search)
- [ ] Brand detail screen
- [x] Search screen (trending tags, collections grid, project results, documents placeholder)
- [x] Strategy screen (navy hero, brand ledger, opportunity cards + section)
- [x] Opportunities screen (brand/location/search filters, project list)
- [x] Brand investments screen (per-brand detail, investment cards)
- [x] Investment detail screen (participación, operation details, documents, "ver proyecto")
- [ ] Profile screen
- [ ] Auth flow (register, login)
- [ ] Repository interfaces (abstract + mock impl)
- [ ] Connect Supabase (replace mock repositories)
