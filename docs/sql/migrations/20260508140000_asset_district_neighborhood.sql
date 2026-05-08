-- Asset district/neighborhood: optional location refinement.
--
-- Two new optional TEXT columns on `assets` for geographic granularity below
-- city. Values are populated from the admin form via reverse geocoding
-- (Nominatim/OSM); admin may override manually. Mobile app does not consume
-- these — only `assets_with_status` (admin listing) is updated.

-- 1. New columns (nullable, no default).
ALTER TABLE assets
  ADD COLUMN district TEXT,
  ADD COLUMN neighborhood TEXT;

-- 2. Recreate assets_with_status to expose the new columns.
DROP VIEW IF EXISTS assets_with_status;

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
    district,
    neighborhood,
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

NOTIFY pgrst, 'reload schema';
