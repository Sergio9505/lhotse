-- ============================================================================
-- Migration: user_opportunities_only_fundraising
-- Principles applied: #8 (views as API), #2 (request ∝ screen needs)
-- Consumers: user_opportunities → opportunitiesProvider (Strategy → Oportunidades)
-- Co-loaded pairs: none
-- Dead fields dropped: none (pure WHERE tightening)
-- New fields added: none
-- Denormalization justifications: n/a
-- Rollback: recreate view without the is_fundraising_open filter (see ADR-47 migration).
-- Note: AllProjects screen now hides pre_construction projects — those surface
-- only here. Tighten the view so the catalogue/opportunity split is enforced
-- at the data layer too, not just the UI.
-- ============================================================================

DROP VIEW IF EXISTS user_opportunities;
CREATE VIEW user_opportunities AS
  SELECT
    auth.uid() AS user_id,
    p.id, p.name, p.image_url,
    p.is_fundraising_open, p.phase,
    p.is_vip,
    a.city, a.country,
    b.id AS brand_id, b.name AS brand_name, b.logo_asset, b.business_model,
    p.created_at
  FROM projects p
    JOIN assets a ON a.id = p.asset_id
    JOIN brands b ON b.id = p.brand_id
  WHERE p.is_fundraising_open = true  -- only capture-open projects are opportunities
    AND p.id NOT IN (
      SELECT cc.project_id FROM coinvestment_contracts cc WHERE cc.user_id = auth.uid()
      UNION
      SELECT proj.id FROM purchase_contracts pc
        JOIN projects proj ON proj.asset_id = pc.asset_id
        WHERE pc.user_id = auth.uid()
    );
ALTER VIEW user_opportunities SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
