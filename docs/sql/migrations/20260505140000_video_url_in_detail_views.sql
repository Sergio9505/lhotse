-- ============================================================================
-- Migration: video_url_in_detail_views
-- Principles applied: #4 (field has named consumer), #2 (detail view only, not list)
-- Consumers:
--   - coinvestment_project_details → coinvestmentProjectDetailProvider (detail)
--   - purchase_asset_details       → purchaseAssetDetailProvider (detail)
-- Co-loaded pairs:
--   [coinvestment_project_details, user_coinvestments] → disjoint on video_url ✅
--   [purchase_asset_details, user_direct_purchases]    → disjoint on video_url ✅
-- Dead fields dropped: none
-- New fields added:
--   - video_url — consumers: coinversion_detail_screen.hero,
--                             direct_purchase_detail_screen.hero,
--                             completed_detail_screen.hero
-- Denormalization justifications: none (not a list view)
-- Rollback: DROP + CREATE without video_url for each view
-- ============================================================================

-- Fix Allegro: replace HLS URL (403 + Android-incompatible) with MP4 1080p
UPDATE projects
SET video_url = 'https://vz-44710bc5-f88.b-cdn.net/71e2f166-cddf-4c26-a766-cbf62a0d7d8e/play_1080p.mp4'
WHERE id = '537e9c16-6b8b-45c5-ad24-89215c321783';

-- coinvestment_project_details: already JOINs projects — add p.video_url
CREATE OR REPLACE VIEW public.coinvestment_project_details AS
 SELECT p.id AS project_id,
    p.render_media,
    p.progress_media,
    a.surface_m2 AS asset_surface_m2,
    a.plot_m2 AS asset_plot_m2,
    a.bedrooms AS asset_bedrooms,
    a.bathrooms AS asset_bathrooms,
    a.floor AS asset_floor,
    a.orientation AS asset_orientation,
    a.views AS asset_views,
    a.terrace_m2 AS asset_terrace_m2,
    a.has_pool AS asset_has_pool,
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
    p.video_url
   FROM projects p
     LEFT JOIN assets a ON a.id = p.asset_id
     JOIN brands b ON b.id = p.brand_id
  WHERE b.business_model = 'coinvestment'::text;

ALTER VIEW public.coinvestment_project_details SET (security_invoker = true);

-- purchase_asset_details: FROM assets only. Use correlated subquery to get
-- video_url from projects (no UNIQUE constraint on projects.asset_id, so
-- a direct LEFT JOIN would risk row duplication).
CREATE OR REPLACE VIEW public.purchase_asset_details AS
 SELECT a.id AS asset_id,
    a.cadastral_reference AS asset_cadastral_reference,
    a.bedrooms AS asset_bedrooms,
    a.bathrooms AS asset_bathrooms,
    a.surface_m2 AS asset_surface_m2,
    a.plot_m2 AS asset_plot_m2,
    a.floor AS asset_floor,
    a.year_built AS asset_year_built,
    a.year_renovated AS asset_year_renovated,
    a.terrace_m2 AS asset_terrace_m2,
    a.has_pool AS asset_has_pool,
    a.parking_spots AS asset_parking_spots,
    a.storage_room AS asset_storage_room,
    a.orientation AS asset_orientation,
    a.views AS asset_views,
    a.floor_plan_url AS asset_floor_plan_url,
    a.gallery_media AS asset_gallery_media,
    a.use_light_overlay AS asset_use_light_overlay,
    (SELECT p.video_url FROM projects p WHERE p.asset_id = a.id LIMIT 1) AS video_url
   FROM assets a;

ALTER VIEW public.purchase_asset_details SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
