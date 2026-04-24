# Lhotse Group — Investor App

## Overview
Mobile app for Lhotse Group, a holding company specializing in wealth management through strategic real estate investments. Investors track their portfolio across the group's brands.

## Links
- **Figma**: https://www.figma.com/design/qIqzt6kAKBLDGrAvm6Zr4v/Lhotse--Isma---Copy-?node-id=0-1
- **Supabase**: project ref `mrwrmigeyatfrzwvfsfe` (MCP server configured — fully connected, no mock data)
- **Bundle ID**: `com.lhotsegroup.lhotseapp` (iOS + Android)

## Stack
Flutter 3.x + Dart, Riverpod, GoRouter, Freezed. Supabase backend — all screens live.

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
│   ├── data/       → Supabase providers (brands, projects, news…)
│   ├── domain/     → Shared models (BrandData, ProjectData, NewsItemData…)
│   ├── theme/      → AppTheme, colors, typography
│   └── widgets/    → Reusable components
├── features/
│   ├── auth/           → Login, welcome (Supabase Auth)
│   ├── home/           → Feed + project/news detail
│   ├── brands/         → Firmas: brand list + brand detail
│   ├── search/         → Global search + archive (catálogo, noticias)
│   ├── investments/    → Portfolio view (investor + VIP only)
│   ├── notifications/  → Notification center
│   └── profile/        → User profile + settings
└── main.dart
```

Data flow: Screen → Riverpod provider → Supabase view/table → Freezed model.
DB contract tables: `purchase_contracts | coinvestment_contracts | fixed_income_contracts | rental_contracts`.
UI business models (investor-facing): `compraDirecta | coinversion | rentaFija` — rental is subordinate to compraDirecta, not a fourth button. See `docs/DOMAIN.md`.

## Navigation
5 bottom tabs: Inicio, Firmas, Buscar, Estrategia, Perfil. Strategy title: "MI ESTRATEGIA PATRIMONIAL".

## User Roles
See `docs/DOMAIN.md § User Roles`. TL;DR: Viewer (mirón, sin inversiones), Investor, Investor VIP.

## Docs (read on demand)
- `docs/ARCHITECTURE.md` — Backend principles + Security model (RLS / `security_invoker`). **Read before any schema/view change.**
- `docs/CONVENTIONS.md` — Code patterns, DB rules, naming, auth flow. **Read before writing code.**
- `docs/DOMAIN.md` — Business glossary, features, roles, seed data, enum conventions.
- `docs/VOICE.md` — Copy rules & tone. **Read before writing UI text.**
- `docs/DESIGN_SYSTEM.md` — Tokens, components, screen patterns (Home feed, Firmas, archives, Strategy, investments, detail heros, video system, notifications). **Read before building/modifying UI.**
- `docs/DECISIONS.md` — ADRs: why X over Y. Read when questioning a pattern.
- `docs/ROADMAP.md` — Pending work + known gaps.
- `docs/sql/MIGRATION_CHECKLIST.md` — Mandatory header for every SQL migration.
- `docs/sql/audits/view_health.sql` — Run via Supabase MCP before schema changes; or invoke `/backend-review` for a full audit.
- `docs/solutions/` — Searchable log of non-obvious problems solved (grep by symptom before reinventing a fix).

## Post-task Checklist
After completing any task that changes code:
1. `flutter analyze` — must pass.
2. Evaluate docs: update any section affected by the change (one concept lives in one doc — don't duplicate).
3. Do NOT skip or defer — update docs in the same conversation.

## Status
Supabase fully connected — all screens live, no mock data. UI patterns per screen in `docs/DESIGN_SYSTEM.md`. Pending work in `docs/ROADMAP.md`.
