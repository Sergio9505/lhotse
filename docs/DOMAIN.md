# Domain

## Overview
Lhotse Group is a holding company specializing in redefining wealth management and creation through strategic investments in real estate assets. The app serves as the investor-facing platform for portfolio tracking and group information.

## Glossary
| Term | Definition |
|------|-----------|
| Lhotse Group | Parent holding company |
| Brand / Firma | A company within the Lhotse Group (Myttas, Lacomb & Bos, Vellte, NUVE, Domorato, Andhy, Ciclo, Renta Fija). Model: `BrandData` (id, name, logoAsset?, coverImageUrl) — logoAsset nullable, fallback to initial letter |
| Project | A specific real estate investment project managed by a brand. Model: `ProjectData` (id, name, brand, architect, location, address, imageUrl, tagline, description, galleryImages, isVip, status) |
| Investment | A user's financial position in a project unit. Model: `InvestmentData` (id, projectId, projectName, brandName, amount, returnRate, durationMonths, expectedEndDate?, constructionPhase?, operation details...) |
| BrandInvestmentSummary | Aggregated view per brand: total amount, avg return, list of investments |
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
- News section (5 from centralized mockNews, beige overlay cards with brand·subtitle metadata, no "Explorar todo" card)
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
- Documents section: investment documents per user (contracts, reports) — to be connected via Supabase

### Investments (Estrategia)
- **Investor/VIP only** — viewers see CTA or locked state
- **Overview (navy hero)**: total patrimony (50px, tabular figures) + avg return. Navy bg differentiates as "VIP zone"
- **Brand ledger**: full-width rows sorted by investment desc, logo + name + operations count left, amount + return right. Ledger lines. Taps → brand detail
- **Brand detail**: per-brand investments with cards (project name, unit, amount, return)
- **Investment detail**: participación, return, duration, construction phase, operation details (purchase, mortgage, conditions), documents placeholder, "Ver proyecto" link
- **New opportunities**: section with compact image cards (beige overlay, same style as Home project cards). Header with ↗ links to full opportunities screen
- **Opportunities screen**: filtered view (brand + location + search as text tabs, combinable). Only shows projects without existing investments

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
- Role is determined server-side (when Supabase connects)
