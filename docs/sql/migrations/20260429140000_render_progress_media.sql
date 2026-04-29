-- Migrate render_images and progress_images from jsonb string[] to
-- [{type:'image'|'video', url:string}] shape, consistent with gallery_media.

-- 1. Drop dependent views
DROP VIEW IF EXISTS public.projects_with_metrics;
DROP VIEW IF EXISTS public.coinvestment_project_details;

-- 2. Add new columns
ALTER TABLE projects ADD COLUMN render_media   jsonb;
ALTER TABLE projects ADD COLUMN progress_media jsonb;

-- 3. Backfill from existing string arrays
UPDATE projects
SET render_media = (
  SELECT jsonb_agg(jsonb_build_object('type', 'image', 'url', img))
  FROM jsonb_array_elements_text(render_images) AS img
)
WHERE render_images IS NOT NULL AND jsonb_array_length(render_images) > 0;

UPDATE projects
SET progress_media = (
  SELECT jsonb_agg(jsonb_build_object('type', 'image', 'url', img))
  FROM jsonb_array_elements_text(progress_images) AS img
)
WHERE progress_images IS NOT NULL AND jsonb_array_length(progress_images) > 0;

-- 4. Drop legacy columns
ALTER TABLE projects DROP COLUMN render_images;
ALTER TABLE projects DROP COLUMN progress_images;

-- 5. Recreate projects_with_metrics
CREATE VIEW public.projects_with_metrics AS
 SELECT p.id,
    p.brand_id,
    p.name,
    p.architect,
    p.image_url,
    p.tagline,
    p.description,
    p.gallery_media,
    p.is_vip,
    p.render_media,
    p.progress_media,
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

ALTER VIEW public.projects_with_metrics SET (security_invoker = true);

-- 6. Recreate coinvestment_project_details with renamed columns
CREATE VIEW public.coinvestment_project_details AS
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
    p.use_light_overlay AS project_use_light_overlay
   FROM projects p
     LEFT JOIN assets a ON a.id = p.asset_id
     JOIN brands b ON b.id = p.brand_id
  WHERE b.business_model = 'coinvestment'::text;

ALTER VIEW public.coinvestment_project_details SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
