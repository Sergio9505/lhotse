# Lhotse Group — Investor App

## Overview
Mobile app for Lhotse Group, a holding company specializing in wealth management through strategic real estate investments. Investors track their portfolio across the group's brands.

## Links
- **Figma**: https://www.figma.com/design/qIqzt6kAKBLDGrAvm6Zr4v/Lhotse--Isma---Copy-?node-id=0-1
- **Supabase**: project ref `mrwrmigeyatfrzwvfsfe` (MCP server configured — 21 tables, 7 views, 2 RPCs, seed data, fully connected)
- **Bundle ID**: `com.lhotsegroup.lhotseapp` (iOS + Android)

## Stack
Flutter 3.x + Dart, Riverpod, GoRouter, Freezed. Supabase connected (all screens live — no mock data).

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
│   ├── data/       → Supabase providers (brands, projects, news)
│   ├── domain/     → Shared models (BrandData, ProjectData, NewsItemData…)
│   ├── theme/      → AppTheme, colors, typography
│   └── widgets/    → Reusable components
├── features/
│   ├── auth/       → Login, onboarding (Supabase Auth)
│   ├── home/       → Featured projects + news feed
│   ├── brands/     → Firmas: brand list + brand detail
│   ├── search/     → Global search
│   ├── investments/→ Portfolio view (investor + VIP only)
│   │   ├── data/   → investmentsProvider (purchase/coinvest/rf/rental)
│   │   └── domain/ → PurchaseContractData, CoinvestmentContractData, FixedIncomeContractData…
│   ├── notifications/ → data/notificationsProvider
│   └── profile/    → User profile + settings
└── main.dart
```

Data flow: Screen → Riverpod FutureProvider → Supabase view/table → Model
Investment domains: purchase_contracts | coinvestment_contracts | fixed_income_contracts | rental_contracts

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
**Supabase fully connected — no mock data.** Home screen with project carousel (5 max, Zara-style: image pure + text below on beige, name headingLarge 24px, no overlay, no ↗ on card) + news (5 from Supabase, beige overlay cards). LhotseImage widget for smart asset/network image loading. Project detail: editorial scroll (SliverAppBar hero, identity headingLarge, description, CARACTERÍSTICAS key-value list with bedrooms/bathrooms, PLANO InteractiveViewer, GALERÍA carousel, CTA "DESCARGAR FOLLETO", collapsed header with name+brand+fade gradient). Firmas screen with 2-column grid brand cards (ratio 1:1, centered logo+name). AllProjects with centered title, status/brand/search filters. AllNews screen with firma (logo row)/región (flag emoji)/buscar text-tab filters. Search screen with trending tags, collections, results (sharp edge thumbnails). Navbar: Zara-inspired beige, Phosphor thin icons (house/magnifyingGlass/user) + text-only (FIRMAS/ESTRATEGIA), dot indicators (black active, red notifications), 48px height. Strategy ("MI ESTRATEGIA PATRIMONIAL"): collapsing black hero (sequential fade: title out first half + slide up, logo in second half, amount 50→28px always visible), brand rows with name+amount·% inline left + chevron right (return % at bodySmall 12px w600), asterisk on estimated returns (coinversión/compraDirecta), footnote "* Rentabilidad estimada" below list, brand initials from all words (RF, L&B), opportunity compact cards. Brand investments: collapsing beige hero (adaptive collapse range via effectiveRange, amount always visible, interpolates position + size; title fades first half + slides up; brand subtitle fades in second half), sticky labels with gradient fade (solid 70% → transparent 30%, 74/70px height), compraDirecta: asset rows (80×60 thumbnails, stacked name/location/amount headingSmall(18), chevron, "MIS ACTIVOS"), rentaFija: _RentaFijaRow with date badge (MES/AÑO 42×42), amount + "duration MESES · 8%" active, amount + "invested · duration · +ROI%" completed (green w600), sorted by soonest maturity, ACTIVAS/FINALIZADAS sections, doc icon per operation, coinversion: single-column rows (thumb + name/amount + "duration MESES · %*" stacked left, chevron right, footnote "* Rentabilidad estimada"), completed: invested·duration·ROI (green) via returnLabelSpans. Completed detail (L3): NestedScrollView, hero totalReturn, 3 metrics (invertido, duración, ROI), 2 tabs (ACTIVO, DOCS). Investment detail: model-aware — compraDirecta: CompraDirectaDetailScreen — hero image + purchaseValue (displayLarge) + 3-col metrics (alquiler/rentabilidad/revalorización) + 3 tabs (ACTIVO with info+floorplan+gallery, FINANCIACIÓN, DOCS); coinversión: CoinversionDetailScreen (30% Zara / 70% Revolut) — 32% compact hero (headingLarge 24px title on image, location·phase inline, badge top-right), hero participation displayLarge (40px) + 3-col secondary headingLarge (24px), Bloomberg scenario panel (bordered pills, displayMedium 28px ROI+TIR, AnimatedSwitcher 300ms), compact timeline (6/10px nodes, 1.5px lines, pulse), gallery (75% × 200px, shadows), premium expandable tiles with collapsedPreview, archive zone (xl spacing, docs+news); rentaFija — no L3 detail, info is in L2. Bottom sheets: LhotseBottomSheetBody shared architecture (drag handle + title + optional header + Flexible body), dynamic sizing via ConstrainedBox(maxHeight 80%) + Column(mainAxisSize.min), square filter chips (sharp edges, black active/transparent inactive, X to clear). Global widgets: LhotseMetricBlock, LhotseSectionLabel, LhotseShellHeader, LhotseNotificationBell, LhotseNotificationBadge, LhotseBottomSheetBody in core/widgets/. Notifications: in-app center (bottom sheet, date-grouped, type icons, read/unread) + bell icon in shell headers (Home/Brands/Search via LhotseShellHeader, Strategy via Positioned in hero) + badge on ESTRATEGIA nav tab. Lhotse logo removed from all screen headers (replaced by bell). Opportunities screen with business model primary tabs (COMPRA/COINVERSIÓN/RENTA FIJA via LhotseFilterTab) + location icon tool (mapPin with dot indicator), filters by brand.businessModel cross-reference. VIP projects: black "PRIVATE" chip on image top-right (Positioned, AppColors.primary bg, white caption), beige bottom sheet on tap (lock icon, separator, monochromatic CTA). News detail: editorial scroll (SliverAppBar 200px hero pinned, collapsed title AnimatedOpacity, identity headingLarge + brand·date row, type badge PROYECTO/PRENSA, body bodyMedium 1.6 height, related news horizontal scroll max 3), fullscreen video placeholder (_VideoPlayerScreen: black overlay, centered play + title + PRÓXIMAMENTE, X close). Supabase seed: 13 brands (logos in brand-assets Storage), 18 projects, 6 assets, 10 news, 6 purchase_contracts + mortgages, 15 coinvestment_contracts, 6 rental_contracts + payments, 2 fixed_income_offerings + 6 contracts + payments, 10 notifications, 5 documents. Flutter enum values renamed to English (directPurchase/coinvestment/fixedIncome, inDevelopment/signatures/closed, project/press) to match Supabase DB CHECK constraint values. Brand color: black (#000000), sharp edges everywhere (exceptions: avatars, notification badges). Auth flow: WelcomeScreen (video loop fullscreen with Ken Burns static fallback — video_player package; velvet multi-stop gradient; logo 44px; tagline letterSpacing 2.0; single outline CTA "INICIAR SESIÓN" 0.5px border), LoginScreen (email+password + forgot password link), no registro (solo admins crean cuentas). LhotseAuthField widget (underline-only border, caption label, eye toggle). AuthRepository (signIn/signOut via Supabase). GoRouter auth guard (redirect to /welcome if not logged in, /home if already logged in). currentUserIdProvider with .distinct() prevents stale cache. Profile screen: real name/role/memberSince from currentUserProfileProvider, logout wired to signOut().

## TODO
- [x] Flutter project scaffold (pubspec, theme, router, shell)
- [x] Home screen (project carousel + news section) — live from Supabase
- [x] Project detail screen
- [x] Firmas screen (brand list with SVG logos from Supabase Storage)
- [x] All projects screen (status/brand/search filters)
- [x] Brand detail screen — live from Supabase
- [x] Search screen (trending tags, brand + project results)
- [x] Strategy screen (portfolio hero, brand ledger, opportunities)
- [x] Opportunities screen (business model tabs + location filter)
- [x] Brand investments screen (typed: compraDirecta / coinversión / rentaFija)
- [x] Investment detail screen (typed routing via GoRouter extra)
- [x] All news screen (firma/región/buscar filters)
- [x] Profile screen (real data from Supabase; sub-screens: edit, KYC, notifications, security, support, legal)
- [x] Auth flow (Supabase Auth + router guard)
- [x] Supabase schema — 4 investment domains (purchase/coinvest/rental/fixed_income), 21 tables, 7 views, 15 migrations
- [x] Supabase connected — all screens live, no mock data, providers for all domains
- [x] Brand logos uploaded to Supabase Storage (brand-assets/logos/)
- [ ] Edit profile screen — connected to read; save not wired
- [ ] KYC screen — statuses must come from kyc_documents table
- [ ] Notifications preferences — not persisted to notification_preferences table
- [ ] Security screen — all actions are no-ops
- [ ] Documents in investment detail — placeholder lists, not fetched from Supabase
- [ ] Real floor plan images — currently uses mock_floor_plan.png as fallback
- [ ] Forgot password flow
- [ ] Welcome screen video — stock Coverr clip, replace with branded content before production
