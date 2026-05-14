# Design System

> Source of truth: [Figma](https://www.figma.com/design/tObKXuw8poV9vqBOrTANG4/Lhotse--Isma---Copy-?node-id=4045-2)
> Code: `lib/core/theme/`

## Design Principles

These rules apply to ALL UI built in the app. Check before every screen/widget implementation.

| Rule | Detail |
|------|--------|
| Sharp edges everywhere | `borderRadius: 0` on all containers, cards, thumbnails, pills, buttons. No rounded corners. Exceptions: avatars (full circle), notification badges (pill/circle), navigation buttons (back button — circular frosted glass on images) |
| Brand color is black | `AppColors.primary` = `#000000`. No navy (`#1A1E2F`) |
| Editorial + fintech premium | Generous whitespace, typographic hierarchy over labels/headers. Numbers are heroes. Minimal UI chrome |
| Calibrate by screen type | Criterion: "Is the user discovering or managing?" Discovery (Home, Project Detail, Brands, Search) → editorial-heavy: large hero images, aspirational, visual rhythm. Portfolio (Strategy, Brand Investments, Investment Detail) → fintech-heavy: data-first, numbers as heroes, progressive disclosure. See ADR-17 for full calibration table |
| No redundant labels | If a value is self-explanatory (€, %) don't add repeated labels per row. Use section context or a single header |
| Thin aesthetic | All icons: Phosphor thin (1px stroke). Typography weights: w400-w500 range. No bold (w700+). Size creates hierarchy, not weight. Inspired by Zara |
| Business models | 3 variants: `compraDirecta`, `coinversion`, `rentaFija` (no `ciclo`) |

## Tokens

### Colors (`app_colors.dart`)
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#000000` | Black — nav bg, cards on dark, text |
| background | `#E5E2DC` | Warm beige — page backgrounds |
| surface | `#D1CEC7` | Lighter beige — sections, inputs |
| textPrimary | `#000000` | Body text, headings |
| textSecondary | `#8C8A85` | Captions, labels, inactive icons |
| textOnDark | `#FFFFFF` | Text on primary/dark surfaces |
| accentMuted | `#5A5854` | Supporting text, muted elements |
| danger | `#7F1D1D` | Negative returns, errors |
| gold | `#DAAC03` | VIP role badge only — justified exception to monochromatic palette |
| border | `rgba(0,0,0,0.1)` | Dividers, card borders |
| borderLight | `rgba(0,0,0,0.05)` | Subtle separators |
| navBackground | `#000000` | Bottom navigation bar |
| overlayWarm | `#1F1916` | Warm sepia gradient on editorial images (ProjectShowcaseCard + detail heroes). Replaces pure black to push toward Sotheby's / Openhouse feel — avoid for punch overlays where contrast matters |

### Typography (`app_typography.dart`) — Campton only

**24 semantic tokens**, role-based (not shape). Use tokens at native size. Contract: `copyWith` restricted to `color` and `fontStyle` only — any other property is either a token or documented with `// EXCEPTION` in the call site. Audit tool: `bash tool/check_typography_overrides.sh`.

| Token | Size | Weight | Role |
|-------|------|--------|------|
| editorialHero | 48 | Light (300) | Top-level covers. L1 Estrategia, project_detail + news_detail heroes, feed_card title. h0.98 / ls −0.5 |
| editorialTitle | 36 | Light (300) | Interior covers (one level down). L2/L3 Estrategia heros, catalog cards (`ProjectShowcaseCard` + `LhotseNewsCard` full). h1.0 / ls −0.4 |
| editorialSubtitle | 24 | Medium (500) | Mixed-case taglines / second-level statements. brand_detail tagline, profile private banner title, search empty state. h1.3 / ls −0.3 |
| titleUppercaseLg | 24 | Medium (500) | Large uppercase titles. project_card title (home feed), large card heros, app_header title, login header, bottom_sheet title. ls −0.2 |
| titleUppercase | 18 | Medium (500) | Uppercase headers. Collapsed AppBar titles, search result project/asset/brand rows. ls −0.2 |
| figureHero | 40 | Book (400) | Full-screen detail header amount. L3 investment detail screens. tabular. h1.1 / ls −0.5 |
| figureRow | 22 | Medium (500) | Row-level capital amounts in investment rows. tabular. h1.2 / ls −0.3 |
| figureAmount | 18 | Book (400) | Ledger-level amounts (metric blocks, Estrategia L1/L2 rows). tabular. Color set per screen |
| figureCurrency | 14 | Book (400) | Paired € / currency glyph beside figureRow or figureAmount. h1.2 / ls −0.1 |
| bodyInput | 18 | Book (400) | Mixed-case text inputs (search field, auth fields). h1.2 |
| bodyEmphasis | 16 | Medium (500) | Emphasized body where the value is the read target. Ledger row title + amount, primary tab navigation. h1.4 |
| bodyRow | 16 | Book (400) | Row primary text in calm read contexts (search result rows, key-value lists, error/empty states). Lighter than bodyEmphasis. h1.4 |
| bodyReading | 14 | Book (400) | Description paragraphs (project/news/brand body), legal text, doc row name. h1.6 |
| labelUppercaseMd | 12 | Medium (500) | Active control labels: CTAs, tab markers (LhotseFilterTab), filter chips, sticky headers. **ls 1.8** |
| labelCompact | 12 | Medium (500) | Dense navigation/settings row labels, KYC rows, notification toggles. Same weight as labelUppercaseMd but **ls 0.8** for contexts where 1.8 reads too open |
| sectionLabel | 12 | Book (400) | Quiet section organizer headers. Used internally by `LhotseSectionLabel` widget and inline Row headers. **ls 1.8, w400** (vs labelUppercaseMd w500) |
| annotation | 12 | Book (400) | Short inline annotations, error messages, fine print. h1.5 |
| annotationParagraph | 12 | Book (400) | Multi-line secondary text in sheets, forms, and fine-print contexts. Same as annotation but **h1.6** for comfortable paragraph reading |
| editorialDeck | 18 | Light (300) | Standfirst between editorial title (36pt w400) and body copy — project/news detail screens + catalog cards. Lead-light pattern (T Magazine, Openhouse): differentiation by size + weight, no italic. textPrimary, h1.5, ls -0.05 |
| metaUppercase | 12 | Medium (500) | Investment row meta lines (yield, reval, payment freq, phase), trending chips, brand initials. ls 0. Case set at call site |
| metaCaption | 12 | Book (400) | Sentence-case label beneath a figure ("Valor de compra", metric column labels). ls 0 |
| labelUppercaseSm | 10 | Medium (500) | Brand names in detail screen AppBar kicker, PRIVATE/VIP chips. ls 1.2 |
| wordmarkByline | 10 | Medium (500) | Uppercase brand identifier in catalog cards, detail heroes, login CTA, PRIVATE badges. **ls 1.5** (wider than labelUppercaseSm to reinforce identity read) |
| badgePill | 9 | Medium (500) | Status pills: role badge (INVERSOR/VIEWER), KYC status, security status. ls 0.8 |
| badgeMicro | 8 | Medium (500) | Compact card bylines (`LhotseNewsCard.compact`) and notification count pills. ls 1.2 |

**Documented exceptions** (marked `// EXCEPTION` in call site):
- `editorialTitle.copyWith(fontWeight: w500)` — avatar initials in profile (w300 Light reads too thin at 36pt)
- `bodyInput.copyWith(fontWeight: w300)` — placeholder hint text (lighter than input value)
- `bodyEmphasis.copyWith(fontFeatures: [tabularFigures()])` — amount columns in `LhotseLedgerRow` (tabular alignment)
- `annotation.copyWith(fontWeight: w600/w500)` — highlighted total row in `LhotseKeyValueList`
- `bodyReading.copyWith(fontWeight: w500/w600)` — value column weight in `LhotseKeyValueList`
- `labelUppercaseSm.copyWith(letterSpacing: 0.8)` — date byline in `LhotseDocRow` (native 1.2 too wide)
- `labelUppercaseSm.copyWith(letterSpacing: 1.0/1.35)` — compact chip/form field label contexts
- `labelUppercaseSm.copyWith(fontWeight: w400)` — input field caption in `LhotseAuthField`
- `labelUppercaseSm.copyWith(letterSpacing: 2.0)` — hero kicker text (intentional opening)
- `labelUppercaseMd.copyWith(letterSpacing: 1.2)` — CTA pill on dark background
- `labelUppercaseSm/Md.copyWith(height: 1.0)` — chip vertical centering

**Contract enforcement:** `bash tool/check_typography_overrides.sh` — reports violations. `--ci` flag exits 1.

**Constante exportada:** `AppTypography.fontFamily` (`'Campton'`) — única ocurrencia legítima del literal.

### Icon scale (Phosphor Thin)

Tier guideline para iconos. No es un set rígido (los call-sites siguen pasando size inline) pero sirve como referencia de coherencia visual:

| Tier | Size | Cuándo usar |
|---|---|---|
| Inline tag | 14pt | Close button dentro de un chip pequeño, micro indicators |
| Row metadata | 16pt | Chevrons, secondary actions in row, gallery "ver más" link |
| Row primary action | 18pt | Doc category icon (visual identity), list inline icons con presencia |
| Row affordance / launcher | 22pt | RF row doc-icon (gates the doc preview), gallery launcher |
| Modal close / fullscreen close | 24pt | Fullscreen viewer dismiss (floor plan, gallery), modal close buttons |

**Jerarquía editorial**: editorial covers 48pt (`editorialHero` base) → editorialTitle 36pt → cards uppercase 24pt → headers 18pt / inputs 18pt → bodyEmphasis 16pt → bodyReading 14pt → labels 12pt → micro labels 10pt. Pesos: w300 editorial (heros mixed case), w500 values/emphasis/CTAs, w400 reading/inputs/annotations.

**Strategy/Investments hero — reglas en `HeroLayout` (`lib/core/theme/app_layout.dart`)**: tokens compartidos por L1 (`InvestmentsScreen`) y L2 (`BrandInvestmentsScreen`). La regla central: `expandedHeight` se DERIVA de la tipografía vía `HeroLayout.expandedHeight(titleHeight, amountMax)` — hardcodear `maxExtent` con un valor que no encaje con el tamaño del título y del amount produce huecos vacíos dentro del hero (bug). Tokens: `chromeTopInset = 16` (status bar buffer), `chromeRowHeight = 44`, `aboveTitle = 42`, `titleAmountGap = 20`, `belowAmount = 34`, `collapsedHeight = 80` (minExtent), `collapsedAmountY = 28`. Resultados: L1 con titleHeight=88 (44pt × 2 líneas) + amountMax=46 → expandedHeight = **290**. L2 con titleHeight=72 (36pt × 2 líneas) + amountMax=42 → expandedHeight = **270**. La jerarquía L1 > L2 vive en la **tipografía** (editorialHero 44pt vs editorialTitle 36pt, amount 28→46 vs 24→42), no en hardcodear alturas. Para detail screens (project/news/coinversion) sigue aplicando `editorialHero` 48pt como cover de su propia jerarquía editorial.

**Hero `totalAmount` — semántica decidida**: la cifra grande del hero (L1 patrimonio total + L2 por brand) representa **capital invertido activo** — suma de `purchaseValue` (CD) / `amount` (RF + coinv) sobre contratos `!isCompleted`. **Excluye** contratos finalizados (capital ya recuperado, no en activo) y **excluye** ganancia/intereses generados (no se mezclan capital y cash flow en una métrica híbrida). La razón de no incluir generated: en coinv los retornos son estimados hasta el cierre — añadirlos al hero forzaría asteriscar la cifra patrimonial total, mensaje confuso para wealth review. La performance individual (yield, revalorización, intereses cobrados) se surface por card, no en el hero. NAV (capital × revalorización) es candidato roadmap, no estado actual.

Note: Figma uses Outfit, Cormorant Garamond, Menlo as placeholders — the brand standard is **Campton exclusively**.

### Spacing (`app_spacing.dart`)
Base unit: 4px. Scale: 4, 8, 16, 24, 32, 48. Page horizontal padding: 24px.

### Border Radius
| Token | Value | Usage |
|-------|-------|-------|
| sm | 8 | Buttons, chips |
| md | 12 | Cards |
| lg | 16 | Bottom sheets |
| xl | 24 | Large cards |
| full | 999 | Avatars, pills |

## Components
To be extracted from Figma as screens are built:
- [x] Bottom navigation (5 tabs) — custom `_LhotseNavBar` in `shell_screen.dart`. Zara-inspired hybrid: icon-only (Phosphor thin: house, magnifyingGlass, user) for universal tabs + text-only (FIRMAS, ESTRATEGIA) for non-obvious tabs. Beige background (seamless with content), no border/shadow. Active indicator: 4px black dot below. Notification indicator: 4px red dot (same position). Bottom-aligned with SizedBox(22px). Text at bodyMedium w400 with FittedBox scaleDown
- [x] Project card — `ProjectCard` in `home/presentation/widgets/project_card.dart`. Zara-style: image pure (no overlay) + text below on beige. Name at headingLarge (24px), brand·location caption below. Legacy widget (the Opportunities/Home-carousel screens that used it were removed — ADR-55). **Not** used in AllProjects/Search catálogo — see ProjectShowcaseCard below
- [x] Feed card — `FeedCard` in `home/presentation/widgets/feed_card.dart`. Universal SNKRS-inspired card for Home feed (one per viewport, 65% media + 35% beige caption). Title `editorialHero` Campton Light w300 48pt — same token as archive showcase + project/news detail heroes, so the Hero transition lands without size jump. Meta row `annotation` accentMuted, inline with right-aligned textual CTA (VER PROYECTO / LEER / EXPLORAR) in `labelUppercaseSm` + arrow icon. Media block wrapped in `Hero(tag: 'project-hero-{id}' | 'news-hero-{id}' | 'asset-hero-{id}')` for shared-element transition into the detail — matching the tags used in `ProjectShowcaseCard` and `LhotseNewsCard`. Supports image or muted-autoplay video via `_Media` child. Renders 4 variants via `_FeedContent` resolver: `FeedProjectItem`, `FeedNewsItem`, `FeedBrandItem`, `FeedAssetItem`.
- [x] Project showcase card — `ProjectShowcaseCard` in `home/presentation/widgets/project_showcase_card.dart`. **Escaparate curado** (Sotheby's / Hermès catalog density). **3:2 image** `AspectRatio(3/2)` with `LhotseImage` wrapped in `Hero(tag: 'project-hero-{id}')`. Image hosts only the **VIP "PRIVATE"** fill chip top-right (gating info, not classification — see chip pattern below). Caption: title `editorialTitle` 36pt mixed case (maxLines 2) → deck `editorialDeck` 18pt w300 textPrimary h1.5 (maxLines 1) → 3-token byline `{BRAND uppercase} · {city} · {phase.label}` (`labelUppercaseSm` ls 1.5 for brand, `annotation` accentMuted for city+phase) → separator `  ·  ` `textPrimary` 40% alpha. `isLocked` → `showVipLockSheet`. Separator between cards `AppSpacing.lg`. Used in `ProjectsArchiveBody` (Firmas › PROYECTOS sub-tab).
- [x] Brand card — `_BrandCard` in `brands/presentation/brands_screen.dart`. **Magazine cover format** (ref. *The World of Interiors* biblioteca de issues, ADR-50 v5). 2-column grid (**portrait** `childAspectRatio: 0.82`, `crossAxisSpacing`/`mainAxisSpacing` `AppSpacing.lg` 24) over `AppColors.background` with hairline border 0.5px alpha 0.18. Column split 25/75: **top 25%** holds centered `BrandWordmark(size: sm)` (36pt height, intrinsic width via unified viewBox 3.2:1) wrapped in `Padding.symmetric(horizontal: 12)` — see BrandWordmark entry; **bottom 75%** renders `LhotseImage(brand.coverImageUrl)` inside `SizedBox.expand` (forces real `BoxFit.cover` regardless of source aspect — portrait brand covers would otherwise respect their intrinsic ratio and render narrow-centered) wrapped in `Padding.fromLTRB(12, 0, 12, 12)` over the same beige background — the lateral + bottom margin evokes a framed magazine cover within the card. Fallback: when `coverImageUrl` is empty, card collapses to the logo-only centered layout. Tap navigates to brand detail (no shared-element Hero yet).
- [x] Brand wordmark — `BrandWordmark` in `core/widgets/brand_wordmark.dart`. Único punto de render para los wordmarks SVG (`brand.logoAsset` centered + opcional `brand.logoAssetDetail` tight — ver ADR-65). Cuatro size tokens con dos estrategias de sizing distintas: **`xs` (24h)** y **`sm` (36h)** se ciñen al ancho intrínseco del SVG (`SvgPicture(height:, fit: contain)`) — el padre provee el slot uniforme (filter row `SizedBox(80×32)`, grid card `Expanded(flex:25)`, search row `width: 56`). **`md` (140×28)** y **`lg` (240×56)** envuelven el SVG en un contenedor fijo (`SizedBox.fromSize`) con `BoxFit.contain` + `alignment` parametrizable — la zona del logo queda **uniforme entre marcas** independiente de su aspect ratio (Ammaca 2:1 vs Vellte 10:1 comparten el mismo bounding box visual). `preferDetail: true` lee `logoAssetDetail` con fallback transparente a `logoAsset`. `alignment: Alignment.centerLeft` en el hero del detalle (anchor a padding-left de la Column); `Alignment.center` (default) en el header flotante. ColorFilter monocromo `srcIn` con `tint = color ?? AppColors.textPrimary`. Fallback opcional cuando ambas variantes son null (texto uppercase del nombre por defecto, o widget custom). **NO usar `SvgPicture` directamente en otras pantallas que muestren un wordmark**: pasa por este widget para mantener consistencia y evitar el bug de inflación de ancho en `Column-start` (ver gotcha global Flutter en `~/.claude/CLAUDE.md`).
- [x] News card — `LhotseNewsCard` in `core/widgets/lhotse_news_card.dart`. Two variants:
  - **Default full**: **escaparate curado**, grammar parallel to `ProjectShowcaseCard`. **3:2 image** `AspectRatio(3/2)` with `LhotseImage` wrapped in `Hero(tag: 'news-hero-{id}')`. No chip on image (type is not gating info). Caption: title `editorialTitle` 36pt mixed case (maxLines 2) → deck `editorialDeck` 18pt w300 textPrimary h1.5 (maxLines 1, skipped if absent or placeholder) → 2-token byline `{BRAND uppercase} · {date}` (`labelUppercaseSm` ls 1.5 for brand, `annotation` accentMuted for date) — type (`PRENSA`/`PROYECTO`) lives in the filter bar, not the byline. Separator `  ·  ` `textPrimary` 40% alpha. Required `heroTag` param. Separator between cards `AppSpacing.lg`. Used in `NewsArchiveBody` (Firmas › NOTICIAS sub-tab).
  - **Compact** (`.compact()`): 260×160 with beige overlay on image (surface 75%), single-line uppercase title + brand·subtitle meta. Used in horizontal carousels inside news detail + coinversion detail
- [x] Project carousel — `ProjectCarousel` in `home/presentation/widgets/project_carousel.dart`. PageView with 5s auto-scroll + progress bar
- [x] Search field — `LhotseSearchField` in `core/widgets/lhotse_search_field.dart`
- [x] Brand filter row — `LhotseBrandFilterRow` in `core/widgets/lhotse_brand_filter_row.dart`. Horizontal scroll de `BrandWordmark(sm, preferDetail: true)` (36pt height sobre el SVG tight `logoAssetDetail`, fallback transparente a `logoAsset`, fallback final a inicial) — single-select por opacidad (1.0 activo, 0.35 inactivo, 0.6 idle) + punto 4px bajo el logo de la marca activa. Slot solo con altura (`SizedBox(height: 36)`); el ancho lo da el SVG tight y el spacing entre marcas el `separatorBuilder` (`AppSpacing.lg`). Outer container 64pt. Usado en los sub-tabs Proyectos y Noticias de `BrandsScreen` (no en Firmas — el grid de marcas ya es el listado).
- [x] Filter bar — `_FilterBar` in `all_projects_screen.dart`. Status filters + brand/search tool icons after separator
- [x] Scroll-aware filter bar — `ScrollAwareFilterBar` in `core/widgets/scroll_aware_filter_bar.dart`. Premium reading-app UX (Apple Stocks / NYT): hides itself completely while the user actively scrolls down (threshold 6pt), restores itself after 2s of scroll idleness. No collapsed pill — the primary navigation tabs (FIRMAS/PROYECTOS/NOTICIAS) above already communicate the active section, so a textual placeholder would be redundant. Uses `AnimatedSize` (250ms easeOutCubic) + `AnimatedSwitcher` (200ms fade) for the transition. Host screen owns a `ScrollController` passed in; `expanded` slot receives the screen-specific filter layout. Used in AllProjects + AllNews + both Archive bodies
- [x] Back button — `LhotseBackButton` in `core/widgets/lhotse_back_button.dart`. Two variants: `.onImage()` (frosted glass circle, backdrop blur, white arrow) and `.onSurface()` (minimal navy arrow, opacity feedback). 44px touch target, 20px icon. Defaults to `context.pop()`
- [x] Ledger row — `LhotseLedgerRow` in `core/widgets/lhotse_ledger_row.dart`. Leading widget + title/subtitle + amount/return. isLast (no border), muted (for completed). Used in brand investments. Strategy screen uses custom `_BrandRow` with cross layout
- [x] App header — `LhotseAppHeader` in `core/widgets/lhotse_app_header.dart`. Back button + centered title + optional subtitle. 44px balanced sides. Shell headers (Home / Brands / Search / Profile) use `LhotseShellHeader` instead (title + notification bell — the Lhotse logo was removed from every shell header when the bell replaced it)
- [x] Bottom sheet — `showLhotseBottomSheet` in `core/widgets/lhotse_bottom_sheet.dart`. Drag handle + title + scrollable list. Fixed height adapted to content (clamp 0.3–0.8), cannot expand (maxChildSize = initialSize), drag down to dismiss. Optional `listPadding` for items with own padding
- [x] Metric block — `LhotseMetricBlock` in `core/widgets/lhotse_metric_block.dart`. Value (headingSmall 18px) + label (bodySmall 12px). Used in 2x2 grids across all investment detail variants
- [x] Section label — `LhotseSectionLabel` in `core/widgets/lhotse_section_label.dart`. Uppercase text (labelLarge 11px/700, letterSpacing 1.8, accentMuted). Used across all detail screens
- [x] Construction status — `_ConstructionStatus` in `investment_detail_screen.dart`. Phase (18px) + "En plazo"/"Retrasado" badge (navy 6% / danger 10% bg)
- [x] Document row — `_DocumentRow` in `investment_detail_screen.dart`. Type icon (scale/banknote/hardHat/receipt) + name + date + preview/download actions
- [x] Filter chip — `LhotseFilterChip` in `core/widgets/lhotse_filter_chip.dart`. Rectangular sharp-edge chip: black bg + white text when active, transparent + hairline 0.5px border (alpha 0.18) when inactive. Caps text with `height: 1.0` + asymmetric padding (`fromLTRB(8, 9, 8, 7)`) for optical centering of uppercase glyphs. Distinct from search `_TagChip` (mixed case, query-style).

  **Filter chip selection model — choose by dimension semantics:**

  | Dimension type | Cardinality | Behaviour | Clear affordance | Example |
  |---|---|---|---|---|
  | Boolean / mutually exclusive | 2 | Single-select toggle — tap active chip to deselect | None (re-tap = clear) | Status: EN DESARROLLO / FINALIZADOS (Firmas › Proyectos) |
  | Facetable category | 4–8 | Multi-select toggle — any combination valid | `PhosphorIconsThin.x` (14px, accentMuted) trailing the chip row, visible only when ≥1 active; add `SizedBox(width: AppSpacing.lg)` after it for scroll breathing room | Category: Contrato / Acta / Boletín (L3 Docs tab) |
  | High-cardinality facet | 50+ | Single selection via bottomsheet with search | Sheet dismiss = clear | Firma / Brand (Projects filter) |

  **Decision rule:** identify the dimension's cardinality and exclusivity *before* wiring chips. Do not default to one pattern.
- **Image overlay chips** (pattern, not a single widget) — chips on top of the card image signal **gating/privileged status only**, not content classification. Phase and news-type are descriptive metadata; they live in the byline caption, not on the image.
  - **Fill chip (privileged)**: `AppColors.primary` bg + white caption w500 ls1.5. Used for VIP "PRIVATE" top-right of `ProjectShowcaseCard` — the only chip that belongs on a catalog image.
  - **Outline chip style** (transparent + 0.5px white border + soft `BoxShadow(Color(0x33000000), 8)` + white w500 ls1.5) exists as a pattern for future gating cases; currently unused in catalog cards (phase chip was removed in favor of byline).
- [x] Key-value list — `LhotseKeyValueList` in `core/widgets/lhotse_key_value_list.dart`. Label-value rows with 0.5px dividers, optional `highlightLast` (bold last row for totals). Entries support `copyable: true` — renders inline `PhosphorIconsThin.copy` (18px, muted), tap copies to clipboard + snackbar. Used for Ref. catastral, IBANs, etc.
- [x] Button variants — `_AuthButton` in `welcome_screen.dart` (filled: black bg + white text; outline: transparent + white 1px border + white text). `_SubmitButton` in `login_screen.dart`/`register_screen.dart` (primary: black bg, full-width 52px, loading state with CircularProgressIndicator). All: `borderRadius: 0` (sharp edges), Campton w500 12px uppercase, letterSpacing 1.2, opacity feedback 120ms
- [x] Trending chip — `_TrendingChip` in `search/presentation/search_screen.dart`. Pill shape (borderRadiusFull), white 40% bg, subtle border, Campton 12px medium
- [x] Collection card — `_CollectionCard` in `search/presentation/search_screen.dart`. Image + bottom gradient + brand name, same visual language as brand cards
- [x] Search result item — `_ProjectResultItem` in `search/presentation/search_screen.dart`. 64px thumbnail + name/brand/location metadata + arrow icon
- [x] Empty results — `_EmptyResults` in `search/presentation/search_screen.dart`. Heading + subtitle, no illustration
- [x] Shell header — `LhotseShellHeader` in `core/widgets/lhotse_shell_header.dart`. Row with child (title) + notification bell. Safe area aware. Used in Home, Brands, Search
- [x] Notification bell — `LhotseNotificationBell` in `core/widgets/lhotse_notification_bell.dart`. Bell icon + badge (count or dot). Accepts `color` param. Used in `LhotseShellHeader` (Home, Brands, Search, Profile) and in Strategy's collapsing `_HeroDelegate` via `Positioned` (same widget, `color: textPrimary` on beige)
- [x] Notification badge — `LhotseNotificationBadge` in `core/widgets/lhotse_notification_badge.dart`. Red dot (6px circle) or pill counter. Exception to sharp-edges rule
- [x] Notifications sheet — `showNotificationsSheet()` in `features/notifications/presentation/notifications_sheet.dart`. Bottom sheet with date-grouped notifications (HOY/ESTA SEMANA/ANTERIORES), type icons, read/unread state
- [x] Role badge — `UserRole.badgeColor` / `UserRole.label` in `profile_screen.dart`. Sharp edges, 9px Campton w500, white text, letterSpacing 1.2. Colors: viewer=accentMuted (#5A5854), investor=primary (#000000), investorVip=gold (#DAAC03)
- [ ] Empty state
- [ ] Skeleton/shimmer loading
- [ ] Modal VIP

## Screen Patterns
- [x] List screen — Firmas (brand list), `ProjectsArchiveBody` (projects catalog inside Firmas PROYECTOS sub-tab), `NewsArchiveBody` (news catalog inside Firmas NOTICIAS sub-tab)
- [x] Detail screen — ProjectDetail (SliverAppBar hero 200px, editorial scroll: identity headingLarge + description + **TOUR VIRTUAL (opcional)** + GALERÍA carousel + CTA "DESCARGAR FOLLETO". No tabs, no shadow panel. Collapsed header: name + brand subtitle + fade gradient below). **TOUR VIRTUAL** section: only renders when `project.virtual_tour_url != null`. Layout: `LhotseSectionLabel('TOUR VIRTUAL')` + 16:9 thumbnail (uses `project.imageUrl` with `Color(0x66000000)` overlay + `arrowsOutSimple` icon 32pt + `INICIAR TOUR` label `labelUppercaseMd` white centered). Tap pushes `FullscreenVirtualTour` (`webview_flutter`-based) — provider-agnostic, loads any tour URL (Matterport, Panoee, Kuula, etc.). Modal supports portrait + landscape and shows loading spinner / "Tour no disponible" error state. The thumbnail-then-fullscreen pattern mirrors the editorial restraint of Sotheby's / Engel & Völkers and avoids paying the WebView render cost for users who don't open the tour.
- [x] Search screen — SearchScreen (header + search field + idle: trending tags + collections grid / active: project results + documents placeholder)
- [x] Strategy screen — InvestmentsScreen (full-beige collapsing hero via `SliverPersistentHeader` + `_HeroDelegate` on `AppColors.background` — no photo, no gradient, all text `textPrimary`. **Hero dimensions deriven de `HeroLayout`** (`lib/core/theme/app_layout.dart`): titleHeight=88 (`editorialHero` 44pt w300 height 1.0 override × 2 líneas), amountMax=46 → `expandedHeight = topPadding + 290`, `collapsedHeight = topPadding + 80`. Title fades 40→100% expandRatio, amount interpolates 28→46pt with `letterSpacing: -1.2` y tabular figures, € suffix 13→21pt w300 alpha 0.55. Logo+bell pinned at top; brand rows: name uppercase + capital `figureAmount` w500 inline left + chevron right; brand marker — SVG `icon_asset` or initials monogram (RF, L&B) — no per-firma return %, no business-model breakdown, no opportunities section. The L1 row purposely strips the % column: aggregate yield across heterogeneous business models (coinv/CD/RF) over only-active capital is misleading; rentability surfaces in L2/L3 in context. Aligned with L2 coinv-active row, which also omits %)
- [x] Brand investments screen — BrandInvestmentsScreen (collapsing beige hero **deriva de `HeroLayout`** con la tipografía L2 (titleHeight=72 = `editorialTitle` 36pt × 2 líneas, amountMax=42) → `expandedHeight = topPadding + 270`, `collapsedHeight = topPadding + 80`. Comparte lienzo y comportamiento con L1 (mismos tokens de spacing) pero baja un nivel tipográficamente: title 36pt vs L1 44pt, amount 24→42 vs L1 28→46, € 16→28pt w400. La jerarquía L1 > L2 vive en la tipografía, no en hardcodear maxExtent. Colapsa a centered amount + brand-name subtitle uppercase 10pt; back button onSurface en lugar de logo+bell; sticky section label. **compraDirecta activa**: `_PurchaseRow` con imagen 96×72 (4:3, natural para arquitectura), capital `figureAmount` 22pt top, address standalone `bodyReading` 14pt sentence case `maxLines: 1 + ellipsis` (sin city — el contexto de marca cubre región; el L3 detail tiene full address), línea meta `{rentalYieldPct}% · ±{assetRevaluationPct}% revalorización` sentence case con `letterSpacing: 0`. Yield bare sin "anual" (paralelo a RF que dropea `ANUAL` por convención TIN). Revalorización con color direccional: green (#2D6A4F) si > 0, muted red (#7F1D1D) si < 0, accentMuted si == 0. Yield stays grey (es una rate, no un delta). Estructura paralela a `_RentaFijaRow` (capital → identidad → meta), 3 líneas en la columna derecha. **coinversión activa**: `_CoinvestmentRow` con imagen 96×72 (4:3, mismo que CD), capital `figureAmount` 22pt top, project name standalone `bodyReading` 14pt accentMuted ellipsis (sin location), línea meta `Plazo estimado · {months} meses` (sentence case `letterSpacing: 0` accentMuted). Sin verde (todo forward-looking estimado). El `%` estimado se omite intencionalmente — surfaces en el L3 detail. El footnote `* Rentabilidad y duración estimadas` se eliminó — la inline `Est.` lo reemplaza per la convención editorial (T Magazine/Sotheby's). **coinversión completada**: mismo widget con `isCompleted: true`, 3 líneas (capital · projectName · `Ganancia +€` con verde solo en la cifra). ROI/TIR/duración salen de la card y viven en L3 detail — la card prioriza performance signal limpia. **rentaFija**: `_RentaFijaRow` con 56×56 black date-block (month abbr + 2-digit year, badge-style), capital `figureAmount` 22pt + two-line meta sentence case con `letterSpacing: 0`. Active: `{rate}% · Vence MM/YY` + `Pago {freq} · Recibido +€` green. Completed mirrors la misma estructura tripartita con verbos paralelos: `{rate}% · Vencido MM/YY` + `Recibido +€` green. **Sección FINALIZADAS** (los 3 modelos): header uppercase tracked + subhead `bodyReading` 14pt sentence case con count + verbo de cierre + `+€` ganancia realizada en verde. Copy adaptado: `X contratos vencidos` (RF), `X propiedades vendidas` (CD), `X proyectos cerrados` (coinv). Singular/plural automático. Si gain=0, solo count. Section header `ACTIVAS`/`FINALIZADAS` es el único uppercase tracked anchor — meta inline stays sentence case to keep the section label as the single graphic accent. Compraditreta usa `_AssetRow` con `returnLabelSpans` para completadas (legacy, no migrado). Sorted by soonest maturity (RF), doc icon per row (RF only))
- [x] Investment detail screen — InvestmentDetailScreen (model-aware). compraDirecta: 2x2 metrics+financing section. rentaFija: 3x2 metrics. coinversión: extracted to CoinversionDetailScreen (30% Zara / 70% Revolut calibration) — 32% compact hero (headingLarge 24px title + location·phase inline on image, construction badge top-right, AnimatedSwitcher logo), hero participation at displayLarge (40px/900) + 3-column secondary row at headingLarge (24px) with vertical dividers, Bloomberg scenario panel (bordered tab pills, hero ROI+TIR at displayMedium 28px, detail pair at headingSmall 18px, AnimatedSwitcher 300ms), compact timeline (6/10px square nodes, 1.5px lines, phase.title + pulse), immersive gallery (75% width × 200px cards, shadows, square play, page indicators), premium expandable tiles with collapsedPreview (AnimatedSize+FadeTransition, row dividers, bold total visible when collapsed). PROYECTO tab: INFORMACIÓN → PLANO DEL INMUEBLE → RENDERS → **TOUR VIRTUAL (opcional)** — la sección Tour Virtual se renderiza solo cuando `coinvestmentProjectDetail.virtualTourUrl != null` y reusa `VirtualTourSection` (mismo widget que el L1 ProjectDetail), con `tourImageUrl = c.projectImageUrl`. Archive zone (xl spacing): Documents (maxVisible 3) + News carousel
- ~~All news screen~~ — removed. Replaced by `NewsArchiveBody` inside Firmas NOTICIAS sub-tab.
- [x] Profile screen — ProfileScreen (header + identity section tappable→edit, role badge, menu sections, Lhotse Private banner, logout)
- [x] Profile sub-screens — EditProfileScreen (form fields), KycScreen (document status), NotificationsScreen (toggle sections), SecurityScreen (password/biometric/2FA), SupportScreen (contact methods), LegalTextScreen (shared for terms+privacy)
- [ ] Dashboard screen (home, investments overview)
- [x] Auth screens — WelcomeScreen (video loop fullscreen via `video_player`; Ken Burns image fallback while loading — `AnimationController` 12s scale 1.0→1.08, repeat; velvet gradient multi-stop 65% height; logo 44px; tagline 13px w400 white 75% letterSpacing 2.0; single CTA outline 0.5px), LoginScreen (beige bg, header + email/password form). No registro — solo admins crean cuentas via Supabase dashboard.
- [x] Auth field — `LhotseAuthField` in `auth/presentation/widgets/lhotse_auth_field.dart`. Underline-only border (0.5px inactive → 1px focused), Campton 18px w400, caption label above (accentMuted uppercase letterSpacing 1.8), optional eye toggle (PhosphorIconsThin 20px), error text below (danger color)

## Financial Data Display
- Positive values: success color, `+` prefix optional
- Negative values: danger color (`#7F1D1D`), `−` prefix
- Currency always with `€` symbol
- Large numbers: abbreviated with suffix (€1,2M) or full with separators (€1.234.567)
- Percentages: one decimal (12,5%), colored by positive/negative
- **Green (#2D6A4F) / Red (#7F1D1D) = directional deltas only** — green for positive directional changes (cash realized as in RF `Recibido +€` / completed contracts `+ROI%`, OR latent appreciation as in `assetRevaluationPct > 0`); muted red for negative directional changes (only latent depreciation today since negative realized returns aren't surfaced). Active rates and yields (RF `8.0%`, CD `rentalYieldPct`) stay accentMuted — they are **rates**, not deltas, and don't carry directional meaning. Forward-looking estimates (coinv `estimatedReturnPct`) are not surfaced in row chrome — they live in L3 detail in context. The wealth voice rejects the Bloomberg semáforo where every +/- is colored; green/red are reserved for the specific "this number tells you direction of value movement on an asset/cash position" signal
- **Estimated returns are L3-only** — per-firma % (L1) and per-coinv-project % (L2 active) are deliberately omitted. Aggregating estimated yield across mixed business models or surfacing forward-looking returns next to active capital reads as a promise. Estimates surface in L3 detail where they have context (project scenarios, duration, business model). RF active rate (`{guaranteedRate}%`) and CD active yield/revaluation are exceptions: contractual rates and observed-to-date deltas, not forward estimates
- **Row meta case (JPM Private × Sotheby's register)** — inline meta on financial rows (rate, vencimiento, frecuencia, recibido) is **sentence case** with `letterSpacing: 0`. Uppercase tracked is reserved for section headers (`ACTIVAS`, `MIS ACTIVOS`, `FINALIZADAS`) so they remain the single graphic anchor per section. Drop redundant labels by convention (`% ANUAL` → `%` since TIN is the default for private fixed-income contracts).
- **Disambiguation labels are mandatory, not decorative** — `Vence` prefixes maturity dates (vs. next-payment dates), `Pago {freq}` prefixes payment frequency, `Recibido` prefixes the accumulated total received. Without `Recibido`, a green `+€` figure adjacent to `Pago mensual` reads as monthly flow when it is in fact contract-to-date accumulation. Canonical accumulated label is `Recibido` (not `Cobrado`, `Ingresado`, or `Acumulado`)
- **FINALIZADAS section subhead** (`BrandInvestmentsScreen` · all 3 business models): tras el header `FINALIZADAS` uppercase tracked, una segunda línea sentence case `bodyReading` 14pt grey muted con count + verbo de cierre adaptado al modelo + label `Ganancia` + `+€` ganancia realizada en verde luxury (#2D6A4F). Copy: `X contratos vencidos · Ganancia +Y€` (RF), `X propiedades vendidas · Ganancia +Y€` (CD), `X proyectos cerrados · Ganancia +Y€` (coinv). Singular/plural automático. La cifra `+€` cubre solo **ganancia** (no capital recuperado) — el capital ya volvió al inversor, no es performance del brand. Si `gain == 0` (datos incompletos) se muestra solo el count, sin `· Ganancia +0€`
- **`Recibido` vs `Ganancia` por estado del contrato** — disambiguación semántica importante:
  - **Estados activos** con cash flow periódico (RF activa con `interestPaidToDate`): `Recibido +€`. Literal correcto — el cash ha llegado a fecha de hoy, el capital sigue invertido.
  - **Estados completados** (RF/coinv terminados, FINALIZADAS subhead): `Ganancia +€`. La cifra es gain neto; el capital ya volvió aparte. "Recibido" en completado es ambiguo (puede leerse como total cobrado = capital + gain), `Ganancia` cierra la ambigüedad. Aplica a `_RentaFijaRow` con `isCompleted: true`, a `_CoinvestmentRow` con `isCompleted: true`, y al subhead de FINALIZADAS.
  - **CD completada** sigue legacy con `_AssetRow.returnLabelSpans` mostrando ROI%, no usa `Ganancia` aún — pendiente de migración a `_PurchaseRow` con flag `isCompleted` (ROADMAP)
- **`Est.` italic prefix para forward-looking** (`_CoinvestmentRow` activo): métricas estimadas (`estimatedReturnPct`, `estimatedDurationMonths`) van precedidas de `Est. ` italic capitalized al inicio de la meta line. Cubre todas las cifras que la siguen por proximidad — no se repite. Reemplaza el patrón fintech `*` + footnote, que es Robinhood/Schwab y no encaja en wealth-luxury voice (T Magazine / Sotheby's / JPM Private muestran la disclosure inline, parte del read, no en footnote oculto)

## Home Feed (SNKRS-inspired)
- **One content unit per viewport** (100vh). Media top ~65% + beige caption ~35%. Title `editorialHero` Campton Light w300 48pt — same token as archive + detail heroes so the Hero transition lands without size jump. Meta (brand · city · date) `annotation` accentMuted inline with right-aligned textual CTA (VER PROYECTO / LEER / EXPLORAR) in `labelUppercaseSm` + arrow icon.
- **Media** — always a static `LhotseImage` in the feed, wrapped in `Hero(tag: 'project-hero-{id}' | 'news-hero-{id}')` for the shared-element transition into the detail. When the item has a Bunny video URL the image is the Bunny static thumbnail (`posterUrlFor()` in `bunny_thumbnail.dart`); otherwise it is the legacy `imageUrl`. No inline autoplay in the feed — the video starts in the detail hero on transition. Hero tags match `ProjectShowcaseCard` and `LhotseNewsCard` for consistent entry from Home or Archive.
- **Item types** — `FeedProjectItem`, `FeedNewsItem`, `FeedBrandItem`, `FeedAssetItem`. Curation is **server-side** in the `home_feed_items` table (polymorphic: `source_type` + `source_id` + `sort_order`), single feed for every role (viewer, investor, investor_vip). VIP gating is per-project via `showVipLockSheet` — not filtered out of the feed. `homeFeedProvider` joins the curation list with the 4 source tables in parallel.
- **Scroll state** — tab scroll + page position preserved natively by `StatefulNavigationShell` (IndexedStack). No ad-hoc provider. Tap on the currently-active tab → `goBranch(i, initialLocation: true)` pops the branch's stack to its root (Instagram / Apple pattern).
- **Pull-to-refresh** invalidates every feed provider used by the composition.
- **Floating Lhotse mark** (`home_screen.dart` → `LhotseMark`) — sits outside the `PageView` so it stays put while cards swap. Height 44 matches `LhotseShellHeader` so the optical Y aligns across shells. Color follows the active item's `logoOnDarkMedia` flag (`true` → white, `false` → black), cross-fading 220ms on page change via `TweenAnimationBuilder<Color>`. No drop shadow — the per-item color flag carries the legibility load.
- **`logoOnDarkMedia` flag** — `home_feed_items.logo_on_dark_media` (default `TRUE`, per-slot). Lives **only on the curation table**, not on the source (projects/news/brands/assets) — the property is "how should the Lhotse mark read on THIS slot of the feed", not a global attribute of the content. Content managers flip to `FALSE` when the top-left region of the hero is bright enough that the black mark reads better.

## Archive Browsing
- `ProjectsArchiveBody` (PROYECTOS) and `NewsArchiveBody` (NOTICIAS) are sub-tabs inside the **Firmas** shell tab (2nd nav). Not inside Search.
- Both use `ScrollAwareFilterBar` and share **escaparate curado** grammar: **3:2 image**, `editorialTitle` 36pt, 1-line `editorialDeck` 18pt w300 standfirst (no italic), byline below caption — `ProjectShowcaseCard` for projects, `LhotseNewsCard` default for news.
- **Filter behavior**: no "TODOS"/"TODAS" chip — `null` state = show all (tap active chip to deselect). Tap-to-toggle on each chip.
- **Byline asymmetry** (intentional): Projects 3-token `{BRAND} · {city} · {phase}` vs News 2-token `{BRAND} · {date}`. Phase is decision-shaping for investors (exited vs active); news type is editorial categorization available via filter bar — redundant in byline.
- No chip-on-image for classification. Only **PRIVATE** VIP chip survives on image (gating info exception). See chip pattern above.
- Separator between cards `AppSpacing.lg` in both. Top padding `AppSpacing.md` before first card.

## Project + News Detail Heros (ADR-49 coherence)
- `expandedHeight = screen * 0.55` (up from the legacy 200px) with a warm sepia gradient bottom (`AppColors.overlayWarm`).
- **Identity block** — mixed-case `displayMedium` title + deck (`news.subtitle` / `project.tagline`, `editorialDeck` 18pt w300 textPrimary, no italic) + byline. **No kicker** (type categorization is redundant once the user is inside the item). News byline `{BRAND} · {DATE}` (2-token, no POR prefix — mirrors `LhotseNewsCard` for visual continuity across Hero). Project byline = location. Collapsed app-bar titles remain UPPERCASE.
- News detail: the lateral type-badge row is absorbed by the kicker — do not reintroduce a separate chip.
- When `videoUrl` is present the hero renders `LhotseVideoPlayer` (muted loop autoplay) in the detail screen. Both `project_detail` and `news_detail` behave identically: autoplaying in the hero, tap → `FullscreenVideoPlayer` with audio. All L3 Estrategia screens (compra directa, coinversión, completados) do the same. The **feed** always shows the static poster — no inline autoplay there.

## Video System (ADR-54)
Regla del sistema — el contexto de reproducción determina el tratamiento del audio:
- **Feed** — items with a video URL show the **Bunny static thumbnail** (`posterUrlFor()`, `lib/core/data/bunny_thumbnail.dart`) as a still image. No autoplay, no play-button overlay. The Hero shuttle during navigation uses this same image, guaranteeing visual continuity.
- **Inline muted** (`LhotseVideoPlayer`, `lib/core/widgets/lhotse_video_player.dart`) — always muted. `setVolume(0)` on init, autoplay only while `isActive`, loops indefinitely. Used in: Project detail hero, News detail hero, and all L3 Estrategia hero screens (compra directa, coinversión, completados).
- **Fullscreen** (`FullscreenVideoPlayer`, `lib/features/home/presentation/widgets/fullscreen_video_player.dart`) — unmuted. `setVolume(1)` on init. Controls auto-hide 3s after load / last interaction. Tap anywhere on the video toggles controls; pausing or reaching the end pins them visible. Controls: `X` close top-left, speaker toggle top-right, 72×72 play/pause in the center, scrubber + `current / total` bottom. All buttons are the shared `_ChromeButton` chassis (44×44 hit target, black 35% circle, Phosphor thin icon, `textOnDark`). Respects iOS hardware mute switch natively through AVPlayer.
- **Poster rule** — canonical poster URL = `posterUrlFor(videoUrl: ..., fallback: imageUrl)`. For Bunny CDN URLs this returns `{host}/{guid}/thumbnail.jpg` (a snapshot of the actual video frame), making poster → first video frame visually seamless. For non-Bunny or null `videoUrl` it falls back to the entity's `imageUrl`. Applies at every level: feed cards, L2 Estrategia rows (`_PurchaseRow`, `_CoinvestmentRow`, `_AssetRow` in `brand_investments_screen.dart`), and L3 detail heroes.
- **Trigger pattern** — `GestureDetector(onTap: signedVideoUrl != null ? () => _openXxxVideoPlayer(...) : null)` wraps the hero `FlexibleSpaceBar.background`. Applied uniformly to all 5 detail screens. L3 Estrategia screens swap from `LhotseImage(videoPosterUrl)` to `LhotseVideoPlayer` once `playableVideoUrlProvider` resolves a signed URL — poster is the Bunny thumb so the swap is seamless.
- **Signed URL resolution** — raw `video_url` values from DB are never passed directly to `LhotseVideoPlayer`. All call-sites watch `playableVideoUrlProvider(rawUrl).valueOrNull` (`lib/core/data/playable_video_url_provider.dart`). While pending, the hero shows the poster image (Bunny thumb when Bunny). Bunny Stream URLs signed via the `sign_video_url` Edge Function (HMAC-SHA256, TTL 1h). See ADR-56.
- **Failure path** — if `initialize()` throws, the player renders the poster + dark overlay + copy `Vídeo no disponible` + X. No retry, no spinner.

## Notifications UI
- `LhotseNotificationBell` in shell headers (Home / Brands / Search / Profile via `LhotseShellHeader`; Strategy via `Positioned` inside its `_HeroDelegate` so it paints on top of the collapsing hero at the right Z-order).
- `LhotseNotificationBadge` — 6px red dot, explicit exception to the sharp-edges rule. Also renders over the `ESTRATEGIA` tab when there are investment-related notifications pending.
- Opened via `showNotificationsSheet()` (`features/notifications/presentation/notifications_sheet.dart`) — bottom sheet grouped HOY / ESTA SEMANA / ANTERIORES with type icons and read/unread state. No filter chips (per feedback: notification centers must stay simple, action labels self-explanatory).

## Splash Screen

**Brand metaphor**: Lhotse is the 4th highest mountain in the world. The splash narrates ascent in three beats — two strokes ascend simultaneously from the base toward the summit, converging there ("the architecture is drawn"); a 150 ms beat marks the outline complete; the silhouette then crossfades into a solid mass that wipes upward from the base ("the architecture is consacrated"). Final wordmark settles below with a tracking-out animation; a soft haptic punctuates the moment of arrival.

- **Background**: `AppColors.primary` (flat black). The atmospheric gradient explored in v5 was reverted at the client's preference for the austere architectural reading.
- **Duration**: ~7.35 s total — 6.85 s animation + 0.5 s fade-out before navigation.
- **Sequence**:

| Window (ms) | Action | Curve |
|---|---|---|
| 0 → 400 | Black settle — anticipation | — |
| 400 → 2200 | Stroke trace (1.8 s): two open paths (`_strokeLeft`, `_strokeRight`) ascend simultaneously from base-left, sharing `strokeProgress`. Left path: long left-exterior diagonal up to summit. Right path: base + right exterior + valley roof + summit-right inner + summit. Both end at the summit — full outline covered with no descending segments | `Curves.easeOutCubic` |
| 2200 → 2350 | **Beat (150 ms)** — outline complete at full opacity; no fill yet. Cinematic punctuation between "drawn" and "consacrated" | — |
| 2350 → 4350 | Crossfade (2.0 s): stroke opacity 1→0 (`easeInCubic`) while the fill ascends bottom-to-top via `clipRect` (`easeOutQuart`). The fill is intentionally slower than the trace — the climactic consacration is contemplated. Last ~30 % of the fill (the narrow peak zone) settles in ~600 ms with visible deceleration | stroke `easeInCubic` / fill `easeOutQuart` |
| 3650 → 4350 | Wordmark **static fade** (0.7 s) — timed so opacity reaches 100 % exactly at t=4350 ms (fill complete). Silhouette, wordmark, letter-spacing settle, and haptic all peak in the same instant — reads as "you've reached the summit: here is Lhotse". Letter-spacing settle factor `0.78 + 0.22 × opacity`. No vertical slide | `Curves.easeOut` |
| ~4350 | **Haptic feedback** (`HapticFeedback.lightImpact`) fires once at the simultaneous arrival of fill + wordmark + settle. Only perceptible on physical device | — |
| 4350 → 6850 | Hold (~2.5 s) — fully legible composition sustained | — |
| 6850 → 7350 | Fade-out → `context.go` | `Curves.easeIn` |

- **Composition**: vertical centered — isotype (160×141 pt canvas) above, 32 pt gap, wordmark below.
- **Isotype canvas**: `CustomPaint` with paths in viewBox `25×22` (Y=0 is summit). Three static paths: `_logo` (closed silhouette, used for fill), `_strokeLeft` and `_strokeRight` (open paths, used for the dual-ascending stroke trace). The painter has three fields: `strokeProgress`, `strokeOpacity`, `fillProgress`. Hard clip edge — consistent with "sharp edges everywhere".
- **Wordmark style**: width-matched to 160 pt via `TextPainter` measurement at build time. "LHOTSE" scales to span the full 160 pt; "GROUP" uses the same computed `fontSize` and `letterSpacing` — naturally narrower and centered (luxury multi-line lock-up convention: JPM Private Bank, Cartier). During fade-in, `letterSpacing` is multiplied by a settle factor `0.78 + 0.22 × opacity` so the tracking relaxes from 22 % tight to its final value as opacity reaches 1. **No vertical slide** — the wordmark appears static in position, fading in as ink onto paper. Local splash override; `AppTypography.splashWordmark` (24 pt base) is unchanged and still consumed by `welcome_screen.dart` for its horizontal lock-up with CTA.
- **Implementation**: `lib/features/auth/presentation/splash_screen.dart`. Provider warm-up runs in parallel — does not block the animation timing. Haptic feedback is fired via a one-shot listener on `_animCtrl` (guarded by a `_hapticFired` flag).

## VIP Projects
- `PRIVATE` chip top-right of the hero image — **fill black** (`AppColors.primary`), white caption w500 letterSpacing 1.5. Coexists with the outline phase chip top-left; the fill/outline contrast creates automatic hierarchy.
- Tap on a locked VIP card → `showVipLockSheet()` — beige bottom sheet with a lock icon, hairline separator, and a monochromatic CTA.
- `gold` (`#DAAC03`) is reserved **exclusively** for the investor-VIP role badge. Do not use it anywhere else — the mono-luxury palette depends on the exception staying narrow.
