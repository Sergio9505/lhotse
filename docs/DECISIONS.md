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
