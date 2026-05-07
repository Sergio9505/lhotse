-- ============================================================================
-- Migration: projects_virtual_tour_url
-- Principles applied: #4 (named consumer), #2 (detail-only field, not exposed in list views)
-- Consumers:
--   - projects (table) → projectByIdProvider (detail)
--                      → lhotse_admin project-form (edit)
-- Co-loaded pairs: none (column lives on the base table only; not added to any view)
-- Dead fields dropped: none
-- New fields added:
--   - virtual_tour_url — consumer: project_detail_screen.virtual_tour_section
--                                  (Flutter app) + admin project-form (Next.js)
-- Denormalization justifications: none
-- Rollback: ALTER TABLE projects DROP COLUMN virtual_tour_url;
-- ============================================================================

ALTER TABLE public.projects
  ADD COLUMN virtual_tour_url TEXT;

COMMENT ON COLUMN public.projects.virtual_tour_url IS
  'Optional URL of an interactive virtual tour (Matterport, Panoee, Kuula, etc.). Rendered as a fullscreen WebView in the project detail screen.';

NOTIFY pgrst, 'reload schema';
