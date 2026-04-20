-- View `projects_with_metrics`: agrega por proyecto captación actual, nº de
-- contratos, nº de fases/escenarios, última actividad, y desnormaliza firma
-- y activo para evitar N+1 en el listado del admin.
--
-- `captured_amount` sigue la semántica canónica post-unify_contract_status:
--   coinversión abierta     → status = 'signed' AND completion_date IS NULL
--   compra directa pendiente → status = 'signed' AND sold_date IS NULL (del
--                              mismo asset_id del proyecto).
--
-- Scope: admin-only. La app no usa esta view (tiene vistas user_* propias).
-- CREATE OR REPLACE no permite alterar el shape de columnas; usamos
-- DROP + CREATE para ser idempotentes.

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
-- project_phases / project_scenarios no tienen updated_at — no entran en la
-- señal de actividad reciente (se editan junto al proyecto padre, que ya la aporta).
FROM projects p
LEFT JOIN brands b ON b.id = p.brand_id
LEFT JOIN assets a ON a.id = p.asset_id;

ALTER VIEW public.projects_with_metrics SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
