-- ============================================================================
-- Migration: projects_with_metrics_refresh
-- Principles applied: #4 (field has named consumer)
-- Consumers (new):
--   - projects_with_metrics.video_url → admin projects list thumbnail
--     (fallback to Bunny thumbnail.jpg when image_url is missing, mirrors
--      the Flutter app's posterUrlFor in lhotse_app)
-- Reason: the view was created with `p.*` BEFORE projects.video_url existed.
-- Postgres materialises `*` at CREATE time, so the view still doesn't
-- surface video_url even after the column was added. DROP + CREATE refreshes
-- the column list.
-- Rollback: re-run with no shape change is idempotent.
-- ============================================================================

DROP VIEW IF EXISTS public.projects_with_metrics;

CREATE VIEW public.projects_with_metrics AS
SELECT
  p.*,
  b.name              AS brand_name,
  b.business_model    AS brand_business_model,
  a.city              AS asset_city,
  a.country           AS asset_country,
  (
    COALESCE((
      SELECT SUM(cc.amount)
      FROM coinvestment_contracts cc
      WHERE cc.project_id = p.id
        AND cc.status = 'signed'
        AND cc.completion_date IS NULL
    ), 0)
    +
    COALESCE((
      SELECT SUM(pc.purchase_value)
      FROM purchase_contracts pc
      WHERE pc.asset_id = p.asset_id
        AND pc.status = 'signed'
        AND pc.sold_date IS NULL
    ), 0)
  )::numeric AS captured_amount,
  (
    (
      SELECT COUNT(*)::int
      FROM coinvestment_contracts cc
      WHERE cc.project_id = p.id
    )
    +
    (
      SELECT COUNT(*)::int
      FROM purchase_contracts pc
      WHERE pc.asset_id = p.asset_id
    )
  ) AS contracts_count,
  (
    SELECT COUNT(*)::int
    FROM project_phases ph
    WHERE ph.project_id = p.id
  ) AS phases_count,
  (
    SELECT COUNT(*)::int
    FROM project_scenarios ps
    WHERE ps.project_id = p.id
  ) AS scenarios_count,
  GREATEST(
    p.updated_at,
    COALESCE((SELECT MAX(cc.updated_at) FROM coinvestment_contracts cc WHERE cc.project_id = p.id),    '-infinity'::timestamptz),
    COALESCE((SELECT MAX(pc.updated_at) FROM purchase_contracts pc     WHERE pc.asset_id = p.asset_id), '-infinity'::timestamptz)
  ) AS last_activity_at
FROM projects p
LEFT JOIN brands b ON b.id = p.brand_id
LEFT JOIN assets a ON a.id = p.asset_id;

ALTER VIEW public.projects_with_metrics SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
