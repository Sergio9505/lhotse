-- ============================================================================
-- Migration: projects_news_sort_order
-- Principles applied:
--   #1 "Single canonical source" — sort_order vive en la fila, junto al resto
--     de atributos editoriales del proyecto/noticia.
--   #4 "No speculative fields" — sort_order tiene 4 consumidores nombrados en
--     la misma PR: `projectsProvider`, `newsProvider`, `openRoundProjectsProvider`
--     (lecturas) y los reorder pages del admin (escritura via `reorderProjects`,
--     `reorderNews`).
--   Precedent: brands.sort_order (ADR del reorder de brands), project_phases.sort_order,
--     project_scenarios.sort_order, home_feed_items.sort_order. El patrón ya está
--     establecido — añadir esta columna es replicar la convención.
-- Consumers:
--   - projects (table, SELECT *) → projectsProvider, openRoundProjectsProvider
--     (detail+list) — orden primario.
--   - projects_with_metrics (recreated) → admin /projects list + /projects/reorder.
--   - news (table, SELECT *) → newsProvider (list) — orden primario.
-- Co-loaded pairs:
--   - projects ↔ projects_with_metrics → ambos exponen sort_order. Disjoint
--     verificado: el resto de campos siguen su política previa (#2 detail-only
--     fields no se exponen en metrics; sort_order es identidad de orden, no
--     detalle).
-- Dead fields dropped: none.
-- New fields added:
--   `projects.sort_order INT NOT NULL DEFAULT 0` — consumer:
--     projectsProvider.order, /projects/reorder admin page.
--   `news.sort_order INT NOT NULL DEFAULT 0` — consumer: newsProvider.order,
--     /news/reorder admin page.
-- Backfill strategy: row_number() OVER (ORDER BY created_at DESC) × 10
--   (proyectos) / row_number() OVER (ORDER BY date DESC) × 10 (noticias).
--   Preserva el orden visible actual al usuario en el primer load tras la
--   migración. El ×10 deja huecos para slot inserts manuales en el futuro.
-- Indexes: btree(sort_order) — list ordering es el hot path.
-- Denormalization justifications: none.
-- Rollback:
--   ALTER TABLE projects DROP COLUMN sort_order;
--   ALTER TABLE news DROP COLUMN sort_order;
--   DROP INDEX IF EXISTS idx_projects_sort_order;
--   DROP INDEX IF EXISTS idx_news_sort_order;
--   DROP VIEW projects_with_metrics;
--   -- (recreate sin la línea `p.sort_order,` — copiar del archivo de la
--   --  migración 20260524120000_project_content_blocks.sql, paso 6).
--   ALTER VIEW projects_with_metrics SET (security_invoker = true);
--   NOTIFY pgrst, 'reload schema';
-- ============================================================================

-- Step 1: add sort_order columns.
ALTER TABLE projects ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;
ALTER TABLE news     ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;

-- Step 2: backfill projects, preservando el orden created_at DESC actual.
UPDATE projects p
   SET sort_order = sub.rn * 10
  FROM (SELECT id, row_number() OVER (ORDER BY created_at DESC) AS rn
          FROM projects) sub
 WHERE p.id = sub.id;

-- Step 3: backfill news, preservando el orden date DESC actual.
UPDATE news n
   SET sort_order = sub.rn * 10
  FROM (SELECT id, row_number() OVER (ORDER BY date DESC) AS rn
          FROM news) sub
 WHERE n.id = sub.id;

-- Step 4: indexes (btree, list ordering hot path).
CREATE INDEX IF NOT EXISTS idx_projects_sort_order ON projects(sort_order);
CREATE INDEX IF NOT EXISTS idx_news_sort_order     ON news(sort_order);

-- Step 5: recreate projects_with_metrics con sort_order expuesto (admin lo
-- necesita para el listado /projects + el reorder page).
DROP VIEW IF EXISTS projects_with_metrics;
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
       p.sort_order,                                            -- NEW
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

-- Step 6: restore security_invoker (CREATE VIEW no preserva reloptions).
ALTER VIEW projects_with_metrics SET (security_invoker = true);

-- Step 7: flush PostgREST schema cache.
NOTIFY pgrst, 'reload schema';
