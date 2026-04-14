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
**Status:** Accepted

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
**Status:** Accepted

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
**Status:** Accepted

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

## ADR-25: Supabase Schema — Single Table Inheritance for Investments

**Date:** 2026-04-14
**Status:** Accepted

**Context:** `InvestmentData` has ~45 fields spanning 3 business models (compra directa, coinversión, renta fija) plus completion fields. Options: (A) single wide table with nullable columns (STI), (B) base table + 3 model-specific join tables, (C) JSONB for model-specific fields.

**Decision:** Single wide table (STI). JSONB for display-only embedded data (gallery arrays, asset_info key-value pairs). Separate tables for queryable structured data (profit_scenarios, investment_phases, documents).

**Rationale:**
- Flutter uses a single `InvestmentData` class — 1:1 mapping means simpler serialization
- <5000 rows expected — nullable column overhead is negligible
- Every query needs base fields (amount, return_rate) — split tables would always JOIN
- ~15 NULL columns per row is harmless on PostgreSQL at this scale
- JSONB for display data avoids unnecessary tables; separate tables for queryable data preserve type safety

Full schema in `.claude/plans/soft-noodling-origami.md`: 11 tables, 8 enums, 4 views, 5 RPC functions, 6 storage buckets.

**Consequences:**
- (+) One Supabase query per investment detail — no joins needed
- (+) Aggregation queries (brand summaries, portfolio total) are simple GROUP BYs
- (+) Flutter `fromJson` maps directly to table columns
- (+) View `v_investment_with_brand` provides denormalized brand_name for compatibility
- (-) ~15 NULL columns per row — acceptable at current scale
- (-) If business models diverge significantly in the future, may need to revisit
