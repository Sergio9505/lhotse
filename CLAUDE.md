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
5 bottom tabs: Inicio, Firmas, Buscar, Estrategia, Perfil. Strategy tab title: "MI ESTRATEGIA PATRIMONIAL"

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
Home screen with project carousel (5 max, Zara-style: image pure + text below on beige, name headingLarge 24px, no overlay, no ↗ on card) + news (5 from centralized mock, beige overlay cards). LhotseImage widget for smart asset/network image loading. Project detail with SliverAppBar + LhotseBackButton. Firmas screen with 2-column grid brand cards (ratio 1:1, centered logo+name). AllProjects with centered title, status/brand/search filters. AllNews screen with firma (logo row)/región (flag emoji)/buscar text-tab filters. Search screen with trending tags, collections, results (sharp edge thumbnails). Navbar: Zara-inspired beige, Phosphor thin icons (house/magnifyingGlass/user) + text-only (FIRMAS/ESTRATEGIA), dot indicators (black active, red notifications), 48px height. Strategy ("MI ESTRATEGIA PATRIMONIAL"): collapsing black hero (sequential fade: title out first half + slide up, logo in second half, amount 50→28px always visible), brand rows with name+amount·% inline left + chevron right (return % at bodySmall 12px w600), asterisk on estimated returns (coinversión/compraDirecta), footnote "* Rentabilidad estimada" below list, brand initials from all words (RF, L&B), opportunity compact cards. Brand investments: collapsing beige hero (adaptive collapse range via effectiveRange, amount always visible, interpolates position + size; title fades first half + slides up; brand subtitle fades in second half), sticky labels with gradient fade (solid 70% → transparent 30%, 74/70px height), compraDirecta: asset rows (80×60 thumbnails, stacked name/location/amount headingSmall(18), chevron, "MIS ACTIVOS"), rentaFija: _RentaFijaRow with date badge (MES/AÑO 42×42), amount + "duration MESES · 8%" active, amount + "invested · duration · +ROI%" completed (green w600), sorted by soonest maturity, ACTIVAS/FINALIZADAS sections, doc icon per operation, coinversion: single-column rows (thumb + name/amount + "duration MESES · %*" stacked left, chevron right, footnote "* Rentabilidad estimada"), completed: invested·duration·ROI (green) via returnLabelSpans. Completed detail (L3): NestedScrollView, hero totalReturn, 3 metrics (invertido, duración, ROI), 2 tabs (ACTIVO, DOCS). Investment detail: model-aware — compraDirecta: CompraDirectaDetailScreen — hero image + purchaseValue (displayLarge) + 3-col metrics (alquiler/rentabilidad/revalorización) + 3 tabs (ACTIVO with info+floorplan+gallery, FINANCIACIÓN, DOCS); coinversión: CoinversionDetailScreen (30% Zara / 70% Revolut) — 32% compact hero (headingLarge 24px title on image, location·phase inline, badge top-right), hero participation displayLarge (40px) + 3-col secondary headingLarge (24px), Bloomberg scenario panel (bordered pills, displayMedium 28px ROI+TIR, AnimatedSwitcher 300ms), compact timeline (6/10px nodes, 1.5px lines, pulse), gallery (75% × 200px, shadows), premium expandable tiles with collapsedPreview, archive zone (xl spacing, docs+news); rentaFija — no L3 detail, info is in L2. Bottom sheets: LhotseBottomSheetBody shared architecture (drag handle + title + optional header + Flexible body), dynamic sizing via ConstrainedBox(maxHeight 80%) + Column(mainAxisSize.min), square filter chips (sharp edges, black active/transparent inactive, X to clear). Global widgets: LhotseMetricBlock, LhotseSectionLabel, LhotseShellHeader, LhotseNotificationBell, LhotseNotificationBadge, LhotseBottomSheetBody in core/widgets/. Notifications: in-app center (bottom sheet, date-grouped, type icons, read/unread) + bell icon in shell headers (Home/Brands/Search via LhotseShellHeader, Strategy via Positioned in hero) + badge on ESTRATEGIA nav tab. Lhotse logo removed from all screen headers (replaced by bell). Opportunities screen with firma/ubicación/buscar filters. Mock: 20 projects, 8 brands (3 businessModel variants: compraDirecta/coinversion/rentaFija), 10 news, 29 investments (24 active + 5 completed), 10 documents, 10 notifications. Brand color: black (#000000), sharp edges everywhere (exceptions: avatars, notification badges).

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
- [x] Investment detail screen (model-aware: compraDirecta/coinversión/ciclo/rentaFija, documents + news)
- [x] All news screen (firma/región/buscar filters, full-size news cards)
- [ ] Profile screen
- [ ] Auth flow (register, login)
- [ ] Repository interfaces (abstract + mock impl)
- [ ] Connect Supabase (replace mock repositories)
