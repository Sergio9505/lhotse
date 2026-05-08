-- Asset surface rename + pool→elevator.
--
-- Semantic remodel of asset.surface_* fields:
--   surface_m2 (was "useful surface") → usable_surface_m2 (data preserved)
--   plot_m2 (plot)                    → DROPPED (no equivalent in new model)
--   terrace_m2 (terrace)              → kept as-is
--   has_pool (pool)                   → renamed to has_elevator (all values were false)
--
-- New columns:
--   built_surface_m2 (built-up area)
--   usable_surface_m2 (filled from old surface_m2)
--
-- Affected views (drop + recreate, security_invoker=true preserved):
--   assets_with_status, purchase_asset_details, coinvestment_project_details

-- 1. Drop dependent views.
DROP VIEW IF EXISTS coinvestment_project_details;
DROP VIEW IF EXISTS purchase_asset_details;
DROP VIEW IF EXISTS assets_with_status;

-- 2. New columns.
ALTER TABLE assets
  ADD COLUMN built_surface_m2 NUMERIC,
  ADD COLUMN usable_surface_m2 NUMERIC;

-- 3. Preserve current "useful surface" values into the renamed slot.
UPDATE assets SET usable_surface_m2 = surface_m2 WHERE surface_m2 IS NOT NULL;

-- 4. Drop legacy columns.
ALTER TABLE assets
  DROP COLUMN surface_m2,
  DROP COLUMN plot_m2;

-- 5. Pool → elevator.
ALTER TABLE assets RENAME COLUMN has_pool TO has_elevator;

-- 6. Recreate assets_with_status.
CREATE VIEW assets_with_status AS
 SELECT id,
    bedrooms,
    bathrooms,
    built_surface_m2,
    usable_surface_m2,
    floor_plan_url,
    current_value,
    created_at,
    updated_at,
    address,
    city,
    country,
    year_built,
    floor,
    terrace_m2,
    parking_spots,
    storage_room,
    orientation,
    year_renovated,
    has_elevator,
    views,
    thumbnail_image,
    cadastral_reference,
    use_light_overlay,
    brand_id,
    gallery_media,
    (EXISTS ( SELECT 1
           FROM projects p
          WHERE (p.asset_id = a.id))) AS has_coinvestment_project,
    (EXISTS ( SELECT 1
           FROM purchase_contracts pc
          WHERE ((pc.asset_id = a.id) AND (pc.status = 'signed'::text) AND (pc.sold_date IS NULL)))) AS has_active_purchase,
    (EXISTS ( SELECT 1
           FROM purchase_contracts pc
          WHERE ((pc.asset_id = a.id) AND (pc.sold_date IS NOT NULL)))) AS is_sold,
    (EXISTS ( SELECT 1
           FROM rental_contracts rc
          WHERE ((rc.asset_id = a.id) AND (rc.is_active = true)))) AS has_active_rental
   FROM assets a;

ALTER VIEW assets_with_status SET (security_invoker = true);

-- 7. Recreate purchase_asset_details.
CREATE VIEW purchase_asset_details AS
 SELECT id AS asset_id,
    cadastral_reference AS asset_cadastral_reference,
    bedrooms AS asset_bedrooms,
    bathrooms AS asset_bathrooms,
    built_surface_m2 AS asset_built_surface_m2,
    usable_surface_m2 AS asset_usable_surface_m2,
    floor AS asset_floor,
    year_built AS asset_year_built,
    year_renovated AS asset_year_renovated,
    terrace_m2 AS asset_terrace_m2,
    has_elevator AS asset_has_elevator,
    parking_spots AS asset_parking_spots,
    storage_room AS asset_storage_room,
    orientation AS asset_orientation,
    views AS asset_views,
    floor_plan_url AS asset_floor_plan_url,
    gallery_media AS asset_gallery_media,
    use_light_overlay AS asset_use_light_overlay,
    ( SELECT p.video_url
           FROM projects p
          WHERE (p.asset_id = a.id)
         LIMIT 1) AS video_url
   FROM assets a;

ALTER VIEW purchase_asset_details SET (security_invoker = true);

-- 8. Recreate coinvestment_project_details.
CREATE VIEW coinvestment_project_details AS
 SELECT p.id AS project_id,
    p.render_media,
    p.progress_media,
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
    p.virtual_tour_url
   FROM ((projects p
     LEFT JOIN assets a ON ((a.id = p.asset_id)))
     JOIN brands b ON ((b.id = p.brand_id)))
  WHERE (b.business_model = 'coinvestment'::text);

ALTER VIEW coinvestment_project_details SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
