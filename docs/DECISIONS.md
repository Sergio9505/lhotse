# Architecture Decisions

## ADR-1: Stack Selection

**Date:** 2026-03-27
**Status:** Accepted

**Context:** Lhotse Group needs a mobile app for investors to track their portfolio across the group's brands. Must be native on iOS and Android.

**Decision:** Flutter + Riverpod + GoRouter + Freezed. Supabase as backend (connected later).

**Consequences:**
- (+) Single codebase for iOS and Android
- (+) Established patterns from previous projects (IE, Longevity, Debtdoo)
- (+) Riverpod provides robust state management with cache control
- (+) Freezed ensures immutable, type-safe models
- (-) Flutter web not a priority (native mobile focus)

---

## ADR-2: Mock-First Architecture

**Date:** 2026-03-27
**Status:** Superseded (2026-04-24 — Supabase fully connected, all repositories live, `lib/core/data/mock/` emptied)

**Context:** Need to show a working prototype quickly before connecting to Supabase. Business wants to see the design implemented with realistic data.

**Decision:** Repository pattern with mock implementations. All data flows through abstract repository interfaces. Mock data in dedicated files under `core/data/mock/`.

**Consequences:**
- (+) Can demo the app immediately with realistic data
- (+) Clean swap to Supabase: only implement new repository classes
- (+) Screens and controllers never touch data source directly
- (+) Forces good separation of concerns from day one
- (-) Must maintain mock data until Supabase is connected
- (-) Some features (auth, real-time) can only be fully tested after Supabase

**Transition plan:**
1. Build all screens with mock repositories
2. Set up Supabase project (tables, RLS, views)
3. Create `Supabase*Repository` classes implementing same interfaces
4. Swap provider registrations — screens unchanged
5. Delete mock files

---

## ADR-3: Lucide Icons Only

**Date:** 2026-03-30
**Status:** Accepted

**Context:** The navbar mixed Material Icons (home, search, pie_chart, person) with Lucide (layers). Material Icons have a thicker stroke weight and a utilitarian look that doesn't match the luxury/editorial aesthetic.

**Decision:** All icons use Lucide exclusively. No Material Icons for UI elements.

**Consequences:**
- (+) Uniform stroke weight across the entire app
- (+) Lucide's geometric style matches Campton typography
- (+) Consistent visual language (premium, not utilitarian)
- (-) No filled variants — active/inactive states differentiated by color only

---

## ADR-4: Navbar Labels Always Visible

**Date:** 2026-03-30
**Status:** Accepted

**Context:** Original navbar showed labels only for the active tab, causing layout jumps on tab change. Evaluated three alternatives: show/hide labels (original), labels always visible, or all-text navbar.

**Decision:** Labels always visible. Active tab: white icon + white label. Inactive tabs: gray icon + gray label.

**Consequences:**
- (+) No layout jumps — stable, predictable navigation
- (+) User always knows what each tab does (clarity over cleverness)
- (+) Matches premium finance app patterns (Julius Bär, UBS)
- (-) Slightly more visual density, but acceptable with 5 tabs

---

## ADR-5: "Estrategia" Tab Rename

**Date:** 2026-03-30
**Status:** Accepted

**Context:** The investments tab was labeled "INVERSIONES" — generic, used by every broker. Lhotse positions itself as a strategic wealth advisor, not a trading platform.

**Decision:** Renamed to "ESTRATEGIA" with compass icon. Communicates guidance, direction, and strategic planning.

**Consequences:**
- (+) Differentiates from generic investment apps
- (+) Aligns with brand positioning (advisor, not broker)
- (+) Compass icon evokes navigation/guidance — fits wealth management context

---

## ADR-6: LhotseBackButton (Frosted/Surface Variants)

**Date:** 2026-03-30
**Status:** Accepted

**Context:** Back buttons were bare GestureDetector + Icon with no touch feedback, 22px target (below 44px minimum), and inconsistent positioning between screens.

**Decision:** Reusable `LhotseBackButton` widget with two named constructors:
- `.onImage()` — frosted glass circle (backdrop blur, sigma 16, 40px circle) for use over hero images
- `.onSurface()` — minimal navy arrow for beige backgrounds, opacity animation on press

Both: 44px touch target, 20px icon, defaults to `context.pop()`.

**Consequences:**
- (+) Consistent back navigation across all screens
- (+) Frosted variant ensures visibility over any photo
- (+) Proper touch target (44px) and feedback (opacity animation)
- (+) Single widget, two variants — easy to maintain

---

## ADR-7: Strategy Screen Navy Hero

**Date:** 2026-03-30
**Status:** Accepted

**Context:** The strategy screen (Mi Estrategia) is the only screen showing real investor money. Needed visual differentiation from browsing screens (Home, Firmas, Search) to communicate "this is your private financial zone."

**Decision:** Navy (#1A1E2F) background for the hero section (header + total patrimony + return). Rest of screen stays beige. Same header dimensions (24px title, 20×18 logo) as other screens — only colors change.

**Consequences:**
- (+) Immediately communicates "VIP zone" without breaking app identity
- (+) Navy is already in the palette (navbar) — no new color introduced
- (+) Creates depth without decorative elements
- (-) Only screen with different header background — intentional exception

---

## ADR-8: Ledger-Style Brand Breakdown

**Date:** 2026-03-30
**Status:** Accepted

**Context:** Tried 2-column grid tiles for brand breakdown — felt like a dashboard widget, not financial data. The tension: editorial aesthetics vs financial data density.

**Decision:** Full-width rows inspired by private banking statements. Logo + brand name left, amount + return right-aligned. Ledger lines (0.5px at 8% opacity) as separators. No backgrounds, no cards — typography and lines create structure. Sorted by investment amount descending.

**Consequences:**
- (+) Amounts right-aligned → scannable, comparable at a glance
- (+) Tabular figures for financial precision
- (+) Consistent with how humans read financial data (left=who, right=how much)
- (+) Editorial aesthetics applied to data-dense layout = "Financial Times meets private banking"

---

## ADR-9: No Redundant Labels

**Date:** 2026-03-30
**Status:** Accepted

**Context:** Early iterations had "Mi estrategia patrimonial" label above the total, "DESGLOSE POR FIRMA" section header, and a separator line between hero and breakdown. All were redundant — the tab title already says "MI ESTRATEGIA", and the breakdown below a total is self-evident.

**Decision:** Remove all redundant labels. The number speaks for itself. Visual transitions (navy→beige) replace explicit section headers. Only add labels when the content isn't self-explanatory.

**Consequences:**
- (+) Cleaner, more confident design
- (+) Respects the investor's intelligence
- (+) Less visual noise → faster comprehension

---

## ADR-10: Opportunities in Strategy Screen

**Date:** 2026-03-30
**Status:** Superseded by ADR-52 (2026-04-24) — opportunities section removed from Strategy; discovery now lives exclusively in the Home feed.

**Context:** Debated whether "Nuevas oportunidades" belongs in the portfolio screen. Revolut keeps portfolio pure. But Lhotse investors actively seek new investments — "where do I put my next half million?" is an active question, not casual discovery. Home shows projects to all users (viewers + investors); Search is for targeted queries. Neither serves the investor scanning for their next opportunity.

**Decision:** Keep opportunities in strategy screen as a section with compact image cards (same beige overlay as Home ProjectCards, scaled down). Header "NUEVAS OPORTUNIDADES ↗" links to full filtered list. Images included because Lhotse's value prop is luxury real estate — the visual quality matters.

**Consequences:**
- (+) Serves active investors looking for next allocation
- (+) Images communicate Lhotse's differentiator (luxury, not generic finance)
- (+) Compact cards maintain financial screen tone
- (+) Full screen available for deeper exploration with filters (brand, location, search)

---

## ADR-11: Model-Aware Investment Detail

**Date:** 2026-03-31
**Status:** Accepted

**Context:** Each brand has a different business model (compraDirecta, coinversión, ciclo, rentaFija). A generic detail screen can't properly represent each model's data.

**Decision:** `InvestmentDetailScreen` switches layout based on `BusinessModel` enum from `BrandData`. CompraDirecta shows 2×2 metrics grid + financing section. Coinversión/Ciclo show grid + construction status badge. Renta Fija shows 3×2 grid with rendimiento estimado, vencimiento, frecuencia de pago. No location subtitle for Renta Fija (financial product, not property).

**Consequences:**
- (+) Each business model displays relevant data without showing irrelevant fields
- (+) `BusinessModel` enum on `BrandData` makes model detection clean
- (+) Same visual language (metric blocks, data rows) across all models — only content varies

---

## ADR-12: Documents Bottom Sheet with Type Filters

**Date:** 2026-03-31 (updated 2026-04-10)
**Status:** Accepted

**Context:** Investment detail screens can have 10+ documents. Showing all inline would dominate the screen. Needed a way to browse and filter without leaving the context.

**Decision:** Show 3 most recent documents inline with "Ver todos (N)" link (left-aligned, accentMuted w500). Full list opens via `showDocsBottomSheet` which uses `LhotseBottomSheetBody` (shared architecture) with `StatefulBuilder` for filter state. Filter chips are square (sharp edges, black fill when active, transparent when inactive, AnimatedContainer color transition, X button to clear). Bottom sheet sizes dynamically to content via `ConstrainedBox(maxHeight: 80%)` + `Column(mainAxisSize: MainAxisSize.min)` — no manual height estimation, safe area handled automatically.

**Consequences:**
- (+) Documents don't dominate the investment detail screen
- (+) Square filter chips consistent with design system (sharp edges) and coinversion detail docs tab
- (+) Dynamic sizing adapts to any number of documents without manual tuning
- (+) `LhotseBottomSheetBody` shared between all bottom sheets — single source of truth for drag handle, title, sizing

---

## ADR-13: Consistent Ledger Row Format Across Models

**Date:** 2026-03-31 (updated 2026-04-10)
**Status:** Accepted

**Context:** Each business model has different key metrics. Considered a single format for all, but RF operations are fundamentally different (no project, no location, no photo). Needed model-specific rows while maintaining visual consistency.

**Decision:** Shared visual structure (leading + content left + trailing right) with model-specific content:
- **compraDirecta**: _AssetRow — 80×60 thumbnail + name/location/amount + chevron. "MIS ACTIVOS" label.
- **coinversión**: _AssetRow — thumbnail + name/amount + "duration·%*" caption + chevron. Active footnote "* Rentabilidad estimada". Completed: returnLabelSpans "invested·duration·+ROI%" (green w600 for ROI).
- **rentaFija**: _RentaFijaRow — 42×42 date badge (MES/AÑO as identifier) + amount + "duration·%" caption. No L3 detail. Completed: amount (totalReturn) + "invested·duration·+ROI%" (green). Sorted by soonest maturity. ACTIVAS/FINALIZADAS sections. Doc icon per row.

Unified completed metrics across all models: **invertido · duración · ROI%** (L2 rows + L3 detail). Duration before ROI everywhere. Green = realized returns only.

**Consequences:**
- (+) Each model shows its relevant data without showing irrelevant fields
- (+) Same visual rhythm: [leading 36-80px] + [content stacked] + [trailing icon]
- (+) Completed metrics consistent across models — user learns the pattern once
- (+) Renta Fija avoids a redundant detail screen — L2 is self-contained

---

## ADR-14: Sequential Fade for Collapsing Heroes

**Date:** 2026-04-05
**Status:** Accepted

**Context:** Linear cross-fade between expanded and collapsed header states caused both to be visible simultaneously at ~50% scroll, creating a messy overlap. Especially noticeable on brand investments where the expanded content is large.

**Decision:** All collapsing heroes use sequential fade with no overlap:
- **First half of scroll** (expandRatio 1→0.5): expanded content fades out (opacity 1→0) and slides up (`shrinkOffset * 0.3`)
- **Second half** (expandRatio 0.5→0): collapsed content fades in (opacity 0→1)
- **Key data always visible**: amount interpolates position + size (42→24px) + alignment (left→center) throughout the transition, never disappears. Only editorial content (title, metadata) fades.
- **Bottom padding**: `expandedHeight - collapsedHeight` added to ensure enough scroll room for full collapse.

**Additional:** Adaptive collapse range for variable content heights.
When content is shorter than the full collapse range (e.g. renta fija with 3 operations + docs), the header would get stuck halfway collapsed. Fix: the delegate reads `Scrollable.maybeOf(context)?.position.maxScrollExtent` (guarded by `hasContentDimensions`) and remaps `expandRatio` to `effectiveRange = min(maxScroll, collapseRange)`, so the full visual transition (title fade, amount reposition, subtitle appear) completes within whatever scroll distance is available. For zero-scroll pages (coinversión, compraDirecta), `SliverFillRemaining(hasScrollBody: false)` fills the viewport gap so the header can't collapse at all. Non-interactive elements in the Stack (title, subtitle) are wrapped in `IgnorePointer` to prevent invisible widgets from stealing taps from the back button when collapsed.

**Consequences:**
- (+) No visual overlap between states at any scroll position
- (+) Amount (key info) always visible — matches Revolut/N26 pattern
- (+) Smooth, professional transition
- (+) Header adapts to content height — no stuck halfway states
- (+) iOS bounce physics preserved (no snap hacks or custom physics)
- (-) More complex delegate code with position/size interpolation

---

## ADR-15: Coinversion Investment Detail — Rich Content Layout

**Date:** 2026-04-06 (updated 2026-04-07)
**Status:** Accepted

**Context:** The web portal shows extensive project data for coinversion investments: hero image, renders, progress photos, videos, floor plans, property info, economic analysis, profitability scenarios (P90/P50/P10), and a project timeline. The mobile app needed to surface this content without overwhelming the investor while maintaining a premium editorial + fintech feel.

**Decision:** Extracted to `CoinversionDetailScreen` (own file). Premium editorial layout:
- **Hero image 45%**: SliverAppBar with cinematic gradients (stronger bottom 0xCC), displayMedium (28px) project name, location with decorative divider line, construction badge repositioned to top-right (status ≠ identity), AnimatedSwitcher on logo color
- **Hero participation metric**: 28px displayMedium amount as the visual anchor ("my money"), followed by 3-column secondary row (ROI, TIR, duration at headingMedium 20px) separated by vertical dividers
- **Bloomberg scenario panel**: bordered tab pills with AnimatedContainer color transitions, hero ROI+TIR at displayMedium (28px), detail metrics (sale price, net profit) at headingSmall (18px), AnimatedSwitcher (300ms fade) between scenarios
- **Square-node timeline**: sharp-edge squares instead of circles (design system consistency), 2px lines, phase.title shown for current phase, pulsing animation on current node
- **Immersive gallery**: 80% screen width cards (was 280px), subtle shadows, square play button, page indicator squares
- **Premium expandable tiles**: AnimatedSize + FadeTransition (replacing AnimatedCrossFade), row dividers between entries, bold total row with thicker divider
- **CTA polish**: haptic feedback, press-state opacity, arrow icon
- **Global widget promotion**: LhotseMetricBlock, LhotseSectionLabel extracted to core/widgets/

**Consequences:**
- (+) Bloomberg × Sotheby's editorial feel — numbers are heroes, generous whitespace
- (+) Participation amount as visual anchor answers "how much is here?" instantly
- (+) Scenario panel with animated transitions feels like a financial terminal
- (+) Consistent sharp edges (square timeline nodes, square play buttons)
- (+) Extracted to own file — cleaner separation, easier iteration
- (-) More animation code — but well-contained in individual widgets

---

## ADR-16: Per-Operation Documents for Renta Fija

**Date:** 2026-04-06
**Status:** Accepted

**Context:** Renta fija had a standalone "DOCUMENTOS" section with global documents. Each operation is an independent contract with its own documents — the global section lost this association.

**Decision:** Remove the standalone documents section. Add a document icon (`fileText`) to each operation row. Tapping opens `showDocsBottomSheet` with that operation's documents + filter tabs. All operations shown inline (removed 3-operation cap + "Ver todos" bottom sheet). Documents bottom sheet reuses the existing `_DocsBottomSheet` widget via new public `showDocsBottomSheet()` helper.

**Consequences:**
- (+) Documents contextually linked to their operation
- (+) Less vertical content — helps with short-scroll issues
- (+) Consistent filter pattern across all document bottom sheets
- (+) `showDocsBottomSheet` reusable from any screen

---

## ADR-17: Editorial/Fintech Calibration by Screen Type

**Date:** 2026-04-08
**Status:** Accepted

**Context:** The app blends two design DNAs — editorial (Zara: full-bleed imagery, bold typography, sharp edges, whitespace as luxury) and fintech (Revolut: numbers as heroes, data-first, progressive disclosure, minimal chrome). Early screens applied the same editorial weight everywhere. This caused portfolio screens (where investors manage money) to feel like discovery screens (where users explore projects). A 45% hero image makes sense when discovering a project, but steals viewport from financial data when an investor is checking their €280K position.

**Decision:** Calibrate the editorial vs fintech weight based on the screen's primary purpose. The criterion is: **"Is the user discovering or managing?"**

| Screen | Purpose | Editorial (Zara) | Fintech (Revolut) | Rationale |
|--------|---------|:-:|:-:|-----------|
| Home | Discovery | **80%** | 20% | First impression — aspirational, visual, emotional. Carousel hero images, editorial overlay cards. The investor is being inspired. |
| Project Detail | Exploration | **70%** | 30% | Deep-dive into a specific project. 55% hero image, editorial content panel with shadow. Still selling the dream. |
| Search | Discovery | **60%** | 40% | Active search with functional filters, but collections and results retain editorial thumbnails. Balanced. |
| All News | Discovery | **60%** | 40% | Content browsing with editorial full-size cards but functional filter tabs. |
| Firmas (Brands) | Discovery | **70%** | 30% | Brand showcase — 2-column grid with cover images and centered logos. Purely visual. |
| Strategy | Portfolio mgmt | 30% | **70%** | "How is my total portfolio?" — collapsing black hero with amount as the visual anchor (50→28px interpolation). Brand rows with financial data. Data-dominant. |
| Brand Investments | Portfolio mgmt | 40% | **60%** | "How are my investments with this brand?" — editorial title ("MI PATRIMONIO CON...") but beige hero (not image), asset rows with amounts, sticky labels. Mixed. |
| Investment Detail (coinversión) | Position review | 30% | **70%** | "How is my money in this specific project?" — 32% compact hero (editorial context), 40px participation amount as undisputed hero number, Bloomberg-style scenario panel, compact timeline, immersive gallery as visual break. Data-first. |
| Investment Detail (compraDirecta) | Position review | 20% | **80%** | Pure metrics — no hero image, 2×2 grid + financing section. Header with title only. Most Revolut. |
| Investment Detail (rentaFija) | Position review | 20% | **80%** | Pure metrics — no hero image, 3×2 grid. Simplest screen. |
| Opportunities | Discovery + mgmt | 50% | 50% | Investor actively scanning for next investment — project cards are editorial but filter tabs are functional. True 50/50. |

**How this translates to implementation:**

| Signal | Editorial (Zara) | Fintech (Revolut) |
|--------|-------------------|-------------------|
| Hero image | Full-bleed, 45-55% viewport | Compact 30-35% or none |
| Typography anchor | Project/brand name (displayLarge 40px) | Financial amount (displayLarge 40px) |
| Content density | Generous xxl (48px) spacing between all sections | xxl for key content, xl (32px) for utility/archive sections |
| Imagery | Immersive carousels, full-width cards | Thumbnails or compact carousels |
| Data presentation | Minimal — name, tagline, description | Metrics grids, scenario panels, expandable tables |
| Disclosure | Everything visible (scroll to experience) | Progressive (expandable, bottom sheets, collapsed previews) |
| Section rhythm | Visual → text → visual → text (magazine flow) | Data → data → visual break → data → reference (report flow) |

**Consequences:**
- (+) Each screen optimized for its user intent — discovery feels aspirational, portfolio feels authoritative
- (+) Same design tokens, components, and brand identity across all screens — only the weight changes
- (+) Clear criteria ("discovering or managing?") makes calibration decisions consistent and predictable
- (+) Investors get financial data faster on portfolio screens without sacrificing the luxury feel on discovery screens
- (-) Requires conscious calibration for every new screen — can't just default to one approach
- (-) The "mixed" screens (Opportunities, Brand Investments) need the most judgment to balance

---

## ADR-18: Notification System — Bell + Center + Contextual Badges

**Date:** 2026-04-08
**Status:** Accepted

**Context:** Investors had no way to know about updates (new documents, news, phase changes) without navigating to the correct tab and scrolling. For a premium investment app, passive discovery is unacceptable.

**Decision:** Three-layer notification system:
1. **Bell icon** in shell-level headers (Home, Brands, Search via `LhotseShellHeader`; Strategy via `Positioned` in hero delegate). Shows unread count badge. Tap opens notification center. Replaces the Lhotse logo that was in that position.
2. **Notification center** as bottom sheet (`showNotificationsSheet`). Date-grouped list (HOY/ESTA SEMANA/ANTERIORES) with type icons (document, news, phase, financial, delay), read/unread state, and navigation to the relevant investment detail + tab.
3. **Contextual badges** (red dots) on nav bar ESTRATEGIA tab, and planned for brand rows, investment rows, and detail tabs.

Architecture: `LhotseNotificationBell` (single widget, accepts `color`) used by both `LhotseShellHeader` (Row layout) and Strategy (Positioned layout). `LhotseNotificationBadge` handles both dot (6px) and counter (pill) variants. Badge is circular — exception to sharp-edges rule (universal UI standard).

Push notifications: deferred to Supabase connection. The in-app system is mock-first, ready to swap to realtime.

**Consequences:**
- (+) Investor always knows about updates without navigating
- (+) Bell replaces redundant logo — more functional use of space
- (+) Single `LhotseNotificationBell` widget works in both Row and Positioned layouts
- (+) Mock-first: ready for Supabase realtime swap
- (-) No push notifications until backend is connected
- (-) Bell position in Strategy required Positioned (not Row) due to custom hero delegate

---

## ADR-19: Renta Fija L2 Design — Date Badge + No L3

**Date:** 2026-04-10
**Status:** Accepted

**Context:** Renta fija operations are simple (fixed duration, fixed rate, monthly payments). An L3 detail screen would be redundant. The L2 screen needed to be the terminal view while showing enough data and maintaining premium design.

**Decision:** Dedicated `_RentaFijaRow` widget with:
- **Date badge** (42×42 black square): shows start month + year (e.g., "MAR 26") as the operation identifier. Replaces numbered badges (1, 2, 3) which had no meaning. Start date is a real identifier — each operation started on a different date.
- **Active rows**: amount (headingSmall 18px) + "duration MESES · 8%" (caption 10px). Two lines, proportional with badge.
- **Completed rows**: totalReturn as hero amount + "invested · duration · +ROI%" with green w600 for ROI (realized return).
- **Sorting**: active by soonest maturity first; completed by most recent completion.
- **No L3**: doc icon per row opens `showDocsBottomSheet` with per-operation documents. No navigation to detail screen.
- **Sections**: "ACTIVAS" + "FINALIZADAS" matching coinversión pattern.

Model fields added to `InvestmentData`: `accumulatedInterest`, `periodicPaymentAmount`, `paymentsReceived`, `totalPayments`, `nextPaymentDate`. All optional, RF-only.

**Consequences:**
- (+) Date badge is a meaningful identifier (vs arbitrary numbering)
- (+) Two-line rows proportional with 42px badge — no visual imbalance
- (+) Sorting by maturity answers "what's ending soonest?" — the key RF question
- (+) No redundant L3 screen — all info fits in L2 row + doc bottom sheet
- (+) ACTIVAS/FINALIZADAS sections consistent with coinversión
- (-) Date badge pattern unique to RF — but justified by the model's nature (no project photo, no brand logo)

---

## ADR-20: Unified Completed Metrics — Invertido · Duración · ROI

**Date:** 2026-04-10
**Status:** Accepted

**Context:** Completed investments showed different metrics per model: coinversión had ROI + plusvalía, RF had nothing (was hidden). Needed a consistent pattern.

**Decision:** All completed investments show 3 metrics: **invertido · duración · ROI%**. Duration before ROI. Applied to:
- L1 (Strategy): not applicable (shows active summary only)
- L2 (Brand investments): subtitle in caption, ROI in green w600
- L3 (Completed detail): 3 LhotseMetricBlock widgets (invertido, duración, ROI)

Plusvalía removed — derivable from hero (totalReturn) minus invested. Duration added — contextualizes the ROI (16% in 24 months ≠ 16% in 48 months). RF uses contractual duration; coinversión uses `actualDuration` (real). Green (#2D6A4F) only for realized returns.

**Consequences:**
- (+) User learns one pattern for all completed investments
- (+) Duration contextualizes ROI — critical for comparing operations
- (+) No redundant data (plusvalía derivable from hero - invested)
- (+) Green = realized returns creates trust (not used for estimates)

---

## ADR-21: Phosphor Thin Icons + Zara Navbar

**Date:** 2026-04-10
**Status:** Accepted

**Context:** Lucide icons (2px stroke) felt heavy against the premium/editorial aesthetic. The navbar with all labels visible and black background felt utilitarian, not luxury. Evaluated Zara's approach: thin icons, seamless navbar, hybrid icon/text navigation.

**Decision:** Three changes:
1. **Phosphor thin** (1px stroke) replaces Lucide across all 20 files. Single weight everywhere — action is communicated by context/position, not icon weight. Lucide kept in pubspec as fallback.
2. **Navbar redesign** (Zara-inspired): beige background (seamless with content), no border/shadow. Hybrid tabs: icon-only for universal actions (home, search, profile) + text-only for non-obvious tabs (FIRMAS, ESTRATEGIA). Active state: 4px black dot below. Notifications: 4px red dot (same position). Height reduced to 48px.
3. **Typography weight reduction**: all weights reduced to w400-w500 range (was w600-w900). Weight hierarchy: w600 (displayLarge hero only) → w500 (values, active states) → w400 (labels, metadata). Size creates hierarchy, not weight.

**Consequences:**
- (+) Consistent thin aesthetic across icons and typography — Zara-level refinement
- (+) Navbar disappears visually, attention goes to content
- (+) Hybrid icon/text solves the "compass = ???" problem without labeling everything
- (+) Three-level weight system (w400/w500/w600) creates subtle hierarchy without bold
- (-) Phosphor thin may be too subtle for older users or accessibility — monitor feedback
- (-) Custom SVG icons deleted, Lucide import kept but unused in production code

---

## ADR-22: VIP Lock — Black PRIVATE Chip on Image

**Date:** 2026-04-14
**Status:** Accepted

**Context:** VIP projects need a visible lock indicator. Initial approach: gold lock icon in the text area below the image. Problem: insufficient contrast on beige background, and text-area clutter. Evaluated Revolut's approach to premium/restricted content.

**Decision:** Black "PRIVATE" chip directly on the project image (top-right, `Positioned`). Black background (`AppColors.primary`), white caption text, w500, letterSpacing 1.5. Tapping opens a beige bottom sheet (not black — black clashed with beige navbar) with lock icon, separator, and monochromatic CTA.

**Consequences:**
- (+) Guaranteed contrast on any photo (opaque black chip)
- (+) Visible without scrolling — positioned on the image itself
- (+) Revolut-inspired pattern recognizable to premium app users
- (+) Beige bottom sheet consistent with app's surface color
- (-) Takes image real estate, but minimal (small chip)

---

## ADR-23: Opportunities Filter Hierarchy — Business Model Primary

**Date:** 2026-04-14
**Status:** Superseded by ADR-52 (2026-04-24) — OpportunitiesScreen and its filter bar deleted. Opportunities now surface only as `FeedOpportunityItem` cards interleaved in the Home feed (no filters on that entry point).

**Context:** Opportunities screen had three equal-weight text tabs (FIRMA/UBICACIÓN/BUSCAR) — same flat hierarchy antipattern as the original AllNews. No primary axis for content classification. For investors evaluating opportunities, the business model (compra directa vs coinversión vs renta fija) is the most important filter — it determines risk profile, return structure, and investment mechanics.

**Decision:** Primary axis: 3 `LhotseFilterTab` text tabs for `BusinessModel` (COMPRA / COINVERSIÓN / RENTA FIJA). Secondary: single location icon tool (mapPin with dot indicator). Brands and search filters removed — brands are implicit in the model selection, and the global search screen serves text queries. Filter cross-references `project.brand → mockBrands.businessModel` since `BusinessModel` lives on `BrandData`, not `ProjectData`.

**Consequences:**
- (+) Primary axis matches investor mental model — "what type of investment am I looking for?"
- (+) Consistent with AllProjects filter bar pattern (text tabs + icon tools)
- (+) Eliminates bottom overflow from too many filter controls
- (+) Cross-reference via brand is correct — business model is a brand attribute
- (-) No text search on opportunities — acceptable since Search screen exists

---

## ADR-24: News Detail — Editorial Scroll + Video Placeholder

**Date:** 2026-04-14
**Status:** Accepted

**Context:** News items had no detail screen — tapping a card did nothing. Needed a premium editorial reading experience consistent with ProjectDetailScreen while accommodating video content (some news items have `hasPlayButton`).

**Decision:** `NewsDetailScreen` with `CustomScrollView` + pinned `SliverAppBar` (200px hero). Same scroll mechanics as `ProjectDetailScreen`:
- Hero: `LhotseImage` + top gradient + optional play button (56px frosted circle)
- Collapsed header: `AnimatedOpacity` with title (headingSmall) + brand (caption)
- Identity: title (headingLarge) + brand · date row
- Type badge: black container PROYECTO/PRENSA + subtitle
- Body: bodyMedium, textSecondary, height 1.6
- Related: "MÁS DE [BRAND]" horizontal scroll (max 3 `LhotseNewsCard.compact`)
- Video: tapping play button opens `_VideoPlayerScreen` — fullscreen black overlay, centered play icon (72px), title, "PRÓXIMAMENTE" label, X close. Placeholder until real video URLs are connected.

**Consequences:**
- (+) Consistent editorial scroll pattern with project detail
- (+) Video placeholder preserves design language — ready for real URLs
- (+) Related news section aids content discovery within the brand
- (+) Collapsed header behavior matches rest of app (sequential fade)
- (-) No CTA at bottom (removed "VER TODAS LAS NOTICIAS") — simplicity over redundancy

---

## ADR-25: Supabase Schema — Class Table Inheritance for Investments

**Date:** 2026-04-14
**Status:** Accepted

**Context:** `investments` spans 3 business models (direct purchase, coinvestment, fixed income) with model-specific fields that differ in name, semantics, and nullability. Options evaluated: (A) single wide table with ~45 nullable columns (STI), (B) CTI — thin base + 4 model-specific detail tables, (C) JSONB for model-specific fields.

**Decision:** CTI. Base `investments` table has 8 columns (id, user_id, project_id, amount, is_completed, is_delayed, created_at, updated_at). Model-specific data lives in detail tables: `direct_purchase_details`, `coinvestment_details`, `fixed_income_details`, `investment_completions`.

**Rationale:**
- STI rejected: ~15 NULLable columns per row is not "world-class" and creates semantic ambiguity — `duration_months` means something different (contractual vs estimated vs N/A) for each model
- JSONB rejected for financial fields: kills type safety, indexability, and aggregation
- CTI: every column on every detail table is semantically precise and non-nullable
- Views use COALESCE to flatten CTI into model-agnostic accessors (`return_rate`, `duration_months`, `start_date`) for generic screens
- `investment_details` view: one query covers all screens by LEFT JOINing all detail tables

**Additional tables outside base:** `mortgages` (1:0..1 — direct purchase with financing), `rental_contracts` (1:N — direct purchase rental history), `investment_transactions` (append-only financial ledger for evolution chart).

Full schema in `.claude/plans/fuzzy-forging-crescent.md`: 19 tables, 4 views, 3 RPCs, 6 storage buckets.

**Consequences:**
- (+) Zero NULLable columns on detail tables — schema enforces model invariants
- (+) COALESCE in views provides generic access without losing precision
- (+) `investment_transactions` ledger enables evolution chart per model
- (+) `mortgages` and `rental_contracts` are extensible without touching base
- (-) INSERT requires writing to 2 tables — mitigated by service_role writes from admin
- (-) `investment_details` view has 8 LEFT JOINs — acceptable at <5000 row scale

---

## ADR-26: Supabase Schema — TEXT + CHECK Instead of PostgreSQL ENUMs

**Date:** 2026-04-14
**Status:** Accepted

**Context:** Needed to define enum-like columns for `business_model`, `project_status`, `user_role`, `doc_category`, `news_type`, `notification_type`, `kyc_doc_type`, `kyc_status`, `mortgage_type`, `transaction_type`. PostgreSQL offers native `CREATE TYPE AS ENUM`.

**Decision:** `TEXT NOT NULL CHECK (col IN (...))` on every column instead of PostgreSQL ENUMs.

**Rationale:**
- PostgreSQL ENUMs cannot remove or rename values — only add. A typo or business rename requires `pg_catalog` surgery.
- TEXT + CHECK can be modified with a simple `ALTER TABLE ... DROP CONSTRAINT / ADD CONSTRAINT` in a new migration.
- No serialization difference for PostgREST/Dart — both come through as strings.
- Convention documented in `docs/CONVENTIONS.md`.

**Consequences:**
- (+) Any value can be renamed/removed via migration without `ALTER TYPE`
- (+) Constraint naming is explicit (`chk_business_model`)
- (+) Dart enums map cleanly via `@JsonValue('snake_case')`
- (-) No database-level type reuse across tables — each column repeats its CHECK

---

## ADR-27: Supabase Schema — Documents with model_type + model_id

**Date:** 2026-04-14 (updated 2026-04-15)
**Status:** Accepted (supersedes original dual-FK approach)

**Context:** Documents belong to different entity types: brands, projects, investments, offerings, contracts. The original design used nullable FKs (`project_id`, `investment_id`) with a CHECK. Adding `contract_id` for fixed income would mean a third nullable FK, more OR branches in RLS, and a pattern that degrades with each new entity type.

**Decision:** Replace nullable FKs with `model_type TEXT NOT NULL` + `model_id UUID NOT NULL`. The `model_type` CHECK covers: `brand`, `project`, `investment`, `offering`, `contract`. RLS uses a single CASE statement per type. Index on `(model_type, model_id)`.

**Rationale:**
- Standard pattern at scale (Stripe, GitHub) for polymorphic ownership
- Zero nullable columns — every row has a type and an owner
- Adding a new entity type = add a CHECK value + a CASE branch in RLS. No ALTER COLUMN.
- Documents are admin-managed (service_role writes) so the lack of FK integrity is acceptable
- `category` column (legal, financial, certificate, etc.) is orthogonal — filters by document type, not by owner

**Consequences:**
- (+) Table shape never changes when new entity types are added
- (+) RLS is a readable CASE instead of nested ORs
- (+) Composite index `(model_type, model_id)` covers all lookup patterns
- (-) No FK enforcement on `model_id` — accepted because writes are admin-only via service_role

---

## ADR-28: Supabase Schema — Separate `assets` Table for Physical Units

**Date:** 2026-04-14
**Status:** Accepted

**Context:** Physical real estate units (bedrooms, surface, floor plan, gallery) were originally embedded as fields on `projects` or as an `AssetInfo` JSONB blob. Problem: (1) a project can have multiple purchasable units, (2) asset data is needed by both `direct_purchase_details` and `coinvestment_details` (the unit is assigned post-construction), (3) individual units need their own gallery and valuation.

**Decision:** Separate `assets` table. `direct_purchase_details.asset_id` is `NOT NULL` (always has a unit). `coinvestment_details.asset_id` is nullable (assigned when construction delivers the unit). Projects keep marketing fields (gallery_images, render_images, description).

**Consequences:**
- (+) Projects remain marketing entities; assets are the physical/financial entities
- (+) Direct purchase: unit is always known → FK enforced at DB level
- (+) Coinvestment: unit assigned post-delivery → nullable FK is semantically correct
- (+) `current_value` and `revaluation_pct` live on `assets`, not on investments — correct ownership
- (-) Extra JOIN in queries, absorbed by `investment_details` view

---

## ADR-29: Asset-First FK Direction (projects.asset_id → assets)

**Date:** 2026-04-15
**Status:** Accepted

**Context:** The original schema had `assets.project_id → projects`, meaning an asset "belonged to" a project. This modelled the creation flow backwards: in reality, the physical asset (property) exists first, and then an investment project is created around it.

**Decision:** Reverse the FK to `projects.asset_id → assets` (nullable). Assets are now first-class independent entities. A project optionally references the asset it's about.

**Rationale:**
- Domain truth: you acquire or register a property first, then create investment vehicles around it
- `projects.asset_id` nullable — coinvestment projects may not have a physical unit assigned yet; it gets linked later via `coinvestment_details.asset_id` when construction delivers
- Individual unit→investment links remain at the investment level (`direct_purchase_details.asset_id`, `coinvestment_details.asset_id`), unaffected
- Data migrated cleanly: all 6 direct_purchase projects had exactly 1 asset (1:1) — `projects.asset_id` populated from the old `assets.project_id`

**Consequences:**
- (+) Assets can exist before any project references them
- (+) Cleaner insert order: CREATE asset → CREATE project (with asset_id)
- (+) Multiple projects could reference the same asset (different investment rounds)
- (-) `projects.asset_id` is nullable — coinvestment projects have NULL until assignment

---

## ADR-31: CompraDirecta + Alquiler as Separate Domains (4-domain model)

**Date:** 2026-04-15
**Status:** Accepted

**Context:** CompraDirecta investments were modelled in the shared `investments` CTI base table, with detail in `direct_purchase_details`. This forced two semantically distinct business models (compraDirecta = buying an asset; coinversión = participating in a development project) to share a base table with almost no common columns (only `user_id`, `amount`, `is_completed`). Following ADR-30 (RentaFija extraction), the same rationale applies here.

Additionally, rental management (alquiler) is a separate business activity — a management brand like Llave manages the rental of an asset, independent of the purchase transaction. Keeping `rental_contracts` linked to `investments` tied rental to the wrong entity (the investment record, not the physical asset).

**Decision:** Four independent domains, each with direct brand association:

1. **`purchase_contracts`** — user owns an asset through a selling brand (Myttas, Andhy). Direct `brand_id` FK. Completion fields inline.
2. **`rental_contracts` + `rental_payments`** — independent rental domain tied to `asset_id` + `brand_id` (management brand, e.g. Llave). Not linked to `purchase_contracts` — the join is logical via `asset_id`.
3. **`coinvestment_contracts`** — renamed from `investments`. Absorbed `coinvestment_details` and `investment_completions` inline. Brand via `project_id → projects.brand_id`.
4. **`fixed_income_contracts`** — unchanged (ADR-30).

**Rationale:**
- CompraDirecta: the investor owns a **physical asset**, not a project. The contractual relationship is with the brand that sold it. Brand = direct FK on `purchase_contracts`.
- Coinversión: the investor participates in a **development project**. Brand is reached via project. Project stays as the primary FK.
- Rental: the management brand may differ from the selling brand (Myttas sells, Llave manages). Tying rental to the asset (not the purchase record) is the correct entity. Logical join via `asset_id` allows ROI/TIR calculation in views: `(rental_payments.amount) / purchase_contracts.purchase_value`.
- Domain-specific transaction ledgers: `purchase_transactions`, `coinvestment_transactions` (replaces shared `investment_transactions`).

**Tables dropped:** `investments` (renamed), `direct_purchase_details`, `coinvestment_details`, `investment_completions`, `investment_transactions`.
**Tables created:** `purchase_contracts`, `rental_payments`, `purchase_transactions`, `coinvestment_transactions`.
**Tables restructured:** `rental_contracts` (FK changed from `investment_id` to `asset_id + brand_id`), `notifications` (`investment_id` → `model_id + model_type`), `mortgages` (`investment_id` → `purchase_contract_id`).
**Documents `model_type` CHECK updated:** added `purchase`, `rental`, `coinvestment`; removed `investment`.
**Views:** dropped `investment_details`; created `purchase_contract_details`, `rental_contract_details`, `coinvestment_contract_details`; recreated `portfolio_summaries`, `brand_investment_summaries` as 3-way UNION ALL.

**Consequences:**
- (+) Each domain has semantically precise tables — no nullable pollution, no CTI indirection
- (+) Brand association is direct and unambiguous per domain
- (+) Rental ROI/TIR computable in views without storing derived data
- (+) Documents, notifications, and RLS policies all cleaner (no OR chains)
- (-) Strategy screen aggregation requires 3-way UNION — handled in views, no Flutter change needed
- (-) Flutter models will need per-domain types when repository layer is built (InvestmentData → PurchaseContractData + CoinvestmentContractData + RentalData)

---

## ADR-30: RentaFija as Separate Domain (fixed_income_offerings/contracts/payments)

**Date:** 2026-04-15
**Status:** Accepted

**Context:** RentaFija was modelled as a `projects` row with 6 nullable columns (`payment_frequency`, `is_capital_guaranteed`, `total_payments`, `periodic_payment_amount`, `target_return_rate`, `target_duration_months`) and a row in `fixed_income_details` per investment. This was wrong: RentaFija is a financial contract (rate, duration, monthly payments), not a real estate project (location, architect, images, renders).

**Decision:** Three dedicated tables:
- `fixed_income_offerings` — product catalog (brand offers X% for Y months). Admin-managed.
- `fixed_income_contracts` — user accepts an offering; snapshots contracted rate+term at signing time. Has `status` (active/completed/cancelled), payment tracking, and completion fields.
- `fixed_income_payments` — append-only ledger of payments received per contract.

RentaFija no longer flows through `investments` or `projects`. The 2 seed "projects" (RF Capital I/II) were migrated to offerings. The 6 rentaFija columns were dropped from `projects`. `fixed_income_details` was dropped (no investment records existed yet).

Views updated: `portfolio_summaries` and `brand_investment_summaries` now UNION investments (compraDirecta+coinversion) with `fixed_income_contracts`. `investment_details` simplified to compraDirecta+coinversion only. New `fixed_income_contract_details` view added.

**Rationale:**
- RentaFija shares 0 domain concepts with real estate projects — different entity, different lifecycle
- `fixed_income_contracts` snapshots the contracted rate+term at signing — protects against future offering changes
- Clean separation enables independent RLS, independent querying, and independent UI flows
- The brand link (for strategy screen aggregation) is preserved via offering → brand

**Consequences:**
- (+) No nullable pollution in `projects` from a completely different business model
- (+) Each domain has its own clean tables with zero nullable columns (except optional fields)
- (+) `fixed_income_contracts` is the single source of truth for a user's RF position
- (-) Strategy screen aggregation requires UNION across investments + contracts — handled in views
- (-) Flutter models will need separate types for RF vs real estate investments

---

## ADR-35: purchase_contracts — Minimal Table, Computed View

**Date:** 2026-04-16
**Status:** Accepted

**Context:** `purchase_contracts` accumulated many fields that were either derivable, premature, or semantically wrong for this domain (rental yield, projected ROI, is_delayed, cash_payment, actual_duration, net_profit). This made the table 17 columns when only 7 represent raw facts.

**Decision:** Strip the table to raw facts only. Computed fields live in the view:
- `actual_roi` → computed: `(total_return - purchase_value) / purchase_value * 100`
- `cash_payment` → computed: `COALESCE(purchase_value - mortgage.principal, purchase_value)`
- `actual_duration` → computed: months between `purchase_date` and `sold_date`
- `asset_revaluation_pct` → computed: `(current_value - purchase_value) / purchase_value * 100`
- `rental_yield_pct` → computed: `COALESCE(rc.yield_pct, monthly_rent * 12 / purchase_value * 100)`
- `is_sold` → computed: `sold_date IS NOT NULL`

Removed: `is_delayed`, `projected_roi`, `cash_payment`, `actual_duration`, `net_profit`, `actual_roi`, `actual_tir`.

**Consequences:**
- (+) Table is a clean fact record — 9 columns (7 business + 2 timestamps)
- (+) Derived metrics always accurate — no stale data risk
- (+) Admin only needs to set: `purchase_value`, `purchase_date`, `total_return` (at exit), `sold_date` (at exit)
- (-) `actual_tir` (IRR) cannot be computed without a transaction ledger — removed until then

---

## ADR-36: purchase_contract_details — Asset-Centric, No Project Join

**Date:** 2026-04-16
**Status:** Accepted

**Context:** The view joined `projects` to get `project_name`, `project_image_url`, `project_location`. But compra directa is about owning an ASSET, not a project. The project is a catalog/marketing entity.

**Decision:** Remove the project JOIN entirely. Identity fields come from `assets`:
- `asset_name` → `a.address` (the investor knows their property by address)
- `asset_location` → `a.city || ', ' || a.country`
- `asset_thumbnail_image` → `a.thumbnail_image` (new field on assets, seeded from project image)

Removed from view: `project_name`, `project_location`, `project_image_url`, `project_status`, `business_model`.

**Consequences:**
- (+) View is semantically correct — compra directa ↔ asset, not project
- (+) `assets` now self-sufficient for investor display (address, thumbnail, location)
- (+) Coinversion correctly keeps its project join (investors participate in a project)

---

## ADR-37: rental_yield — Gross Fallback with Admin Override

**Date:** 2026-04-16
**Status:** Accepted

**Context:** Rental yield can be computed as `monthly_rent × 12 / purchase_value`, but this is gross yield (no expenses). When expenses data is available, the admin should set a net yield. Two approaches: always compute, or allow override.

**Decision:** `COALESCE(rc.yield_pct, round(monthly_rent * 12 / purchase_value * 100, 2))`. Admin can set `rental_contracts.yield_pct` manually (net or custom). If null, falls back to gross computation. View always returns a value when rental contract exists.

**Why on rental_contracts, not purchase_contracts:** Yield is a property of the rental relationship (rent amount, expenses, conditions). When expenses are added in future, they'll be on the rental contract too.

**Consequences:**
- (+) Always shows a yield for active rentals (gross fallback)
- (+) Admin can override with net yield without schema changes
- (+) Natural home for yield — same table as the rent it derives from

---

## ADR-38: L2 Selective Select + L3 Self-Sufficient Fetch

**Date:** 2026-04-16
**Status:** Accepted

**Context:** `brandPurchaseContractsProvider` fetched all ~35 columns for the L2 list, which only uses 6. L3 received the full object via `state.extra`, coupling list and detail.

**Decision:**
- L2 uses `.select('id, user_id, brand_id, brand_name, brand_logo_asset, purchase_value, sold_date, asset_name, asset_location, asset_thumbnail_image')` — 10 fields
- L3 has a dedicated `purchaseContractByIdProvider` that fetches with full `.select()` by the `:id` already in the route URL
- Router passes `contractId` (String), not the full object via `state.extra`

**Consequences:**
- (+) L2 payload reduced ~70% — faster list render
- (+) L3 self-sufficient — works with deep links, no list dependency
- (+) Decoupled: list and detail can evolve independently
- (-) L3 makes a separate network request (acceptable — detail screens always do)

---

## ADR-43: Coinvestment Data Separation — Deal Terms vs Investor Performance vs Derived Progress

**Date:** 2026-04-17
**Status:** Accepted

**Context:** `coinvestment_contracts` had 20 columns conflating three concerns: (a) deal terms shared across all investors of the same project, (b) individual investor performance, (c) denormalized phase progress. Seed data confirmed conceptual grouping: `estimated_return_pct`, `estimated_duration_months`, `expected_end_date`, `projected_roi`, `is_delayed`, `current_phase_index`, `construction_phase` were effectively project-level (1 distinct value per project across contracts). `actual_duration` was derivable from two existing dates.

**Decision:** Three-layer separation:

1. **Deal terms → `projects` (moved, 5 cols):** `estimated_return_pct`, `estimated_duration_months`, `expected_exit_date` (renamed from `expected_end_date` for clarity), `projected_roi`, `is_delayed`. All shared by all investors of the same project.

2. **Investor performance → `coinvestment_contracts` (stays):** `actual_roi`, `actual_tir`, `total_return`, `completion_date`, `is_completed`. Stored per-contract, NOT derived. Rationale: investors within the same project may legitimately receive different actual figures due to fees, share classes, or late-entry bonuses. Admin panel stores what was actually paid, not a formula.

3. **Phase progress → derived in view:** `current_phase_index` (count of completed `project_phases`), `construction_phase` (name of next incomplete phase). Single source of truth is `project_phases.is_completed + sort_order`.

Also derived in view: `actual_duration = completion_date − start_date` in months (kept as a view column so Flutter doesn't change; the underlying storage is just the two dates).

**Consequences:**
- (+) `coinvestment_contracts` goes from 20 to 12 columns (-40%)
- (+) No risk of deal terms drifting between contracts of same project (single source on `projects`)
- (+) Phase progress cannot go stale (always reflects current `project_phases` state)
- (+) View aliases preserve Flutter field names → zero code changes in Dart
- (-) Queries joining contracts with project deal terms always need join (acceptable — view handles this)
- (-) Two other views (`portfolio_summaries`, `brand_investment_summaries`) needed recreation to pull `estimated_return_pct` from `projects` instead of `coinvestment_contracts`

**Why `actual_roi` is NOT derived:** Mathematically `total_return = amount × (1 + actual_roi/100)`, but real payouts differ due to management fees, carried interest splits, or withholding. Storing all three as independent fields on the contract lets admin record what actually happened, accepting the risk of minor drift for accuracy.

---

## ADR-42: Typed Economic Columns on Projects, Boolean Status, Drop Dead Columns

**Date:** 2026-04-17
**Status:** Accepted

**Context:** `projects` had several columns that either (a) duplicated derived data in free-form JSON, (b) were never read, or (c) modeled a concept that could be simpler:

- `status` (text enum `in_development` / `closed`) — 2-state field better modeled as boolean. No third value planned. Derivation from `project_phases` rejected: commercialization status ≠ construction progress (a project can be closed to new investors while still in build).
- `video_url`, `video_thumbnail_url` — unused after video feature was deferred (detail screen shows "PRÓXIMAMENTE").
- `search_vector` (tsvector) — never queried from Flutter; search uses in-memory filtering. Dead column.
- `economic_analysis` (JSONB) — 4-key free-form array that in practice always held the same fields: precio compra, m² construidos, reforma, gastos totales. Business spec defines 10 fixed fields with strict percentage rules (ITP 2%, gastos compra 1%).

Also missing: `target_capital` — the "raising X" figure shown to investors, with no home on the schema.

**Decision:**
1. `status` → `is_fundraising_closed boolean NOT NULL DEFAULT false`. View exposes as `project_is_fundraising_closed`. Naming is explicit to avoid confusion with (a) construction progress (derived from `project_phases.is_completed`) and (b) hypothetical future `is_archived`/`is_cancelled` states.
2. Drop `video_url`, `video_thumbnail_url`, `search_vector`.
3. Replace `economic_analysis` JSONB with typed numeric columns: `purchase_price`, `built_sqm`, `agency_commission`, `itp_amount`, `purchase_expenses_amount`, `renovation_cost`, `furniture_cost`, `other_costs`. Plus `total_cost` as `GENERATED ALWAYS AS` sum of all components, `STORED`.
4. Add `target_capital numeric` (nullable — only populated for projects actively raising).
5. Flutter `CoinvestmentContractData.economicAnalysis` becomes a getter that composes the `List<AssetInfoEntry>` from typed fields at read time (keeps UI contract stable). `€/m² construido` computed on the fly (not a DB column).

**Consequences:**
- (+) Queryable: admin panel can filter projects by price range, sum ITP across portfolio, etc.
- (+) `total_cost` always correct (can't drift from inputs)
- (+) `ITP` and `gastos compra` percentages documented in code + visible to admin as amounts (not hidden in labels)
- (+) 4 dead/redundant columns removed — simpler schema
- (-) Migration required backfill for 10 coinvestment projects (done in seed migration)
- (-) If a non-standard cost category appears in future (e.g. "impuesto regional"), needs a new typed column rather than just a new JSON entry — acceptable trade-off for the stricter contract

---

## ADR-41: Asset Belongs to Project, Not Coinvestment Contract

**Date:** 2026-04-17
**Status:** Accepted

**Context:** `coinvestment_contracts` had a nullable `asset_id` column duplicating `projects.asset_id`. In coinvestment, all investors share the same physical asset (the project's asset) — there's no scenario where two coinvestors on the same project reference different assets. The redundant column was 0/15 populated in seed, and the view `coinvestment_contract_details` joined assets via `cc.asset_id`, so the view returned null asset data everywhere even though each project had its asset linked.

**Decision:** Drop `coinvestment_contracts.asset_id`. The view joins assets via `projects.asset_id`. Single source of truth: asset is a property of the project, not of the individual investor's contract.

Contrast with `purchase_contracts.asset_id` which **stays** — in compra directa, a contract IS for a specific asset (potentially different units within a project), and the asset identity is the core of the contract.

**Consequences:**
- (+) No silent data gap (asset data now flows through the view for all contracts)
- (+) Single source of truth; no risk of cc.asset_id diverging from projects.asset_id
- (+) One less nullable column to maintain in seed
- (-) Future feature "investor-specific asset variant" would need to reintroduce the column (not on roadmap)

---

## ADR-40: Drop `document_categories.key`, Link Documents by FK

**Date:** 2026-04-17
**Status:** Accepted — supersedes part of ADR-39

**Context:** ADR-39 added a string `key` column to `document_categories` and stored `documents.category` as the same string. With an admin panel coming, `key` became a liability: renaming a key silently breaks all referencing documents (no FK integrity), and admins have to memorize exact strings. Two sources of truth (`key` + `label`).

**Decision:** Drop `document_categories.key`. Link documents via `documents.category_id` (uuid, NOT NULL, FK → `document_categories.id`). Flutter filter state and icon map now use `id` instead of `key`. Admin panel freely renames labels / adds / removes categories; Postgres enforces integrity on FK.

Icons still stored as Phosphor icon name strings in `icon_name` — that part of ADR-39 stands. Admin picks from a known library, not from Flutter code, so it's not a hardcoded coupling.

**Consequences:**
- (+) Referential integrity at DB level; no orphan `documents.category` strings
- (+) Admin renames labels freely without touching documents
- (+) One less column, one less source of truth
- (-) Filter state holds UUIDs instead of readable keys (acceptable — filter state is ephemeral UI state)

---

## ADR-39: Dynamic Document Categories — DB-driven, icon key in table

**Date:** 2026-04-16
**Status:** Partially superseded by ADR-40 (the `key` column was dropped)

**Context:** Document categories were hardcoded in a Dart enum (`DocCategory`) + DB CHECK constraint, duplicated across 4 screens, with inconsistent labels. Admin couldn't add new categories without a code change. Filter chips showed all possible categories for a model type, even when no documents of that type existed.

**Decision:** New `document_categories` table: `key`, `label`, `icon_name`, `sort_order`. Admin adds/edits rows in Supabase dashboard. Flutter fetches all categories once via `allDocumentCategoriesProvider` and filters locally per screen to show only categories present in the loaded documents.

Icons stored as Phosphor icon name strings (`'scales'`, `'money'`...). Flutter maps via `_kDocIcons: Map<String, IconData>` in `lhotse_documents_section.dart`. Unknown keys fall back to `PhosphorIconsThin.file`. Admin panel will show only the icons in this map as a gallery.

**Why no `model_types` column:** Categories are universal. Which ones appear as filter chips is determined by the actual documents the object has — not by a per-model config. This avoids a second maintenance surface.

**Consequences:**
- (+) Admin adds categories without any code change
- (+) Filter chips only show categories present in the object's real documents
- (+) Single source of truth: `document_categories` table
- (+) Labels/icons consistent across all screens automatically
- (+) `DocCategory` enum eliminated — no DB/Dart sync to maintain
- (-) Extra DB query on app start (one-time, cached globally)

## ADR-32: All Physical Property Data Belongs to `assets`, Not `projects`

**Date:** 2026-04-16
**Status:** Accepted

**Context:** `projects` had `location`, `address`, and ghost fields in `ProjectData` (`bedrooms`, `bathrooms`, `floor_plan_url`) that were never hydrated because those values only lived in `assets`. This created a split brain: marketing data and physical property data mixed in one table.

**Decision:** All physical property attributes live exclusively on `assets`:
- `city`, `country`, `address` moved from `projects` to `assets`
- `location` (was `"Madrid, ES"`) split into `city` + `country` (ISO code)
- `projects.asset_id` made `NOT NULL` — every project must have an associated asset
- Assets auto-created for the 15 projects that had none

`ProjectData` now fetches all property fields via assets join: `.select('*, brands(...), assets(city, country, bedrooms, floor, ...)')`.

**Rationale:**
- A project is a marketing/catalog entity (name, description, images, brand)
- An asset is a physical/financial entity (location, bedrooms, current_value)
- Multiple projects could wrap the same asset (different investment rounds) — FK direction `projects.asset_id → assets` makes this possible

**Consequences:**
- (+) `projects` table is clean: only marketing + status fields
- (+) `assets` is the single source of truth for all physical property data
- (+) `project.location` getter computes `"$city, $country"` — UI unchanged
- (+) Project detail CARACTERÍSTICAS section now shows real data (was always null)
- (-) One extra JOIN on every project query — absorbed by PostgREST auto-embed

---

## ADR-33: `asset_info` JSONB Eliminated — Typed Columns Only

**Date:** 2026-04-16
**Status:** Accepted

**Context:** `assets.asset_info` was a catch-all `JSONB` array of `{label, value}` pairs for property attributes (Planta, Año construcción, Garaje, Trastero, Orientación, Vistas, Parcela, Piscina…). Each attribute was fetched and displayed as a generic string pair — no type safety, no filtering, no conditional display logic.

**Decision:** Promote every recurring attribute to a typed column. Drop `asset_info`.

New columns added: `floor TEXT`, `year_built INTEGER`, `year_renovated INTEGER`, `terrace_m2 NUMERIC`, `parking_spots INTEGER`, `storage_room BOOLEAN`, `orientation TEXT`, `views TEXT`, `plot_m2 NUMERIC`, `has_pool BOOLEAN`.

**What gets JSONB:** nothing on `assets`. `coinvestment_contracts.economic_analysis` remains JSONB (display-only financial scenarios, never filtered individually).

**Rationale:**
- Per CONVENTIONS.md: typed attributes need their own columns; JSONB is for display-only freeform extras
- Typed columns enable: conditional display in Flutter (`if (project.hasPool == true)`), future filtering (show only properties with pool), and type safety in models

**Consequences:**
- (+) Every asset attribute is typed, validated, and queryable
- (+) Flutter `characteristicEntries` list is built from typed fields — no string parsing
- (+) `AssetInfo` model retained only for `coinvestment_contracts.economic_analysis`
- (-) Migration required to promote existing JSONB values — one-time cost

---

## ADR-34: `revaluation_pct` Computed in View, Not Stored

**Date:** 2026-04-16
**Status:** Accepted

**Context:** `assets.revaluation_pct` stored the appreciation percentage as a static value that had to be manually updated whenever `current_value` changed. Stale data risk.

**Decision:** Drop `assets.revaluation_pct`. Compute it in `purchase_contract_details` view:
```sql
CASE WHEN a.current_value IS NOT NULL AND pc.purchase_value > 0
     THEN round(((a.current_value - pc.purchase_value) / pc.purchase_value) * 100, 2)
     ELSE NULL END AS asset_revaluation_pct
```

For coinversión: no reference purchase price exists at the asset level, so `asset_revaluation_pct` is removed from `coinvestment_contract_details` entirely.

**Consequences:**
- (+) Always accurate — auto-updates when `current_value` changes
- (+) Removes a manually-maintained derived field
- (+) Correct semantics: compra directa has a purchase price to compare against; coinversión does not
- (-) Cannot sort/filter by revaluation_pct in a simple query — requires subquery or materialized view if needed at scale

---

## ADR-35: Split Contract Views into Contract (per-row) + Project/Asset Details (per-entity)

**Date:** 2026-04-18
**Status:** Accepted

**Context:** `coinvestment_contract_details` and `purchase_contract_details` were wide views that inlined every project/asset field onto every contract row: renders, progress images, gallery, economics, all 15+ physical asset attributes. Lists (Strategy → brand rows, brand investments) and detail heroes only read a small subset; the heavy fields were only consumed inside detail tabs (ACTIVO, FINANZAS, AVANCE). Effect: every list request duplicated per-project/per-asset data across rows and every row paid the wire cost of fields the list never rendered.

**Decision:** Two-layer split per business model.

- **`<model>_contract_details`** — minimal per-contract view. Only fields needed for lists + detail hero + per-contract tabs (mortgage for purchase, outcomes for completed). Filtered by `user_id`.
- **`<model>_project_details`** (coinvestment) / **`<model>_asset_details`** (purchase) — per-project or per-asset view with the heavy static data (asset physical info, floor plan, gallery, economics, renders). No user filter. Loaded lazily via `FutureProvider.family` keyed by `projectId` or `assetId` only when a detail screen opens.

Flutter: contract models drop the moved fields; new `CoinvestmentProjectDetails` / `PurchaseAssetDetails` models own `assetInfo` / `economicAnalysis` getters. Detail screens `ref.watch` the per-entity provider and pass derived lists to tab widgets.

`fixed_income_contract_details` is NOT split — all its fields are per-contract (no project-level heavy data) and the detail screen has no tab structure.

**Rationale:**
- Lists send 1/3 to 1/2 the payload (coinvestment: 43 → 20 columns; purchase: 47 → 24).
- Eliminates per-row duplication when multiple contracts share a project/asset (coinvestment: N investors in same project).
- Aligns with the tab-level lazy-loading already in place for phases, scenarios, and documents.

**Consequences:**
- (+) Faster list responses, less memory in contract list providers.
- (+) One extra request when a detail screen opens — lazy and cached per `projectId`/`assetId`.
- (+) Physical asset data centralized: future commercial `project_details` view (home/AllProjects) can reuse the same asset columns.
- (+) Floor plan fallback hardcoded in `CoinversionDetailScreen` (`Image.asset('mock_floor_plan.png')`) removed — `LhotseImage` resolves the DB value, asset or URL.
- (-) Detail screens must handle a second async state; acceptable (AsyncValue fallback is trivial).
- (-) Two views per model to keep in sync when schema evolves.

---

## ADR-36: Pure RLS + RLS Isolation Tests as the Authorization Model

**Date:** 2026-04-18
**Status:** Accepted

**Context:** User-scoped views (`user_portfolio`, contract views) previously exposed a `user_id` column, and every provider filtered with `.eq('user_id', userId)`. At the same time, the base tables (`purchase_contracts`, `coinvestment_contracts`, `fixed_income_contracts`) had RLS policies `user_id = auth.uid()`, and the views ran with `security_invoker = true`. So the filter was applied twice: once by RLS (canonical), once by the client (redundant). The "defense in depth" justification doesn't hold up:

- If RLS is correct, the client filter is noise that ships `user_id` to every client and clutters the providers.
- If RLS is misconfigured, the client filter can **mask the bug silently** — a view returns 0 rows and nobody realises the policy broke; the filter happens to be filtering what should have been filtered by RLS anyway.

The guard that actually works is an **integration test**: a SQL harness that impersonates two users and verifies user A cannot read user B's rows. This fails loud, in CI.

**Decision:** Adopt **pure RLS** as the single canonical authorization source.

- User-scoped views do NOT expose `user_id` as a column.
- Client providers do NOT filter by `user_id`. They still watch `currentUserIdProvider.distinct()` to trigger re-fetch on auth state change (logout + login as different user).
- Row isolation is verified by `docs/sql/tests/rls_user_isolation.sql` — a test file run against a staging DB that impersonates two users and asserts zero leakage.
- Every migration that touches a user-scoped view includes "RLS test executed ✅" in its header per `docs/sql/MIGRATION_CHECKLIST.md`.

**Rationale:**
- **One canonical source** for authorization (principle #1). RLS is where data access is decided.
- **Fail loud, not silent**: tests fail with a clear assertion; redundant filters hide regressions.
- **Smaller surface**: views ship fewer columns, providers have less code, models drop unused fields.
- **Industry alignment**: Supabase's own docs, Vercel Supabase templates, and Resend-style architectures all recommend pure RLS over belt-and-suspenders when the schema is Supabase-first.

**Consequences:**
- (+) Views and providers are leaner — `user_id` removed from 4 views and ~8 providers.
- (+) RLS bugs surface as assertion failures in tests, not silent nulls in the UI.
- (+) Future schema changes to user-scoped tables automatically inherit the pattern via the checklist.
- (-) One-time discipline cost: RLS tests must be written and kept fresh when policies evolve.
- (-) If RLS on the base tables is ever disabled, data leaks immediately (no belt). Mitigation: never ship a migration that disables RLS on user-scoped tables; the migration header flags the risk.

**Not in scope for this ADR** (deferred):
- Tables without user scoping (`brands`, `projects`, `news`, `assets`) are read-public for authenticated users. This ADR applies to user-scoped tables and their views only.
- Admin/staff access paths (via service_role key) are outside RLS by design.

---

## ADR-44: Unified Contract Status — pending/signed/cancelled + Derived Completion

**Date:** 2026-04-19
**Status:** Accepted

**Context:** Before this ADR, the 4 investment domains each modelled contract lifecycle differently:
- `purchase_contracts`: no status column (implicit via `sold_date`).
- `coinvestment_contracts.is_completed BOOLEAN`.
- `fixed_income_contracts.status TEXT CHECK ('active','completed','cancelled')` with default `'active'`.
- `rental_contracts`: no status column (implicit via `is_active` / `end_date`).

This was flagged as pending debt in `ARCHITECTURE.md#6` ("future ADR"). The inconsistency forced per-model UI logic for "ACTIVAS / FINALIZADAS" sections and made cancellation non-modellable in 3 of 4 domains.

**Decision:** Introduce `status TEXT NOT NULL DEFAULT 'signed' CHECK (status IN ('pending','signed','cancelled'))` on **all 4 contract tables**. The enum captures only **human-driven state** on the contract document itself:
- `pending`: row created, awaiting signature.
- `signed`: signed, in force.
- `cancelled`: cancelled (before or after signature).

"Finalizado" is **not** a contract status — it's a **UI projection** derived in the view, with a different source per domain:

| Domain | `is_completed` derived in view from |
|---|---|
| purchase | `sold_date IS NOT NULL` — external event (asset sold) |
| coinvestment | `cc.completion_date IS NOT NULL` — contract-level event (investor received final distribution) |
| fixed_income | `maturity_date < CURRENT_DATE` — natural contract end |
| rental | `end_date < CURRENT_DATE` — natural contract end (rental has no standalone view; semantics reserved for future use) |

The 3 contract views (`user_direct_purchases`, `user_coinvestments`, `user_fixed_income_contracts`) expose both `status` and `is_completed` so the UI filter "FINALIZADAS" reads one uniform boolean.

**Why CHECK, not PostgreSQL ENUM:** ADR-26 already establishes TEXT + CHECK as the project convention. Constraint naming: `chk_<table>_status`.

**Why `cancelled` in all 4 models even without UI today:** contingency / operational blindaje. Renaming a CHECK is cheap; renaming + backfilling a column after contracts start referencing the enum in UI is not.

**Rationale:**
- **Principle #1** (canonical source): one column, one vocabulary across 4 domains.
- **Principle #3** (computed > stored): `is_completed` is derived, not stored. Two sources of truth for "finalized" would drift.
- **Principle #6** (naming consistency): removes the last pending-debt note from `ARCHITECTURE.md`.
- **UI uniformity**: `brand_investments_screen` drops per-model getters (`isSold`, `isCompleted` from enum, etc.) in favor of a single `isCompleted` read from the view.

**Consequences:**
- (+) One vocabulary for all 4 domains; cancellation modellable everywhere.
- (+) `coinvestment_contracts.is_completed` eliminated (dead column — derivable from projects).
- (+) `fixed_income_contracts.status` aligned with the rest (was the odd one with `active/completed`).
- (+) `ARCHITECTURE.md#6` pending debt closed.
- (-) Existing UI code referencing `PurchaseContractData.isSold` / `FixedIncomeStatus.active|completed` must be updated in the same migration (Flutter sweep).
- (-) `completion_date` on coinvestment contracts is now decoupled from `is_completed` (still used to compute `actual_duration`). If it drifts from project close date, handle in a future ADR.

**Migration:** `docs/sql/migrations/20260419145816_unify_contract_status.sql`.

**Not in scope:**
- Rental has no standalone contract view yet; adding `status` to the table is blindaje for when that view exists. Current `rc.is_active` filter in `user_direct_purchases` untouched.
- UI for cancellation workflow (flag only; no admin screen to set `status = 'cancelled'` yet).

---

## ADR-45: Project Estimates Derived from `project_scenarios` (P50), Not Stored on `projects`

**Date:** 2026-04-19
**Status:** Accepted (supersedes the `estimated_return_pct` / `estimated_duration_months` / `projected_roi` / `expected_exit_date` columns introduced in ADR-43)

**Context:** `projects` carried 4 deal-term columns that duplicated or drifted from `project_scenarios`:
- `estimated_return_pct` (10/18 filled — headline figure stored independently of scenarios, e.g. Allegro 22% vs P50 17.60%)
- `estimated_duration_months` (10/18 filled — same pattern)
- `projected_roi` (2/18 filled, 0 consumers — dead column)
- `expected_exit_date` (10/18 filled, 0 consumers — speculative, principle #4)

In parallel, `project_scenarios` stores the probabilistic distribution (P90 / P50 / P10) used in the L3 Bloomberg panel. Having two sources for the same concept ("expected return / duration of a project") violates principle #1 (canonical source) and leads to headline drift.

**Decision:** Drop the 4 columns from `projects`. Expose `estimated_return_pct` and `estimated_duration_months` in `user_coinvestments` (and `return_pct` in the coinvestment branch of `user_portfolio`) **derived** via a `LEFT JOIN LATERAL` to the scenario closest to the median (`ORDER BY abs(sort_order - 2), sort_order LIMIT 1`). If P50 exists it is used; otherwise the closest available scenario (P10 before P90 on ties) gives a best-effort fallback.

**Rationale:**
- **Principle #1** (canonical source): one vocabulary for "expected return" — the scenario model.
- **Principle #3** (computed > stored): the view derives; we don't store the same number twice.
- **Principle #4** (no speculative fields): `projected_roi` and `expected_exit_date` had no consumers.
- **Flutter-invisible change**: the Dart model (`CoinvestmentContractData.estimatedReturnPct` / `estimatedDurationMonths`) reads the same column names from the view; only the source changes.

**Consequences:**
- (+) Single source of truth for headline projections.
- (+) L3 Bloomberg panel and L1/L2 list headlines read from the same table — no more drift.
- (+) `projects` lost 4 columns; 2 were dead to start with.
- (−) The visible headline number changes for projects whose old `estimated_return_pct` didn't match P50 (e.g. Allegro 22% → 17.60%). Acceptable: the previous value was a marketing figure disconnected from the modelled distribution.
- (−) Projects without scenarios show `null` in list views — same behaviour as before (those projects had `null` in the dropped columns too).

**Migration:** `docs/sql/migrations/20260419153747_project_estimates_from_scenarios.sql`.

**Not in scope:** `is_delayed` on `projects` remains (unchanged by this ADR). Projects without any scenarios still render as `null` in the headline; if a UX pass later needs a default for those, backfill with a P50 scenario rather than reintroducing the headline column.

---

## ADR-46: Fixed Income Schema + UX Consolidation

**Date:** 2026-04-20
**Status:** Accepted

**Context:** The fixed_income domain accumulated three unrelated issues: (1) document rows used `model_type = 'contract'`, inconsistent with `'purchase'` / `'coinvestment'` on the other domains; (2) an unreachable `InvestmentDetailScreen` (L3 for RF) existed in `lib/` with a registered route but no navigation; (3) the L2 row pretended to carry a "doc icon per operation" but rendered none, because the list view didn't expose whether a contract had docs and the `fixed_income_payments` table had zero consumers despite holding real data.

**Decision:** Consolidate RF into a single, self-sufficient L2 experience backed by view-derived flags:

1. **Rename `documents.model_type` `'contract'` → `'fixed_income'`** (16 rows), update CHECK to the 4-domain vocabulary, and add the missing `WHEN 'fixed_income'` branch to the SELECT RLS policy.
2. **RF is L2-only by design.** Delete `investment_detail_screen.dart` + route. The L2 `_RentaFijaRow` owns all RF data presentation.
3. **Add derived columns to `user_fixed_income_contracts`** (principles #2 + #3):
   - `has_documents BOOLEAN` — `EXISTS(SELECT 1 FROM documents WHERE model_type='fixed_income' AND model_id = c.id)`. Drives the doc icon visibility with zero extra queries.
   - `interest_paid_to_date NUMERIC` — sum of `fixed_income_payments.amount` with `type='interest' AND date <= CURRENT_DATE`. Powers the active-row "+€cobrados" figure.
   - `total_interest_earned NUMERIC` — sum across all interest rows. Powers the completed-row total.
4. **UX pattern for RF docs**: conditional `fileText` icon on the row; tap opens a bottom sheet (`_RentaFijaDocsSheet`, `ConsumerStatefulWidget`) that lazy-loads `documentsProvider` and renders filter chips via `categoriesForIds`, replicating the UX of the L3 DOCS tabs in purchase/coinversion without needing an L3.
5. **RF main figure = capital invertido** (both active and completed). Breaks the pattern used in purchase/coinvestment completed rows (total return) because RF interest is a **periodic cash flow**, not a single payout at close. Showing `invested + total_interest` as the big number would misrepresent the payment mechanics — the investor already received those interests in installments.
6. **Drop dead columns from `fixed_income_offerings`**: `is_capital_guaranteed`, `min_amount`, `description` (0 Flutter consumers, principle #4). `is_active` retained for future admin UI.

**Rationale:**
- **Principle #1 (canonical source)**: one vocabulary for `model_type` across 4 domains.
- **Principle #2 (request ∝ screen needs)**: `has_documents` + interest aggregates exposed in the L2 list view → zero per-row docs queries and no lazy fetch needed for the headline figures.
- **Principle #3 (computed > stored)**: interest aggregates derived from `fixed_income_payments`; never stored on the contract.
- **Principle #4 (no speculative fields)**: 3 unused offering columns removed.
- **Principle #8 (views as API)**: the view carries the full payload the L2 row + bottom sheet + metrics need.

**Consequences:**
- (+) RF L2 row ships with doc-icon + cobrados + vence + rate in a single query.
- (+) `fixed_income_payments` gets its first consumer (via the derived columns) — table is no longer orphan.
- (+) Delete of dead L3 removes ~317 lines + one stale route.
- (+) Doc workflow now works on RF (was broken because RLS had only a `'contract'` branch; renaming + adding the `'fixed_income'` branch fixed both issues).
- (−) Pattern break: RF main figure = invested, whereas completed purchase/coinvest rows show total return. Documented.

**Migrations:**
- `docs/sql/migrations/20260419160133_fixed_income_cleanup.sql` (rename + drop offering cols).
- `docs/sql/migrations/20260419172030_rls_documents_fixed_income_branch.sql` (RLS branch fix).
- `docs/sql/migrations/20260419161855_user_fi_has_documents.sql` (derived flag).
- `docs/sql/migrations/20260419210610_user_fi_interest_metrics.sql` (derived aggregates).

**Not in scope:** Admin panel wiring of `fixed_income_offerings.is_active`. Future L3 for RF if the product surface grows (e.g. per-payment detail view).

---

## ADR-47: Project Lifecycle — Two Orthogonal Axes

**Date:** 2026-04-20
**Status:** Accepted

**Context:** `projects.is_fundraising_closed boolean` tried to encode two independent business dimensions in one flag:

- **Commercial**: is the project still accepting new investors?
- **Physical**: where is the asset in its build-to-sale lifecycle?

This collapses a real scenario that crowdfunded real estate depends on: partial capital raised, construction starts, capture continues during the build. A single boolean forces us to either (a) hide the fact that fundraising is still open during construction or (b) misreport construction as "not started" because capture isn't closed yet.

`projects` is used exclusively by coinvestment (flip: raise → build → sell). Direct purchase, rental, and fixed income do not go through a "project" — they live on their own domain tables. So this ADR only concerns the coinvestment lifecycle.

**Decision:** Replace `is_fundraising_closed` with two orthogonal columns plus an invariant CHECK:

```sql
is_fundraising_open       boolean     NOT NULL DEFAULT true
phase                     text        NOT NULL DEFAULT 'pre_construction'
  CHECK (phase IN ('pre_construction','construction','exited'))
construction_completed_at timestamptz  -- optional marker for the "built but unsold" window
CHECK (phase <> 'exited' OR is_fundraising_open = false)  -- you can't exit while still capturing
```

3 phases (not 4). No `operating` / `built` state because coinvestment is a flip: the interval between "construction done" and "exited" is short (weeks/months, not years) and is captured by the optional `construction_completed_at` timestamp. There is no long-term tenure phase at the project level for this domain.

**UI mapping** (single-select filter tabs):
- `is_fundraising_open = true` → **"EN CAPTACIÓN"**
- `phase = 'construction'` → **"EN OBRA"**
- `phase = 'exited'` → **"FINALIZADO"**

Tabs are compositional: a project with `is_fundraising_open=true ∧ phase='construction'` matches both "EN CAPTACIÓN" and "EN OBRA" filters.

**Rationale:**
- **Principle #6 (unified status)**: TEXT+CHECK per ADR-26 (not ENUM), aligned with how contract statuses are modelled. Divergence from the pattern: instead of a single enum, two columns + invariant CHECK — because the two axes are genuinely orthogonal and an enum would encode a state machine that doesn't exist.
- **Honest modelling**: eliminates the class of bug where a single boolean has to "lie" to cover a valid real-world state.
- **Principle #3 (computed > stored)**: rejected alternatives where phase is derived from contract milestones — `completion_date` on an individual contract means one investor exited, not that the project exited. The project-level exit is a business decision that must be stored explicitly.

**Consequences:**
- (+) The "partial capital raised, construction started" state is now representable.
- (+) Views can filter independently on either axis (`brands_with_metrics.coinv_active_projects` now counts `is_fundraising_open=true` regardless of phase).
- (+) Admin can move phase forward (pre_construction → construction → exited) without forcing captación-closed implicitly.
- (−) Two columns instead of one; CHECK required to prevent `phase='exited' ∧ is_fundraising_open=true`. Considered acceptable: a single-boolean model made worse states (semantically invalid combinations) silently representable.
- (−) Backfill of 18 seed projects defaulted to `phase='pre_construction'`; construction/exit states must be set manually per project via Dashboard. We deliberately did not invent a heuristic from `completion_date` counts (unreliable).

**Migration:** `docs/sql/migrations/20260420174731_projects_lifecycle_status.sql` — recreates `user_opportunities`, `projects_with_metrics`, `brands_with_metrics` (the 3 views that referenced the dropped column).

**Consumers updated in the same PR:**
- `lib/core/domain/project_data.dart` — `isFundraisingOpen`, `phase` (Dart enum `ProjectPhase`), `constructionCompletedAt`.
- `lib/features/home/presentation/all_projects_screen.dart` — filter tabs `EN CAPTACIÓN` / `EN OBRA` / `FINALIZADO`.

**Not in scope:** An "EN VENTA" state for the post-construction/pre-exit window. If that window ever becomes long enough to warrant its own UX, add a 4th phase value (not a separate boolean) and extend the CHECK.

**Follow-up (2026-04-20):** AllProjects and Strategy → Oportunidades split by intent. AllProjects is the portfolio catalogue (`phase IN ('construction','exited')` only); `user_opportunities` view tightened with `WHERE is_fundraising_open = true` so only open deals surface as opportunities. Rationale: different user mental models (browsing what exists vs. discovering what can be joined). Migration: `docs/sql/migrations/20260420191513_user_opportunities_only_fundraising.sql`.

---

## ADR-48: Home Feed — Nike SNKRS-Style Vertical (Zara Visual Language)

**Date:** 2026-04-21
**Status:** Accepted

**Context:** The original Home tab was an editorial portal (auto-scroll carousel of featured projects + horizontal news row + section stubs). Client asked for a Nike SNKRS-style immersive feed: one content unit per viewport, vertical scroll, mixed formats including video.

**Decision:** Rebuild Home as a vertical feed of full-viewport cards. Interaction model inspired by Nike; visual language stays Zara/editorial (beige caption below pure image, no dark scrim, no text-over-image). Each card = media block (~65%) + beige caption (~35%).

---

## ADR-49: Four Zone Calibration — Lookbook Editorial for Projects + News Archives

**Date:** 2026-04-22
**Status:** Accepted (v2 after simulator verification — v1 overlay/85vh/alternating-ratios approach was rejected; see v2 addendum at bottom)

**Context:** AllProjects (PROYECTOS) and AllNews (NOTICIAS) were rendered as uniform lists of standard cards (`ProjectCard` 550px fixed and `LhotseNewsCard` 4:3 default). Three problems:

1. `ProjectCard` was used identically in three zones with very different intents (AllProjects archive, Search catálogo, Opportunities deal-scan) — zero differentiation.
2. `LhotseNewsCard` had editorial base vocabulary (kicker, byline) but no deck, no rhythm. Read as "RSS feed", not "magazine archive".
3. Card designs did not cohere with detail screens (200px hero vs card full-bleed; title smaller in detail than in card).

Brand positioning for Lhotse is **luxury-fashion × real-estate**. The correct editorial family is T Magazine / Openhouse / AD / Cabana / Sotheby's International — *not* Monocle/Bloomberg (too corporate-austere) or Vogue (too commercial-glossy). ADR-15's "Bloomberg × Sotheby's" reference applies specifically to the coinversion L3 detail (fintech-heavy with scenarios/TIR) and should not be generalised as the app-wide direction.

**Decision:** Four distinct zone calibrations. Each pair of card + matching detail screen speaks the same visual language so tapping a card feels like turning a page.

| Zone | Carácter | Card / Screen |
|---|---|---|
| Home feed | SNKRS loud rotativo | `FeedCard` — one per viewport, mixed types |
| **AllProjects + Search catálogo** | **Lookbook producto** (Sotheby's) | `ProjectShowcaseCard` — full-bleed edge-to-edge, warm sepia gradient, text overlay bottom-left, 4:5/3:2 alternated, 85vh lead |
| **AllNews + NewsArchiveBody** | **Lookbook editorial** (T Magazine) | `LhotseNewsCard` full — full-bleed image, beige caption below with kicker/mixed-case-title/deck/byline(`POR X · DATE`), 4:5/3:2 alternated, 85vh lead |
| Opportunities | Deal-scan aspiracional | `ProjectCard` (unchanged) — loud image-dominant |

**Shared editorial vocabulary** between Projects and News archives:
- Mixed-case display titles (no `.toUpperCase()`). Uppercase reserved for kicker/byline/metadata.
- Kicker above title (caption 10px w500 ls 2.0): `FIRMA · FASE` for projects, `PROYECTO`/`PRENSA` for news.
- Full-bleed edge-to-edge with alternating 4:5/3:2 ratios and 85vh lead.
- Generous whitespace between cards (no hairlines — Monocle language rejected). 32px projects, 48px news.
- Warm sepia gradient (`AppColors.overlayWarm` #1F1916) replaces pure black overlays — Sotheby's/Openhouse feel vs "instagram story" coldness.

**Detail screens updated for coherence**:
- `NewsDetailScreen` + `ProjectDetailScreen`: hero `200px` → `screen * 0.55`, warm gradient added, title `headingLarge uppercase` → `displayMedium mixed case`, kicker elevated above title (news type-badge lateral row removed), deck/tagline rendered between title and byline. Collapsed app bar titles stay uppercase.

**Fuera de alcance**: Home `FeedCard`, Opportunities, compact carousels, detail sections below hero (body/characteristics/gallery/related) unchanged. No new fonts. Share affordance on project cards deferred.

**Consequences:**
- (+) Each zone has a distinct editorial identity; Home vs archive vs deal-scan no longer compete.
- (+) Cards become screenshot-ready posters — supports "users share projects with friends" intent.
- (+) Card → detail reads as continuous (large hero in both, same title treatment).
- (+) Removes duplication: `ProjectCard` lives only in Home carousel + Opportunities, `ProjectShowcaseCard` owns archives.
- (−) AllProjects scroll length increases (lead 85vh + subsequent ≈65-75vh). Mitigated by the lookbook feel encouraging slow browse.
- (−) Mixed case titles diverge from rest of app (headers, section labels still uppercase). Justified: luxury-fashion editorial uses mixed case for long-form titles.

**Reference audit:** ADR-15's "Bloomberg × Sotheby's" remains valid *for coinversion L3*. App-wide editorial direction is T Magazine × Sotheby's × Openhouse.

### v2 addendum (2026-04-22, post-simulator verification)

The v1 concrete choices (85vh lead + alternating 4:5/3:2 ratios + warm-gradient overlay + text-on-image) failed in the simulator:

1. **Viewport math broken**: persistent chrome (status + header + tabs + filter bar + nav + home indicator) consumes ~337pt on iPhone 17 Pro Max, leaving ~595pt of usable vertical. A "lead 85vh" = ~792pt cannot fit; overlay text fell below viewport and the user saw only photograph, no info.
2. **Text-on-image reintroduced the legibility risk** that had been rejected in an earlier iteration.
3. **Alternating ratios (85vh / 4:5 / 3:2)** read as visual noise, not editorial pacing.

v2 revises the concrete execution while keeping the zone calibration intent intact:

- **Uniform 4:5 ratio** for both zones (lead included). Rhythm comes from typography, not altura variable.
- **Text always on beige, never overlay**. AllProjects uses a beige label **adhered** to the image (card-as-object, `AppColors.surface` darker beige) — the card reads as a self-contained poster, supporting shareability. AllNews uses an **open** caption on the page `background` — the image and text are separate pieces, more editorial/spread feel.
- **Lead differentiated by typography only**: `displayLarge` (40px) + 3-line deck vs `displayMedium` (28px) + 1-2 line deck. Same ratio everywhere.
- **Filter bar scroll-aware** (`ScrollAwareFilterBar`): collapses to a compact pill while scrolling, restores itself after 2s idle. Premium reading-app UX (Apple Stocks / NYT) that gives the editorial content more room during active scroll without making the filters hard to find.
- **`AppColors.overlayWarm`** token kept (used in news-detail + project-detail hero gradients) but no longer applied to archive cards.
- Detail screens unchanged (already use mixed case + kicker + deck + warm gradient in hero, coherent with both v1 and v2 cards).

Rejected references during v2 iteration: Monocle / Bloomberg (corporate-austere, incompatible with luxury-fashion positioning). Reconfirmed family: T Magazine × Openhouse × Sotheby's.

### v3 addendum (2026-04-22, post-v2 iteration in simulator)

Further refinements after walking through the v2 cards with the client:

- **Filter bar collapse: no pill substitute**. v2 used a textual pill (`SECCIÓN · N FILTROS · ⌵`) while collapsed. Rejected because the primary navigation tabs (FIRMAS/PROYECTOS/NOTICIAS) above already communicate the active section — a textual placeholder was redundant. Now the secondary filter bar simply hides and restores.
- **Unified beige across cards**. v2 used `AppColors.surface` (darker beige) as an adhered label under the image on `ProjectShowcaseCard` to make it read as a "card-object" poster. Rejected because it broke the unified palette and felt like a gray block against the page. Both cards now use the page `background` — captions flow as open editorial text below the photograph, consistent with `LhotseNewsCard`.
- **Ratio 4:5 → 1:1 square**. v2 portrait (4:5) made the first card overflow the viewport once filters were expanded (517pt image + ~200pt caption > 595pt usable vertical). Square (1:1) gives ~103pt back, fits cleanly, and remains editorial-contemporary (Cabana / AD Collector use 1:1 in digital grids).
- **Typography-only lead (no `displayLarge`)**. v2 bumped lead titles to `displayLarge` (40px). Combined with 1:1 image, still forced scroll to see tagline/location. Now all titles are `displayMedium` (28px); lead only differs by extended tagline maxLines (3 vs 1).
- **Projects caption reordered location-first**. v2 used `FIRMA · FASE` as kicker + LOCATION as footer. Revised because in luxury real estate listings (Sotheby's International, Engel & Völkers, Christie's) location is the primary hook — what sells. Now: location kicker → title → tagline → `[firma logo] · fase` byline.
- **Byline: SVG logo instead of wordmark text — tried and rolled back**. The LVMH-inspired maison mark idea was implemented with `SvgPicture.network`/`.asset` + `ColorFilter.mode srcIn` to render each brand logo monochrome black in the byline. Rolled back after testing in simulator: Lhotse's brand logos are too heterogeneous to coexist at a uniform size — Ciclo Capital is a two-line mark, Lacomb & Bos has thin serif weight, Vellte is a heavy wordmark, Revolut is a long horizontal logotype. Forcing them into 64×14pt broke each one differently. LVMH works because its maisons (Louis Vuitton, Dior, Fendi, Tiffany) are all serif wordmarks of similar optical weight; Lhotse's family is not there yet. Reverted to textual `{BRAND} · {FASE}` in the byline — listings stay typographically uniform. The logo gets its proper treatment in the project detail screen, where it has prime real estate and doesn't compete with others. News keeps `POR {BRAND}` textual because in editorial content the brand is an author, not a maison.
- **"POR" prefix removed from Projects byline**. In architecture/interior credits the convention is just the name (like closing credits of a film) — "POR" is reserved for editorial authorship (news).

Rejected in v3: full LVMH restraint (tagline + country + fase stripped from listing) — real estate needs contextual hooks per card that moda does not. The adopted hybrid keeps the Sotheby's/T Magazine editorial structure while borrowing one LVMH element (maison mark as logo).

---

## ADR-50: Archive card premium — minimal luxury modern (Campton-only transformación)

**Date:** 2026-04-22
**Status:** Accepted

**Context:** Tras iterar estructura, ratio, jerarquía y logo de firma en `ProjectShowcaseCard` y `LhotseNewsCard`, las cards quedaban "correctas" pero no transmitían el carácter luxury auténtico pedido por el cliente ("tiene que ser un producto premium, busquemos la mejor solución"). Diagnóstico: les faltaba el factor fundacional que separa productos digitales luxury editoriales auténticos (Faena, Aman, Openhouse, Cabana, Auberge) de productos premium genéricos (Airbnb Luxe, Compass, Sotheby's International app). Dos territorios viables:

- **Editorial magazine warm** (T Magazine / Openhouse / Cabana) — requiere serif display para ser auténtico
- **Minimal luxury modern** (Céline / Jil Sander / Totême / The Row) — sans puro con composición extrema

Sergio rechaza introducir fuente serif nueva. Elegido el segundo territorio, que además se alinea mejor con HNW español conservador (sobrio, moderno, menos decorativo).

**Decisión:** Upgrade premium Campton-only con los siguientes moves coordinados:

1. Nuevo token `displayHero` — Campton Light w300, fontSize 48, line-height 0.95, letterSpacing -0.5. Aplicado a títulos de `ProjectShowcaseCard`, `LhotseNewsCard` y sus detail hero titles
2. Tagline / deck en italic (Campton Book Italic) — convención magazine de declarative captions
3. Hairlines editoriales 0.5px alpha 15% top y bottom del caption, enmarcando el bloque como spread de revista
4. Logo SVG de firma uniforme en byline de projects — widget `_BrandStamp` con `SizedBox(100×28)` + `BoxFit.contain` + `ColorFilter srcIn` negro (patrón exacto de `_BrandCard` en Firmas, reducido de 40→28pt). News mantiene byline textual `POR {BRAND} · {DATE}` porque el brand es autor editorial, no maison
5. Shared-element `Hero` transition al abrir detail (`tag: 'project-hero-{id}'` y `'news-hero-{id}'`)

**Deferred (no implementado en esta iteración):**
- Grain texture 2% overlay sobre caption beige — print-magazine feel, requiere asset PNG noise
- Parallax 0.85 en imagen al scroll — depth cinematográfica, requiere ScrollController tracking per-card

Son dos refinements visuales low-impact que se pueden añadir después sin restructurar.

**Consequences:**
- (+) Cards premium auténticas con Campton solo — sin añadir fuentes, sin tocar bundle size, consistencia total del sistema
- (+) Título Campton Light 48pt transforma el carácter de "ficha" a "cover de revista" instantáneamente
- (+) Italic en tagline/deck introduce sabor editorial usando una variante ya disponible en la licencia Campton
- (+) Hairlines son marca compositiva editorial sin añadir contenido
- (+) Logo SVG uniforme resuelve la heterogeneidad de logos (Ciclo Capital 2 líneas, Lacomb & Bos fino, Vellte grueso) con el mismo pattern que ya funciona en Firmas
- (+) Hero transition crea continuidad perceptual card → detail
- (−) Pierde el "warm editorial" que daría una serif display (T Magazine territory)
- (−) Requiere Campton Light (w300) disponible en pubspec — verificado: todos los pesos de Campton están cargados como assets

**Reference audit:** los 7 moves son coordinados — no es un menú a elegir. La transformación viene del cambio tipográfico hero + italic + framing + logo uniforme + continuidad al detail funcionando juntos. Quitar cualquiera de los 5 principales reduce el efecto desproporcionadamente.

### Addendum v2 (2026-04-22, pulido definitivo tras revisión integral)

Seis refinamientos tras mirar la card como un todo:

- **Hairlines editoriales eliminadas**. 0.5px alpha 15% sobre fondo beige no se percibían en simulador; aportaban "sensación caja" sin función visible. Sustituidas por whitespace ajustado (24pt uniforme antes y después del bloque title+subtitle+tagline).
- **Compactado spacing tagline → byline** de ~50pt (original hairline + padding doble) a 24pt. El byline ahora se siente "pie de foto" continuo con el caption, no bloque suelto.
- **Logo SVG reducido** de 100×28 → **72×20**. La altura 20pt casa mejor con texto caption (10px) adyacente — evita desbalance óptico donde el logo quedaba "flotante" al lado de la fase textual.
- **Fase movida de byline a chip sobre imagen**. Separación semántica: estado operacional (condiciona acción — "¿puedo invertir aún?") pertenece a chip badge, no a byline de créditos. Convención del sector real estate (Sotheby's International, Engel & Völkers, Christie's).
- **Chip variants fill vs outline**. Dos chips fill negros (VIP + fase) se sentirían "e-commerce flat". PRIVATE mantiene fill black (privilegio máximo); la fase usa outline (transparent + 0.5px white border + soft shadow). Jerarquía visual automática cuando ambos coexisten.
- **Location simplificada a `project.city`**. "Dubai, AE" con código ISO se leía seco/dudoso en todo el catálogo (MADRID, ES / MIAMI, US / DUBAI, AE). Usar solo la ciudad ("Dubai", "Madrid", "Miami") es más luxury, screenshot-universal, menos ruido.
- **Edge-to-edge imagen confirmado**. El efecto marco (imagen con padding lateral) se descartó definitivamente: crea tensión semántica con scroll vertical continuo ("soy pieza curada separada" vs "hay 18 más inmediatamente debajo"). La diferenciación con Home ya viene del modelo de interacción (1 per viewport vs scroll catálogo), no del padding.

Esta es la estructura final de `ProjectShowcaseCard` y la alineada `LhotseNewsCard` (que mantiene byline `POR BRAND · DATE` textual porque la firma es autor editorial, no maison).

### Addendum v3 (2026-04-23, convergencia news↔projects)

`LhotseNewsCard` converge con `ProjectShowcaseCard`:
- **Tipo (PROYECTO/PRENSA) movido de kicker textual a chip outline sobre imagen** (top-left, mismo styling exacto que la fase chip de projects)
- Caption arranca directamente con el título — 3 bloques (título + deck italic + byline) en simetría compositiva con projects
- Byline textual `POR {BRAND} · {DATE}` se mantiene — asimetría semántica intencional con projects (que usa logo SVG): en news el brand es **autor editorial**, no maison; la convención magazine es "POR/BY autor"

Resultado: ambas cards comparten gramática visual unificada — **chip outline top-left = clasificación, caption = contenido editorial**. El usuario aprende el patrón una vez y se aplica igual en todo el archivo. Diferenciación entre cards queda en los campos semánticos propios (logo de maison vs autor editorial textual; chip de fase vs chip de tipo; con/sin VIP), no en la arquitectura.

Rechazado en v3: añadir intro/lead paragraph en la card de news. Card es preview, detail es lectura — el deck italic ya es el equivalente magazine al "standfirst". Lead paragraph rompería el carácter scan-friendly.

### Addendum v4 (2026-04-23, separator news + decisión de aspect en news)

Dos cambios + una decisión revertida tras verificación en simulador:

- **Separator entre cards de news** reducido de 56pt → 32pt. La altura previa generaba ~104pt de aire entre items, la siguiente noticia no asomaba en viewport y el scroll se sentía "vacío". 32pt mantiene algo más de respiro que projects (16pt) — news escanea un beat más lento por carácter editorial — pero permite el "asomar" como en projects.

- **Aspect 4:5 portrait probado y revertido** a 1:1. Hipótesis inicial: cada tab de Search puede adoptar su formato (Firmas grid 2×2 ya rompe el patrón listing) → news a 4:5 daría carácter cover-magazine. Verificación en simulador: con 4:5 (414×517pt), el caption (título displayHero + deck italic + byline) sale del viewport en escenarios comunes (título 2 líneas + deck 2 líneas), forzando scroll para ver la info. En un catálogo scrollable donde el usuario escanea pieza a pieza, sacrificar la legibilidad de la info por carácter visual rompe la función primaria. **El cover-magazine treatment pertenece al detail screen**, no al listing tile. Vuelta a 1:1.

- **Regla del sistema clarificada**: "cada tab adopta el formato que mejor sirve a su CONTENIDO". Firmas usa grid 2×2 porque su contenido (logos discretos, comparables) **literalmente lo requiere**. Projects y News son ambos listings de teasers con misma función (escanear y elegir cuál abrir) → mismo aspect 1:1. La diferenciación entre projects y news viene de los campos semánticos (chip de fase vs tipo, byline logo vs textual, location/tagline vs deck), no del formato. Diferenciar por aspect cuando rompe la legibilidad del catálogo es regla artificial sin payoff.

### Addendum v5 (2026-04-23, Firmas grid — magazine cover format)

Evolución del grid de Firmas de logo-only monocromo a **formato magazine cover** (referencia directa: *The World of Interiors* biblioteca de issues). El cliente quiere narrativa editorial por firma, no solo identificación.

**Cambio:**

- **Top 30% beige** con logo SVG centrado reducido a **64×18** (wordmark discreto tipo cabecera de revista — antes 100×40, ahora prima la imagen como protagonista)
- **Bottom 70%** con `LhotseImage(brand.coverImageUrl)` envuelto en `Padding.symmetric(horizontal: 12)` sobre fondo `AppColors.background` — la imagen queda con margen lateral simétrico sobre beige, evocando el rectángulo de portada de revista dentro de la card (fiel a referencia — edge-to-edge se descartó por "plano de app" vs "objeto editorial")
- **Fondo de la card** pasa a `AppColors.background` (antes transparent sobre el beige del screen)
- Hairline border 0.5px alpha 0.1 se mantiene — sharp-edge coherente con el sistema
- Fallback: si `coverImageUrl` está vacío, card vuelve al layout logo-only centrado anterior sin romper grid

Reutiliza `brand.coverImageUrl` (ya existente en `BrandData`, leído de `brands.cover_image_url` y usado en `brand_detail_screen`). No requiere schema change.

**Consequences:**

- (+) Firmas gana narrativa editorial por marca — cada maison proyecta su mundo visual sin necesidad de texto
- (+) Tab FIRMAS se diferencia del resto (grid 2×2 + composición magazine) mantiene identidad propia dentro del hub Search
- (−) **Fragmenta la unidad cromática monocroma del holding** — 13 covers introducen 13 paletas. Se asume como tradeoff consciente: la narrativa de marca por firma pesa más que la lectura "pertenecen al mismo grupo" en esta pantalla (la pertenencia al holding la comunica el chrome de la app, no el grid)
- (−) Acerca formalmente Firmas a `ProjectShowcaseCard` del catálogo (ambos son "imagen + signifier de marca"). Diferenciación queda en: grid 2×2 vs stream vertical, ratio 1:1 card vs 1:1 imagen, wordmark top vs byline bottom
- (−) Requiere `cover_image_url` curado por firma (ya existe en seed, verificado)

**Rechazado:**

- Edge-to-edge sin padding — pierde el guiño "portada enmarcada" de la referencia
- Padding también inferior (logo arriba + imagen centrada + aire abajo) — acerca demasiado a "card de revista" hiperrealista, sobrecargado para grid 2×2 en móvil
- Logo 72×20 (patrón `_BrandStamp`) — demasiado presente; 64×18 deja respirar mejor la cover

**Regla actualizada (ADR-50 v5):** "cada tab adopta el formato que mejor sirve a su CONTENIDO" sigue vigente — Firmas requiere grid 2×2 por logos comparables, y ahora **además añade imagen** porque el cliente quiere proyectar mundo editorial por maison. La regla no cambia; cambia el contenido de Firmas (pasa de "set de logos" a "set de covers-con-wordmark").

**Pulido v5.1 (mismo día, 2026-04-23):** tras ver el grid en simulador, tres afinados:

- Border alpha `0.1` → `0.18` (el hairline sobre card beige-sobre-fondo-beige era visualmente nulo — ahora el frame se percibe sin romper el flat-editorial)
- Grid spacing `AppSpacing.md` (16) → `AppSpacing.lg` (24) — cards respiraban poco verticalmente
- Column split `3/7` → `25/75` — logo arriba con menos aire, cover abajo con más presencia
- `childAspectRatio` `1.0` → `0.82` — **gesto final**. Sin portrait, el símil con *The World of Interiors* queda a medias (esas portadas son claramente verticales). No introduce un tercer ratio al sistema porque Firmas ya vive en su propia gramática compositiva (grid 2×2 vs listing 1:1 de projects/news); su aspect es independiente. Coste: ~2 filas por viewport en vez de ~2.5 — irrelevante con 13 firmas fijas.

### Addendum ADR-48 (2026-04-23, alineación tipográfica con archive)

Con el upgrade premium del archive (ADR-50: `displayHero` Campton Light 48pt + italic + Hero shared-element), el Home feed quedaba con tipografía inconsistente: mismo proyecto mostraba `headingLarge` w500 24pt en Home y `displayHero` Light 48pt en archive. Además no había Hero shared-element entre Home → detail.

**Refinamiento aplicado en `FeedCard` sin tocar estructura SNKRS**:

- Título: `headingLarge` (24pt w500) → `displayLarge` override a w300 (40pt Light, line-height 1.0). Un paso bajo el hero de archive (48pt) para mantener un beat más loud que el archive mientras comparte la familia tipográfica Campton Light.
- Hero shared-element tag añadido al media block: `project-hero-{id}` para projects + opportunities, `news-hero-{id}` para news. Matching con los tags ya definidos en ProjectShowcaseCard / LhotseNewsCard / detail screens. Tap en feed card → imagen se expande con continuidad cinemática al detail.
- Brand feed item queda sin Hero tag por ahora — brand detail no define Hero matching todavía.

**No tocado** (estructura SNKRS intacta per ADR-48):
- 1 per viewport, 65% media + 35% caption beige
- CTA textual (VER PROYECTO / LEER / etc)
- Video autoplay activo-only, pull-to-refresh, scroll memory
- Mixed content types (project/news/opportunity/brand), curación server-side

Resultado: Home sigue siendo "stadium loud SNKRS discovery" en comportamiento e interacción; gana coherencia tipográfica con el resto de la app. Rechazado: subir el título a `displayHero` 48pt (rompería carácter loud Home), chips outline sobre imagen (Home no usa chips, caption beige debajo es el lenguaje propio).

## ADR-51: Strategy Screen — Full-Beige Collapsing Hero (Supersedes ADR-7 Navy + refines ADR-14 Sequential Fade)

**Date:** 2026-04-24

**Context:** The Strategy screen hero went through several iterations — navy slab (ADR-7), collapsing black hero with sequential fade (ADR-14), and most recently an editorial photo hero (Alberto Aguilera 58 salon + warm gradient with the same collapsing mechanic). The photo iteration also extracted the asset-allocation breakdown (Coinversión / Compra directa / Renta fija %) into a dedicated table below the slab.

Client review: the editorial photo hero felt too heavy for a wealth-report screen, and the allocation breakdown was redundant noise on top of the brand rows (which already disclose the model per row). But the **scroll-collapse mechanic itself was valuable** — title fading out + patrimonio total interpolating into the chrome-band center is the signal that keeps orientation while browsing the ledger. Preference: **strip the visual drama (photo, gradient, dark background, text shadows) but keep the collapse behaviour**, all on beige.

**Decision:**

- Keep the `SliverPersistentHeader` + `_HeroDelegate` pattern (same mechanic as the photo iteration) but simplified:
  - **Background** `AppColors.background` (beige) — no photo, no gradient, no `overlayWarm`.
  - **Text** `AppColors.textPrimary` (black) — no text shadows. Status bar icons stay dark (default over beige), so no `AnnotatedRegion<SystemUiOverlayStyle>` override.
  - **Title** `'Mi estrategia\npatrimonial'` in `displayLarge` Campton Light w300, fades out over the first ~60% of the collapse (`titleOpacity = ((expandRatio - 0.4) / 0.6).clamp(0,1)`) — softer ramp than the photo iteration (which used `/0.4`) because there are no shadows to mask the transition.
  - **Patrimonio total** as `RichText`: amount interpolates `28 + 20*expandRatio` (i.e. 48pt expanded → 28pt collapsed), ` €` interpolates `13 + 9*expandRatio` (22pt → 13pt). Fixed-padding position slides bottom-left (expanded) → chrome-band center (collapsed).
  - **Logo + bell** drawn as `Positioned` children of the same delegate (`LhotseMark(color: textPrimary)` + `LhotseNotificationBell(color: textPrimary)`, no `hasShadow`) so they stay pinned while the cifra moves underneath.
  - `expandedHeight = topPadding + 260` (down from 320 of the photo iteration — without a photo we don't need the extra respiro).
  - `collapsedHeight = topPadding + 80` (unchanged).
- **Remove** asset-allocation breakdown table: `_AllocationSlice`, `_allocationModels`, `_buildAllocationBreakdown` helper, and the `_AllocationTable` widget.
- **Remove** legacy asset `assets/images/strategy_hero.webp`.
- **Remove** `flutter/services.dart` import (no longer needed without `SystemUiOverlayStyle`).
- Brand rows, hairline separator, and opportunities section unchanged.

**Why this supersedes ADR-7 + refines ADR-14 for Strategy:**
- ADR-7 (navy hero differentiation): no longer needed — the notification bell + bottom-nav dot already mark ESTRATEGIA as the private financial zone, and the patrimonio total itself is the loudest signal on screen. Visual differentiation doesn't require a distinct colour slab.
- ADR-14 (sequential fade for collapsing heroes): **still applies here** — the mechanic survives, just on beige. The screen remains part of the family of collapsing heroes with sequential fade (Brand investments, project/news detail, etc.).

**Trade-offs:**
- (+) Keeps the scroll-collapse orientation cue (patrimonio total always visible in the chrome band) that the client relies on while scanning the ledger.
- (+) Removes the editorial photo weight + dark overlays — the screen now feels closer to a wealth-report page (Pictet / Julius Bär) than to an Openhouse editorial.
- (+) Removing the allocation table tightens the hierarchy: patrimonio → per-brand holdings → opportunities.
- (-) The collapse is less dramatic without the photo fade underneath — acceptable; the title fade + cifra interpolation still carry the motion.
- (-) Logo+bell have to be drawn manually in the delegate (can't reuse `LhotseShellHeader`) because their Z-order relative to the sliding cifra matters. Same trade-off as every previous iteration of this screen.

---

## ADR-52: Opportunities moved to Home-only (supersedes ADR-10 + ADR-23)

**Date:** 2026-04-24

**Context:** ADR-10 kept "NUEVAS OPORTUNIDADES" as a section at the bottom of the Strategy screen plus a full `OpportunitiesScreen` reachable through it, with business-model tabs + location filter (ADR-23). Since the SNKRS-style Home feed (ADR-48) shipped, opportunities already interleave naturally as `FeedOpportunityItem` cards for investors/VIPs, with the same imagery and the editorial typography the feed uses. The Strategy section duplicated that discovery job in a smaller, less premium format, and pulled the investor away from the patrimonio read. The dedicated Opportunities listing added filters that investors rarely reach — by the time they're evaluating a specific model they're in the project detail, not a filtered list.

**Decision:** Remove the opportunities section from the Strategy screen and delete the dedicated `OpportunitiesScreen` + `/investments/opportunities` route. Opportunity discovery lives exclusively in the Home feed. Strategy becomes a pure wealth-report view: hero + brand ledger.

Kept in place:
- `opportunitiesProvider` and the `user_opportunities` Supabase view — still consumed by `homeFeedProvider` (investor/VIP path).
- `ref.invalidate(opportunitiesProvider)` in `app.dart` and `home_screen.dart` — still needed for Home feed refresh.

Removed:
- Section (header "NUEVAS OPORTUNIDADES ↗" + horizontal carousel of 4 compact cards) inside `InvestmentsScreen`.
- `_OpportunityCard` private widget (only consumer was the deleted section).
- `lib/features/investments/presentation/opportunities_screen.dart` (`OpportunitiesScreen` + its state + `_FilterTab` widget).
- `AppRoutes.opportunities` constant and its `GoRoute` entry in `router.dart`.
- Import of `project_data.dart`, `lhotse_image.dart`, `projects_provider.dart` from `investments_screen.dart` (orphaned after `_OpportunityCard` + `opportunitiesProvider` removal there).

**Trade-offs:**
- (+) Strategy is tighter — one job, done well (wealth report), matching the Pictet / Julius Bär reference frame in ADR-51.
- (+) No duplicated discovery surface; Home feed is the canonical place to encounter a new opportunity.
- (+) Less code (one screen + a card + a route + a filter bar gone).
- (-) Loses the "filter opportunities by business model / location" affordance — acceptable because investors who want that granularity land in Search or Home's model-specific flows, and the filter was rarely used in practice per ADR-23's own concession ("no text search on opportunities — acceptable since Search screen exists").
- (-) Investors who memorised the Strategy → Opportunities nav path lose it. Acceptable; the Home feed entry is more discoverable.

---

## ADR-53: Shell UX — preserve depth + pop-to-root on active-tab re-tap + disk image cache

**Date:** 2026-04-24

**Context:** Three shell-level UX issues surfaced together:
1. A custom `homeFeedPositionProvider` was re-implementing scroll memory via `ref.read` inside `dispose` — which crashes on Riverpod 3 (`ref` is invalidated before dispose runs). The crash fired on logout because that's the only path where `HomeScreen` actually gets disposed (tab switching inside `StatefulNavigationShell` only deactivates widgets).
2. Users on a deep screen (e.g. Strategy L3 compra-directa detail) had no escape hatch to jump back to the tab's root without tapping the system back button multiple times.
3. First-tap Hero transitions from the Home feed flashed a blank hole because `LhotseImage` used plain `Image.network` — no disk cache, so every first view of an image was a network fetch and the Hero flight ended before the decode.

**Decision:**

- **Preserve depth per tab as the default** — `StatefulNavigationShell` already does this natively via IndexedStack semantics. No provider needed. Deleted `homeFeedPositionProvider` + `home_scroll_offset_provider.dart` + the `initState`/`dispose` dance in `home_screen.dart`. If an investor pauses L3 to glance at Home and returns, they land back in L3 — the premium default (Apple / Instagram / Linear pattern).
- **Escape hatch via `initialLocation: i == currentIndex`** — the shell already passes this flag to `goBranch`, so a re-tap on the active tab pops the branch's stack to its root. Confirmed working; no code change needed. Documented in CLAUDE.md so future contributors don't reinvent it.
- **Disk image cache via `cached_network_image`** — upgraded `LhotseImage` to `CachedNetworkImage` with:
  - 180ms `fadeInDuration`
  - `placeholder` and `errorWidget` both set to `Container(color: AppColors.surface)` so no code path flashes a white hole.
  - Asset path branch (`Image.asset`) preserved unchanged.
- Rejected alternative: **pass `ImageProvider` through navigation `extra`**. Local fix, adds nav coupling, doesn't cover deeplink / Search / notification entries into detail. `cached_network_image` covers every image in the app (brand cards, gallery, news, detail heroes) without touching call sites.

**Trade-offs:**
- (+) Less code (one provider + one dead dispose path removed).
- (+) Every image in the app benefits — Firmas grid, project gallery, news archive, brand detail, Strategy ledger icons.
- (+) Disk cache survives app restarts, so second-cold-start is instant for previously-viewed content.
- (+) Standard Flutter ecosystem dependency (~300KB, stable).
- (-) `cached_network_image` transitively brings `sqflite` + `path_provider` — slightly heavier build, irrelevant at runtime.
- (-) Very first view of any image (fresh install) still shows the beige placeholder for a beat while the network fetches. Acceptable; the fade turns "flicker" into a deliberate-looking load transition.

---

## ADR-54: Video audio — thumbnails muted fijo, fullscreen unmuted con controles

**Date:** 2026-04-24

**Context:** El app tiene dos contextos de reproducción de video y la gestión de audio estaba mal en ambos:
1. **Thumbnails** (`FeedVideoPlayer` en home feed + project/news detail heros): autoplay muted correcto, pero con un botón `_MuteToggle` que permitía desilenciar. En reproducción pasiva (scroll sobre el feed, entrar al detalle) cualquier audio es invasivo — el control no aportaba valor y ensuciaba el layout editorial.
2. **Fullscreen** (tap en hero de noticia con `hasPlayButton`): `_VideoPlayerScreen` era un placeholder estático (imagen + "PRÓXIMAMENTE") sin reproductor real.

**Decision:** Establecer una regla del sistema — el contexto de reproducción determina la gestión de audio:

- **Thumbnail → muted fijo, sin toggle.** `setVolume(0)` permanente. Reproducción pasiva, el usuario no pidió ver el video, inyectar audio sería hostil. Elimina `_muted`, `_toggleMute`, `_MuteToggle` de `FeedVideoPlayer`.
- **Fullscreen → unmuted, con controles para silenciar.** `setVolume(1)` al arrancar — el usuario tapeó play explícitamente, la acción implica "quiero ver esto completo". `FullscreenVideoPlayer` (nuevo widget público) con controles auto-hide (X cerrar top-left, speaker toggle top-right, play/pause central 72×72, scrubber + duración bottom). Visibles al arrancar + 3s, tap en video los toggle, pausa/fin los pinnea visibles. Respeta hardware mute switch de iOS por defecto vía AVPlayer del paquete `video_player`.

**Rejected alternatives:**
- **Fullscreen muted con badge "TAP PARA SONIDO"**: más conservador pero frustrante — el usuario ya hizo la acción explícita de play y tiene que hacer una segunda para oír. Los navegadores bloquean autoplay con sonido por policy, pero en native app (iOS/Android) no hay tal restricción y el hardware mute switch cubre el caso del contexto público.
- **Mantener toggle en thumbnail "por si acaso"**: contradice el patrón premium editorial (NYT, Apple Newsroom, Dior) donde el thumbnail es siempre silent y la decisión de audio pasa al fullscreen.
- **Fullscreen con controles siempre visibles**: ensucia el contenido, rompe el tono Apple TV / Netflix.

**Trade-offs:**
- (+) Regla clara y coherente del sistema — predecible para el usuario y fácil de aplicar a futuros videos.
- (+) `FullscreenVideoPlayer` es widget público reutilizable — project detail podrá adoptarlo cuando se añada play button ahí.
- (+) Menos superficie de UI en thumbnail (elimina botón circular + timer de dismissal + state).
- (-) Un usuario en contexto público sin auriculares tiene que reaccionar rápido al speaker toggle para silenciar. Mitigado por el hardware mute switch de iOS, que es el mecanismo que ese usuario ya usa por norma.

---

## ADR-55: Home feed server-side curated, polymorphic, roleless — supersedes ADR-52

**Date:** 2026-04-24
**Status:** Accepted

**Context:** The Home feed was hybrid: `featured_projects` (curated, role-scoped, projects-only) + client-side composition that layered in news, brands, and computed opportunities. Two friction points: (1) the recently-added `logo_on_dark_media` flag lived on three different tables because the feed had no table of its own; (2) opportunities were a shrinking feature — investor-only, computed per user, and the client UI kept shedding surface area (ADR-10 killed the Strategy section, ADR-52 killed the dedicated screen). Both problems were symptoms of the same thing: the feed had no first-class representation server-side.

**Decision:**
- Introduce a single polymorphic curation table `home_feed_items (source_type ∈ {project,news,brand,asset}, source_id, sort_order, logo_on_dark_media)`. `homeFeedProvider` reads it ordered by `sort_order` and batch-fetches the four source types in parallel.
- Drop `featured_projects` (role-scoped, projects-only — obsolete).
- Drop `user_opportunities` view, `opportunitiesProvider`, `ProjectData.fromOpportunityRow`, `FeedOpportunityItem`, `OpportunitiesScreen`, and the `new_opportunities` notification preference. **Opportunities as a feature are removed entirely.**
- The feed is identical for every role (viewer, investor, investor_vip). VIP gating stays per-project through the existing `showVipLockSheet` bottom sheet when a viewer taps a VIP card.
- Add `FeedAssetItem` as a new content type — an `assets` row surfaced editorially (address, city, thumbnail_image). Tap target for its detail is TBD (tracked in ROADMAP).
- `logo_on_dark_media` lives **only** in `home_feed_items`, keyed per slot. Removed from `projects`, `news`, and `brands` — the property is about "how the Lhotse mark reads on this slot," not an attribute of the content itself.
- Polymorphic integrity via a trigger that validates `source_id` against the right source table. Integrity on source-row deletes is best-effort: the provider filters orphan rows (`whereType<FeedItem>`).

**Rejected alternatives:**
- Extend `featured_projects` to accept other types. Would need to drop `role` and add `source_type`, a DROP/CREATE either way — no saving.
- Leave `logo_on_dark_media` on the source tables. Keeps the flag duplicated across three tables for a property that only matters in the Home feed slot.
- Keep opportunities as computed client-side without a screen. Dead code path — the entity no longer exists in the product.

**Trade-offs:**
- (+) Single source of curation; admin edits one table.
- (+) Single feed for every role — simpler mental model; no per-role divergence to reason about.
- (+) `logoOnDarkMedia` lives where it's consumed — no cross-table duplication.
- (+) Mass removal of dead opportunities code (~12 files touched, 1 view dropped, 1 column dropped).
- (-) Polymorphic FK via trigger instead of referential constraints. Acceptable: the only writer is the admin via dashboard.
- (-) Asset detail route is not yet defined — tap on `FeedAssetItem` is a no-op. Tracked.
## ADR: Rename "Compra Directa" → "Adquisición" (2026-04-24)

**Decision**: the UI label for the `direct_purchase` business model changes from "Compra Directa" to "Adquisición" across app and admin.

**Motivation**: "Compra Directa" broke register parity with "Coinversión" and "Renta Fija" — sounded like a retail transaction rather than a financial product. "Adquisición" is a single word with a private-banking tone; within Lhotse's real-estate context there's no ambiguity with other meanings (M&A, procurement).

**Impact**: visible label only. The following identifiers stay intact:
- DB value `direct_purchase` (table `purchase_contracts`, view `user_direct_purchases`, routes, bucket paths).
- Dart `BusinessModel.directPurchase` enum and the `'direct_purchase'` JSON serialization.
- Internal variable names like `isCompraDirecta` in `brand_investments_screen.dart` and file names (`direct_purchase_detail_screen.dart`). An identifier refactor is out of scope.
- Historical ADRs mentioning "CompraDirecta" or "compra directa" (historical record — not rewritten).

## ADR-56: Video access control — Bunny Token Auth + Edge Function signing (supersedes ADR-54 public URL assumption)

**Date:** 2026-05-05
**Status:** Accepted

**Context:** ADR-54 assumed video URLs would be publicly reachable. After MVP, the client requirement changed: video assets are paid investment-marketing content and must not be freely accessible to anyone with the link. The CDN already in use (Bunny Stream) supports Token Authentication natively.

**Decision:** Raw video URLs are stored in DB as canonical Bunny CDN paths. Before playback, the client calls `playableVideoUrlProvider` which delegates signing to the `sign_video_url` Supabase Edge Function. The function verifies the user's JWT, validates the Bunny hostname against a whitelist, computes `HMAC-SHA256(BUNNY_SECURITY_KEY + path + expires)`, and returns a signed URL with TTL 1h. The secret never leaves the Edge Function environment.

**Alternatives rejected:**
- *Public URLs* — original plan, rejected because marketing video assets have investment-grade value and must not be freely shareable.
- *Client-side signing* — would require embedding `BUNNY_SECURITY_KEY` in the Flutter binary (extractable). Rejected.
- *Move all video to Supabase Storage* — avoids Bunny dependency but increases storage cost (Supabase egress ~10× more expensive than Bunny for video). Documented as fallback for small uploads via relative path in `playableVideoUrlProvider`.
- *HLS streaming* — adaptive bitrate, but `video_player` on Android handles HLS unreliably. Rejected. Videos in this app are short (15–40 s hero clips) — progressive MP4 at 4 Mbps is adequate even on 4G.

**Consequences:**
- (+) Videos inaccessible without a valid user session; signed URLs expire in 1h.
- (+) Key rotation (Bunny panel → `supabase secrets set` → redeploy function) does not require any app update.
- (-) ~200–400 ms extra latency on hero open while signing resolves. Hero shows poster image in the interim — no layout shift.
- (-) Edge Function must be deployed and `BUNNY_SECURITY_KEY` secret set before video plays in production.

## ADR-57: Splash — CustomPainter draw animation replaces SVG + pulse
**Status:** Superseded by ADR-72. Full body in git history of this file.

## ADR-58: Asset surface fields remodel + pool→elevator (refines ADR-33)

**Date:** 2026-05-08
**Status:** Accepted

**Context:** ADR-33 promoted asset attributes from JSONB to typed columns and, among others, added `surface_m2`, `plot_m2`, and `has_pool`. After running the catalog with real activos we found that:

- What we labeled `surface_m2` was effectively *useful* surface, not built. The Spanish real-estate market routinely shows both *superficie construida* and *superficie útil* — investors expect both.
- `plot_m2` never applied: every asset in the portfolio is an urban dwelling without an independent plot.
- `has_pool` was always `false` — pool isn't a relevant amenity for our segment, but **elevator** is the binary that actually changes a flat's value in the cities we operate in.

**Decision:** schema remodel (migration `20260508130000_asset_surface_rename_and_elevator.sql`):

- `surface_m2` → renamed to `usable_surface_m2`, data preserved.
- `plot_m2` → DROPPED.
- `has_pool` → renamed to `has_elevator` (all values were `false`, no data loss).
- New column `built_surface_m2 NUMERIC` — separate from the useful slot, fills from admin.
- Views recreated (`assets_with_status`, `purchase_asset_details`, `coinvestment_project_details`) to project the new shape with `security_invoker = true`.
- UI labels updated in Flutter: "Superficie / Parcela / Piscina" → "Superficie construida / Superficie útil / Ascensor".

**Rationale:**
- Keeps ADR-33's core thesis intact (typed columns > JSONB); this ADR only adjusts which typed columns we keep.
- Mirrors the dual-surface convention used by every Spanish portal (Idealista, Fotocasa, Sotheby's RE) so investors don't have to reconcile vocabularies.
- Reflects the reality of the catalog rather than a speculative "could one day have a pool" ask.

**Consequences:**
- (+) `built_surface_m2` and `usable_surface_m2` coexist explicitly — no overloaded "surface" with ambiguous meaning.
- (+) `has_elevator` reuses the boolean slot for an attribute that actually appears in CARACTERÍSTICAS.
- (+) Catalog does not lose data: useful surface preserved, pool/plot eliminations are factually empty.
- (-) `built_surface_m2` is NULL for legacy rows until the admin fills each activo (graceful: the assetInfo getter omits NULL entries).
- (-) Three views had to be DROP+CREATE'd; no `CREATE OR REPLACE` shortcut because we were dropping columns.

**Supersedes (partial):** the column list in ADR-33. The JSONB-elimination thesis itself stands.

---

## ADR-59: Asset district & neighborhood — admin-only, mobile views untouched

**Date:** 2026-05-08
**Status:** Accepted

**Context:** Admins needed to record the *distrito* and *barrio* of every activo for filtering, grouping and reporting. The portfolio is Madrid-only today (21 distritos / 131 barrios) but will expand to other Spanish cities, so a hardcoded enum-per-city does not scale.

**Decision:** add two nullable TEXT columns to `assets` — `district` and `neighborhood` — and populate them from the admin form via reverse geocoding (Nominatim/OSM). Migration `20260508140000_asset_district_neighborhood.sql` recreates `assets_with_status` to project the new columns. **`purchase_asset_details` and `coinvestment_project_details` are intentionally not touched**: the investor app does not display these fields, so leaving the mobile-facing views untouched avoids cascading regenerations and keeps the surface that the Flutter app must read minimal.

**Rationale:**
- Free-text columns scale to any city without code changes; UI normalization comes from Nominatim's structured response.
- Geocoding via Nominatim (gratis, sin API key) suffices for admin volumes; rate limit (1 req/s) is a non-issue for an interactive form.
- Backoffice-only scope: admin filters and exports benefit, but investors don't see "Calle Ayala 94, Goya, Salamanca" — they already see "Madrid, España" and the address line, which is enough.

**Consequences:**
- (+) Catalogue gains structured location data without a hardcoded `madrid_districts` enum.
- (+) Mobile views stay frozen — no changes propagate to `lhotse_app` providers.
- (-) Two views diverge in shape (admin sees more than mobile). Acceptable: views already differ for other reasons.
- (-) Legacy assets need a one-shot backfill (done via MCP + Nominatim, not productionized as an endpoint).

## ADR-60: "Avance de obra" — Panoee 360° URL replaces gallery of images/videos

**Date:** 2026-05-11
**Status:** Accepted

**Context:** The L3 coinvestment detail screen's AVANCE tab used to show a gallery of construction progress photos/videos populated via `projects.progress_media` (JSONB array). Two problems: (1) the admin had to upload media one by one on every visit to the site, and (2) static photos compete with the immersive feel of the Tour Virtual section (same screen, PROYECTO tab) which already uses a Panoee 360° walkthrough.

**Decision:** drop `projects.progress_media` (JSONB) and add `projects.progress_tour_url` (TEXT). The Flutter `_AvanceTab` reuses `VirtualTourSection` — same component as Tour Virtual — parametrised with `label: 'AVANCE DE OBRA'`. The admin field becomes a single URL input mirroring `virtual_tour_url`. Migration `20260511120000_progress_tour_url.sql` recreates `coinvestment_project_details` and `projects_with_metrics` to project the new column.

**Rationale:**
- One URL ≪ N uploads. Admin friction drops; updates become an in-Panoee operation.
- Mirrors the proven Tour Virtual pattern (WebView via `flutter_inappwebview`, `FullscreenVirtualTour`). Zero new UI primitives.
- Principles #1 (single canonical source) and #4 (no speculative fields): `progress_media` had a single consumer (the gallery now removed), so it's not a candidate for "keep as historical record".

**Consequences:**
- (+) Admin time per progress update collapses from several minutes (upload+sort) to seconds (paste URL).
- (+) UI consistency between PROYECTO and AVANCE tabs — same Matterport-like immersion.
- (-) Historical galleries in `progress_media` are lost (DROP COLUMN). Acceptable: no productive data; seed only.
- (-) Requires manual Panoee setup per project (capture + scene authoring). Outside this app's scope.

## ADR-61: `extended_nested_scroll_view` for independent per-tab scroll in L3

**Date:** 2026-05-11
**Status:** Accepted

**Context:** L3 detail screens (coinversion, direct purchase, completed) wrap a collapsing hero, a scrollable identity block and a pinned `TabBar` in `NestedScrollView`, with each tab's body inside a `TabBarView`. Stock `NestedScrollView` does not preserve a `ScrollPosition` per tab — its internal `_NestedScrollController` manages only one active `ScrollPosition`, so switching tabs transfers the outer offset to the newly active tab, producing the bug "scroll persists across tabs". Tried `SliverOverlapAbsorber`/`Injector` (broke the rich `SliverAppBar` with `expandedHeight + flexibleSpace`), `PageStorageKey` on `SingleChildScrollView` (not enough in `NestedScrollView`'s coordinator), and `AutomaticKeepAliveClientMixin` (state survives but the shared controller still wins). All failed due to the same framework limit.

**Decision:** adopt the `extended_nested_scroll_view` package (https://pub.dev/packages/extended_nested_scroll_view), a maintained drop-in replacement for `NestedScrollView` purpose-built to support per-tab scroll persistence. Replace `NestedScrollView` → `ExtendedNestedScrollView` in the 3 L3 detail screens with `onlyOneScrollInBody: true` and `pinnedHeaderSliverHeightBuilder: () => MediaQuery.paddingOf(context).top + kToolbarHeight + kLhotseTabBarHeight`. Header, hero, identity, pinned tab bar and the `_outerController` + `_heroGone` / `_showCollapsedTitle` callbacks stay unchanged.

**Rationale:**
- Preserves the exact current visual / animation contract — zero design impact.
- Drop-in API: each screen gets a 2-line addition. No restructuring of slivers, no consolidation of hero+identity (which would change the animation).
- Package is mature (500+ likes, active maintainer, widely used).
- Building the equivalent ourselves would mean reimplementing `NestedScrollView`'s coordinator with multi-position support — impractical.

**Consequences:**
- (+) Per-tab scroll persists correctly across tab switches in the 3 L3 screens.
- (+) `LhotseTabScrollWrapper` (extracted to `core/widgets/`) provides a single contract for tab body Scrollables and is reusable for future tab-based detail screens.
- (-) New runtime dependency (`extended_nested_scroll_view` + transitive `visibility_detector`). Reviewable: package is small and focused.
- (-) Maintenance contract: if the package's API changes around `pinnedHeaderSliverHeightBuilder` or `onlyOneScrollInBody`, the 3 L3 screens must be revisited. The signal will be visual (offset on initial tab open or shared scroll regression) — covered by the manual smoke test below.

**How to verify on package upgrade:**
1. Enter each L3 (coinversion, direct purchase, completed).
2. Scroll inside a tab, switch to another (must open at top), switch back (must restore previous offset).
3. Section labels (e.g. "ANÁLISIS ECONÓMICO" in coinversion Finanzas) must be visible immediately on tab entry — no `pinnedHeaderSliverHeightBuilder` offset bug.
4. Hero collapse animation and `_heroGone`/`_showCollapsedTitle` state flips must behave exactly as before.

## ADR-62: News video — static poster + play overlay, no inline autoplay

**Date:** 2026-05-11
**Status:** Accepted

**Context:** News items frequently carry videos (interviews, statements, press). The previous implementation cloned the project-detail hero pattern (poster → autoplay muted inline after 2.5s → tap for fullscreen audio), copied via copy-paste. Result: viewers saw mute lips moving — a "content to listen to" experience presented as a silent loop. The card widget already documented the rationale ("never autoplay-muted inline") but the detail hero contradicted it.

**Decision:** news detail hero shows the static poster (Bunny thumbnail or `image_url`) with a centred `LhotsePlayButton(size: 64)` overlay when there is a video. Tap opens the fullscreen viewer with audio. No inline playback. The same play-overlay grammar applies to news listings (catalog, related compact, L3 AVANCE compact).

**Rationale:**
- Honours the documented invariant: news = audio-driven content.
- Unified grammar across every news touchpoint (listings, carousels, detail) — a single visual signal "this item is a video, tap to listen".
- Faster first-frame on detail (no background video buffering).
- Avoids the autoplay-with-sound anti-pattern: blocked by iOS/Android without a prior user gesture, and embarrassing in public contexts.

**Consequences:**
- (+) News hero is immediately readable and predictable.
- (+) Bandwidth/battery: video only downloads when explicitly requested.
- (-) Loses the "inline liveness" of the project hero — defensible since news is informational, not aesthetic loop.
- Project hero stays as-is (autoplay muted): asset videos are visual loops where the absence of audio is fine (Zara / Nike-SNKRS pattern). Asymmetry intentional and justified by content type.

## ADR-63: Phone OTP for signup + password recovery — Twilio direct, not OneSignal

**Date:** 2026-05-12
**Status:** Accepted

**Context:** The app needs a password-recovery flow accessible from the login screen. The brief was "enter phone → receive SMS code → set a new password". We considered three SMS routes — Twilio directly via Supabase Auth, Vonage Verify, and routing through OneSignal (which can call Twilio under the hood).

**Decision:**
1. **Email + password is the primary login identity.** Phone is a **mandatory second factor at signup** (E.164), verified by SMS OTP before reaching the app shell.
2. Password recovery is **SMS-only** (no parallel email-reset flow). Phone OTP → verifyOTP creates an ephemeral session → user sets a new password → `signOut` → back to login.
3. SMS provider is **Twilio**, integrated through Supabase Auth's native provider config (Authentication → Providers → Phone). No code path inside the app touches Twilio.
4. `auth.users.phone` is the single source of truth; `user_profiles.phone` is a read-only mirror synced by triggers `handle_new_user` (INSERT) and `handle_user_updated` (UPDATE).

**Implementation correction (2026-05-12):** an earlier draft labelled this as "phone-first signup" and passed both `email` and `phone` to `auth.signUp` in a single call. GoTrue does not support email + phone in the same `signUp` — the call failed silently and accounts could not be created. The correct pattern is **two sequential calls**: `signUp(email, password)` creates the user (session active, requires "Confirm email" OFF in Supabase Dashboard) and `attachPhone(phone)` (wraps `auth.updateUser`) attaches the phone, which makes Supabase send the SMS via Twilio automatically. Signup OTP verification uses `OtpType.phoneChange`; password recovery OTP still uses `OtpType.sms`.

**Resume of unverified accounts (2026-05-12 follow-up):** the original "zombie-account guard" tried to detect `phoneConfirmedAt == null` and force `/otp-verify` from the router redirect. It does not work because the gotrue Dart SDK (^2.19.0) does not expose the `auth.users.phone_change` column — the local `User` class only has `phone` (verified) and `phoneConfirmedAt`, both of which are `null` between `signUp` and `verifyOTP`. The router redirect must also be synchronous, which rules out reading server state.

The premium solution is a `SECURITY DEFINER` RPC `public.get_pending_phone()` (migration `20260512150000_get_pending_phone.sql`) that returns `auth.users.phone_change` for `auth.uid()` when `phone_confirmed_at IS NULL`. `SplashScreen` and `LoginScreen` call this RPC: if there's a pending phone, they navigate to `/otp-verify` with `isResume: true` (the screen skips the resend cooldown because the previous SMS may be stale). This works across devices (in contrast to a SharedPreferences flag, which was rejected for that reason). If session exists with `phoneConfirmedAt == null` AND no `phone_change` pending — the signup never reached `attachPhone` — Splash signs the user out so they can restart, and Login surfaces "Tu cuenta no se completó. Vuelve a registrarte o contacta con soporte." The router redirect now only routes fully-verified sessions; it does not try to interpret intermediate states.

**Rationale:**
- **Native Supabase integration**: Supabase already encapsulates OTP generation, expiry, rate-limiting, and `verifyOTP` session creation. Twilio plugs in via dashboard credentials only.
- **OneSignal rejected for auth OTP**: OneSignal targets marketing/journeys (push + SMS campaigns). Using it as a relay would require generating + verifying OTPs ourselves, plumbing the Supabase "Send SMS Hook", and paying the same Twilio SMS cost plus OneSignal overhead. Zero benefit for this flow. OneSignal remains a candidate for **non-auth transactional/marketing SMS** later.
- **Vonage Verify** is cheaper at mid volume but offers smaller trial credit and identical Supabase integration; portable later by swapping dashboard credentials — zero Flutter changes.
- **Mandatory phone over optional**: an opt-in phone field at signup splits the user base into "can recover" and "can't", forcing a second recovery channel and a "bind your phone" flow for legacy users. Cleaner to gate signup behind phone verification once.
- **SMS-only recovery (no email reset)**: a single canonical recovery path avoids users trying both channels and hitting confusing "which session is active" issues. Email reset can be added later if support volume justifies it.

**Consequences:**
- (+) One auth surface to reason about: every active user can recover via SMS.
- (+) Trial Twilio credit (~$15) covers all of development + QA.
- (+) Migrating to Vonage/Plivo later is a dashboard swap.
- (-) International rollouts pay Twilio's per-SMS price in each country; mid-volume costs are tracked separately.
- (-) Users without a working phone temporarily can't recover access — accepted: this is the same constraint as a bank app.
- (-) Phone capture at signup adds one field of friction — acceptable for a wealth-management product where identity verification (KYC) is expected.

**Implementation pointers:**
- Repository methods: `signUp` (email+password only), `attachPhone`, `verifyPhoneChangeOtp` (signup 2FA), `sendPhoneOtp`, `verifyPhoneOtp` (recovery), `updatePassword`, `resendPhoneOtp` (`lib/features/auth/data/auth_repository.dart`).
- Screens: `signup_screen.dart` (chains signUp + attachPhone), `forgot_password_screen.dart`, `otp_verify_screen.dart` (purpose enum, args nullable for guard redirects), `reset_password_screen.dart`.
- Migration: `docs/sql/migrations/20260512084756_signup_phone_sync.sql` extends `handle_new_user` and adds `handle_user_updated` (no further migration needed for the email-primary fix).
- Router: `redirect` includes a zombie-account guard (`phoneConfirmedAt == null → /otp-verify`) and `refreshListenable` listens to every auth event so `phone_confirmed_at` mutations trigger re-evaluation. `_kTransientAuthRoutes` bypasses the standard auth-route redirect for `/reset-password` (sessions flip mid-flow).

---

## ADR-64: Push permission UX — custom soft-ask with persistent cap, denied banner with cooldown

**Date:** 2026-05-13
**Status:** Accepted

**Context:** The first iteration of push notifications called `OneSignal.Notifications.requestPermission(true)` directly inside `onboarding_done_screen.dart` via a 1.5s timer. Two problems with that approach: (1) the OS dialog appeared without context, increasing the chance of a `Don't Allow` tap that locks the permission as `denied` permanently in iOS; (2) users who reached the app via login (not signup) never saw the request at all, leaving them at `notDetermined` forever and triggering the OneSignal error `"All included players are not subscribed"` for any broadcast targeted at them.

**Decision:**
1. **Custom Flutter bottom sheet** (`PushSoftAskSheet`) — not `UIAlertController` / `CupertinoAlertDialog` / `AlertDialog`. Apple HIG explicitly recommends against alert-style pre-permission UI. The custom container also lets us apply the Campton / ivory / hairline-border design language and the formal "usted" voice from `docs/VOICE.md`.
2. **`OneSignal.Notifications.requestPermission(true)` fires only when the user taps "Activar"** in our custom sheet. If the user taps "Más tarde" the OS dialog never fires, preserving `notDetermined` and the future ability to re-ask via our own UI.
3. **Lifetime cap of 2 soft-ask shows per device**, persisted via `shared_preferences` (`push_soft_ask_count`). After the cap, no more custom prompts; users can still enable from the system Settings or via the passive banner in the notifications feed.
4. **Triggers**: (a) `onboarding_done_screen.dart` — explicit `Continuar` CTA replaces the previous timer-fire fade-out (anti-ambush). (b) `notifications_sheet.dart` — auto-triggers on open when `notDetermined` and cap allows.
5. **`denied` recovery** — discreet dismissable banner in the feed: "Notificaciones en pausa · Active en Ajustes →" → opens iOS/Android settings via `OneSignal.Notifications.requestPermission(true)` (the SDK's `fallbackToSettings=true` path). Dismiss persists a 7-day cooldown timestamp (`push_denied_banner_dismissed_at`).
6. **`pushPermissionProvider`** (StateProvider) synced by `OneSignal.Notifications.addPermissionObserver` — when the user returns from Settings with push enabled, the banner disappears without a manual reload.

**Rationale:**
- **App Store §4.5.4** — "explicit consent via UI language in your app… explain the purpose before requesting permission". The soft-ask IS that language; the system dialog runs only once, at the user's tap.
- **App Store §5.1.1(iv)** — anti dark-pattern. Symmetric CTAs (equal weight, equal hit area), informative non-FOMO copy ("Active las notificaciones." / "Le avisaremos cuando haya nuevas oportunidades, documentos disponibles o cambios relevantes en su cartera."), hard cap of 2, dismissable banner with cooldown — all neutralise the only review-time grey zone (perception of "spam of prompts"). Copy explicitly names "notificaciones" in the title so the user knows immediately what the sheet is asking — addressed during code review when the original "Estaremos en contacto" header was flagged as ambiguous.
- **Material 3 rationale UI** — same doctrine applies for Android 13+ `POST_NOTIFICATIONS`. The same Dart code path is OS-agnostic via `onesignal_flutter` 5.x.
- **Persistent cap rather than session-only** — without it, a user who taps "Más tarde" once would see the soft-ask on every cold launch indefinitely. That would cross the line from "contextual re-ask" to "nag" in a reviewer's eyes.
- **Custom container instead of native dialog** — Stripe, Revolut, Coinbase, Cash App, JPM Mobile, Robinhood, Notion all use custom UI for this. Native dialogs are commodity; an editorial wealth product cannot afford to fall back to them at the most important moment of permission ergonomics.

**Consequences:**
- (+) Users who tap "Más tarde" once still have a path to opt in later (banner) without us burning the OS-level permission slot.
- (+) Users who never went through onboarding (account predates the OneSignal integration) get the soft-ask on their first feed open.
- (+) Review defensibility — every safeguard traces to a written guideline, captured here.
- (-) Adds `shared_preferences` as a dependency (small, official, standard).
- (-) Logic now spans `OneSignalService` + the soft-ask sheet + the feed banner — more surface than a single `requestPermission` call but each piece is local and obvious.

**Implementation pointers:**
- `lib/core/notifications/push_permission_provider.dart` — Riverpod state mirror.
- `lib/core/notifications/onesignal_service.dart` — observer wiring + persistence helpers (`softAskCount`, `incrementSoftAskCount`, `canShowSoftAsk`, `deniedBannerDismissedAt`, `markDeniedBannerDismissed`, `shouldShowDeniedBanner`, `openSystemPushSettings`).
- `lib/features/notifications/presentation/push_soft_ask_sheet.dart` — custom bottom sheet, symmetric CTAs.
- `lib/features/onboarding/presentation/onboarding_done_screen.dart` — `Continuar` CTA gates the soft-ask + navigates to home.
- `lib/features/notifications/presentation/notifications_sheet.dart` — auto-trigger on open + `_PermissionBanner` for the `denied` / `notDetermined` cap-agotado states.

**Follow-up (body field)**: subsequent iteration added an optional `body` (max 300 chars) to broadcasts — surfaces as the second-line of an iOS push (`headings` = title bold, `contents` = body) and as a descriptive second line in the in-app feed. Same `{ en, es }` duplication fallback applies to both `headings` and `contents`. Backwards compatible: notifications without body keep the prior single-line behaviour.

## ADR-65: Brand wordmark — two SVG variants (`logo_asset` centered + `logo_asset_detail` tight) + `BrandWordmark` widget

**Date:** 2026-05-14
**Status:** Accepted

**Context:** Originally each brand had a single `logo_asset` SVG, but the wordmarks were authored with tightly cropped viewBoxes — each marca había nacido con un ratio distinto (Ammaca ~2:1, Andhy ~3:1, Vellte ~10:1). Rendering them at any fixed height in a grid produced visually inconsistent cards: la marca corta se veía pequeña, la larga se desbordaba. To fix the grid we unified the viewBoxes to a common canvas (`128×40`) with internal padding centering each wordmark — this gave the grid a uniform bounding box across brands. But the same centered SVGs are **unusable in the brand detail screen** because the internal padding is baked into the path coordinates: no `Align(centerLeft)`, no Flutter wrapper can pull the trazo to the column's padding-left. The wordmark visually "floats" with phantom margin to its left.

**Decision:**

1. **Two SVG variants per brand** in the `brands` table:
   - `logo_asset` — centered wordmark on a uniform canvas (current `viewBox="0 0 128 40"`, ratio 3.2:1). Used wherever bounding-box uniformity matters: grid de Firmas, filter row, search row.
   - `logo_asset_detail` — tightly cropped wordmark with `viewBox` ajustado al contenido (no padding lateral). Used in la pantalla detalle de marca (header flotante + hero) para anclar el trazo al margen izquierdo. **Nullable**: si la marca aún no tiene la versión tight subida, el widget cae transparentemente al `logo_asset`. El isotipo cuadrado (`icon_asset`) sigue siendo una entidad aparte (queda en `portfolio_entry`, usado solo en Inversiones).

2. **Componente compartido `BrandWordmark`** (`lib/core/widgets/brand_wordmark.dart`) con cuatro size tokens (`xs/sm/md/lg`) y dos modos de sizing:
   - **xs (24) y sm (36)**: ancho intrínseco (`SvgPicture(height: _height, fit: contain)`). El padre (filter row 80×32, card del grid via `Expanded(flex:25)`, search row 56w) ya provee un slot uniforme — el wordmark se ciñe al SVG y BoxFit.contain protege overflow.
   - **md (28) y lg (48)**: contenedor fijo `Size(140,28)` y `Size(240,56)` via `SizedBox.fromSize` + `SvgPicture(fit: contain, alignment:)`. Todas las marcas comparten el mismo bounding box independiente del aspect ratio — la zona del logo es uniforme entre fichas. La prop `alignment` (default center) la usa el caller: `Alignment.centerLeft` en el hero del detalle (anchor a padding-left de la Column), `Alignment.center` en el header flotante (centrado en su Row).

3. **`preferDetail: bool` flag** en el widget: cuando es `true`, intenta `logoAssetDetail` primero y cae a `logoAsset` si null. Default `false` (todos los call-sites del grid/filter/search siguen con la versión centered).

**Rationale:**
- **Por qué dos variantes y no una sola**: el grid y el detalle tienen requirements opuestos — el grid exige bounding box uniforme entre marcas (lo que el SVG centered da gratis); el detalle exige anchor izquierdo del trazo (lo que el SVG tight da gratis). Forzar uno solo significaría sacrificar uno de los dos. Mantener ambos como assets independientes es 1 columna extra en `brands` y 1 SVG extra en Storage por marca — coste mínimo, beneficio editorial significativo.
- **Por qué `nullable` para la variante tight**: permite incorporar marcas nuevas sin requerir que el admin suba ambas variantes el mismo día. El fallback a `logo_asset` es visualmente aceptable (queda centrado en el contenedor del detalle, no anclado, pero legible) hasta que se suba la tight.
- **Por qué contenedor fijo (140×28 / 240×56) en md/lg en vez de altura intrínseca**: con aspects entre 2.0 (Ammaca) y 9.84 (Vellte, Renta Fija), un mismo `height: 48` produce wordmarks de ancho dispar (97pt a 472pt). Visualmente la card de una marca corta dominaría menos que la de una larga — inconsistencia editorial. El contenedor fijo + `BoxFit.contain` con `Alignment.centerLeft` da: (a) bounding box uniforme entre marcas, (b) anchor izquierdo del trazo, (c) la altura del trazo varía proporcionalmente al aspect ratio (wide wordmarks render shorter — comportamiento "correcto" tipográficamente).
- **Por qué no `IntrinsicWidth` o `ConstrainedBox(maxWidth)` solos**: probados en iteraciones #5 y #6. `ConstrainedBox` cap horizontal sigue dejando el bounding box variable per brand (no uniforme). `SvgPicture(height: _height)` solo, en `Column-start`, además **infla** la caja a `parent.maxWidth` (bug en flutter_svg con loose-width parents — ver gotcha global). El contenedor fijo es la única solución que da uniformidad cross-brand + estabilidad de layout.

**Consequences:**
- (+) Cada pantalla recibe la SVG ajustada a su contexto sin compromisos.
- (+) Cinco call-sites del wordmark (grid, filter row, search row, detail header, detail hero) consumen un único componente — sizing decisions viven en un solo archivo.
- (+) El admin (`lhotse_admin`) expone los tres slots — Logo principal, Logo de detalle, Isotipo — con copy explicando la diferencia funcional.
- (-) Subir una marca nueva requiere idealmente dos SVGs (centrado + tight). El admin acepta solo uno; el otro se rellena en una segunda pasada cuando esté listo.
- (-) Un cambio en la dirección editorial del wordmark obliga a actualizar dos archivos por marca, no uno.

**Implementation pointers:**
- `lib/core/widgets/brand_wordmark.dart` — widget compartido con los 4 tokens.
- `lib/core/domain/brand_data.dart` — `logoAsset` y `logoAssetDetail` (mapped from `logo_asset` y `logo_asset_detail`).
- `lib/features/brands/presentation/brand_detail_screen.dart` — `_BrandLogo` (hero, lg + centerLeft) y `_BrandLogoHeader` (md + center default), ambos `preferDetail: true`.
- `lib/features/brands/presentation/brands_screen.dart` — `_BrandCard` con `BrandWordmark.sm`.
- `lib/core/widgets/lhotse_brand_filter_row.dart` — `BrandWordmark.xs` con fallback a inicial.
- `lib/features/search/presentation/search_screen.dart` — `BrandWordmark.xs` con fallback a iniciales.
- `lhotse_admin/components/forms/brand-form.tsx` — tres slots de upload con copy distintivo.
- `lhotse_admin/scripts/upload-logos-detail.ts` — one-shot que pobló las 15 marcas iniciales.
- Migration: `docs/sql/migrations/20260513184807_brand_logo_asset_detail.sql`.

## ADR-66: Self-service account deletion — RPC SECURITY DEFINER + CASCADE/SET NULL split

**Date:** 2026-05-17
**Status:** Accepted

**Context:** Apple App Store y Google Play exigen un mecanismo in-app para eliminar la cuenta. La app tenía botón de logout pero ningún flujo de borrado. Limitación de Supabase: `DELETE FROM auth.users` requiere `service_role` — no es invocable desde una sesión `authenticated` directa.

**Decision:**

1. **RPC `public.delete_my_account()`** en `SECURITY DEFINER` (migración `20260517130000_delete_my_account_rpc.sql`). Sin parámetros; ejecuta `DELETE FROM auth.users WHERE id = auth.uid()` y deja que las FKs aguas abajo hagan el trabajo. `REVOKE` de `anon`/`PUBLIC` + `GRANT EXECUTE TO authenticated` + `SET search_path = public, auth`.

2. **Política de FKs aguas abajo — split CASCADE vs SET NULL:**
   - **CASCADE (personal/PII)**: `user_profiles`, `notifications`, `notification_preferences`, `user_requests`, `user_onboarding`, `documents`, y todas las tablas de `auth.*` (sessions, identities, mfa_factors, etc.).
   - **SET NULL (histórico contractual)**: `purchase_contracts`, `coinvestment_contracts`, `fixed_income_contracts`, `rental_contracts` (configurado en migración `20260429161455_user_delete_set_null_contracts.sql`). El asset histórico se preserva con `user_id = NULL`; el ex-user pierde toda trazabilidad personal.

3. **UI**: `_DeleteAccountButton` en `profile_screen.dart` debajo del logout (color `AppColors.danger`, icon `trash`). Abre `showDeleteAccountSheet` — modal con descripción explícita, checkbox de acknowledgement y botón rojo "ELIMINAR MI CUENTA". `enableDrag: false`/`isDismissible: false` para evitar dismiss accidental sobre acción irreversible.

**Rationale:**
- **Por qué RPC y no Edge Function**: el patrón canónico ya en uso en la app es RPC `SECURITY DEFINER` (ver `get_pending_phone`). Edge Functions sólo se usan para integraciones externas (signed video URLs). Una RPC tiene la ventaja de leer `auth.uid()` directamente del JWT firmado sin pasar headers manualmente.
- **Por qué CASCADE en `documents`**: los documentos del scope `investor` son PII personal (KYC, declaraciones, contratos firmados). Mantenerlos huérfanos tras "derecho al olvido" sería inconsistente con la política de privacidad. Los documentos de scope `project`/`asset` son admin-uploaded (no afectados).
- **Por qué SET NULL en contratos**: la trazabilidad del activo (qué unidad, qué precio, qué fechas) es información contable y legal que la empresa debe conservar incluso si el inversor desaparece. Anonimizar el `user_id` cumple "olvido" sin destruir el histórico contractual.
- **Por qué un único `DELETE FROM auth.users` y no un script con N pasos**: las FKs declarativas son el contrato más robusto. Un script imperativo podría dejar el estado inconsistente si falla a mitad (sin transacción explícita); el cascade es atómico y verificable con `pg_constraint`.

**Security model — only the caller can delete themselves:**
1. Sin parámetros — caller no puede pasar `user_id` ajeno.
2. `WHERE id = auth.uid()` — el body usa la `uid` del JWT del caller; `SECURITY DEFINER` no la sobreescribe.
3. `auth.uid() IS NULL → 42501` — anon bloqueado en duro.
4. `REVOKE anon` + `GRANT authenticated` — sólo sesiones con JWT pueden invocar.
5. JWT firmado por GoTrue's `JWT_SECRET` — impersonación infeasible sin el secret.

**Consequences:**
- (+) Cumple store policy.
- (+) Un solo DELETE atómico — sin script imperativo que pueda dejar estado parcial.
- (+) Histórico contractual preservado anonimizado sin esfuerzo manual.
- (-) Si en el futuro añadimos tablas con FK al user, hay que decidir explícitamente CASCADE vs SET NULL (no hay default automático "correcto").

**Implementation pointers:**
- Migration: `docs/sql/migrations/20260517130000_delete_my_account_rpc.sql`.
- Repository: `lib/features/auth/data/auth_repository.dart` (`deleteMyAccount()`).
- Sheet: `lib/features/profile/presentation/widgets/delete_account_sheet.dart`.
- Button: `lib/features/profile/presentation/profile_screen.dart` (`_DeleteAccountButton`).
- Prior FK migration: `docs/sql/migrations/20260429161455_user_delete_set_null_contracts.sql`.

## ADR-67: Intro video MP4 replaces the CustomPainter splash animation
**Status:** Superseded by ADR-72. Full body in git history of this file.

## ADR-68: Dynamic Type handled via non-linear `LhotseTextScaler` (curve by fontSize), not a flat clamp

**Date:** 2026-05-19
**Status:** Accepted

**Context.** Without any text-scaling protection the editorial composition of the app — and the strategy hero in particular — breaks at iOS Dynamic Type ≥ XL and Android Font Scale ≥ 1.2x. The strategy hero's title ("Mi estrategia patrimonial") collides with the total amount because `_HeroDelegate` reserves space using a hardcoded `titleHeight = 88` calibrated for `textScale = 1.0`, while the rendered `Text(fontSize: 44)` grows unchecked with the system scaler. Filas financieras with `width/height: 56` badges of fixed-income mortality dates also overflow. A flat `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)` would protect body text but still let `editorialHero 48pt` grow to 62pt, breaking the composition. A second `withClampedTextScaling(1.15)` wrapper around each editorial Text restores the composition but is a convention — easy to forget, fragile when new screens land.

**Decision.** A single custom `TextScaler` (`lib/core/theme/lhotse_text_scaler.dart`) applied globally in `MaterialApp.builder`. The scaler emits a non-linear maxScale **as a continuous function of the fontSize being rendered** — not of the system scale.

Curve:

| `fontSize` | Effective `maxScale` |
|------------|----------------------|
| ≤ 14 (body/meta/labels) | 1.30 |
| 18 (figureRow, figureAmount) | ~1.27 |
| 24 (editorialKicker) | ~1.22 |
| 30 (transition) | ~1.18 |
| ≥ 36 (editorialTitle, editorialHero) | 1.15 |

Between 14 and 36 the curve is `lerp(1.30, 1.15, t)` with `t = (fontSize - 14) / (36 - 14)`. C0-continuous → animations like the strategy hero's `amountSize = 28 + 18 * expandRatio` (which crosses 32pt during scroll) have no visible jumps. Lower bound is fixed at 1.0 — iOS "Smaller Text" is not honoured (editorial composition assumes 1.0 as floor).

```dart
class LhotseTextScaler extends TextScaler {
  const LhotseTextScaler.fromSystem(this.systemScale);
  final double systemScale;

  double _maxScaleFor(double fontSize) {
    final t = ((fontSize - 14) / (36 - 14)).clamp(0.0, 1.0);
    return 1.30 + (1.15 - 1.30) * t;
  }

  @override
  double scale(double fontSize) =>
      fontSize * systemScale.clamp(1.0, _maxScaleFor(fontSize));
}
```

Applied in `lib/app/app.dart`:

```dart
builder: (context, child) {
  final media = MediaQuery.of(context);
  final systemScale = media.textScaler.scale(14) / 14;
  return MediaQuery(
    data: media.copyWith(
      textScaler: LhotseTextScaler.fromSystem(systemScale),
    ),
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: child ?? const SizedBox.shrink(),
    ),
  );
},
```

**Layout constants must use the same scaler.** Slivers that derive their `expandedHeight` from typography (`_HeroDelegate`, `_BrandHeroDelegate`) call `MediaQuery.textScalerOf(context).scale(...)` for `titleHeight`, `amountMax`, and `collapsedAmountY` adjustments. Because the `Text` and the layout consult the same `LhotseTextScaler`, **divergence is impossible by construction** — this eliminates the class of bug where text grows but reserved space doesn't.

**Brand assets and chrome do not scale.** `LhotseMark`, `BrandWordmark`, isotypes are brand signatures; bottom-nav icons / bell / back arrow are navigation glyphs. Flutter's `Icon` widget doesn't respond to the text scaler when `size` is set, so chrome stays fixed.

**Rationale.** This is what iOS Dynamic Type does natively: at AX5 body grows ×3.1 but `title1` only ×1.9. The motivation for accessibility scaling is to make small text legible; large editorial text is already legible and growing it breaks composition. JPM Private Bank, Apple Wallet, Robinhood Premium ship the same heuristic.

**Why a fontSize-driven curve instead of a flat clamp + an "editorial" wrapper widget:**
- The wrapper (`LhotseEditorialText`) would be a convention. New screens would forget to use it.
- The scaler is a property of the system; every `Text` and `RichText` in the app — present and future — gets the right behaviour automatically.
- Continuous curve → smooth animations across the 14–36 range (e.g. hero amount sliding from 28 → 46pt during scroll).

**Trade-offs.**
- (+) Cualquier `Text` futuro respeta la curva sin intervención del developer.
- (+) Garantía matemática de que el layout reserva el espacio exacto que el render ocupa (mismo scaler en ambos lados).
- (+) AX5 + clamp aún produce una pantalla coherente — no se rompe la composición.
- (−) AX1–AX5 no escalan el cuerpo más allá de 1.30× ni el editorial más de 1.15×. Decisión consciente: la composición editorial es load-bearing para la identidad de Lhotse; el clamp es el contrato con accesibilidad.
- (−) "Smaller Text" (iOS) se ignora — los heros se verían vacíos a 0.82×.

**Implementation pointers.**
- Scaler: `lib/core/theme/lhotse_text_scaler.dart`.
- Application point: `lib/app/app.dart` (builder de `MaterialApp.router`).
- Strategy heros: `lib/features/investments/presentation/investments_screen.dart` (L1) y `brand_investments_screen.dart` (L2) — derivan `titleHeight`/`amountMax`/`collapsedAmountY` con `MediaQuery.textScalerOf(context).scale(...)`.
- Badge renta fija: `brand_investments_screen.dart` — `ConstrainedBox(minWidth/minHeight: 56) + IntrinsicWidth`.

## ADR-69: Rollback al CustomPainter intro tras evaluación del MP4
**Status:** Superseded by ADR-72. Full body in git history of this file.

## ADR-70: News hero supports multi-image carousel — `hero_media` jsonb shape, `image_url` kept as cover

**Date:** 2026-05-20
**Status:** Accepted (column renamed `gallery_media → hero_media` in 20260520130000 — see ADR-71)

**Context.** Editores piden subir varias imágenes thumbnail por noticia y poder deslizar entre ellas en el hero del detalle. Hoy `news.image_url TEXT` admite una sola URL; 6 consumidores la leen (feed card, archive card, L3 coinversión, home_feed_provider, router, detail). Los heros de `assets` y `projects` ya manejan galerías mixtas vía `gallery_media JSONB[{type,url}]` con `MultiMediaUploadField` del admin.

**Decision.** Añadir columna `news.hero_media JSONB` con shape `{type:'image'|'video', url}` (renombrada desde `gallery_media` en 20260520130000 — ver ADR-71). El form del admin restringe a `type='image'` vía el prop nuevo `acceptedTypes` en `MultiMediaUploadField` (default = ambos, news pasa `['image']`). `news.image_url` se mantiene como portada denormalizada del primer slot imagen — el admin la sobrescribe en cada save desde `hero_media[0].url`, así los 6 list-row consumers siguen leyendo el mismo campo sin tocar nada. El hero del detalle (`lib/core/widgets/media_hero_carousel.dart`, compartido con projects per ADR-71) renderiza `PageView` con dots solo cuando `video_url IS NULL && imageUrls.length > 1`; si hay `video_url` el hero vuelve al single-frame con play overlay (ADR-62 inalterado).

**Trade-offs.**
- (+) Consistencia cross-entidad: news y projects usan el mismo nombre `hero_media` para la galería del hero (alineado en ADR-71). Admin reutiliza `MultiMediaUploadField` + `uploadFormMediaGallery` sin duplicar componentes.
- (+) Backward-compat trivial: `image_url` queda como cover, los 6 consumidores siguen funcionando sin migración paralela del modelo en cliente.
- (+) Hero tag sólo en el slot 0 conserva la transición compartida desde feed/card; los slots 1..n son `LhotseImage` planos.
- (−) Duplicación cover ↔ `hero_media[0]`. Justificada por principio #1b (list display identity): cinco list-row call-sites leen `image_url`; forzar a cada list query a proyectar `hero_media[0]` server-side sería peor.
- (−) `hero_media` admite `type='video'` por shape pero el form lo prohíbe hoy. Decisión consciente: news ya tiene su `video_url` dedicado (ADR-62) y mezclar video como slot del carrusel rompería la regla "video manda en el hero". El schema queda simétrico por si en el futuro el carrusel admite video sin nueva migración.

**Files touched.**
- App: `docs/sql/migrations/20260520120000_news_gallery_media.sql` (nuevo), `docs/sql/migrations/20260520130000_news_rename_gallery_to_hero.sql` (rename), `lib/core/domain/news_item_data.dart`, `lib/core/data/news_provider.dart`, `lib/core/utils/hero_media_parser.dart` (nuevo, compartido con projects), `lib/core/widgets/media_hero_carousel.dart` (nuevo, compartido con projects), `lib/features/home/presentation/news_detail_screen.dart`, `docs/DOMAIN.md`, `docs/DESIGN_SYSTEM.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md` (este archivo).
- Admin: `lib/db/database.types.ts`, `lib/schemas/news.ts`, `app/(admin)/news/actions.ts`, `components/forms/news-form.tsx`, `components/forms/fields/multi-media-upload-field.tsx` (prop `acceptedTypes` añadido).

## ADR-71: Project hero supports multi-image carousel — `hero_media` column, separate from `gallery_media`; cross-entity naming alignment

**Date:** 2026-05-20
**Status:** Accepted

**Context.** El cliente pide para projects el mismo carrusel multi-imagen en el hero que acabamos de añadir en news (ADR-70). En el admin del proyecto la "Imagen principal" hoy es un único `ImageUploadField → projects.image_url`. Reutilizar `gallery_media` no funciona: en `projects` esa columna alimenta la sección **"Proyecto terminado"** del scroll (fotografía post-cierre) — un concepto distinto al carrusel del hero. Necesitamos columna nueva y nombre nuevo.

**Decision.** Añadir `projects.hero_media JSONB` (mismo shape `{type:'image'|'video', url}` que `assets.gallery_media` y la `news.gallery_media` que se ship en ADR-70). El form del admin reemplaza la subsección "Imagen principal" (single image required) por un `MultiMediaUploadField acceptedTypes={["image"]}` ligado a `hero_media`; `min(1)` en zod conserva la invariante "todo proyecto tiene portada". `projects.image_url` queda como portada denormalizada (sigue leída por feed/archive/L1/L2/L3/router y hero shuttle) y el admin la deriva de `hero_media[0]` en cada save. `gallery_media` (post-cierre) y `render_media` (renders pre-obra) **no se tocan**: siguen con sus secciones distintas y su columna distinta.

Para alinear vocabulario cross-entidad **renombramos también** `news.gallery_media → news.hero_media` en este mismo PR (la columna se shipó hace apenas un ciclo, sin datos productivos relevantes). Coste de migración bajo, beneficio alto: news y projects comparten ahora el mismo nombre para el mismo rol, sin asimetría histórica.

El widget `NewsHeroCarousel` se extrae a `lib/core/widgets/media_hero_carousel.dart` con params explícitos (`heroTag`, `imageUrls`, `videoUrl`, `coverImageUrl`, `useLightOverlay`, `signedVideoUrl`, `onOpenVideo`, `heroGone`, `videoChild?`) — sin acoplarse a ningún modelo. El nuevo prop opcional `videoChild` permite que projects inyecte `LhotseVideoPlayer` (autoplay muteado per DESIGN_SYSTEM § Video System); news lo deja `null` y cae al poster + play overlay (ADR-62).

**Trade-offs.**
- (+) Cross-entity consistency: news y projects usan `hero_media` para el carrusel del hero, `image_url` como cover denormalizada. Un solo helper `parseHeroMediaImageUrls`, un solo widget `MediaHeroCarousel`, una sola convención.
- (+) Separación clara de roles en projects: `hero_media` (carrusel del hero), `gallery_media` (post-cierre), `render_media` (renders pre-obra). Cuatro fuentes de imagen del proyecto, cuatro propósitos, cero solapamiento.
- (+) `videoChild` opcional preserva la asimetría inline-autoplay (projects) vs poster-only (news, ADR-62) sin que el widget compartido se entere del modelo.
- (−) Cuatro columnas relacionadas con imagen en `projects` (`image_url`, `hero_media`, `gallery_media`, `render_media`). Riesgo de confusión para futuros editores. Mitigado en docs (DOMAIN § Projects media model) + helper text del admin en cada sección.
- (−) El rename de news.gallery_media descarta un ciclo de trabajo de hace una hora. Justificado por el coste neto positivo: si dejamos la asimetría, todo desarrollador futuro tropieza con "por qué dos columnas con mismo rol tienen nombres distintos".

**Files touched.**
- App: `docs/sql/migrations/20260520130000_news_rename_gallery_to_hero.sql` (rename), `docs/sql/migrations/20260520140000_projects_hero_media.sql` (nuevo + recrea `projects_with_metrics`), `lib/core/domain/news_item_data.dart` (helper reuse), `lib/core/domain/project_data.dart` (nuevo campo `imageUrls`), `lib/core/utils/hero_media_parser.dart` (nuevo), `lib/core/widgets/media_hero_carousel.dart` (extraído de `NewsHeroCarousel`), `lib/features/home/presentation/widgets/news_hero_carousel.dart` (eliminado), `lib/features/home/presentation/news_detail_screen.dart`, `lib/features/home/presentation/project_detail_screen.dart`, `docs/DOMAIN.md`, `docs/DESIGN_SYSTEM.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md` (este archivo).
- Admin: `lib/db/database.types.ts`, `lib/schemas/news.ts`, `lib/schemas/project.ts`, `app/(admin)/news/actions.ts`, `app/(admin)/projects/actions.ts`, `components/forms/news-form.tsx`, `components/forms/project-form.tsx`.

## ADR-72: Splash final — MP4 muteado (`introLhotse.mp4`)

**Date:** 2026-05-20
**Status:** Accepted (supersedes ADR-57, ADR-67, ADR-69)

**Context.** El splash ha vivido cuatro iteraciones: SVG + pulse → CustomPainter v6.5 (ADR-57) → MP4 v1 entregado por el cliente (ADR-67) → rollback al CustomPainter (ADR-69) → MP4 v2 actual. Cada vuelta ha sido un trade-off entre "control fino en Dart con haptic sincronizado al wordmark-settle" y "motion design cinemático fuera del alcance de un `CustomPainter`". El cliente entrega una nueva versión del MP4 (`introLhotse.mp4`, ~1.5 MB) que considera definitiva.

**Decision.** El splash reproduce `assets/videos/intro_lhotse.mp4` full-bleed y **muteado** (`setVolume(0)`, mismo patrón que `lhotse_welcome.mp4`). `flutter_native_splash` (PNG negro `lhotse_splash.png`) cubre el arranque nativo hasta que el `VideoPlayerController` está inicializado; el frame 0 negro del MP4 y el Scaffold negro hacen la transición invisible. Listener sobre el controller detecta `position >= duration` y dispara un fade-out de 500 ms antes de `context.go(...)`. Si `initialize()` lanza (asset corrupto, codec no soportado), navegamos directo sin fade — un splash roto no bloquea boot. Routing (welcome / home / OTP resume / complete-phone, ADR-63) y warm-up de providers en paralelo durante el video se conservan.

**Trade-offs.**
- (+) Fidelidad de motion design del MP4 (typography work, atmósfera) supera lo factible en `CustomPainter`.
- (+) Vídeo muteado: cero fricción auditiva, alineado con el otro vídeo embebido (`lhotse_welcome.mp4`).
- (+) Una sola fuente decisional viva sobre splash (este ADR). ADR-57/67/69 quedan reducidos a tombstones (ver `git log -p docs/DECISIONS.md` para sus cuerpos originales).
- (−) Cambios visuales requieren re-render del MP4 (no Dart). Aceptado: el cliente posee el motion end-to-end.
- (−) Bundle pesa ~1.5 MB más.
- (−) El haptic sincronizado con wordmark-settle de la era CustomPainter ya no existe — no hay frame narrativamente anclado donde dispararlo.

**Implementation.**
- Asset: `assets/videos/intro_lhotse.mp4` (1.5 MB).
- File: `lib/features/auth/presentation/splash_screen.dart` (`VideoPlayerController.asset(_introAsset)` + `setVolume(0)` + `setLooping(false)` + listener fin-de-vídeo + fade-out 500 ms + fallback).
- Pubspec: sin cambios (`- assets/videos/` ya declarado por `lhotse_welcome.mp4`).
- Native splash (PNG negro): sin cambios.
- Routing y warm-up de providers: intactos respecto a ADR-63.

**Iteration history.** Cuerpos completos de ADR-57 (CustomPainter v6.5 — dual stroke trace + fill wipe + wordmark settle + haptic), ADR-67 (MP4 v1) y ADR-69 (rollback al CustomPainter) viven en `git log -p docs/DECISIONS.md`. Los IDs se mantienen como tombstones de una línea para no romper la numeración secuencial y conservar la trazabilidad.

## ADR-73: RGPD-grade consent capture — `consent_log` append-only + `/accept-consent` gate + signup checkbox

**Date:** 2026-05-20
**Status:** Accepted

**Context.** El signup público hacía aceptación implícita ("al crear cuenta aceptas…") y el admin no cubría marketing en absoluto. RGPD Art. 7.1 (consent demostrable) + Art. 5.2 (accountability) + Considerando 32 (marketing como opt-in separable) exigen:
1. Aceptación explícita y separable de T&C/Privacy vs marketing.
2. Demostrable: cada decisión registrada con fecha + dispositivo.
3. Revocable: retirar tan fácil como dar.

Además, los usuarios creados desde el admin no tienen forma de "haber tildado" nada — necesitan un gate en su primer login.

**Decision.** Sistema de tres piezas:

1. **Tabla append-only `consent_log`** (migración 20260520180000) con `consent_type` ∈ {`terms_and_conditions`, `privacy_policy`, `marketing`}, `granted BOOLEAN`, `document_version`, `platform`, `os_version`, `app_version`, `user_agent`, `ip_address INET`, `created_at`. RLS: el user lee sus propias filas, admin lee todas, INSERTs solo vía RPC `record_consent` (SECURITY DEFINER que rellena IP + user-agent desde `request.headers` de PostgREST) o vía trigger `handle_new_user`. **Las filas nunca se borran** — revocar es insertar `granted=false`, no DELETE.

2. **Vista `latest_user_consents`** pivota el log al estado actual (una fila por user con `terms_accepted/at`, `privacy_accepted/at`, `marketing_accepted/at`). Tras un bug de permisos (20260520200000), la view se reescribió para **no depender de `auth.users`**: usa `auth.uid()` + subqueries a `consent_log` directamente — el rol `authenticated` no tiene grant SELECT sobre `auth.users`, así que el FROM original devolvía 0 filas y causaba un loop en el gate.

3. **Captura en 3 puntos del flow**:
   - **Signup público**: dos checkboxes editorial (`LegalConsentCheckbox` required gating el submit + `MarketingConsentCheckbox` opcional). Metadata se manda en `auth.signUp(data: {document_version_terms, document_version_privacy, platform, os_version, app_version, marketing_consent})`. El trigger `handle_new_user` lee el meta y, **sólo si `document_version_terms IS NOT NULL`** (señal de signup público con consents reales), inserta las 3 filas iniciales en `consent_log`. Sin este signal (admin-created), no inserta nada — el user acepta más tarde en el gate.
   - **`/accept-consent`** (route transient): pantalla con los mismos dos checkboxes que ejecuta los 3 `record_consent` al pulsar CONTINUAR. El helper `routeAfterAuth` (en splash, login, otp-verify) detecta consents missing y redirige aquí ANTES de `/home` o `/onboarding`. `PopScope(canPop:false)` bloquea back gesture.
   - **Notificaciones screen → COMUNICACIONES**: toggle bidireccional para grant/revoke marketing. Cada tap escribe un evento en `consent_log` (el grant original no se borra; el último evento por tipo es el estado vigente).

**Trade-offs.**
- (+) Audit-grade demostrable: cada acto humano queda con timestamp + IP + dispositivo. Un auditor pide y se le muestra el histórico completo.
- (+) Reversible sin perder historial: la columna del estado actual la calcula la view, no se duplica en `user_profiles`. No hay drift posible.
- (+) Cero fabrication para admin-created users: la condición `meta_doc_tc IS NOT NULL` en el trigger es la frontera entre "se aceptó explícitamente" y "lo creó un tercero".
- (+) Gate UNA vez: usuarios pre-existentes al consent_log ven `/accept-consent` en su primer login post-deploy; los demás flujos no lo ven.
- (−) Tres puntos donde se escribe `consent_log` (trigger, RPC en accept-consent, RPC en notificaciones) — la lógica de "qué meterse" vive en tres sitios. Acoplado pero atomizado por `consent_type`.
- (−) `audience-picker` del admin NO filtra por `marketing_accepted` aún. Operacionalmente un broadcast promocional hoy llegaría a usuarios que han revocado. Follow-up apuntado: filtrar `WHERE marketing_accepted=true` desde la view en la query del audience picker.

**Files touched (cronología).**
- `docs/sql/migrations/20260520180000_consent_log.sql` (tabla + RLS + view + RPC + trigger).
- `docs/sql/migrations/20260520190000_handle_new_user_skip_admin_consent.sql` (trigger condicional).
- `docs/sql/migrations/20260520200000_latest_user_consents_self_only.sql` (bug-fix view, drop `FROM auth.users`).
- App: `lib/core/utils/consent_metadata.dart`, `lib/features/auth/data/auth_repository.dart` (`signUp` + `recordConsent`), `lib/features/auth/data/consent_provider.dart`, `lib/features/auth/data/route_after_auth.dart`, `lib/features/auth/presentation/widgets/consent_checkboxes.dart`, `lib/features/auth/presentation/signup_screen.dart`, `lib/features/auth/presentation/accept_consent_screen.dart`, `lib/features/profile/presentation/notifications_screen.dart` (sección COMUNICACIONES), splash/login/otp-verify (call sites de `routeAfterAuth`).

---

## ADR-74: Buscador como herramienta — densidad uniforme idle/active, sin Tendencias

**Date:** 2026-05-21
**Status:** Accepted

**Context:** El idle de `SearchScreen` arrastraba tres patrones que se peleaban entre sí: (1) chips de TENDENCIAS hardcoded (`Madrid Centro`, `Dubai`, `Vellte`…) sin tracking ni analítica, ruido sin signal; (2) sección DESTACADOS con `ProjectShowcaseCard` 3:2 + 36pt + Hero flight — densidad de catálogo curado (Firmas, archives) plantada en una pantalla cuyo propósito es ser herramienta navegable; (3) filas de resultados activos con título `bodyReading` 14pt, fijas a thumb 64×64 sin escalar con Dynamic Type — el design system declara explícitamente `bodyRow` 16pt para "search result rows" (`app_typography.dart`), así que el código violaba su propia intención.

**Decision:** Tres movimientos coordinados que tratan el buscador como **herramienta** (no catálogo):
1. **Eliminar TENDENCIAS** por completo. Sin pretender resucitarla como analytics-driven hasta que haya señal real.
2. **DESTACADOS pasa a la misma densidad** que un search-result — reusa `_ProjectResultItem` en lugar de `ProjectShowcaseCard`. Contenido: tres proyectos `isFundraisingOpen == true && !isProjectLocked(ref, p)` (accesibles al rol del user — no destacar VIP-only a un viewer); fallback a los primeros tres del list si el filtro deja vacío (la sección nunca queda vacía). Etiqueta sigue siendo `DESTACADOS`, coherente con `RECIENTES`.
3. **Sizing de las tres rows de resultado (`_ProjectResultItem`, `_AssetResultItem`, `_BrandResultItem`)**: título `bodyReading` 14pt → `bodyRow` 16pt (lo que la theme ya prescribía). Thumbnail `64` fijo → `MediaQuery.textScalerOf(context).scale(16) / 16 * 64` — escala proporcional al título, igual que se hace en slivers (ADR-68 LhotseTextScaler). `maxLines: 1` → `maxLines: 2` para absorber wrap a Dynamic Type alto.

**Consequences:**
- (+) **Pantalla coherente**: idle y active comparten la misma rejilla tipográfica/dimensional. La disonancia "showcase enorme vs filas compactas" desaparece. El header DESTACADOS sigue cumpliendo función (categorización), pero no impone un lenguaje editorial sobre una pantalla funcional.
- (+) **Dynamic Type robusto**: con scale 1.3x el título crece a ≈20.6pt y el thumb a ≈82pt — proporción preservada. Antes el texto crecía y el thumb se quedaba pequeño.
- (+) **Cero invención**: usa tokens existentes (`bodyRow`), reusa widgets existentes (`_ProjectResultItem`), reutiliza `isProjectLocked` para el gating de DESTACADOS. El cambio es de **alineación**, no de incorporar nuevos componentes.
- (+) **Catálogo curado intacto**: `ProjectShowcaseCard` sigue siendo el lenguaje de Firmas y archives. El buscador no es catálogo — distinción semántica clara entre contextos.
- (−) Para usuarios sin recientes y con muy pocos proyectos abiertos, la sección DESTACADOS muestra siempre lo mismo (fallback a primeros tres). Es aceptable: el dataset Lhotse es pequeño y los proyectos rotan con baja frecuencia.

**Files touched:**
- `lib/features/search/presentation/search_screen.dart` (eliminación de trending + refactor de `_FeaturedSection` + sizing en las tres `_*ResultItem` + helper `_selectFeatured`).
- `docs/DOMAIN.md`, `docs/DESIGN_SYSTEM.md`, `docs/ROADMAP.md` (afirmaciones falseadas por el cambio).

---

## ADR-75: Eliminar feature "folleto" — DROP completo (app + admin + DB)

**Date:** 2026-05-21
**Status:** Accepted

**Context:** El project detail screen cerraba con un CTA full-width "DESCARGAR FOLLETO" que abría un PDF en navegador externo (`url_launcher`). La infraestructura abarcaba tres capas: la columna `projects.brochure_url` en DB, el campo `PdfUploadField` en el form del admin (subida al bucket `public-media/projects/brochures/`), y el lectura/render en la app Flutter (`ProjectData.brochureUrl` + CTA en `project_detail_screen.dart`). Decisión de producto: el folleto deja de formar parte del proyecto comercial — la historia se cuenta en la app misma (tagline + description + galerías + tour virtual + noticias relevantes). El PDF era ruido editorial duplicado.

**Decision:** DROP completo en las tres capas — no se conserva la columna en DB, ni el campo en el admin, ni la lectura en la app. Una historia menos que mantener:

1. **App** (`project_detail_screen.dart`): el bloque condicional `if (project.brochureUrl != null)` queda reemplazado por un `SliverToBoxAdapter` con `SizedBox(height: bottomPadding + AppSpacing.xl)` que preserva el remate inferior (el CTA era el único sliver que aplicaba el bottom safe area). Import `url_launcher` se elimina — quedaba huérfano.
2. **Model** (`ProjectData`): `brochureUrl` field + constructor param + lectura en `fromSupabaseRow` se eliminan.
3. **Admin** (`project-form.tsx` + `project.ts` Zod + `actions.ts` + `database.types.ts`): el `FieldGroup`, la validación, el `uploadFormImage` y el tipo TypeScript se eliminan.
4. **DB** (migración `20260521160000_drop_projects_brochure_url`): `DROP VIEW projects_with_metrics; ALTER TABLE projects DROP COLUMN brochure_url; CREATE VIEW projects_with_metrics AS … (idéntica menos esa columna); ALTER VIEW SET (security_invoker = true); NOTIFY pgrst, 'reload schema'`. La view no se puede mantener cuando se dropea una columna referenciada — recreación es la vía limpia, no `CASCADE`.

**Consequences:**
- (+) **Cero columna huérfana**: aplica `feedback_no_unrequested_ops` desde la otra dirección — el user pidió eliminar del admin, lo que implica que no se persistiría más → conservar la columna sería deuda muerta. Drop alineado con `ARCHITECTURE.md` principio #4 ("no speculative fields").
- (+) **El CTA al final ya no era el cierre editorial natural**. La pantalla cierra ahora con NOTICIAS RELEVANTES (cuando hay) o GALERÍA (cuando hay) o description (mínimo). Estructura más respirada.
- (+) **Una dependencia npm/pub menos en uso**: `url_launcher` queda solo activo en otras pantallas (no se desinstala — sigue lazy-disponible si se necesita en el futuro).
- (−) **Storage cleanup pendiente**: los PDFs ya subidos a `public-media/projects/brochures/` quedan como blobs huérfanos. Sus URLs públicas no están enlazadas desde ningún lado, pero el bucket es público y un agente con la URL exacta puede descargarlas. La limpieza es una operación manual de Storage (fuera de scope de migración DDL).
- (−) **Rollback no trivial**: si en el futuro se decide restaurar el folleto, hay que reinstaurar columna + view + Zod + form + action + model + CTA. La migración deja el SQL rollback documentado en el header.

**Files touched:**
- `lib/features/home/presentation/project_detail_screen.dart`, `lib/core/domain/project_data.dart`, `docs/sql/migrations/20260521160000_drop_projects_brochure_url.sql`, `docs/DESIGN_SYSTEM.md`.
- (Admin repo) `components/forms/project-form.tsx`, `lib/schemas/project.ts`, `app/(admin)/projects/actions.ts`, `lib/db/database.types.ts`.

---

## ADR-76: Boot state machine owns post-auth routing

**Date:** 2026-05-23
**Status:** Accepted

**Context:** Antes de este ADR, el routing post-auth se calculaba en TRES sitios distintos con timings distintos:
1. **Router redirect (sync)**: enforced `isLoggedIn` y `phoneConfirmedAt`.
2. **`routeAfterAuth` (async)**: query DB para consent + onboarding; lo invocaban screens (LoginScreen, OtpVerifyScreen, AcceptConsentScreen, SplashScreen) tras su acción.
3. **`currentUserConsentsProvider`** (FutureProvider.autoDispose): cacheaba el resultado del consent fetch.

La interacción de los tres produjo cuatro bugs distintos en sucesión (todos commits previos a `2e9cc69`):

1. **Cold-start gate false positive** — `currentUserIdProvider` (StreamProvider) no emitía hasta ~1 microtask post-subscripción. `routeAfterAuth` leía `valueOrNull = null` → falso negativo → gate fire.
2. **autoDispose mid-await disposal** — `ref.read(currentUserConsentsProvider.future)` sin listener vivo. El provider quedaba disposable mid-await; cuando la query completaba, lanzaba `Bad state: provider was disposed during loading state`. El catch en `routeAfterAuth` interpretaba el error como "consent missing" → gate fire indebido.
3. **Router race vs routeAfterAuth** — `authNotifier.value++` post-signIn disparaba el redirect callback sincrónicamente. Antes de que `await routeAfterAuth` completara la query async, el router veía `fullyVerified && isAuthRoute` y rebotaba `/login → /home`, bypaseando el consent gate (RGPD violation latente).
4. **Stale-build invalidation** — `ref.watch(currentUserIdProvider)` dentro del cuerpo del FutureProvider. Cuando el StreamProvider emitía su initial event mid-build, Riverpod marcaba el build como stale y descartaba el resultado. `ref.read(.future)` quedaba awaiteando un future huérfano → spinner colgado infinito en LoginScreen.

Cada parche introdujo el siguiente bug. La causa raíz era estructural: **la decisión de destino post-auth se distribuía en piezas que competían**.

**Decision:** Single boot state machine. Una sola fuente de verdad — `BootStateNotifier` (Riverpod Notifier) en `lib/core/boot/boot_state.dart`. Sealed `BootState` con 6 estados: `Loading`, `SignedOut`, `PendingPhone`, `PendingConsent`, `PendingOnboarding`, `Ready`. Escucha `onAuthStateChange`, recomputa via `refresh()` que evalúa session → phone → consent → onboarding en orden. El router redirect es 100% declarativo: un `switch` sobre el state que mapea a la ruta canónica. Screens post-auth (login, OTP verify, accept-consent submit, onboarding done) sólo llaman `bootStateProvider.notifier.refresh()`; el router redirige solo via `refreshListenable` bridge.

**Reglas load-bearing del diseño:**
- **Fail-closed en error/timeout**: cualquier TimeoutException o error de query → `BootPendingConsent`. Re-pedir consent es molesto; bypaseo de RGPD por flakiness es inaceptable.
- **`BootLoading` exclusivamente al cold-start**: `refresh()` NO transita por Loading mid-flight — el estado anterior se mantiene hasta el commit final. Si lo hiciera, el router bombearía al usuario a `/splash` entre transiciones (post-consent → onboarding, post-onboarding → home), re-reproduciendo el video del splash.
- **`/splash` self-governs**: early-return en el redirect para `/splash`. El splash widget reproduce video + fade en su totalidad y luego hace `context.go('/')`. El router nunca lo preempta.
- **`_refreshSeq` guard**: refresh() concurrentes (múltiples `onAuthStateChange` events seguidos) sólo commitean el último.

**Consequences:**
- (+) **Cero races sync/async**: el redirect es síncrono y declarativo; el state machine pre-computa.
- (+) **Single source of truth**: cualquier consumer (router, screen, debug overlay) lee `bootStateProvider`.
- (+) **Extensible**: añadir un check nuevo (KYC, suspensión, etc.) = añadir un state al sealed class + un check en `refresh()` + un mapping en el switch del redirect. Sin tocar screens.
- (+) **Auditable**: toda la lógica de gating vive en una sola función (`refresh`). Tests unitarios triviales con mock client.
- (+) **`routeAfterAuth` deleted**: 72 líneas borradas. Screens son tontas tras su acción (sólo llaman `refresh()`).
- (−) **`currentUserConsentsProvider` se conserva slim** para el marketing toggle de `notifications_screen` (rendering, no routing). Es separación de concerns aceptada: la view se queryea dos veces (una para gating, otra para UI) — costo trivial.
- (−) **Riverpod foot-guns documentados inline** en `boot_state.dart` y `consent_provider.dart`: sin esos comentarios un dev futuro reintroduce los bugs. Tradeoff: comentarios largos pero load-bearing.

**Files touched (commit `2e9cc69`):**
- Nuevo: `lib/core/boot/boot_state.dart`.
- Modificados: `lib/app/router.dart` (redirect declarativo + bridge), `lib/features/auth/presentation/splash_screen.dart` (espera bootState != Loading post-video), `login_screen.dart`, `otp_verify_screen.dart`, `accept_consent_screen.dart` (todos llaman `refresh()`), `lib/features/onboarding/data/onboarding_controller.dart` (refresh tras markCompleted), `lib/features/auth/data/consent_provider.dart` (slim, sólo marketing).
- Eliminado: `lib/features/auth/data/route_after_auth.dart`.

**Reglas para futuros proyectos con este stack (Flutter + Riverpod + Supabase + GoRouter):**
1. Si una decisión de routing depende de **al menos una fuente async** (DB query, RPC, etc.), centraliza en un Notifier state machine. NO repartas entre router redirect + screen callbacks.
2. Routes que tengan vida propia (splash, OTP, transient) → early-return en el redirect. No metas su lógica en el switch del state.
3. `FutureProvider.autoDispose` + `ref.read(provider.future)` sin listener vivo = bomba de relojería. Usa Notifier non-autoDispose o mantén `ref.listenManual` durante el read.
4. `ref.watch(StreamProvider)` dentro del cuerpo de un `FutureProvider` que necesita completar = race. Usa `ref.read(sdkSource).currentSession` síncronamente; reactividad post-build via `ref.listen` o explicit `refresh()`.


## ADR-77: Biometric gate vía BootStateNotifier + soft-ask post-login

**Date:** 2026-05-23
**Status:** Accepted

**Context:** El Home y el tab Estrategia exponen capital invertido, IRR, próximos pagos y feed editorial privado en cuanto el usuario pasa el `BootReady`. Si el móvil cambia de manos desbloqueado, cualquiera ve la cartera. El estándar premium en banca privada (JPM Private Bank, Sotheby's, Revolut) es exigir biometría tras el unlock del SO. La app no almacena ningún dato biométrico — `local_auth` delega 100% al Secure Enclave / TEE.

**Decision:** Añadir un sexto estado al sealed `BootState`: `BootPendingBiometric`, integrado en el state machine de ADR-76. La activación se ofrece vía un **soft-ask branded** post-login: bottom sheet con CTA único "Activar" + dismiss por swipe abajo (patrón canónico de `request_info_sheet.dart` / `vip_lock_sheet.dart` para opt-ins de baja fricción), hard cap 2 lifetime, sin penalizar reintentos. Apple HIG lo acepta — Face ID a nivel de app no es system permission sino feature toggle interno reversible desde Perfil > Seguridad. Cero pantalla nueva en el cold-start gate flow para usuarios que no opten-in. Body del sheet centrado en el "por qué" (qué protege en términos del usuario, no propiedades técnicas de la biometría): *"Le pediremos Face ID al abrir Lhotse y tras unos minutos sin actividad, para que su cartera mantenga su privacidad."*

**Modelo único `enabled` (tri-state, per-user en SharedPreferences):**
- `null` → nunca decidido. El soft-ask aparece en Home (hasta cap 2).
- `true` → opt-in activo. Hard gate al cold start y tras 5 min en background.
- `false` → explícitamente off. Cero gates. El usuario lo reactiva desde Perfil > Seguridad.

**Vías a `enabled = true`:**
1. Tap "Activar" en el soft-ask + Face ID OK.
2. Toggle on en Perfil > Seguridad + Face ID OK.

**Vías a `enabled = false`:**
1. Toggle off en Settings.
2. Gate detecta `notAvailable` (usuario quitó biometría del SO entre sesiones) → fail-open: persiste `false` + entra. El usuario puede re-activar cuando reconfigure el SO.

**Reglas load-bearing:**
- **Per-user namespacing en prefs**: `biometric.enabled.{userId}` y `biometric.softAskCount.{userId}` — si un User A enabled=true se almacena globalmente, User B en el mismo dispositivo hereda la pref. Cuelga sus preferencias del session userId leído sincrónicamente vía `client.auth.currentSession?.user.id` (regla [[currentUserIdProvider]] — sin `ref.watch` en stream que pueda emitir mid-build).
- **`lastUnlockAt` en memoria, NO persistido**: cold start fuerza re-auth. Persistir un timestamp sería un agujero (sobrevive a force-quit).
- **`_lastUnlockAt = null` en `onAuthStateChange`**: cuando un usuario distinto inicia sesión en el mismo proceso, debe limpiarse el unlock heredado. Hecho dentro del listener en `BiometricLockController.build()`.
- **Catch localizado en `BootStateNotifier.refresh()`**: un fallo cargando `SharedPreferences` NO debe bouncear al usuario a `BootPendingConsent` (el fail-mode genérico de ADR-76). La biometría es key-value, no compliance; si falla, fail-open a `BootReady`. Catch envuelve solo el await del controller.
- **Captura del destino antes del gate**: el redirect del router llama `capturePendingDestination(loc)` al desviar a `/biometric-gate`. El case `BootReady` restaura ese destino al consumir el pending — si el gate apareció mid-sesión en `/investments`, post-unlock vuelve a `/investments` (no a `/home`).
- **No commitear `BootLoading` mid-refresh**: misma regla que ADR-76. El estado anterior se mantiene hasta el commit final del biometric check.
- **Lifecycle observer ignora `resumed` sin `paused` previo**: iOS NO emite `paused` cuando muestra el system prompt de Face ID (es un overlay, no backgrounding). Solo emite `inactive` → `resumed`. Cualquier fallback tipo "si no hay timestamp previo, asume 24h" invalida el `_lastUnlockAt` que el gate acaba de setear y bucle infinito de gate. Patrón canónico (Apple Wallet, 1Password, BBVA): trackear `paused` para set `_backgroundedAt`, ignorar `inactive`, hacer `bg == null → return` en `resumed`. Cold start NO invoca el callback en iOS (inicialización va en `initState`/`build`, NO en el observer). Aplica a cualquier futuro gate que dependa de lifecycle (KYC, subscription, etc.).

**Consequences:**
- (+) **Coherente con push**: misma UX, mismo cap, mismo bottom sheet — el usuario aprende el patrón una vez.
- (+) **Zero-friction quando el usuario dice no**: cancelar el soft-ask la primera vez NO bloquea ni re-pregunta agresivamente (hasta cap 2). Respeta agencia.
- (+) **Bank-grade cuando dice sí**: hard gate post-activación sin escape valve más allá de "cerrar sesión". Es lo que Apple Wallet y Revolut hacen.
- (+) **Extensible al patrón ADR-76**: añadir biometric fue 1 estado nuevo + 1 case en el switch + 1 check en `refresh()`. Cero screens tocados (excepto los que ya conocían el ciclo).
- (+) **Cero almacenamiento biométrico**: no impacta App Privacy nutrition label. iOS / Android delegate IS the security boundary.
- (−) **`AuthRepository` ahora toma `Ref`**: necesario para invalidar el unlock en `signOut()` y `deleteMyAccount()` sin tocar 10 call sites. Refactor mínimo, contrato del provider intacto.
- (−) **`local_auth` requiere `FlutterFragmentActivity` en Android**: cambio en MainActivity.kt obligatorio. Sin esto, BiometricPrompt crashea al primer uso.

**Files touched:**
- Nuevo: `lib/core/auth/biometric_service.dart`, `lib/core/auth/biometric_lock_controller.dart`, `lib/core/data/preferences_provider.dart`, `lib/features/auth/presentation/biometric_gate_screen.dart`, `lib/features/auth/presentation/biometric_soft_ask_sheet.dart`, `lib/features/profile/presentation/security_settings_screen.dart`.
- Modificados: `lib/core/boot/boot_state.dart` (+ estado + check en refresh), `lib/app/router.dart` (+ ruta + redirect case + restore-destination), `lib/app/app.dart` (invalidate unlock + refresh tras 5min background), `lib/features/home/presentation/home_screen.dart` (trigger soft-ask), `lib/features/profile/presentation/profile_screen.dart` (fila Seguridad), `lib/features/auth/data/auth_repository.dart` (invalidate en signOut + deleteMyAccount).
- Plataforma: `pubspec.yaml` (+ `local_auth: ^2.3.0`), `ios/Runner/Info.plist` (+ `NSFaceIDUsageDescription`), `android/app/src/main/AndroidManifest.xml` (+ `USE_BIOMETRIC`), `android/.../MainActivity.kt` (FlutterActivity → FlutterFragmentActivity).

**Para futuros gates (KYC, suspensión, subscription, etc.):**
Sigue el mismo patrón. 4 pasos:
1. Añadir estado al sealed `BootState` (e.g. `BootPendingKyc`).
2. Añadir check en `BootStateNotifier.refresh()` en el orden correcto.
3. Añadir case en el switch del redirect (con captura de destino si se quiere restore).
4. Crear screen de gate que llama `bootStateProvider.notifier.refresh()` tras resolver. Cero `context.go()` para routing — el router transita solo.


