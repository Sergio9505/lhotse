-- ============================================================================
-- Migration: project_estimates_from_scenarios
-- Principles applied: #1 (canonical source), #3 (computed > stored), #4 (no speculative fields)
-- Consumers:
--   user_coinvestments          → coinvestmentContractsProvider / brandCoinvestmentContractsProvider (list)
--   user_portfolio              → userPortfolioProvider / userPortfolioEntryProvider (Strategy hero)
-- Co-loaded pairs:
--   [user_coinvestments, coinvestment_project_details] → disjoint (project_details has no status/is_completed/estimated_*) ✅
-- Dead fields dropped:
--   projects.projected_roi       (0 Flutter refs, 0 view refs, 2 rows duplicating estimated_return_pct)
--   projects.expected_exit_date  (0 Flutter refs, 0 view refs — principle #4)
-- Moved fields (stored → derived in view from project_scenarios):
--   projects.estimated_return_pct     → user_coinvestments.estimated_return_pct = ps.roi_investor (closest to P50 by sort_order)
--   projects.estimated_duration_months → user_coinvestments.estimated_duration_months = ps.duration_months (same row)
-- New fields added: none (names preserved in the view).
-- Denormalization justifications: none (reducing duplication).
-- Rollback:
--   ALTER TABLE projects ADD COLUMN estimated_return_pct NUMERIC;
--   ALTER TABLE projects ADD COLUMN estimated_duration_months INTEGER;
--   ALTER TABLE projects ADD COLUMN projected_roi NUMERIC;
--   ALTER TABLE projects ADD COLUMN expected_exit_date DATE;
--   -- (backfill from project_scenarios P50 if needed; previous headline values are lost)
--   -- Restore previous view definitions from git history of this file.
-- User-scoped view touched? YES (user_coinvestments, user_portfolio).
--   RLS test MUST be run at apply time: docs/sql/tests/rls_user_isolation.sql.
-- ============================================================================

BEGIN;

-- Drop views that reference the columns we're removing
DROP VIEW IF EXISTS user_portfolio;
DROP VIEW IF EXISTS user_coinvestments;

-- Drop the 4 columns from projects
ALTER TABLE projects DROP COLUMN estimated_return_pct;
ALTER TABLE projects DROP COLUMN estimated_duration_months;
ALTER TABLE projects DROP COLUMN projected_roi;
ALTER TABLE projects DROP COLUMN expected_exit_date;

-- Recreate user_coinvestments: estimated_* come from the scenario closest to P50.
CREATE VIEW user_coinvestments AS
  SELECT
    cc.id,
    cc.project_id,
    cc.amount,
    cc.start_date,
    cc.status,
    (cc.completion_date IS NOT NULL) AS is_completed,
    cc.actual_roi,
    cc.actual_tir,
    cc.total_return,
    cc.created_at,
    ps.roi_investor AS estimated_return_pct,
    ps.duration_months AS estimated_duration_months,
    p.brand_id,
    CASE
      WHEN cc.completion_date IS NOT NULL THEN
        (EXTRACT(year FROM age(cc.completion_date::timestamp with time zone, cc.start_date::timestamp with time zone)) * 12::numeric
         + EXTRACT(month FROM age(cc.completion_date::timestamp with time zone, cc.start_date::timestamp with time zone)))::integer
      ELSE NULL::integer
    END AS actual_duration,
    p.name AS project_name,
    (a.city || ', ' || a.country) AS project_location,
    p.image_url AS project_image_url
  FROM coinvestment_contracts cc
  JOIN projects p ON p.id = cc.project_id
  LEFT JOIN assets a ON a.id = p.asset_id
  LEFT JOIN LATERAL (
    SELECT roi_investor, duration_months
    FROM project_scenarios
    WHERE project_id = p.id
    ORDER BY abs(sort_order - 2), sort_order
    LIMIT 1
  ) ps ON true;

ALTER VIEW user_coinvestments SET (security_invoker = true);

-- Recreate user_portfolio: coinvestment return_pct also derived from closest-to-P50.
CREATE VIEW user_portfolio AS
  SELECT
    brand_id,
    brand_name,
    logo_asset,
    business_model,
    sum(amount) AS total_amount,
    avg(return_pct) AS avg_return_pct,
    count(*) AS active_count
  FROM (
    SELECT
      b.id AS brand_id,
      b.name AS brand_name,
      b.logo_asset,
      b.business_model,
      pc.purchase_value AS amount,
      CASE
        WHEN a.current_value IS NOT NULL AND pc.purchase_value > 0::numeric
        THEN round((a.current_value - pc.purchase_value) / pc.purchase_value * 100::numeric, 2)
        ELSE NULL::numeric
      END AS return_pct
    FROM purchase_contracts pc
    JOIN assets a ON a.id = pc.asset_id
    JOIN brands b ON b.id = pc.brand_id
    WHERE pc.status = 'signed' AND pc.sold_date IS NULL
    UNION ALL
    SELECT
      b.id AS brand_id,
      b.name AS brand_name,
      b.logo_asset,
      b.business_model,
      cc.amount,
      ps.roi_investor AS return_pct
    FROM coinvestment_contracts cc
    JOIN projects p ON p.id = cc.project_id
    JOIN brands b ON b.id = p.brand_id
    LEFT JOIN LATERAL (
      SELECT roi_investor
      FROM project_scenarios
      WHERE project_id = p.id
      ORDER BY abs(sort_order - 2), sort_order
      LIMIT 1
    ) ps ON true
    WHERE cc.status = 'signed' AND cc.completion_date IS NULL
    UNION ALL
    SELECT
      b.id AS brand_id,
      b.name AS brand_name,
      b.logo_asset,
      b.business_model,
      c.amount,
      o.guaranteed_rate AS return_pct
    FROM fixed_income_contracts c
    JOIN fixed_income_offerings o ON o.id = c.offering_id
    JOIN brands b ON b.id = o.brand_id
    WHERE c.status = 'signed'
      AND (c.maturity_date IS NULL OR c.maturity_date > CURRENT_DATE)
  ) combined
  GROUP BY brand_id, brand_name, logo_asset, business_model;

ALTER VIEW user_portfolio SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';

COMMIT;
