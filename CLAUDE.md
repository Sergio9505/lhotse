# Lhotse Group — Investor App

## Overview
Mobile app for Lhotse Group, a holding company specializing in wealth management through strategic real estate investments. Investors track their portfolio across the group's brands.

## Links
- **Figma**: https://www.figma.com/design/qIqzt6kAKBLDGrAvm6Zr4v/Lhotse--Isma---Copy-?node-id=0-1
- **Supabase**: project ref `mrwrmigeyatfrzwvfsfe` (MCP server configured — 21 tables, 10 views, 6 functions, seed data, fully connected)
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
- `docs/ARCHITECTURE.md` — Backend data-layer principles (**read before any schema/view change**)
- `docs/CONVENTIONS.md` — Code patterns, data layer rules, naming (read before writing code)
- `docs/DOMAIN.md` — Business glossary, features, roles (read before new feature)
- `docs/VOICE.md` — Copy rules (read before writing UI text)
- `docs/DESIGN_SYSTEM.md` — Tokens, components, screen patterns (read before building screens)
- `docs/DECISIONS.md` — ADRs: why X over Y (read when questioning a pattern)
- `docs/sql/MIGRATION_CHECKLIST.md` — Mandatory header for every SQL migration
- `docs/sql/audits/view_health.sql` — Run via Supabase MCP before schema changes; or invoke `/backend-review` for full audit
- `docs/solutions/` — Searchable log of non-obvious problems solved (grep by symptom before reinventing a fix)

## Post-task Checklist
After completing any task that changes code:
1. `flutter analyze` — must pass
2. Evaluate docs: update any section affected by the change
3. Do NOT skip or defer — update docs in the same conversation

## Status
**Supabase fully connected — no mock data.** Home = SNKRS-inspired vertical feed, one content unit per viewport (100vh). Media top ~65% (image or muted-autoplay video, pauses off-screen via active-index tracking) + beige caption ~35% (title `displayLarge` Campton Light w300 40pt tight line-height — one step below archive's `displayHero` 48pt, same tipographic family; meta brand·city·date bodySmall; CTA textual). Media envuelto en `Hero(tag: 'project-hero-{id}' | 'news-hero-{id}')` para shared-element transition hacia el detalle (matching con archive cards). Types: projectHero / news / opportunity (investor only) / brandSpotlight (1 rotating daily). Curation composed client-side in `homeFeedProvider`. Scroll + page position preserved between tabs de forma nativa por el `StatefulNavigationShell` (IndexedStack) — sin provider ad-hoc. Tap en el tab activo → `goBranch(i, initialLocation: true)` → pop a la raíz del branch (Instagram / Apple pattern). Pull-to-refresh invalidates all feed providers. Archive browsing (catálogo, noticias) lives in Search idle state (tabs CATÁLOGO · NOTICIAS) — Search tab absorbs the former AllProjects + AllNews entry points; their routes `/projects` and `/news` stay alive for deeplinks. LhotseImage widget for smart asset/network image loading. Project detail: editorial scroll (SliverAppBar hero, identity headingLarge, description, CARACTERÍSTICAS key-value list with bedrooms/bathrooms, PLANO InteractiveViewer, GALERÍA carousel, CTA "DESCARGAR FOLLETO", collapsed header with name+brand+fade gradient). Firmas screen with 2-column grid brand cards (**portrait** `childAspectRatio: 0.82`) in **magazine cover format** (*The World of Interiors* ref, ADR-50 v5): top 30% beige con logo SVG monocromo 64×18 centrado (wordmark discreto, `ColorFilter srcIn` negro) + bottom 70% con `LhotseImage(brand.coverImageUrl)` envuelto en `SizedBox.expand` (fuerza `BoxFit.cover` real) con padding 12pt laterales + inferior sobre fondo beige (evoca el rectángulo de portada sobre la card). Hairline border 0.5px alpha 0.1 exterior. Fallback a logo-only centrado si `coverImageUrl` vacío. AllProjects + Search catálogo use **ProjectShowcaseCard** (lookbook producto captioned photograph, Sotheby's × T Magazine × Openhouse + LVMH-inspired maison mark): edge-to-edge **1:1 square image** + 12pt gap + caption open sobre `background` (paleta unificada). Premium minimal-luxury-modern (Céline / Jil Sander / Totême territory, Campton-only — ADR-50). Imagen 1:1 edge-to-edge con `LhotseImage` envuelto en `Hero(tag: 'project-hero-{id}')` para shared-element transition al detalle. **Dos chips sobre imagen**: fase `project.phase.label` top-left como chip **outline** (transparent + 0.5px white border + soft shadow + caption w500 ls1.5 blanco) y VIP `PRIVATE` top-right como chip **fill** negro — jerarquía visual automática cuando coexisten. Caption sin hairlines: título `displayHero` Campton Light w300 48pt mixed case (line-height 0.95) → `project.city` (solo ciudad, no compound location — evita códigos ISO) bodyMedium accentMuted → tagline bodyMedium **italic** accentMuted → 24pt spacer → `_BrandStamp` byline con logo SVG **72×20** monocromo (patrón `_BrandCard` Firmas, ColorFilter srcIn negro; fallback textual). Separator 16pt. VIP "PRIVATE" chip top-right en imagen. Separator 16pt. AllNews + NewsArchiveBody: arquitectura compositiva alineada con `ProjectShowcaseCard`, **mismo aspect 1:1** (probamos 4:5 portrait pero el caption salía del viewport rompiendo el escaneo del catálogo — el cover-magazine treatment se reserva al detail screen). Imagen edge-to-edge con chip outline `PROYECTO`/`PRENSA` top-left. Caption: título `displayHero` Light 48pt + deck italic + byline textual `POR {BRAND} · {DATE}` (asimetría intencional con projects: en news brand es autor editorial, no maison). Hero tag `news-hero-{id}`. Separator 32pt (algo más de aire que projects 16pt — news escanea un beat más lento por carácter editorial). Regla del sistema (ADR-50 v5): cada tab de Search adopta el formato que mejor sirve a su CONTENIDO — Firmas grid 2×2 en magazine cover format (logo wordmark arriba + cover editorial abajo, referencia *World of Interiors*); Projects y News son ambos listings de teasers, comparten 1:1 con imagen edge-to-edge + caption. Ambas pantallas usan `ScrollAwareFilterBar` — **oculta completamente** los filtros secundarios (status chips + stack/region/search icons) durante scroll activo, reexpande tras 2s idle (Apple Stocks / NYT UX). Los tabs primarios (FIRMAS/PROYECTOS/NOTICIAS) comunican siempre el contexto, sin pill substituto. Search screen with trending tags, collections, results (sharp edge thumbnails). Navbar: Zara-inspired beige, Phosphor thin icons (house/magnifyingGlass/user) + text-only (FIRMAS/ESTRATEGIA), dot indicators (black active, red notifications), 48px height. Strategy ("MI ESTRATEGIA PATRIMONIAL"): full-beige collapsing hero (`_HeroDelegate` sobre `AppColors.background`, logo+campana `textPrimary` pintados en el propio delegate para controlar Z-order sobre la cifra que se mueve; sequential fade: título `Mi estrategia\npatrimonial` `displayLarge` Campton Light w300 desvanece en primer tramo del scroll, cifra interpola de 48pt bottom-left → 28pt centro de la banda chrome; sin foto, sin gradiente, sin business-model breakdown), hairline separator, brand rows with name+amount·% inline left + chevron right (return % at bodySmall 12px w600), asterisk on estimated returns (coinversión/compraDirecta), footnote "* Rentabilidad estimada" below list, brand marker per row: SVG `brands.icon_asset` (compact square icon from `brand-assets/icons/`, monochrome via `ColorFilter srcIn textPrimary`) when present, fallback a thin-border initials monogram de todas las palabras (RF, L&B). Brand investments: collapsing beige hero (adaptive collapse range via effectiveRange, amount always visible, interpolates position + size; title fades first half + slides up; brand subtitle fades in second half), sticky labels with gradient fade (solid 70% → transparent 30%, 74/70px height), compraDirecta: asset rows (80×60 thumbnails, stacked name/location/amount headingSmall(18), chevron, "MIS ACTIVOS"), rentaFija: _RentaFijaRow with date badge (MES/AÑO 42×42), capital invertido grande + "{rate}% anual · vence MM/YY · +€cobrados" active, capital invertido grande + "duración Xm · +€intereses_totales" completed (green w600), sorted by soonest maturity, ACTIVAS/FINALIZADAS sections, conditional doc icon per operation (opens bottom sheet with filter chips derived from categories present), coinversion: single-column rows (thumb + name/amount + "duration MESES · %*" stacked left, chevron right, footnote "* Rentabilidad estimada"), completed: invested·duration·ROI (green) via returnLabelSpans. Completed detail (L3): NestedScrollView, hero totalReturn, 3 metrics (invertido, ROI, TIR — duración eliminada porque ya está codificada en la TIR), 2 tabs (ACTIVO, DOCS). Investment detail: model-aware — compraDirecta: CompraDirectaDetailScreen — hero image + purchaseValue (displayLarge) + 3-col metrics (alquiler/rentabilidad/revalorización) + 3 tabs (ACTIVO with info+floorplan+gallery, FINANCIACIÓN, DOCS); coinversión: CoinversionDetailScreen (30% Zara / 70% Revolut) — 32% compact hero (headingLarge 24px title on image, location·phase inline, badge top-right), hero participation displayLarge (40px) + 3-col secondary headingLarge (24px), Bloomberg scenario panel (bordered pills, displayMedium 28px ROI+TIR, AnimatedSwitcher 300ms), compact timeline (6/10px nodes, 1.5px lines, pulse), gallery (75% × 200px, shadows), premium expandable tiles with collapsedPreview, archive zone (xl spacing, docs+news); rentaFija — no L3 detail, info is in L2. Bottom sheets: LhotseBottomSheetBody shared architecture (drag handle + title + optional header + Flexible body), dynamic sizing via ConstrainedBox(maxHeight 80%) + Column(mainAxisSize.min), square filter chips (sharp edges, black active/transparent inactive, X to clear). Global widgets: LhotseMetricBlock, LhotseSectionLabel, LhotseShellHeader, LhotseNotificationBell, LhotseNotificationBadge, LhotseBottomSheetBody in core/widgets/. Notifications: in-app center (bottom sheet, date-grouped, type icons, read/unread) + bell icon in shell headers (Home/Brands/Search via LhotseShellHeader, Strategy via `Positioned` within its collapsing hero delegate) + badge on ESTRATEGIA nav tab. Lhotse logo removed from all screen headers (replaced by bell). Opportunity discovery lives solely in the Home feed (`FeedOpportunityItem`, investor-only) — dedicated OpportunitiesScreen removed along with the Strategy "NUEVAS OPORTUNIDADES" section (ADR-10 superseded). VIP projects: black "PRIVATE" chip on image top-right (Positioned, AppColors.primary bg, white caption), beige bottom sheet on tap (lock icon, separator, monochromatic CTA). News detail + Project detail share **coherence with their archive cards** (ADR-49): hero expandedHeight = `screen * 0.55` (up from 200px) with warm sepia gradient bottom, identity block with kicker above mixed-case `displayMedium` title + deck (news.subtitle / project.tagline) + byline `POR BRAND · DATE` (news) or location (project). Collapsed app bar titles stay uppercase. News detail lateral type-badge row removed (kicker absorbs it). News detail also has fullscreen video placeholder (_VideoPlayerScreen: black overlay, centered play + title + PRÓXIMAMENTE, X close). Supabase seed: 13 brands (wordmark `logo_asset` in `brand-assets/logos/` used in Firmas grid + project cards; compact square `icon_asset` in `brand-assets/icons/` used in Strategy ledger monogram slot — 5 poblados: Domorato, Lacomb & Bos, Myttas, NUVE, Vellte), 18 projects, 6 assets, 10 news, 6 purchase_contracts + mortgages, 15 coinvestment_contracts, 6 rental_contracts + payments, 2 fixed_income_offerings + 6 contracts + payments, 10 notifications, ~85 documents (4/contrato compra, 3-5/contrato coinversión por fase, 2-3/contrato renta fija), 10 proyectos coinversión con scenarios/phases/economic_analysis backfilled. Flutter enum values renamed to English (directPurchase/coinvestment/fixedIncome, inDevelopment/signatures/closed, project/press) to match Supabase DB CHECK constraint values. Brand color: black (#000000), sharp edges everywhere (exceptions: avatars, notification badges). Auth flow: WelcomeScreen (video loop fullscreen with Ken Burns static fallback — video_player package; velvet multi-stop gradient; logo 44px; tagline letterSpacing 2.0; single outline CTA "INICIAR SESIÓN" 0.5px border), LoginScreen (email+password + forgot password link), no registro (solo admins crean cuentas). LhotseAuthField widget (underline-only border, caption label, eye toggle). AuthRepository (signIn/signOut via Supabase). GoRouter auth guard (redirect to /welcome if not logged in, /home if already logged in). currentUserIdProvider with .distinct() prevents stale cache. Profile screen: real name/role/memberSince from currentUserProfileProvider, logout wired to signOut().

## TODO
- [x] Flutter project scaffold (pubspec, theme, router, shell)
- [x] Home screen (project carousel + news section) — live from Supabase
- [x] Project detail screen
- [x] Firmas screen (brand list with SVG logos from Supabase Storage)
- [x] All projects screen (status/brand/search filters)
- [x] Brand detail screen — live from Supabase
- [x] Search screen (trending tags, brand + project results)
- [x] Strategy screen (portfolio hero + brand ledger; opportunities moved to Home feed only, ADR-10 superseded)
- [x] Brand investments screen (typed: compraDirecta / coinversión / rentaFija)
- [x] Investment detail screen (typed routing via GoRouter extra)
- [x] All news screen (firma/región/buscar filters)
- [x] Profile screen (real data from Supabase; sub-screens: edit, KYC, notifications, security, support, legal)
- [x] Auth flow (Supabase Auth + router guard)
- [x] Supabase schema — 4 investment domains (purchase/coinvest/rental/fixed_income), 21 tables, 7 views, 15 migrations
- [x] Supabase connected — all screens live, no mock data, providers for all domains
- [x] Brand logos uploaded to Supabase Storage (brand-assets/logos/)
- [x] Edit profile screen — read + save wired (`user_profiles` update)
- [x] KYC screen — reads from `kyc_documents` table
- [x] Notifications preferences — persisted via `updateNotificationPreferences`
- [x] Security screen — change password wired (`auth.updateUser`)
- [x] Documents in investment detail — live via `documentsProvider` (purchase/coinvest L3 DOCS tab + RF L2 bottom sheet, all with filter chips)
- [ ] Security screen — 2FA toggle + "cerrar todas las sesiones" son no-ops; biometric state solo local
- [ ] Support screen — email/teléfonos/horario hardcodeados; mover a tabla `support_contacts` o config
- [ ] Legal text screen — `LegalContent.terms` + `.privacy` como `static const`; mover a tabla `legal_documents` (versionable)
- [ ] Search trending tags — lista const en `search_screen.dart`; idealmente vía analytics o admin
- [ ] Real floor plan images — bundle mock removed; 11 proyectos con floor_plan_url NULL (sección PLANO oculta). Subir planos reales a Supabase Storage cuando haya material.
- [ ] Forgot password flow
- [ ] Welcome screen video — stock Coverr clip, replace with branded content before production
