-- ============================================================================
-- Migration: brands_icon_asset_and_portfolio
-- Principles applied: #4 (no speculative fields — direct consumer), #2 (data flows through views)
-- Consumers (Flutter providers reading new/changed views):
--   - user_portfolio → userPortfolioProvider (Strategy L1 brand-row ledger; _BrandRow monogram slot)
-- Co-loaded pairs: none
-- Dead fields dropped: none
-- New fields added:
--   - brands.icon_asset — compact square brand icon, distinct from the horizontal wordmark in logo_asset.
--     Consumer: Strategy ledger _BrandRow (lib/features/investments/presentation/investments_screen.dart).
--   - user_portfolio.icon_asset — pass-through from brands.icon_asset.
-- Denormalization justifications: none (single source-of-truth column on brands)
-- Rollback: DROP COLUMN public.brands.icon_asset CASCADE; then recreate the previous
--           user_portfolio view without icon_asset (previous definition preserved in
--           Supabase migration history).
-- Notes: CREATE OR REPLACE VIEW cannot reorder columns → view is dropped and recreated.
--        No other views depend on user_portfolio (verified before dropping).
-- ============================================================================

ALTER TABLE public.brands ADD COLUMN IF NOT EXISTS icon_asset text;

COMMENT ON COLUMN public.brands.icon_asset IS
  'URL to a compact square brand icon (distinct from the horizontal wordmark in logo_asset). Used in the Strategy ledger monogram slot; null means Strategy falls back to initials.';

-- Populate the five brands whose icons live at brand-assets/icons/{slug}.svg.
UPDATE public.brands SET icon_asset =
  'https://mrwrmigeyatfrzwvfsfe.supabase.co/storage/v1/object/public/brand-assets/icons/domorato.svg'
  WHERE name = 'Domorato';
UPDATE public.brands SET icon_asset =
  'https://mrwrmigeyatfrzwvfsfe.supabase.co/storage/v1/object/public/brand-assets/icons/lacomb-bos.svg'
  WHERE name = 'Lacomb & Bos';
UPDATE public.brands SET icon_asset =
  'https://mrwrmigeyatfrzwvfsfe.supabase.co/storage/v1/object/public/brand-assets/icons/myttas.svg'
  WHERE name = 'Myttas';
UPDATE public.brands SET icon_asset =
  'https://mrwrmigeyatfrzwvfsfe.supabase.co/storage/v1/object/public/brand-assets/icons/nuve.svg'
  WHERE name = 'NUVE';
UPDATE public.brands SET icon_asset =
  'https://mrwrmigeyatfrzwvfsfe.supabase.co/storage/v1/object/public/brand-assets/icons/vellte.svg'
  WHERE name = 'Vellte';

DROP VIEW IF EXISTS public.user_portfolio;

CREATE VIEW public.user_portfolio AS
SELECT
  brand_id,
  brand_name,
  logo_asset,
  icon_asset,
  business_model,
  sum(amount) AS total_amount,
  avg(return_pct) AS avg_return_pct,
  count(*) AS active_count
FROM (
  SELECT
    b.id AS brand_id,
    b.name AS brand_name,
    b.logo_asset,
    b.icon_asset,
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
  WHERE pc.status = 'signed'::text AND pc.sold_date IS NULL
  UNION ALL
  SELECT
    b.id AS brand_id,
    b.name AS brand_name,
    b.logo_asset,
    b.icon_asset,
    b.business_model,
    cc.amount,
    ps.roi_investor AS return_pct
  FROM coinvestment_contracts cc
    JOIN projects p ON p.id = cc.project_id
    JOIN brands b ON b.id = p.brand_id
    LEFT JOIN LATERAL (
      SELECT project_scenarios.roi_investor
      FROM project_scenarios
      WHERE project_scenarios.project_id = p.id
      ORDER BY (abs(project_scenarios.sort_order - 2)), project_scenarios.sort_order
      LIMIT 1
    ) ps ON true
  WHERE cc.status = 'signed'::text AND cc.completion_date IS NULL
  UNION ALL
  SELECT
    b.id AS brand_id,
    b.name AS brand_name,
    b.logo_asset,
    b.icon_asset,
    b.business_model,
    c.amount,
    o.guaranteed_rate AS return_pct
  FROM fixed_income_contracts c
    JOIN fixed_income_offerings o ON o.id = c.offering_id
    JOIN brands b ON b.id = o.brand_id
  WHERE c.status = 'signed'::text AND (c.maturity_date IS NULL OR c.maturity_date > CURRENT_DATE)
) combined
GROUP BY brand_id, brand_name, logo_asset, icon_asset, business_model;

ALTER VIEW public.user_portfolio SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
