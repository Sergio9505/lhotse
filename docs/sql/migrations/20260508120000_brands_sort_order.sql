-- Add manual sort_order to brands so the admin can curate how firms appear
-- in the investor app. Defaults to alphabetical position * 10 for legacy
-- rows so the initial state matches what users see today; new rows go to
-- the end via the createBrand server action.
--
-- The view brands_with_metrics was created with `SELECT b.*` which Postgres
-- expanded to the explicit column list at create time, so adding a column
-- to brands does NOT propagate. We DROP + CREATE the view with the same
-- body so sort_order becomes part of the view's projection.

ALTER TABLE public.brands
  ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0;

UPDATE public.brands b
SET sort_order = sub.rn * 10
FROM (
  SELECT id, ROW_NUMBER() OVER (ORDER BY name ASC) AS rn
  FROM public.brands
) sub
WHERE b.id = sub.id;

CREATE INDEX IF NOT EXISTS brands_sort_order_idx ON public.brands (sort_order);

DROP VIEW IF EXISTS public.brands_with_metrics;

CREATE VIEW public.brands_with_metrics AS
SELECT
  b.*,
  (
    SELECT COUNT(*)::int
    FROM projects p
    WHERE p.brand_id = b.id
      AND p.is_fundraising_open = true
  ) AS coinv_active_projects,
  (
    SELECT COALESCE(SUM(cc.amount), 0)
    FROM coinvestment_contracts cc
    JOIN projects p ON p.id = cc.project_id
    WHERE p.brand_id = b.id
  ) AS coinv_captured,
  (
    SELECT COALESCE(SUM(p.target_capital), 0)
    FROM projects p
    WHERE p.brand_id = b.id
  ) AS coinv_target,
  (
    SELECT COUNT(*)::int
    FROM purchase_contracts pc
    WHERE pc.brand_id = b.id
  ) AS purchase_contracts_count,
  (
    SELECT COALESCE(SUM(pc.purchase_value), 0)
    FROM purchase_contracts pc
    WHERE pc.brand_id = b.id
  ) AS purchase_volume,
  (
    SELECT COUNT(*)::int
    FROM fixed_income_offerings fo
    WHERE fo.brand_id = b.id
      AND fo.is_active = true
  ) AS fi_open_offerings,
  (
    SELECT COALESCE(SUM(fic.amount), 0)
    FROM fixed_income_contracts fic
    JOIN fixed_income_offerings fo ON fo.id = fic.offering_id
    WHERE fo.brand_id = b.id
  ) AS fi_issued,
  (
    SELECT COUNT(*)::int
    FROM rental_contracts rc
    WHERE rc.brand_id = b.id
      AND rc.is_active = true
  ) AS rental_active,
  (
    SELECT COALESCE(SUM(rc.monthly_rent), 0)
    FROM rental_contracts rc
    WHERE rc.brand_id = b.id
      AND rc.is_active = true
  ) AS rental_monthly,
  GREATEST(
    b.updated_at,
    COALESCE((SELECT MAX(p.updated_at)   FROM projects p                WHERE p.brand_id = b.id),                                                 '-infinity'::timestamptz),
    COALESCE((SELECT MAX(pc.updated_at)  FROM purchase_contracts pc     WHERE pc.brand_id = b.id),                                                 '-infinity'::timestamptz),
    COALESCE((SELECT MAX(cc.updated_at)  FROM coinvestment_contracts cc JOIN projects p ON p.id = cc.project_id WHERE p.brand_id = b.id),          '-infinity'::timestamptz),
    COALESCE((SELECT MAX(fic.updated_at) FROM fixed_income_contracts fic JOIN fixed_income_offerings fo ON fo.id = fic.offering_id WHERE fo.brand_id = b.id), '-infinity'::timestamptz),
    COALESCE((SELECT MAX(fo.updated_at)  FROM fixed_income_offerings fo WHERE fo.brand_id = b.id),                                                 '-infinity'::timestamptz),
    COALESCE((SELECT MAX(rc.updated_at)  FROM rental_contracts rc       WHERE rc.brand_id = b.id),                                                 '-infinity'::timestamptz)
  ) AS last_activity_at
FROM brands b;

ALTER VIEW public.brands_with_metrics SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
