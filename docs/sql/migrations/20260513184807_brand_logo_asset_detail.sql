-- ============================================================================
-- Migration: brand_logo_asset_detail
-- Principles applied: #4 (no speculative fields — consumer ships in same PR),
--                     #5 (schema evolution matches feature evolution)
-- Consumers (Flutter providers reading new/changed views):
--   - brands → brandsProvider (list/detail) via select * — exposes new column
-- Co-loaded pairs: none new (column added to base table, not a view)
-- Dead fields dropped: none
-- New fields added:
--   - brands.logo_asset_detail — consumer: brand_detail_screen
--     (_BrandLogoHeader + _BrandLogo), tight-cropped wordmark variant for
--     left-anchored rendering. Fallback to logo_asset when NULL.
-- Denormalization justifications: n/a (independent asset URL, not a duplicate
--   of logo_asset — distinct viewBox/crop semantics).
-- Rollback: ALTER TABLE brands DROP COLUMN logo_asset_detail;
-- ============================================================================

ALTER TABLE brands
  ADD COLUMN logo_asset_detail text NULL;

COMMENT ON COLUMN brands.logo_asset_detail IS
  'Wordmark tightly cropped (viewBox ajustado al contenido, sin padding lateral interno) para anclar a izquierda en la pantalla detalle de la firma. Fallback a logo_asset si NULL.';

NOTIFY pgrst, 'reload schema';
