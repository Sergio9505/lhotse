-- ============================================================================
-- Migration: project_content_blocks
-- Principles applied:
--   #2 "Request size ∝ screen needs" — `content` is detail-only, never exposed
--      in `projects_with_metrics` (list path).
--   #4 "No speculative fields" — `content` has a named consumer the same PR:
--      `ProjectContentRenderer` in `project_detail_screen.dart`.
--   ADR-71 precedent — JSONB for ordered display content (matches `hero_media`,
--      `gallery_media`, `render_media`).
-- Consumers:
--   - projects (table, SELECT *) → projectsProvider (detail) — reads `content`.
--   - projects_with_metrics (recreated) → lhotse_admin projects listing —
--     does NOT include `content` (detail-only); `description` removed.
-- Co-loaded pairs: `projects_with_metrics` is the only view referencing the
--   projects table. No new co-loaded views.
-- Dead fields dropped: `projects.description` (migrated to a single `text`
--   block inside `content`; grep verified — only consumers are the Dart model
--   + project_detail_screen render + projects_archive_body search haystack;
--   all three updated in the same PR).
-- New fields added:
--   `projects.content jsonb` — consumer: project_detail_screen.body via
--   ProjectContentRenderer. 5 block types (heading/text/image/gallery/video),
--   admin-edited in lhotse_admin/projects/[id]/content.
-- Denormalization justifications: none.
-- Rollback:
--   ALTER TABLE projects ADD COLUMN description TEXT;
--   UPDATE projects SET description = (
--     SELECT string_agg(b->>'text', E'\n\n' ORDER BY ord)
--       FROM jsonb_array_elements(content) WITH ORDINALITY AS arr(b, ord)
--      WHERE b->>'type' IN ('heading', 'text')
--   );
--   DROP VIEW projects_with_metrics;
--   -- (recreate with description column — see this file's CREATE VIEW for
--   --  the post-drop snapshot; add `p.description,` before `p.is_vip,`)
--   ALTER VIEW projects_with_metrics SET (security_invoker = true);
--   ALTER TABLE projects DROP COLUMN content;
--   NOTIFY pgrst, 'reload schema';
-- ============================================================================

-- Step 1: add `content` as JSONB array (empty default — backfill in step 2).
ALTER TABLE projects
  ADD COLUMN content jsonb NOT NULL DEFAULT '[]'::jsonb;

-- Step 2: backfill — every project with a non-empty `description` gets a
-- single `text` block. Projects with NULL or whitespace-only descriptions
-- keep the empty `[]` default.
UPDATE projects
   SET content = jsonb_build_array(
                   jsonb_build_object(
                     'type', 'text',
                     'text', description
                   )
                 )
 WHERE description IS NOT NULL
   AND length(btrim(description)) > 0;

-- Step 3: assertion — no project with a non-empty description should remain
-- with an empty content array. Raises an exception if the backfill missed
-- any row, aborting the migration before destructive steps.
DO $$
DECLARE
  missed_count integer;
BEGIN
  SELECT count(*)
    INTO missed_count
    FROM projects
   WHERE description IS NOT NULL
     AND length(btrim(description)) > 0
     AND content = '[]'::jsonb;

  IF missed_count > 0 THEN
    RAISE EXCEPTION 'Backfill incomplete: % project(s) with non-empty description still have empty content', missed_count;
  END IF;
END $$;

-- Step 4: drop the view (depends on `description`).
DROP VIEW IF EXISTS projects_with_metrics;

-- Step 5: drop the old column.
ALTER TABLE projects DROP COLUMN description;

-- Step 6: recreate `projects_with_metrics` without `description`. All other
-- fields preserved verbatim from the pre-drop definition. `content` is
-- intentionally NOT exposed here — it's detail-only (principle #2).
CREATE VIEW projects_with_metrics AS
SELECT p.id,
       p.brand_id,
       p.name,
       p.architect,
       p.image_url,
       p.tagline,
       p.is_vip,
       p.created_at,
       p.updated_at,
       p.asset_id,
       p.target_capital,
       p.purchase_price,
       p.built_sqm,
       p.agency_commission,
       p.itp_amount,
       p.purchase_expenses_amount,
       p.renovation_cost,
       p.furniture_cost,
       p.other_costs,
       p.total_cost,
       p.is_delayed,
       p.is_fundraising_open,
       p.phase,
       p.construction_completed_at,
       p.video_url,
       p.use_light_overlay,
       p.hero_media,
       p.gallery_media,
       p.render_media,
       p.virtual_tour_url,
       p.virtual_tour_thumbnail_url,
       p.progress_tour_url,
       p.progress_tour_thumbnail_url,
       b.name AS brand_name,
       b.business_model AS brand_business_model,
       a.city AS asset_city,
       a.country AS asset_country,
       COALESCE((SELECT sum(cc.amount)
                   FROM coinvestment_contracts cc
                  WHERE cc.project_id = p.id
                    AND cc.status = 'signed'::text
                    AND cc.completion_date IS NULL), 0::numeric)
         + COALESCE((SELECT sum(pc.purchase_value)
                       FROM purchase_contracts pc
                      WHERE pc.asset_id = p.asset_id
                        AND pc.status = 'signed'::text
                        AND pc.sold_date IS NULL), 0::numeric)
         AS captured_amount,
       ((SELECT count(*)::integer
           FROM coinvestment_contracts cc
          WHERE cc.project_id = p.id))
         + ((SELECT count(*)::integer
               FROM purchase_contracts pc
              WHERE pc.asset_id = p.asset_id))
         AS contracts_count,
       (SELECT count(*)::integer
          FROM project_phases ph
         WHERE ph.project_id = p.id) AS phases_count,
       (SELECT count(*)::integer
          FROM project_scenarios ps
         WHERE ps.project_id = p.id) AS scenarios_count,
       GREATEST(p.updated_at,
                COALESCE((SELECT max(cc.updated_at)
                            FROM coinvestment_contracts cc
                           WHERE cc.project_id = p.id),
                         '-infinity'::timestamp with time zone),
                COALESCE((SELECT max(pc.updated_at)
                            FROM purchase_contracts pc
                           WHERE pc.asset_id = p.asset_id),
                         '-infinity'::timestamp with time zone))
         AS last_activity_at
  FROM projects p
       LEFT JOIN brands b ON b.id = p.brand_id
       LEFT JOIN assets a ON a.id = p.asset_id;

-- Step 7: restore security_invoker (CREATE VIEW does not preserve reloptions).
ALTER VIEW projects_with_metrics SET (security_invoker = true);

-- Step 8: flush PostgREST schema cache.
NOTIFY pgrst, 'reload schema';
