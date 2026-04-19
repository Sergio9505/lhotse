-- ============================================================================
-- Migration: unify_contract_status
-- Principles applied: #1 (canonical source), #3 (computed > stored), #6 (unified status)
-- Consumers:
--   user_direct_purchases         → purchaseContractsProvider, brandPurchaseContractsProvider (list)
--   user_coinvestments            → coinvestmentContractsProvider, brandCoinvestmentContractsProvider (list)
--   user_fixed_income_contracts   → fixedIncomeContractsProvider, brandFixedIncomeContractsProvider (list)
--   user_portfolio                → userPortfolioProvider, userPortfolioEntryProvider (Strategy hero)
-- Co-loaded pairs:
--   [user_direct_purchases, purchase_asset_details]     → disjoint (asset details has no status/is_completed) ✅
--   [user_coinvestments, coinvestment_project_details]  → disjoint (project details has no status/is_completed) ✅
-- Dead fields dropped: coinvestment_contracts.is_completed
--   Replacement: derived in view from cc.completion_date IS NOT NULL.
--   (projects has no project_status column — is_fundraising_closed is about
--    fundraising, not delivery; completion_date on the contract itself is the
--    authoritative event.)
-- New fields added:
--   purchase_contracts.status TEXT                                         → consumer: future cancellation flow (enum blindado, no UI yet)
--   coinvestment_contracts.status TEXT                                     → consumer: same
--   rental_contracts.status TEXT                                           → consumer: same
--   user_direct_purchases.is_completed, user_direct_purchases.status       → consumer: brand_investments_screen (ACTIVAS/FINALIZADAS)
--   user_coinvestments.is_completed, user_coinvestments.status             → consumer: same
--   user_fixed_income_contracts.is_completed, user_fixed_income_contracts.status → consumer: same
-- Denormalization justifications: is_completed exposed uniformly in all 4 user_* views
--   (#1b display identity — the UI filter for "FINALIZADAS" reads one boolean across the 4 domains).
-- Rollback:
--   ALTER TABLE coinvestment_contracts ADD COLUMN is_completed BOOLEAN NOT NULL DEFAULT false;
--   UPDATE coinvestment_contracts SET is_completed = true WHERE completion_date IS NOT NULL;
--   ALTER TABLE purchase_contracts DROP COLUMN status;
--   ALTER TABLE coinvestment_contracts DROP COLUMN status;
--   ALTER TABLE rental_contracts DROP COLUMN status;
--   UPDATE fixed_income_contracts SET status = 'active' WHERE status = 'signed';
--   ALTER TABLE fixed_income_contracts DROP CONSTRAINT chk_fixed_income_contracts_status;
--   ALTER TABLE fixed_income_contracts ADD CONSTRAINT fixed_income_contracts_status_check CHECK (status IN ('active','completed','cancelled'));
--   ALTER TABLE fixed_income_contracts ALTER COLUMN status SET DEFAULT 'active';
--   (and restore the previous view definitions — see git history of this file)
-- User-scoped view touched? YES (user_direct_purchases, user_coinvestments, user_fixed_income_contracts, user_portfolio).
--   RLS test MUST be run at apply time: docs/sql/tests/rls_user_isolation.sql.
-- ============================================================================

BEGIN;

-- ── 1) Add `status` to the 3 tables that lack it ────────────────────────────
ALTER TABLE purchase_contracts
  ADD COLUMN status TEXT NOT NULL DEFAULT 'signed'
    CONSTRAINT chk_purchase_contracts_status
    CHECK (status IN ('pending','signed','cancelled'));

ALTER TABLE coinvestment_contracts
  ADD COLUMN status TEXT NOT NULL DEFAULT 'signed'
    CONSTRAINT chk_coinvestment_contracts_status
    CHECK (status IN ('pending','signed','cancelled'));

ALTER TABLE rental_contracts
  ADD COLUMN status TEXT NOT NULL DEFAULT 'signed'
    CONSTRAINT chk_rental_contracts_status
    CHECK (status IN ('pending','signed','cancelled'));

-- ── 2) Migrate fixed_income_contracts.status to the unified vocabulary ──────
--    Drop the old CHECK BEFORE backfill so UPDATE to 'signed' doesn't violate it.
--    Backfill: active / completed → signed (completion now derived in view from
--    maturity_date); cancelled stays; pending is a new value (no existing rows).
ALTER TABLE fixed_income_contracts
  DROP CONSTRAINT fixed_income_contracts_status_check;

UPDATE fixed_income_contracts
   SET status = 'signed'
 WHERE status IN ('active','completed');

ALTER TABLE fixed_income_contracts
  ADD CONSTRAINT chk_fixed_income_contracts_status
  CHECK (status IN ('pending','signed','cancelled'));

ALTER TABLE fixed_income_contracts
  ALTER COLUMN status SET DEFAULT 'signed';

-- ── 3) Drop `is_completed` from coinvestment_contracts (derivable from projects.project_status) ─
--    Must drop AFTER the view that uses it is also dropped (see step 4).

-- ── 4) Drop views that reference changed columns (DROP + CREATE because we
--       add columns and change a derived column — not safe with CREATE OR REPLACE) ─
DROP VIEW IF EXISTS user_portfolio;
DROP VIEW IF EXISTS user_coinvestments;
DROP VIEW IF EXISTS user_direct_purchases;
DROP VIEW IF EXISTS user_fixed_income_contracts;

-- Now safe to drop the column
ALTER TABLE coinvestment_contracts DROP COLUMN is_completed;

-- ── 5) Recreate views with unified `status` + derived `is_completed` ────────

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
    p.estimated_return_pct,
    p.estimated_duration_months,
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
  LEFT JOIN assets a ON a.id = p.asset_id;

ALTER VIEW user_coinvestments SET (security_invoker = true);

CREATE VIEW user_direct_purchases AS
  SELECT
    pc.id,
    pc.brand_id,
    pc.asset_id,
    pc.purchase_value,
    pc.purchase_date,
    pc.total_return,
    pc.sold_date,
    pc.status,
    pc.created_at,
    (pc.sold_date IS NOT NULL) AS is_completed,
    (m.principal IS NOT NULL) AS has_financing,
    CASE
      WHEN pc.total_return IS NOT NULL AND pc.purchase_value > 0::numeric
      THEN round((pc.total_return - pc.purchase_value) / pc.purchase_value * 100::numeric, 2)
      ELSE NULL::numeric
    END AS actual_roi,
    COALESCE(pc.purchase_value - m.principal, pc.purchase_value) AS cash_payment,
    CASE
      WHEN pc.sold_date IS NOT NULL THEN
        (EXTRACT(year FROM age(pc.sold_date::timestamp with time zone, pc.purchase_date::timestamp with time zone)) * 12::numeric
         + EXTRACT(month FROM age(pc.sold_date::timestamp with time zone, pc.purchase_date::timestamp with time zone)))::integer
      ELSE NULL::integer
    END AS actual_duration,
    COALESCE(
      rc.yield_pct,
      CASE
        WHEN rc.id IS NOT NULL AND pc.purchase_value > 0::numeric
        THEN round(rc.monthly_rent * 12::numeric / pc.purchase_value * 100::numeric, 2)
        ELSE NULL::numeric
      END
    ) AS rental_yield_pct,
    rc.monthly_rent,
    a.address AS asset_name,
    (a.city || ', ' || a.country) AS asset_location,
    a.thumbnail_image AS asset_thumbnail_image,
    CASE
      WHEN a.current_value IS NOT NULL AND pc.purchase_value > 0::numeric
      THEN round((a.current_value - pc.purchase_value) / pc.purchase_value * 100::numeric, 2)
      ELSE NULL::numeric
    END AS asset_revaluation_pct
  FROM purchase_contracts pc
  JOIN assets a ON a.id = pc.asset_id
  LEFT JOIN mortgages m ON m.purchase_contract_id = pc.id
  LEFT JOIN rental_contracts rc ON rc.asset_id = pc.asset_id AND rc.is_active = true;

ALTER VIEW user_direct_purchases SET (security_invoker = true);

CREATE VIEW user_fixed_income_contracts AS
  SELECT
    c.id,
    c.offering_id,
    c.amount,
    c.term_months,
    c.start_date,
    c.maturity_date,
    c.status,
    (c.maturity_date IS NOT NULL AND c.maturity_date < CURRENT_DATE) AS is_completed,
    o.name AS offering_name,
    o.guaranteed_rate,
    o.payment_frequency,
    o.brand_id
  FROM fixed_income_contracts c
  JOIN fixed_income_offerings o ON o.id = c.offering_id;

ALTER VIEW user_fixed_income_contracts SET (security_invoker = true);

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
      p.estimated_return_pct AS return_pct
    FROM coinvestment_contracts cc
    JOIN projects p ON p.id = cc.project_id
    JOIN brands b ON b.id = p.brand_id
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

-- ── 6) Flush PostgREST cache ────────────────────────────────────────────────
NOTIFY pgrst, 'reload schema';

COMMIT;
