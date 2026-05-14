-- ============================================================================
-- Migration: news_subtype
-- Principles applied: #4 (consumer exists), #5 (one feature one migration),
--                     #7 (snake_case in DB)
-- Consumers:
--   - NewsItemData.subtype (lib/core/domain/news_item_data.dart) -> NewsSubtype enum
--   - NewsArchiveBody._applyFilters (excludes subtype = 'progress')
--   - lhotse_admin news form (Combobox "Subtipo")
-- Co-loaded pairs: none (column on news table; views unaffected)
-- Dead fields dropped: none
-- New fields added: news.subtype TEXT NULL -- consumer: NewsArchiveBody global
--   exclusion + admin form subtype selector
-- Design: open-ended CHECK enables future subtypes (e.g. 'milestone',
--   'commercial', 'market_update') via simple ALTER without renaming.
-- Rollback:
--   ALTER TABLE public.news DROP COLUMN subtype;
--   NOTIFY pgrst, 'reload schema';
-- ============================================================================

ALTER TABLE public.news
  ADD COLUMN subtype TEXT NULL
  CHECK (subtype IS NULL OR subtype IN ('progress'));

COMMENT ON COLUMN public.news.subtype IS
  'Optional sub-classification orthogonal to news.type. When set to ''progress'' the row is excluded from the global Noticias archive (Firmas > Noticias) and is meant to surface only inside the project L3 Avance tab. NULL = generic news (default).';

-- Backfill: 4 filas existentes con titulo "Avances del Proyecto - X" pasan a subtype = 'progress'.
UPDATE public.news
SET subtype = 'progress'
WHERE title ILIKE 'Avances del Proyecto%';

NOTIFY pgrst, 'reload schema';
