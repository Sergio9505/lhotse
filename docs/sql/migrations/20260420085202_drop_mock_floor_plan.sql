-- ============================================================================
-- Migration: drop_mock_floor_plan
-- Principles applied: #4 (no speculative fields) — applied to seed content
-- Consumers: project_detail_screen.dart renders PLANO section only when
--   `project.floorPlanUrl != null`, so NULLing these rows hides PLANO without
--   breaking anything.
-- Co-loaded pairs: n/a.
-- Dead fields dropped: n/a (data-only migration).
-- New fields added: n/a.
-- Denormalization justifications: n/a.
-- Rollback: UPDATE assets SET floor_plan_url = 'assets/images/mock_floor_plan.png'
--   WHERE floor_plan_url IS NULL AND id IN (<list of the 11 asset ids if needed>);
--   (only useful if the mock file is re-added to the Flutter bundle.)
-- User-scoped view touched? No (assets is read-public).
-- Context: 11 rows pointed to an embedded bundle path. We cleared them so the
--   Flutter bundle can drop that file — content imagery belongs in DB/Storage,
--   not in the binary.
-- ============================================================================

BEGIN;

UPDATE assets
   SET floor_plan_url = NULL
 WHERE floor_plan_url = 'assets/images/mock_floor_plan.png';

COMMIT;
