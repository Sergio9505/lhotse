-- ============================================================================
-- Migration: video_url_in_user_investment_lists
-- Principles applied: #1b (list-row display identity — video_url denormalized
--   in list view to derive the Bunny poster that identifies the row visually),
--   #4 (named consumers: _PurchaseRow, _CoinvestmentRow, _AssetRow in
--   brand_investments_screen.dart)
-- Consumers:
--   - user_coinvestments      → investmentsProvider (list, L2)
--   - user_direct_purchases   → investmentsProvider (list, L2)
-- Co-loaded pairs:
--   [user_coinvestments, coinvestment_project_details] → video_url present in
--     both. Justified by #1b: L2 needs video_url for poster identity; L3
--     needs it for the hero player. Both are legitimate, no refactor needed.
--   [user_direct_purchases, purchase_asset_details] → same justification.
-- Dead fields dropped: none
-- New fields added:
--   - video_url — consumer: brand_investments_screen (_PurchaseRow,
--                             _CoinvestmentRow, _AssetRow) via posterUrlFor
-- Denormalization justifications: video_url (#1b list-row display identity)
-- Audit before migration: view_health reported 0 views_without_security_invoker ✅
-- Rollback: DROP + CREATE without video_url for each view
-- ============================================================================

-- user_coinvestments: add p.video_url (projects already JOINed)
DROP VIEW IF EXISTS public.user_coinvestments;

CREATE VIEW public.user_coinvestments AS
 SELECT cc.id,
    cc.project_id,
    cc.amount,
    cc.start_date,
    cc.status,
    (cc.completion_date IS NOT NULL) AS is_completed,
    cc.actual_roi,
    cc.actual_tir,
    cc.total_return,
    cc.created_at,
    ps.roi_investor AS estimated_return_pct,
    ps.duration_months AS estimated_duration_months,
    p.brand_id,
        CASE
            WHEN (cc.completion_date IS NOT NULL) THEN (((EXTRACT(year FROM age((cc.completion_date)::timestamp with time zone, (cc.start_date)::timestamp with time zone)) * (12)::numeric) + EXTRACT(month FROM age((cc.completion_date)::timestamp with time zone, (cc.start_date)::timestamp with time zone))))::integer
            ELSE NULL::integer
        END AS actual_duration,
    p.name AS project_name,
    ((a.city || ', '::text) || a.country) AS project_location,
    p.image_url AS project_image_url,
    p.video_url
   FROM (((coinvestment_contracts cc
     JOIN projects p ON ((p.id = cc.project_id)))
     LEFT JOIN assets a ON ((a.id = p.asset_id)))
     LEFT JOIN LATERAL ( SELECT project_scenarios.roi_investor,
            project_scenarios.duration_months
           FROM project_scenarios
          WHERE (project_scenarios.project_id = p.id)
          ORDER BY (abs((project_scenarios.sort_order - 2))), project_scenarios.sort_order
         LIMIT 1) ps ON (true));

ALTER VIEW public.user_coinvestments SET (security_invoker = true);

-- user_direct_purchases: add video_url via correlated subquery on projects
-- (mirrors purchase_asset_details pattern — no UNIQUE constraint on
-- projects.asset_id so direct LEFT JOIN risks row duplication)
DROP VIEW IF EXISTS public.user_direct_purchases;

CREATE VIEW public.user_direct_purchases AS
 SELECT pc.id,
    pc.brand_id,
    pc.asset_id,
    pc.purchase_value,
    pc.purchase_date,
    pc.total_return,
    pc.sold_date,
    pc.status,
    pc.created_at,
    (pc.sold_date IS NOT NULL) AS is_completed,
    (m.principal IS NOT NULL) AS has_financing,
        CASE
            WHEN ((pc.total_return IS NOT NULL) AND (pc.purchase_value > (0)::numeric)) THEN round((((pc.total_return - pc.purchase_value) / pc.purchase_value) * (100)::numeric), 2)
            ELSE NULL::numeric
        END AS actual_roi,
    COALESCE((pc.purchase_value - m.principal), pc.purchase_value) AS cash_payment,
        CASE
            WHEN (pc.sold_date IS NOT NULL) THEN (((EXTRACT(year FROM age((pc.sold_date)::timestamp with time zone, (pc.purchase_date)::timestamp with time zone)) * (12)::numeric) + EXTRACT(month FROM age((pc.sold_date)::timestamp with time zone, (pc.purchase_date)::timestamp with time zone))))::integer
            ELSE NULL::integer
        END AS actual_duration,
    COALESCE(rc.yield_pct,
        CASE
            WHEN ((rc.id IS NOT NULL) AND (pc.purchase_value > (0)::numeric)) THEN round((((rc.monthly_rent * (12)::numeric) / pc.purchase_value) * (100)::numeric), 2)
            ELSE NULL::numeric
        END) AS rental_yield_pct,
    rc.monthly_rent,
    a.address AS asset_name,
    ((a.city || ', '::text) || a.country) AS asset_location,
    a.thumbnail_image AS asset_thumbnail_image,
        CASE
            WHEN ((a.current_value IS NOT NULL) AND (pc.purchase_value > (0)::numeric)) THEN round((((a.current_value - pc.purchase_value) / pc.purchase_value) * (100)::numeric), 2)
            ELSE NULL::numeric
        END AS asset_revaluation_pct,
    (SELECT p.video_url FROM projects p WHERE p.asset_id = a.id LIMIT 1) AS video_url
   FROM (((purchase_contracts pc
     JOIN assets a ON ((a.id = pc.asset_id)))
     LEFT JOIN mortgages m ON ((m.purchase_contract_id = pc.id)))
     LEFT JOIN rental_contracts rc ON (((rc.asset_id = pc.asset_id) AND (rc.is_active = true))));

ALTER VIEW public.user_direct_purchases SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
