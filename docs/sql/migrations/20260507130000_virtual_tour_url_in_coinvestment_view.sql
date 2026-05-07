-- ============================================================================
-- Migration: virtual_tour_url_in_coinvestment_view
-- Principles applied: #4 (field has named consumer), #2 (detail view only)
-- Consumers:
--   - coinvestment_project_details → coinvestmentProjectDetailProvider (detail)
-- Co-loaded pairs:
--   [coinvestment_project_details, user_coinvestments] → disjoint on
--     virtual_tour_url ✅ (the field only exists in the detail view)
-- Dead fields dropped: none
-- New fields added:
--   - virtual_tour_url — consumer: coinversion_detail_screen.virtual_tour_section
--                                  (rendered below RENDERS, opens Panoee/
--                                   Matterport/Kuula in fullscreen WebView)
-- Denormalization justifications: none (not a list view)
-- Rollback: CREATE OR REPLACE VIEW without virtual_tour_url
-- ============================================================================

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
    p.video_url,
    p.virtual_tour_url
   FROM projects p
     LEFT JOIN assets a ON a.id = p.asset_id
     JOIN brands b ON b.id = p.brand_id
  WHERE b.business_model = 'coinvestment'::text;

-- CREATE OR REPLACE VIEW does NOT preserve reloptions; reapply security_invoker.
ALTER VIEW public.coinvestment_project_details SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
