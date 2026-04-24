-- ============================================================================
-- Migration: feed_logo_on_dark_media
-- Principles applied: #4 (no speculative fields — wired to Home feed today)
-- Consumers:
--   projects.logo_on_dark_media   → FeedProjectItem + FeedOpportunityItem (home_screen.dart Lhotse mark color)
--   news.logo_on_dark_media       → FeedNewsItem (home_screen.dart Lhotse mark color)
--   brands.logo_on_dark_cover     → FeedBrandItem (home_screen.dart Lhotse mark color over brand cover)
--   user_opportunities.logo_on_dark_media → ProjectData.fromOpportunityRow (opportunitiesProvider)
-- Co-loaded pairs: none (single per-row flag)
-- Dead fields dropped: none
-- New fields added:
--   projects.logo_on_dark_media  — consumer: home_screen.dart floating Lhotse mark
--   news.logo_on_dark_media      — consumer: home_screen.dart floating Lhotse mark
--   brands.logo_on_dark_cover    — consumer: home_screen.dart floating Lhotse mark (brand spotlight day)
--   user_opportunities.logo_on_dark_media — exposes projects.logo_on_dark_media to the opportunities feed path
-- Denormalization justifications: n/a
-- Rollback:
--   DROP VIEW user_opportunities; recreate from 20260420191513.
--   ALTER TABLE brands   DROP COLUMN logo_on_dark_cover;
--   ALTER TABLE news     DROP COLUMN logo_on_dark_media;
--   ALTER TABLE projects DROP COLUMN logo_on_dark_media;
-- Note: default TRUE matches the current visual behaviour (white Lhotse mark
--   over dark media). Content managers flip to FALSE only for pieces whose
--   top-left region is light enough that black reads better.
-- ============================================================================

ALTER TABLE projects
  ADD COLUMN logo_on_dark_media BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE news
  ADD COLUMN logo_on_dark_media BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE brands
  ADD COLUMN logo_on_dark_cover BOOLEAN NOT NULL DEFAULT TRUE;

-- Recreate user_opportunities to surface the new column. Same body as
-- 20260420191513 plus p.logo_on_dark_media.
DROP VIEW IF EXISTS user_opportunities;
CREATE VIEW user_opportunities AS
  SELECT
    auth.uid() AS user_id,
    p.id, p.name, p.image_url,
    p.is_fundraising_open, p.phase,
    p.is_vip,
    p.logo_on_dark_media,
    a.city, a.country,
    b.id AS brand_id, b.name AS brand_name, b.logo_asset, b.business_model,
    p.created_at
  FROM projects p
    JOIN assets a ON a.id = p.asset_id
    JOIN brands b ON b.id = p.brand_id
  WHERE p.is_fundraising_open = true
    AND p.id NOT IN (
      SELECT cc.project_id FROM coinvestment_contracts cc WHERE cc.user_id = auth.uid()
      UNION
      SELECT proj.id FROM purchase_contracts pc
        JOIN projects proj ON proj.asset_id = pc.asset_id
        WHERE pc.user_id = auth.uid()
    );
ALTER VIEW user_opportunities SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
