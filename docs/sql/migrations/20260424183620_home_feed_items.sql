-- ============================================================================
-- Migration: home_feed_items
-- Principles applied: #1 (single canonical source — logo flag now lives in one
--   table, not in every source), #4 (no speculative fields), #8 (views as API).
-- Consumers:
--   home_feed_items → homeFeedProvider (Home feed, server-side curated)
-- Co-loaded pairs: none (single table, 4 source tables fetched by id-batch).
-- Dead fields dropped:
--   projects.logo_on_dark_media       (moved to home_feed_items.logo_on_dark_media)
--   news.logo_on_dark_media           (moved to home_feed_items.logo_on_dark_media)
--   brands.logo_on_dark_cover         (moved to home_feed_items.logo_on_dark_media)
-- Legacy structures dropped:
--   TABLE featured_projects   — replaced by home_feed_items (supports 4 types,
--                               single feed for all roles).
--   VIEW  user_opportunities  — opportunities feature removed entirely
--                               (supersedes ADR-52 which kept them only in Home).
-- New fields added:
--   home_feed_items.*  — consumer: homeFeedProvider (Home feed list).
-- Denormalization justifications: n/a.
-- Rollback: restore featured_projects + user_opportunities from their original
--   migrations (20260322_featured_projects, 20260420191513); re-add the three
--   logo columns with DEFAULT TRUE.
-- Notes:
--   * Polymorphic integrity via trigger (no single FK). Deletes in source
--     tables are NOT cascaded — the homeFeedProvider filters orphaned rows.
--   * Single feed for every role: viewer, investor, investor_vip share the
--     same list. VIP gating is per-project via showVipLockSheet.
-- ============================================================================

CREATE TABLE home_feed_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_type TEXT NOT NULL CHECK (source_type IN ('project','news','brand','asset')),
  source_id UUID NOT NULL,
  sort_order INTEGER NOT NULL,
  logo_on_dark_media BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (source_type, source_id),
  UNIQUE (sort_order)
);

CREATE INDEX idx_home_feed_items_sort ON home_feed_items(sort_order);

-- Polymorphic source integrity.
CREATE OR REPLACE FUNCTION check_home_feed_item_source() RETURNS TRIGGER AS $$
BEGIN
  CASE NEW.source_type
    WHEN 'project' THEN
      IF NOT EXISTS (SELECT 1 FROM projects WHERE id = NEW.source_id)
        THEN RAISE EXCEPTION 'home_feed_items: project % not found', NEW.source_id;
      END IF;
    WHEN 'news' THEN
      IF NOT EXISTS (SELECT 1 FROM news WHERE id = NEW.source_id)
        THEN RAISE EXCEPTION 'home_feed_items: news % not found', NEW.source_id;
      END IF;
    WHEN 'brand' THEN
      IF NOT EXISTS (SELECT 1 FROM brands WHERE id = NEW.source_id)
        THEN RAISE EXCEPTION 'home_feed_items: brand % not found', NEW.source_id;
      END IF;
    WHEN 'asset' THEN
      IF NOT EXISTS (SELECT 1 FROM assets WHERE id = NEW.source_id)
        THEN RAISE EXCEPTION 'home_feed_items: asset % not found', NEW.source_id;
      END IF;
  END CASE;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_home_feed_items_check_source
  BEFORE INSERT OR UPDATE ON home_feed_items
  FOR EACH ROW EXECUTE FUNCTION check_home_feed_item_source();

CREATE TRIGGER trg_home_feed_items_updated_at
  BEFORE UPDATE ON home_feed_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE home_feed_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "home_feed_items public read"
  ON home_feed_items FOR SELECT TO anon, authenticated USING (true);
-- Admin writes via service_role / Supabase dashboard.

-- ----------------------------------------------------------------------------
-- Legacy cleanup
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS user_opportunities;
DROP TABLE IF EXISTS featured_projects;

ALTER TABLE projects DROP COLUMN IF EXISTS logo_on_dark_media;
ALTER TABLE news     DROP COLUMN IF EXISTS logo_on_dark_media;
ALTER TABLE brands   DROP COLUMN IF EXISTS logo_on_dark_cover;

-- ----------------------------------------------------------------------------
-- Seed demo feed — 12 editorial slots
-- ----------------------------------------------------------------------------
-- CTEs with ROW_NUMBER() guarantee distinct rows even when ORDER BY ties exist.
WITH
  ranked_projects AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY created_at DESC, id) AS rn FROM projects
  ),
  ranked_news AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY date DESC, id) AS rn FROM news
  ),
  ranked_assets AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY created_at DESC, id) AS rn FROM assets
  ),
  ranked_brands AS (
    SELECT id, ROW_NUMBER() OVER (ORDER BY name, id) AS rn FROM brands WHERE logo_asset IS NOT NULL
  )
INSERT INTO home_feed_items (source_type, source_id, sort_order, logo_on_dark_media) VALUES
  ('project', (SELECT id FROM ranked_projects WHERE rn = 1), 10,  TRUE),
  ('news',    (SELECT id FROM ranked_news     WHERE rn = 1), 20,  TRUE),
  ('project', (SELECT id FROM ranked_projects WHERE rn = 2), 30,  TRUE),
  ('asset',   (SELECT id FROM ranked_assets   WHERE rn = 1), 40,  TRUE),
  ('news',    (SELECT id FROM ranked_news     WHERE rn = 2), 50,  TRUE),
  ('brand',   (SELECT id FROM ranked_brands   WHERE rn = 1), 60,  TRUE),
  ('project', (SELECT id FROM ranked_projects WHERE rn = 3), 70,  TRUE),
  ('news',    (SELECT id FROM ranked_news     WHERE rn = 3), 80,  TRUE),
  ('project', (SELECT id FROM ranked_projects WHERE rn = 4), 90,  TRUE),
  ('asset',   (SELECT id FROM ranked_assets   WHERE rn = 2), 100, TRUE),
  ('news',    (SELECT id FROM ranked_news     WHERE rn = 4), 110, TRUE),
  ('project', (SELECT id FROM ranked_projects WHERE rn = 5), 120, TRUE);

NOTIFY pgrst, 'reload schema';
