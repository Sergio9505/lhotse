-- View `assets_with_status`: enriquece cada activo con flags de su estado
-- operativo actual (en coinversión, vendido, alquilado, libre) para que el
-- listado /assets del admin pueda mostrar chips de estado y filtrar sin N+1.
--
-- Estados (ortogonales, no excluyentes):
--   has_coinvestment_project → existe project con asset_id = a.id
--   has_active_purchase     → purchase_contract status='signed' y sold_date IS NULL
--   is_sold                 → purchase_contract con sold_date IS NOT NULL
--   has_active_rental       → rental_contract con is_active = true
--
-- Scope: admin-only. La app de inversor no usa esta vista.
-- CREATE OR REPLACE no permite alterar shape; usamos DROP + CREATE para
-- idempotencia.

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
