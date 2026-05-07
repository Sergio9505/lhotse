-- Refresh assets_with_status view to include brand_id (and any future columns).
--
-- Gotcha: Postgres freezes a view's column list at creation time, even with
-- `SELECT a.*`. Columns added to the underlying table afterwards don't appear
-- automatically. Here brand_id was added (20260427180000_assets_brand_id.sql)
-- one day after the view was created, so it was missing from the view shape.
-- Fix: DROP + CREATE forces Postgres to re-snapshot `a.*`.

DROP VIEW IF EXISTS public.assets_with_status;

CREATE VIEW public.assets_with_status AS
SELECT
  a.*,
  EXISTS (
    SELECT 1 FROM projects p WHERE p.asset_id = a.id
  ) AS has_coinvestment_project,
  EXISTS (
    SELECT 1 FROM purchase_contracts pc
    WHERE pc.asset_id = a.id
      AND pc.status = 'signed'
      AND pc.sold_date IS NULL
  ) AS has_active_purchase,
  EXISTS (
    SELECT 1 FROM purchase_contracts pc
    WHERE pc.asset_id = a.id
      AND pc.sold_date IS NOT NULL
  ) AS is_sold,
  EXISTS (
    SELECT 1 FROM rental_contracts rc
    WHERE rc.asset_id = a.id
      AND rc.is_active = true
  ) AS has_active_rental
FROM assets a;

ALTER VIEW public.assets_with_status SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
