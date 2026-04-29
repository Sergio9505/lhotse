-- gallery_media: unified image+video JSONB column replacing gallery_images.
-- Shape: [{ "type": "image" | "video", "url": "..." }, ...]
-- Separate storage buckets per media type keep egress/permissions clean.
--
-- Affected views (all have security_invoker=true; preserved after DROP+CREATE):
--   assets_with_status, purchase_asset_details, projects_with_metrics

-- 1. Drop dependent views.
DROP VIEW IF EXISTS assets_with_status;
DROP VIEW IF EXISTS purchase_asset_details;
DROP VIEW IF EXISTS projects_with_metrics;

-- 2. New columns.
ALTER TABLE assets   ADD COLUMN gallery_media jsonb;
ALTER TABLE projects ADD COLUMN gallery_media jsonb;

-- 3. Backfill: gallery_images is jsonb array of strings -> [{type:'image',url}].
UPDATE assets
SET gallery_media = (
  SELECT jsonb_agg(jsonb_build_object('type', 'image', 'url', img))
  FROM jsonb_array_elements_text(gallery_images) AS img
)
WHERE gallery_images IS NOT NULL AND jsonb_array_length(gallery_images) > 0;

UPDATE projects
SET gallery_media = (
  SELECT jsonb_agg(jsonb_build_object('type', 'image', 'url', img))
  FROM jsonb_array_elements_text(gallery_images) AS img
)
WHERE gallery_images IS NOT NULL AND jsonb_array_length(gallery_images) > 0;

-- 4. Drop legacy columns.
ALTER TABLE assets   DROP COLUMN gallery_images;
ALTER TABLE projects DROP COLUMN gallery_images;

-- 5. Recreate assets_with_status (gallery_images -> gallery_media).
CREATE VIEW assets_with_status AS
 SELECT id,
    bedrooms,
    bathrooms,
    surface_m2,
    floor_plan_url,
    current_value,
    gallery_media,
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
    plot_m2,
    has_pool,
    views,
    thumbnail_image,
    cadastral_reference,
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

-- 6. Recreate purchase_asset_details (gallery_images -> gallery_media).
CREATE VIEW purchase_asset_details AS
 SELECT id AS asset_id,
    cadastral_reference AS asset_cadastral_reference,
    bedrooms AS asset_bedrooms,
    bathrooms AS asset_bathrooms,
    surface_m2 AS asset_surface_m2,
    plot_m2 AS asset_plot_m2,
    floor AS asset_floor,
    year_built AS asset_year_built,
    year_renovated AS asset_year_renovated,
    terrace_m2 AS asset_terrace_m2,
    has_pool AS asset_has_pool,
    parking_spots AS asset_parking_spots,
    storage_room AS asset_storage_room,
    orientation AS asset_orientation,
    views AS asset_views,
    floor_plan_url AS asset_floor_plan_url,
    gallery_media AS asset_gallery_media,
    use_light_overlay AS asset_use_light_overlay
   FROM assets;

ALTER VIEW purchase_asset_details SET (security_invoker = true);

-- 7. Recreate projects_with_metrics (gallery_images -> gallery_media).
CREATE VIEW projects_with_metrics AS
 SELECT p.id,
    p.brand_id,
    p.name,
    p.architect,
    p.image_url,
    p.tagline,
    p.description,
    p.gallery_media,
    p.is_vip,
    p.render_images,
    p.progress_images,
    p.created_at,
    p.updated_at,
    p.asset_id,
    p.brochure_url,
    p.is_fundraising_open,
    p.phase,
    p.construction_completed_at,
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
    b.name AS brand_name,
    b.business_model AS brand_business_model,
    a.city AS asset_city,
    a.country AS asset_country,
    (COALESCE(( SELECT sum(cc.amount) AS sum
           FROM coinvestment_contracts cc
          WHERE ((cc.project_id = p.id) AND (cc.status = 'signed'::text) AND (cc.completion_date IS NULL))), (0)::numeric) + COALESCE(( SELECT sum(pc.purchase_value) AS sum
           FROM purchase_contracts pc
          WHERE ((pc.asset_id = p.asset_id) AND (pc.status = 'signed'::text) AND (pc.sold_date IS NULL))), (0)::numeric)) AS captured_amount,
    (( SELECT (count(*))::integer AS count
           FROM coinvestment_contracts cc
          WHERE (cc.project_id = p.id)) + ( SELECT (count(*))::integer AS count
           FROM purchase_contracts pc
          WHERE (pc.asset_id = p.asset_id))) AS contracts_count,
    ( SELECT (count(*))::integer AS count
           FROM project_phases ph
          WHERE (ph.project_id = p.id)) AS phases_count,
    ( SELECT (count(*))::integer AS count
           FROM project_scenarios ps
          WHERE (ps.project_id = p.id)) AS scenarios_count,
    GREATEST(p.updated_at, COALESCE(( SELECT max(cc.updated_at) AS max
           FROM coinvestment_contracts cc
          WHERE (cc.project_id = p.id)), '-infinity'::timestamp with time zone), COALESCE(( SELECT max(pc.updated_at) AS max
           FROM purchase_contracts pc
          WHERE (pc.asset_id = p.asset_id)), '-infinity'::timestamp with time zone)) AS last_activity_at
   FROM ((projects p
     LEFT JOIN brands b ON ((b.id = p.brand_id)))
     LEFT JOIN assets a ON ((a.id = p.asset_id)));

ALTER VIEW projects_with_metrics SET (security_invoker = true);

-- 8. New video storage buckets (public, 200 MB per file, MP4 only).
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('asset-videos',   'asset-videos',   true, 209715200, ARRAY['video/mp4']),
  ('project-videos', 'project-videos', true, 209715200, ARRAY['video/mp4']);

-- 9. RLS policies for asset-videos.
CREATE POLICY "public can read asset videos"
  ON storage.objects FOR SELECT USING (bucket_id = 'asset-videos');
CREATE POLICY "admins can insert asset videos"
  ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'asset-videos' AND is_admin());
CREATE POLICY "admins can update asset videos"
  ON storage.objects FOR UPDATE USING (bucket_id = 'asset-videos' AND is_admin())
  WITH CHECK (bucket_id = 'asset-videos' AND is_admin());
CREATE POLICY "admins can delete asset videos"
  ON storage.objects FOR DELETE USING (bucket_id = 'asset-videos' AND is_admin());

-- 10. RLS policies for project-videos.
CREATE POLICY "public can read project videos"
  ON storage.objects FOR SELECT USING (bucket_id = 'project-videos');
CREATE POLICY "admins can insert project videos"
  ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'project-videos' AND is_admin());
CREATE POLICY "admins can update project videos"
  ON storage.objects FOR UPDATE USING (bucket_id = 'project-videos' AND is_admin())
  WITH CHECK (bucket_id = 'project-videos' AND is_admin());
CREATE POLICY "admins can delete project videos"
  ON storage.objects FOR DELETE USING (bucket_id = 'project-videos' AND is_admin());

NOTIFY pgrst, 'reload schema';
