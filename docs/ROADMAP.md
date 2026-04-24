# Roadmap

Pending features + known gaps. Completed work lives in git history, not here.

## Gaps to close

- [ ] **Security screen** — 2FA toggle and "cerrar todas las sesiones" are no-ops; biometric state is local-only. Wire to real backend state (Supabase Auth factors + session revocation) when the feature is prioritized.
- [ ] **Support screen** — email / teléfonos / horario are hardcoded in the screen. Move to a `support_contacts` table (or env-driven config) so marketing can update without a release.
- [ ] **Legal text screen** — `LegalContent.terms` + `LegalContent.privacy` live as `static const` strings. Move to a `legal_documents` table (versionable, with `effective_date`) so a new version can be published + tracked without rebuilding the app.
- [ ] **Search trending tags** — the idle-state tag list is a `const` in `search_screen.dart`. Ideal source: analytics-driven (most-searched over the last N days) or admin-managed. Low priority until we have data volume.
- [ ] **Real floor-plan images** — the bundle mock was removed. 11 projects currently have `floor_plan_url = NULL` and the PLANO section is hidden for those. Upload real floor plans to Supabase Storage when material is available (no code change needed — the UI already handles the NULL branch).
- [ ] **Forgot password flow** — login screen has the link but the target flow is not implemented. Supabase Auth supports the reset email out of the box — needs a screen + deep link handler.
- [ ] **Welcome screen video** — currently a stock Coverr clip. Replace with branded content before production.
- [ ] **Asset detail screen** — `FeedAssetItem` (Home feed) tap is currently a no-op. Decide whether it links to a standalone asset screen, an equivalent of project detail, or a bottom sheet. Hero tag `asset-hero-{id}` is already in place so the shared-element transition lands when a destination exists.
