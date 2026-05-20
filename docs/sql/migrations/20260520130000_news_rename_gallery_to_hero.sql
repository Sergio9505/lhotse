-- ============================================================================
-- Migration: news_rename_gallery_to_hero
-- Principles applied: #7 (column naming — consistency across entities)
-- Consumers: news → newsProvider, newsByIdProvider (no view in between)
-- Co-loaded pairs: none
-- Dead fields dropped: none (rename)
-- New fields added: none (rename)
-- Denormalization justifications: none (rename)
-- Rollback: ALTER TABLE news RENAME COLUMN hero_media TO gallery_media;
--          ALTER TABLE news RENAME CONSTRAINT news_hero_media_is_array
--            TO news_gallery_media_is_array;
-- ============================================================================
--
-- Aligns vocabulary with projects.hero_media (see 20260520140000). Both
-- entities now use `hero_media` for the multi-image hero carousel. The
-- column was added one cycle earlier as `gallery_media` (20260520120000)
-- and is renamed before any productive data depends on the original name.

ALTER TABLE news RENAME COLUMN gallery_media TO hero_media;

ALTER TABLE news
  RENAME CONSTRAINT news_gallery_media_is_array TO news_hero_media_is_array;

NOTIFY pgrst, 'reload schema';
