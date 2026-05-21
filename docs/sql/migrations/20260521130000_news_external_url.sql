-- ============================================================================
-- Migration: news_external_url
-- Principles applied: #7 (column naming en snake_case, English)
-- Consumers: news → newsProvider, newsByIdProvider (auto via `*`), and
--   NewsDetailScreen's bottom CTA.
-- Co-loaded pairs: none — `external_url` is a simple text field, no view
--   needs recreating.
-- Dead fields dropped: none
-- New fields added: news.external_url — consumer: NewsDetailScreen CTA.
--   When `project_id IS NULL`, the CTA at the bottom of the news detail
--   opens this URL embedded in-app via `flutter_inappwebview` inside
--   `EmbeddedWebViewScreen` (same pattern used for terms / privacy /
--   support legal pages). When `project_id` is set, the CTA navigates to
--   the project detail and this field is ignored.
-- Denormalization justifications: none (simple field, no joins involved).
-- Rollback:
--   ALTER TABLE news DROP COLUMN external_url;
-- ============================================================================

ALTER TABLE news ADD COLUMN external_url TEXT NULL;

COMMENT ON COLUMN news.external_url IS
'URL externa del artículo original (e.g. World of Interiors, AD, T Magazine). '
'Se renderiza embebida en la app vía flutter_inappwebview (no abre Safari). '
'Sólo la usa el CTA del NewsDetailScreen cuando project_id IS NULL.';

NOTIFY pgrst, 'reload schema';
