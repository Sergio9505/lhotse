# Domain

## Overview
Lhotse Group is a holding company specializing in redefining wealth management and creation through strategic investments in real estate assets. The app serves as the investor-facing platform for portfolio tracking and group information.

## Glossary
| Term | Definition |
|------|-----------|
| Lhotse Group | Parent holding company |
| Brand / Firma | A company within the Lhotse Group (Myttas, Lacomb & Bos, Vellte, NUVE, Domorato, Andhy, Ciclo, Renta Fija, Llabe…). Model: `BrandData` (id, name, logoAsset?, coverImageUrl) — logos served from Supabase Storage (brand-assets/logos/) |
| Project | A specific real estate investment project managed by a brand. Model: `ProjectData` (id, name, brand, architect, location, imageUrl, tagline, description, galleryImages, isVip, isFundraisingOpen, phase, constructionCompletedAt). **Lifecycle state lives on two orthogonal axes (ADR-47)**: commercial (`isFundraisingOpen` — accepting new investors) and physical (`phase`: `preConstruction` / `construction` / `exited`). Typed economic columns on `projects`: purchase_price, built_sqm, agency_commission, itp_amount, purchase_expenses_amount, renovation_cost, furniture_cost, other_costs, total_cost (GENERATED), target_capital (ADR-42). Deal terms (estimated_return_pct, estimated_duration_months, expected_exit_date, projected_roi, is_delayed) stored here since they're shared by all coinversores (ADR-43). |
| Asset | A physical property unit (address, surface, bedrooms, bathrooms, floor_plan_url, current_value). Source of truth for compra directa. Linked via `projects.asset_id` (coinversión uses the project's asset — ADR-41) and `purchase_contracts.asset_id` (compra directa owns a specific asset directly). |
| Compra Directa | User owns a physical asset purchased through a brand. Model: `PurchaseContractData` — linked to asset + selling brand (e.g. Myttas, Andhy). Rental income tracked separately via rental_contracts. |
| Coinversión | User participates in a real estate development project. Model: `CoinvestmentContractData` — linked to project (brand via project). **Contract stores only per-investor fields**: amount, start_date, actual_roi/actual_tir/total_return/completion_date, is_completed. Deal terms + profit scenarios + phases live on the project and related tables (ADR-43). |
| Renta Fija | User subscribes to a fixed-income offering from a brand. Model: `FixedIncomeContractData` — offerings catalog + user contracts + payments ledger. |
| Alquiler | Rental management of an owned asset, managed by a brand (e.g. Llabe). Independent domain: rental_contracts → rental_payments. Linked to asset, not to purchase_contract. |
| BrandInvestmentSummaryData | Aggregated view per brand from brand_investment_summaries view: total amount, avg return, active count. Used in Strategy screen. |
| PortfolioSummary | User-level totals from portfolio_summaries view: total invested, avg return, active count. 3-way UNION of all investment types. |
| Viewer (mirón) | Registered user who is not yet an investor — browses public content |
| Investor | Active client with investments in one or more projects |
| Investor VIP | Premium investor tier with additional features (TBD) |
| Portfolio | Aggregate view of a user's investments across all brands |
| News | Updates published by Lhotse Group (projects, market, group events) |

## User Roles

| Role | Access | Description |
|------|--------|-------------|
| Viewer | Home, Brands, Search, Profile | Registered but not investing. Can browse projects, news, and brand info |
| Investor | All of Viewer + Investments | Active client. Sees own investment data segmented by brand/project |
| Investor VIP | All of Investor + Premium features | Premium tier. Additional features TBD |
| (Admin) | — | Not in this app. Managed separately |

## Features

### Home (Inicio)
- Project carousel (auto-scroll 5s, 5 projects max, full-width cards with beige overlay)
- News section (5 from Supabase news table, beige overlay cards with brand·subtitle metadata)
- "NOTICIAS ↗" → AllNews screen
- Tap project → project detail screen (SliverAppBar with collapsing hero image)

### All News (sub-screen of Home)
- Full news listing with text-tab filters: FIRMA (brand logo row), REGIÓN (flag emoji row: 🇪🇸🇲🇽🇺🇸🇵🇹🇦🇪), BUSCAR (search field)
- Brand and region combinable; search exclusive
- Full-size LhotseNewsCard (320×213px) with beige overlay

### Firmas (formerly Marcas)
- List of all brands within Lhotse Group (Myttas, Lacomb & Bos, Vellte, NUVE, Domorato, Andhy, Ciclo, Renta Fija)
- Each brand shown as card with cover image + SVG logo + name
- Brand detail: TBD (description, active projects, key metrics)

### All Projects (sub-screen of Home)
- Full project listing with filters:
  - Status: EN DESARROLLO, CERRADOS (toggle)
  - Brand: horizontal logo row with multi-select (icon: layers)
  - Search: text search (icon: search)
- Status + brand filters can combine; brand row and search are mutually exclusive

### Search (Buscar)
- Global search across projects, brands, and investment documents
- Idle state: trending tags (locations, brands, categories) + collections (brand grid)
- Active state: results grouped by type (projects, documents)
- Documents section: investment documents per user — placeholder UI, documents table exists in Supabase (model_type + model_id pattern)

### Investments (Estrategia)
- **Investor/VIP only** — viewers see CTA or locked state
- **Overview (navy hero)**: total patrimony from portfolio_summaries view + avg return
- **Brand ledger**: rows from brand_investment_summaries view — 3-way UNION (purchase + coinvest + fixed_income). Logo from Supabase Storage.
- **Brand investments**: typed detail per domain (compraDirecta / coinversión / rentaFija). Navigation via GoRouter extra (pre-loaded typed model).
- **Investment detail routing**: typed routes — `/investments/detail/purchase/:id`, `/investments/detail/coinvestment/:id`, `/investments/detail/completed/purchase/:id`, `/investments/detail/completed/coinvestment/:id`, `/investments/detail/:id` (RF inline)
- **CompraDirecta detail**: PurchaseContractData — purchase value, rental yield, revaluation, mortgage details (3 tabs: ACTIVO / FINANCIACIÓN / DOCS)
- **Coinversión detail**: CoinvestmentContractData — scenarios from project_scenarios, phases from project_phases, render/progress images from projects table (4 tabs: AVANCE / ACTIVO / FINANZAS / DOCS)
- **Renta Fija**: inline in InvestmentDetailScreen — contract metrics, no L3 detail
- **Completed detail**: CompletedContractData adapter (maps from either purchase or coinvest)
- **Alquiler**: rental_contracts + rental_payments. Rental income shown in purchase contract detail (rental_yield_pct derived in view). No separate screen yet.
- **New opportunities**: from get_opportunities RPC (projects not yet invested in). Compact image cards.
- **Opportunities screen**: filtered by business model + location via RPC params

### Profile (Mi Perfil)
- User info (name, email, photo)
- Account settings
- Role-specific info (investment summary for investors)
- Legal (terms, privacy)
- Support / contact
- Logout

## Navigation Flow
```
App Shell (BottomNav: 5 tabs)
├── Inicio → All Projects → Project Detail; News Detail
├── Firmas → Brand Detail → Project Detail
├── Buscar → Results → Any Detail; Documents
├── Estrategia → Brand Investments → Investment Detail; Opportunities → Project Detail
└── Perfil → Settings, Legal, Support
```

## Business Rules
- Viewers cannot see investment data (amounts, returns, portfolio)
- Investment data is per-user and private
- Projects are public info (visible to all roles)
- Brands are public info
- News is public
- Role is determined server-side via user_profiles.role (Supabase RLS enforces access)
- Supabase views use security_invoker = true — RLS applies at view level
- Brand logos served from Supabase Storage public bucket (brand-assets/logos/); SVG loaded via SvgPicture.network()
