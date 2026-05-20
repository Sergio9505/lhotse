-- ============================================================================
-- Migration: projects_tour_thumbnails
-- Principles applied: #4 (no speculative — consumer named per field)
-- Consumers:
--   - projects_with_metrics (recreated) → projectsProvider, projectByIdProvider
--     · virtual_tour_thumbnail_url → ProjectDetailScreen.VirtualTourSection
--     · progress_tour_thumbnail_url → (kept on the view for symmetry — main
--       reader of progress_tour_thumbnail_url is coinvestment_project_details)
--   - coinvestment_project_details (recreated) → coinvestmentProjectDetailsProvider
--     · virtual_tour_thumbnail_url → CoinversionDetailScreen.PROYECTO tab
--     · progress_tour_thumbnail_url → CoinversionDetailScreen.AVANCE tab
-- Co-loaded pairs: projects_with_metrics and coinvestment_project_details are
--   never co-loaded for the same screen — projects_with_metrics powers the
--   public commercial detail; coinvestment_project_details powers the L3
--   investor view. No disjoint check needed.
-- Dead fields dropped: none.
-- New fields added:
--   · projects.virtual_tour_thumbnail_url — consumer: project_detail_screen.dart
--     VirtualTourSection (fallback to image_url when null)
--   · projects.progress_tour_thumbnail_url — consumer: coinversion_detail_screen.dart
--     _AvanceTab VirtualTourSection (fallback to image_url when null)
-- Denormalization justifications: none (single-source TEXT columns on the
--   owning table).
-- Rollback:
--   ALTER TABLE projects DROP COLUMN virtual_tour_thumbnail_url,
--                        DROP COLUMN progress_tour_thumbnail_url;
--   then re-create both views from the previous definition (see git history
--   of this file's directory for the prior `_refresh.sql` migrations).
-- ============================================================================
--
-- Adds editable thumbnails for the two virtual tours per project. Each is
-- nullable; the app falls back to projects.image_url when the column is
-- null (preserves the historical behaviour and keeps all existing rows
-- working unchanged). Both `projects_with_metrics` and
-- `coinvestment_project_details` are recreated so the new columns are
-- exposed to the public API; security_invoker=true is re-applied since
-- DROP+CREATE wipes reloptions (Supabase gotcha).

ALTER TABLE projects
  ADD COLUMN virtual_tour_thumbnail_url TEXT NULL,
  ADD COLUMN progress_tour_thumbnail_url TEXT NULL;

-- 1. projects_with_metrics — add hero_media siblings.
DROP VIEW IF EXISTS projects_with_metrics;

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
    p.brochure_url,
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
    COALESCE(( SELECT sum(cc.amount) AS sum
           FROM coinvestment_contracts cc
          WHERE cc.project_id = p.id AND cc.status = 'signed'::text AND cc.completion_date IS NULL), 0::numeric) + COALESCE(( SELECT sum(pc.purchase_value) AS sum
           FROM purchase_contracts pc
          WHERE pc.asset_id = p.asset_id AND pc.status = 'signed'::text AND pc.sold_date IS NULL), 0::numeric) AS captured_amount,
    (( SELECT count(*)::integer AS count
           FROM coinvestment_contracts cc
          WHERE cc.project_id = p.id)) + (( SELECT count(*)::integer AS count
           FROM purchase_contracts pc
          WHERE pc.asset_id = p.asset_id)) AS contracts_count,
    ( SELECT count(*)::integer AS count
           FROM project_phases ph
          WHERE ph.project_id = p.id) AS phases_count,
    ( SELECT count(*)::integer AS count
           FROM project_scenarios ps
          WHERE ps.project_id = p.id) AS scenarios_count,
    GREATEST(p.updated_at, COALESCE(( SELECT max(cc.updated_at) AS max
           FROM coinvestment_contracts cc
          WHERE cc.project_id = p.id), '-infinity'::timestamp with time zone), COALESCE(( SELECT max(pc.updated_at) AS max
           FROM purchase_contracts pc
          WHERE pc.asset_id = p.asset_id), '-infinity'::timestamp with time zone)) AS last_activity_at
   FROM projects p
     LEFT JOIN brands b ON b.id = p.brand_id
     LEFT JOIN assets a ON a.id = p.asset_id;

ALTER VIEW projects_with_metrics SET (security_invoker = true);

-- 2. coinvestment_project_details — expose both thumbnails next to their
-- tour URL siblings.
DROP VIEW IF EXISTS coinvestment_project_details;

CREATE VIEW coinvestment_project_details AS
 SELECT p.id AS project_id,
    p.render_media,
    p.progress_tour_url,
    p.progress_tour_thumbnail_url,
    a.built_surface_m2 AS asset_built_surface_m2,
    a.usable_surface_m2 AS asset_usable_surface_m2,
    a.bedrooms AS asset_bedrooms,
    a.bathrooms AS asset_bathrooms,
    a.floor AS asset_floor,
    a.orientation AS asset_orientation,
    a.views AS asset_views,
    a.terrace_m2 AS asset_terrace_m2,
    a.has_elevator AS asset_has_elevator,
    a.parking_spots AS asset_parking_spots,
    a.storage_room AS asset_storage_room,
    a.year_built AS asset_year_built,
    a.year_renovated AS asset_year_renovated,
    a.cadastral_reference AS asset_cadastral_reference,
    a.floor_plan_url AS asset_floor_plan_url,
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
    p.use_light_overlay AS project_use_light_overlay,
    p.video_url,
    p.virtual_tour_url,
    p.virtual_tour_thumbnail_url
   FROM projects p
     LEFT JOIN assets a ON a.id = p.asset_id
     JOIN brands b ON b.id = p.brand_id
  WHERE b.business_model = 'coinvestment'::text;

ALTER VIEW coinvestment_project_details SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
