-- ============================================================================
-- Migration: projects_lifecycle_status
-- Principles applied: #6 (unified status TEXT+CHECK per ADR-44), #8 (views as API)
-- Consumers (Flutter providers reading new/changed views):
--   - projects (projectsProvider, projectByIdProvider, featuredProjectsProvider) → list + detail
--   - user_opportunities → opportunitiesProvider (Strategy → Opportunities)
--   - projects_with_metrics, brands_with_metrics → admin/metrics (no mobile consumer yet)
-- Co-loaded pairs: [projects, brands, assets] — disjoint columns ✅ (brand/asset data via nested selects)
-- Dead fields dropped: is_fundraising_closed (grep verified — only 2 Flutter refs, both updated in same PR)
-- New fields added:
--   is_fundraising_open       — consumer: project_card badge "EN CAPTACIÓN", filter tab
--   phase                     — consumer: project_card badge "EN OBRA"/"FINALIZADO", filter tab
--   construction_completed_at — consumer: none yet (admin-only marker)
-- Denormalization justifications: none (orthogonal state axes replace single boolean)
-- Rollback: re-add is_fundraising_closed as GENERATED (= NOT is_fundraising_open);
--          drop new columns + check; revert view definitions from this file's header.
-- ============================================================================

-- 1) Add new columns ---------------------------------------------------------
ALTER TABLE projects
  ADD COLUMN is_fundraising_open       boolean     NOT NULL DEFAULT true,
  ADD COLUMN phase                     text        NOT NULL DEFAULT 'pre_construction',
  ADD COLUMN construction_completed_at timestamptz;

-- 2) Backfill is_fundraising_open as inverse of old column -------------------
UPDATE projects SET is_fundraising_open = NOT is_fundraising_closed;

-- 3) Constraints -------------------------------------------------------------
-- Phase enum (pre_construction | construction | exited). 3 states only: coinversión
-- es un flip (build → sell), no hay fase "operating" de tenencia duradera.
ALTER TABLE projects
  ADD CONSTRAINT projects_phase_check
    CHECK (phase IN ('pre_construction','construction','exited'));

-- Invariante: un proyecto salido no puede seguir captando. No existe simetría
-- en el otro sentido: puedes cerrar captación antes o después de arrancar obra.
ALTER TABLE projects
  ADD CONSTRAINT projects_phase_fundraising_check
    CHECK (phase <> 'exited' OR is_fundraising_open = false);

-- 4) Recreate dependent views ------------------------------------------------
-- a) user_opportunities: swap passthrough column
DROP VIEW IF EXISTS user_opportunities;
CREATE VIEW user_opportunities AS
  SELECT
    auth.uid() AS user_id,
    p.id,
    p.name,
    p.image_url,
    p.is_fundraising_open,
    p.phase,
    p.is_vip,
    a.city,
    a.country,
    b.id AS brand_id,
    b.name AS brand_name,
    b.logo_asset,
    b.business_model,
    p.created_at
  FROM projects p
    JOIN assets a ON a.id = p.asset_id
    JOIN brands b ON b.id = p.brand_id
  WHERE p.id NOT IN (
    SELECT cc.project_id
      FROM coinvestment_contracts cc
      WHERE cc.user_id = auth.uid()
    UNION
    SELECT proj.id
      FROM purchase_contracts pc
      JOIN projects proj ON proj.asset_id = pc.asset_id
      WHERE pc.user_id = auth.uid()
  );
ALTER VIEW user_opportunities SET (security_invoker = true);

-- b) projects_with_metrics: swap passthrough column
DROP VIEW IF EXISTS projects_with_metrics;
CREATE VIEW projects_with_metrics AS
  SELECT
    p.id,
    p.brand_id,
    p.name,
    p.architect,
    p.image_url,
    p.tagline,
    p.description,
    p.gallery_images,
    p.is_vip,
    p.render_images,
    p.progress_images,
    p.created_at,
    p.updated_at,
    p.asset_id,
    p.brochure_url,
    p.is_fundraising_open,
    p.phase,
    p.construction_completed_at,
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
    b.name AS brand_name,
    b.business_model AS brand_business_model,
    a.city AS asset_city,
    a.country AS asset_country,
    (COALESCE((SELECT sum(cc.amount) FROM coinvestment_contracts cc
                WHERE cc.project_id = p.id
                  AND cc.status = 'signed'
                  AND cc.completion_date IS NULL), 0)
     + COALESCE((SELECT sum(pc.purchase_value) FROM purchase_contracts pc
                  WHERE pc.asset_id = p.asset_id
                    AND pc.status = 'signed'
                    AND pc.sold_date IS NULL), 0)
    ) AS captured_amount,
    ((SELECT count(*)::integer FROM coinvestment_contracts cc WHERE cc.project_id = p.id)
     + (SELECT count(*)::integer FROM purchase_contracts pc WHERE pc.asset_id = p.asset_id)
    ) AS contracts_count,
    (SELECT count(*)::integer FROM project_phases ph WHERE ph.project_id = p.id) AS phases_count,
    (SELECT count(*)::integer FROM project_scenarios ps WHERE ps.project_id = p.id) AS scenarios_count,
    GREATEST(
      p.updated_at,
      COALESCE((SELECT max(cc.updated_at) FROM coinvestment_contracts cc WHERE cc.project_id = p.id), '-infinity'::timestamptz),
      COALESCE((SELECT max(pc.updated_at) FROM purchase_contracts pc WHERE pc.asset_id = p.asset_id), '-infinity'::timestamptz)
    ) AS last_activity_at
  FROM projects p
    LEFT JOIN brands b ON b.id = p.brand_id
    LEFT JOIN assets a ON a.id = p.asset_id;
ALTER VIEW projects_with_metrics SET (security_invoker = true);

-- c) brands_with_metrics: filter uses new column
DROP VIEW IF EXISTS brands_with_metrics;
CREATE VIEW brands_with_metrics AS
  SELECT
    id,
    name,
    logo_asset,
    cover_image_url,
    business_model,
    tagline,
    description,
    website_url,
    created_at,
    updated_at,
    is_visible,
    (SELECT count(*)::integer FROM projects p
      WHERE p.brand_id = b.id AND p.is_fundraising_open = true) AS coinv_active_projects,
    (SELECT COALESCE(sum(cc.amount), 0) FROM coinvestment_contracts cc
      JOIN projects p ON p.id = cc.project_id
      WHERE p.brand_id = b.id) AS coinv_captured,
    (SELECT COALESCE(sum(p.target_capital), 0) FROM projects p
      WHERE p.brand_id = b.id) AS coinv_target,
    (SELECT count(*)::integer FROM purchase_contracts pc WHERE pc.brand_id = b.id) AS purchase_contracts_count,
    (SELECT COALESCE(sum(pc.purchase_value), 0) FROM purchase_contracts pc
      WHERE pc.brand_id = b.id) AS purchase_volume,
    (SELECT count(*)::integer FROM fixed_income_offerings fo
      WHERE fo.brand_id = b.id AND fo.is_active = true) AS fi_open_offerings,
    (SELECT COALESCE(sum(fic.amount), 0) FROM fixed_income_contracts fic
      JOIN fixed_income_offerings fo ON fo.id = fic.offering_id
      WHERE fo.brand_id = b.id) AS fi_issued,
    (SELECT count(*)::integer FROM rental_contracts rc
      WHERE rc.brand_id = b.id AND rc.is_active = true) AS rental_active,
    (SELECT COALESCE(sum(rc.monthly_rent), 0) FROM rental_contracts rc
      WHERE rc.brand_id = b.id AND rc.is_active = true) AS rental_monthly,
    GREATEST(
      updated_at,
      COALESCE((SELECT max(p.updated_at) FROM projects p WHERE p.brand_id = b.id), '-infinity'::timestamptz),
      COALESCE((SELECT max(pc.updated_at) FROM purchase_contracts pc WHERE pc.brand_id = b.id), '-infinity'::timestamptz),
      COALESCE((SELECT max(cc.updated_at) FROM coinvestment_contracts cc JOIN projects p ON p.id = cc.project_id WHERE p.brand_id = b.id), '-infinity'::timestamptz),
      COALESCE((SELECT max(fic.updated_at) FROM fixed_income_contracts fic JOIN fixed_income_offerings fo ON fo.id = fic.offering_id WHERE fo.brand_id = b.id), '-infinity'::timestamptz),
      COALESCE((SELECT max(fo.updated_at) FROM fixed_income_offerings fo WHERE fo.brand_id = b.id), '-infinity'::timestamptz),
      COALESCE((SELECT max(rc.updated_at) FROM rental_contracts rc WHERE rc.brand_id = b.id), '-infinity'::timestamptz)
    ) AS last_activity_at
  FROM brands b;
ALTER VIEW brands_with_metrics SET (security_invoker = true);

-- 5) Drop legacy column ------------------------------------------------------
ALTER TABLE projects DROP COLUMN is_fundraising_closed;

-- 6) Flush PostgREST cache ---------------------------------------------------
NOTIFY pgrst, 'reload schema';
