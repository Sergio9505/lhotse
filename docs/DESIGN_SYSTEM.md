# Design System

> Source of truth: [Figma](https://www.figma.com/design/tObKXuw8poV9vqBOrTANG4/Lhotse--Isma---Copy-?node-id=4045-2)
> Code: `lib/core/theme/`

## Tokens

### Colors (`app_colors.dart`)
| Token | Value | Usage |
|-------|-------|-------|
| primary | `#1A1E2F` | Navy — nav bg, cards on dark, text |
| background | `#E5E2DC` | Warm beige — page backgrounds |
| surface | `#D1CEC7` | Lighter beige — sections, inputs |
| textPrimary | `#1A1E2F` | Body text, headings |
| textSecondary | `#8C8A85` | Captions, labels, inactive icons |
| textOnDark | `#FFFFFF` | Text on primary/dark surfaces |
| accentMuted | `#5A5854` | Supporting text, muted elements |
| danger | `#7F1D1D` | Negative returns, errors |
| border | `rgba(26,30,47,0.1)` | Dividers, card borders |
| borderLight | `rgba(26,30,47,0.05)` | Subtle separators |
| navBackground | `#1A1E2F` | Bottom navigation bar |

### Typography (`app_typography.dart`) — Campton only
| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| displayLarge | 40 | Black (900) | Hero sections |
| displayMedium | 28 | Bold (700) | Feature headings |
| headingLarge | 24 | Bold (700) | Screen titles (uppercase) |
| headingMedium | 20 | SemiBold (600) | Section headers |
| headingSmall | 18 | SemiBold (600) | Subsection headers |
| bodyLarge | 16 | Book (400) | General text |
| bodyMedium | 14 | Book (400) | Secondary text |
| bodySmall | 12 | Book (400) | Descriptions, paragraphs |
| labelLarge | 11 | Bold (700) | Menu items, buttons (uppercase) |
| labelSmall | 10 | Book (400) | Nav labels, tags |
| caption | 9 | Book (400) | Metadata, dates (uppercase) |
| captionSmall | 8 | Book (400) | Version info |

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
- [x] Bottom navigation (5 tabs) — custom `_LhotseNavBar` in `shell_screen.dart`. All Lucide icons (home, layers, search, compass, user), labels always visible (white active / gray inactive), no filled variants. Tabs: INICIO, FIRMAS, BUSCAR, ESTRATEGIA, PERFIL
- [x] Project card — `ProjectCard` in `home/presentation/widgets/project_card.dart`. Dynamic overlay (padding-based height), AutoSizeText title (40px, 1 line), brand+location metadata, ↗ icon
- [x] Brand card — `_BrandCard` in `brands/presentation/brands_screen.dart`. 192px, cover image + gradient overlay + centered SVG logo (48px height) + name bottom-left
- [x] News card — `LhotseNewsCard` in `core/widgets/lhotse_news_card.dart`. Beige overlay (surface 75%), title (1 line, ellipsis) + brand·subtitle metadata. Full (320×213) and compact (260×160) constructors. No "Explorar todo" card — ↗ header handles navigation
- [x] Project carousel — `ProjectCarousel` in `home/presentation/widgets/project_carousel.dart`. PageView with 5s auto-scroll + progress bar
- [x] Search field — `LhotseSearchField` in `core/widgets/lhotse_search_field.dart`
- [x] Brand filter row — `LhotseBrandFilterRow` in `core/widgets/lhotse_brand_filter_row.dart`. Horizontal scroll of SVG logos/initials (32px) with multi-select (opacity-based). Used in AllProjects, Opportunities, AllNews
- [x] Filter bar — `_FilterBar` in `all_projects_screen.dart`. Status filters + brand/search tool icons after separator
- [x] Back button — `LhotseBackButton` in `core/widgets/lhotse_back_button.dart`. Two variants: `.onImage()` (frosted glass circle, backdrop blur, white arrow) and `.onSurface()` (minimal navy arrow, opacity feedback). 44px touch target, 20px icon. Defaults to `context.pop()`
- [x] Ledger row — `LhotseLedgerRow` in `core/widgets/lhotse_ledger_row.dart`. Leading widget + title/subtitle + amount/return. isLast (no border), muted (for completed). Used in strategy and brand investments
- [x] App header — `LhotseAppHeader` in `core/widgets/lhotse_app_header.dart`. Back button + centered title + optional subtitle + Lhotse logo. 44px balanced sides
- [x] Bottom sheet — `showLhotseBottomSheet` in `core/widgets/lhotse_bottom_sheet.dart`. Drag handle + title + scrollable list. Dynamic height (clamp 0.3–0.8), safe area padding
- [x] Opportunity card — `_OpportunityCard` in `investments_screen.dart`. 180×160px, beige overlay, sharp edges
- [x] Metric block — `_MetricBlock` in `investment_detail_screen.dart`. Value (headingSmall 18px) + label (bodySmall 12px). Used in 2x2 grids
- [x] Construction status — `_ConstructionStatus` in `investment_detail_screen.dart`. Phase (18px) + "En plazo"/"Retrasado" badge (navy 6% / danger 10% bg)
- [x] Document row — `_DocumentRow` in `investment_detail_screen.dart`. Type icon (scale/banknote/hardHat/receipt) + name + date + preview/download actions
- [x] Filter tab — `_FilterTab` in `opportunities_screen.dart`. Text + animated underline + dot indicator. Multi-select support
- [ ] Button variants (primary, secondary, text)
- [x] Trending chip — `_TrendingChip` in `search/presentation/search_screen.dart`. Pill shape (borderRadiusFull), white 40% bg, subtle border, Campton 12px medium
- [x] Collection card — `_CollectionCard` in `search/presentation/search_screen.dart`. Image + bottom gradient + brand name, same visual language as brand cards
- [x] Search result item — `_ProjectResultItem` in `search/presentation/search_screen.dart`. 64px thumbnail + name/brand/location metadata + arrow icon
- [x] Empty results — `_EmptyResults` in `search/presentation/search_screen.dart`. Heading + subtitle, no illustration
- [ ] Empty state
- [ ] Skeleton/shimmer loading
- [ ] Modal VIP

## Screen Patterns
- [x] List screen — Firmas (brand list), AllProjects (project list with filters)
- [x] Detail screen — ProjectDetail (SliverAppBar hero + content panel)
- [x] Search screen — SearchScreen (header + search field + idle: trending tags + collections grid / active: project results + documents placeholder)
- [x] Strategy screen — InvestmentsScreen (navy hero + brand ledger + opportunity section)
- [x] Opportunities screen — OpportunitiesScreen (text-tab filters: firma/ubicación/buscar + project list)
- [x] Brand investments screen — BrandInvestmentsScreen (centered header + summary + investment cards)
- [x] Investment detail screen — InvestmentDetailScreen (model-aware: compraDirecta 2x2+financing, coinversión/ciclo grid+status, rentaFija 3x2. Documents list+bottom sheet with type filters. News carousel+bottom sheet. Navy CTA button)
- [x] All news screen — AllNewsScreen (firma logos/región flags/buscar text-tab filters + full-size news cards)
- [ ] Dashboard screen (home, investments overview)
- [ ] Form screen (profile edit, login)

## Financial Data Display
- Positive values: success color, `+` prefix optional
- Negative values: danger color (`#7F1D1D`), `−` prefix
- Currency always with `€` symbol
- Large numbers: abbreviated with suffix (€1,2M) or full with separators (€1.234.567)
- Percentages: one decimal (12,5%), colored by positive/negative
