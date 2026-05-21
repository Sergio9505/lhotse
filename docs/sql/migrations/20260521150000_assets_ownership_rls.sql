-- ============================================================================
-- Migration: assets_ownership_rls
-- Principles applied: ARCHITECTURE.md Security model — least-privilege RLS.
-- Consumers: assets → assetsProvider (search), home_feed_provider (asset feed
--   items), projects_provider join, news_provider join, asset_detail_provider.
-- Co-loaded pairs: none — assets is a base table, no views recreated here.
-- Dead fields dropped: none.
-- New fields added: none (RLS-only change).
-- RLS change rationale: previous `"public can read assets"` policy
--   (USING true) let non-owners read direct-purchase assets (e.g. Andhy) via
--   the global search. Replaced with two OR-able policies:
--     (a) `users_read_own_purchased_assets`: the user has a purchase_contracts
--         row for the asset (asset_id match + user_id = auth.uid()).
--     (b) `public_read_coinversion_assets`: the asset is part of a coinversion
--         project (any projects row references the asset).
--   Preserves the public catalog of investment-ready projects' assets
--   (`projects_provider` + `news_provider` joins continue to work) while
--   hiding direct-purchase-only assets from non-owners.
--   The pre-existing `admin_write_assets` policy (polcmd '*', is_admin())
--   already covers admin SELECT — no separate admin policy needed.
-- Denormalization justifications: none.
-- Rollback:
--   DROP POLICY users_read_own_purchased_assets ON assets;
--   DROP POLICY public_read_coinversion_assets ON assets;
--   CREATE POLICY "public can read assets" ON assets
--     FOR SELECT TO anon, authenticated USING (true);
-- ============================================================================

-- Drop the over-permissive existing read policy.
DROP POLICY IF EXISTS "public can read assets" ON assets;

-- Policy 1: a user can read an asset they have purchased directly.
-- The inner EXISTS subquery is itself RLS-filtered on purchase_contracts
-- (which restricts to user_id = auth.uid()), so a user only "sees" their
-- own contracts inside this subquery — the explicit user_id check below
-- is defense in depth.
CREATE POLICY users_read_own_purchased_assets ON assets
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM purchase_contracts pc
      WHERE pc.asset_id = assets.id
        AND pc.user_id = auth.uid()
    )
  );

-- Policy 2: anyone (anon or authenticated) can read an asset that is part
-- of a coinversion project. Preserves the public catalog: projects detail
-- joins assets to render city/surface/bedrooms/etc., and news joins to
-- projectAsset(city) for region inference. Direct-purchase-only assets
-- (no projects row referencing them) stay private to their owners.
CREATE POLICY public_read_coinversion_assets ON assets
  FOR SELECT
  TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects p
      WHERE p.asset_id = assets.id
    )
  );

NOTIFY pgrst, 'reload schema';
