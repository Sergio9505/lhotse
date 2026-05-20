-- ============================================================================
-- Migration: projects_hero_media
-- Principles applied: #1b (image_url stays as list display identity, derived
--   from hero_media[0]), #7 (column naming aligned with news.hero_media)
-- Consumers: projects → projectsProvider, projectByIdProvider
--   - projects_with_metrics (recreated) → projectsProvider (catalog + detail)
-- Co-loaded pairs: projects_with_metrics is the main projection; recreated
--   below so the new column is exposed.
-- Dead fields dropped: none
-- New fields added: projects.hero_media — consumer: ProjectDetailScreen.hero
--   (MediaHeroCarousel)
-- Denormalization justifications: projects.image_url remains denormalized as
--   the cover field (#1b). Five list-row call-sites read it (feed, archive,
--   L2/L3 row, hero shuttle). Avoids forcing every list query to project
--   hero_media[0] server-side.
-- Rollback:
--   DROP VIEW projects_with_metrics;
--   ALTER TABLE projects DROP COLUMN hero_media;
--   then re-run the previous view definition (see git history for
--   20260511170739_projects_with_metrics_refresh).
-- ============================================================================
--
-- Shape mirrors news.hero_media (renamed in 20260520130000). Per-element
-- validation (type ∈ {image,video} + non-empty url) is enforced in the
-- application layer (zod + Dart parser); CHECK only verifies the column
-- is a jsonb array.
--
-- `gallery_media` stays as the post-cierre gallery section; `render_media`
-- stays as pre-obra renders. `hero_media` is the new field that drives the
-- multi-image carousel in the public hero (ADR-71).

ALTER TABLE projects
  ADD COLUMN hero_media jsonb NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE projects
  ADD CONSTRAINT projects_hero_media_is_array
    CHECK (jsonb_typeof(hero_media) = 'array');

-- Backfill: existing rows with image_url → single-image hero gallery.
UPDATE projects
   SET hero_media = jsonb_build_array(
         jsonb_build_object('type', 'image', 'url', image_url)
       )
 WHERE image_url IS NOT NULL
   AND image_url <> ''
   AND hero_media = '[]'::jsonb;

-- Recreate projects_with_metrics to expose hero_media. CREATE OR REPLACE
-- VIEW does not preserve reloptions, so we DROP + CREATE + re-apply
-- security_invoker=true (Supabase gotcha).
DROP VIEW IF EXISTS projects_with_metrics;

CREATE VIEW projects_with_metrics AS
 SELECT p.id,
    p.brand_id,
    p.name,
    p.architect,
    p.image_url,
    p.tagline,
    p.description,
    p.is_vip,
    p.created_at,
    p.updated_at,
    p.asset_id,
    p.brochure_url,
    p.target_capital,
    p.purchase_price,
    p.built_sqm,
    p.agency_commission,
    p.itp_amount,
    p.purchase_expenses_amount,
    p.renovation_cost,
    p.furniture_cost,
    p.other_costs,
    p.total_cost,
    p.is_delayed,
    p.is_fundraising_open,
    p.phase,
    p.construction_completed_at,
    p.video_url,
    p.use_light_overlay,
    p.hero_media,
    p.gallery_media,
    p.render_media,
    p.virtual_tour_url,
    p.progress_tour_url,
    b.name AS brand_name,
    b.business_model AS brand_business_model,
    a.city AS asset_city,
    a.country AS asset_country,
    COALESCE(( SELECT sum(cc.amount) AS sum
           FROM coinvestment_contracts cc
          WHERE cc.project_id = p.id AND cc.status = 'signed'::text AND cc.completion_date IS NULL), 0::numeric) + COALESCE(( SELECT sum(pc.purchase_value) AS sum
           FROM purchase_contracts pc
          WHERE pc.asset_id = p.asset_id AND pc.status = 'signed'::text AND pc.sold_date IS NULL), 0::numeric) AS captured_amount,
    (( SELECT count(*)::integer AS count
           FROM coinvestment_contracts cc
          WHERE cc.project_id = p.id)) + (( SELECT count(*)::integer AS count
           FROM purchase_contracts pc
          WHERE pc.asset_id = p.asset_id)) AS contracts_count,
    ( SELECT count(*)::integer AS count
           FROM project_phases ph
          WHERE ph.project_id = p.id) AS phases_count,
    ( SELECT count(*)::integer AS count
           FROM project_scenarios ps
          WHERE ps.project_id = p.id) AS scenarios_count,
    GREATEST(p.updated_at, COALESCE(( SELECT max(cc.updated_at) AS max
           FROM coinvestment_contracts cc
          WHERE cc.project_id = p.id), '-infinity'::timestamp with time zone), COALESCE(( SELECT max(pc.updated_at) AS max
           FROM purchase_contracts pc
          WHERE pc.asset_id = p.asset_id), '-infinity'::timestamp with time zone)) AS last_activity_at
   FROM projects p
     LEFT JOIN brands b ON b.id = p.brand_id
     LEFT JOIN assets a ON a.id = p.asset_id;

ALTER VIEW projects_with_metrics SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
