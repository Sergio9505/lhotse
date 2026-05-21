-- ============================================================================
-- Migration: drop_projects_brochure_url
-- Principles applied: #4 "No speculative fields" (ARCHITECTURE.md). The
--   "DESCARGAR FOLLETO" feature has been removed from both the Flutter app
--   (project_detail_screen CTA + ProjectData.brochureUrl) and the admin
--   (project-form field + storage upload + Zod schema). The column was
--   therefore an orphan in the schema — drop it.
-- Consumers affected: only `projects_with_metrics` exposed it. No Flutter
--   provider read it from a view (the app went directly to `projects` table
--   via `projects_provider`). The admin's `lib/data/projects.ts` reads
--   `projects_with_metrics` for listings but never used `brochure_url`
--   for any list column — the view is recreated without it.
-- Co-loaded pairs: none — `projects_with_metrics` is the only view
--   referencing this column.
-- Dead fields dropped: `projects.brochure_url` (0 Flutter/admin refs after
--   this migration ships).
-- New fields added: none.
-- Denormalization justifications: none.
-- Storage cleanup: PDFs previously uploaded to
--   `public-media/projects/brochures/` remain in the bucket — orphan blobs
--   with public URLs that are no longer linked anywhere. Removing them is
--   a manual Storage operation (out of scope for this DDL migration).
-- Rollback:
--   ALTER TABLE projects ADD COLUMN brochure_url TEXT;
--   DROP VIEW projects_with_metrics;
--   -- (recreate `projects_with_metrics` with the `p.brochure_url` column
--   --  restored — see pre-drop snapshot in git history).
--   ALTER VIEW projects_with_metrics SET (security_invoker = true);
--   NOTIFY pgrst, 'reload schema';
-- ============================================================================

-- Step 1: drop the view that depends on the column.
DROP VIEW IF EXISTS projects_with_metrics;

-- Step 2: drop the column.
ALTER TABLE projects DROP COLUMN brochure_url;

-- Step 3: recreate the view without `brochure_url`. All other fields
-- preserved verbatim from the pre-drop definition.
CREATE VIEW projects_with_metrics AS
SELECT p.id,
       p.brand_id,
       p.name,
       p.architect,
       p.image_url,
       p.tagline,
       p.description,
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

-- Step 4: restore security_invoker (CREATE VIEW does not preserve reloptions).
ALTER VIEW projects_with_metrics SET (security_invoker = true);

-- Step 5: flush PostgREST schema cache.
NOTIFY pgrst, 'reload schema';
