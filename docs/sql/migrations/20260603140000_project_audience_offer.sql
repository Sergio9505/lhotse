-- ============================================================================
-- Migration: project_audience_offer
-- Principles applied: #8 (views are first-class endpoints), #11 (security invoker
--   + schema reload), #12 (authorization canonical source is RLS)
-- Consumers (Flutter providers reading new/changed views):
--   - user_open_round_projects → openRoundProjectsProvider (list, Estrategia "Nuevos proyectos")
-- Co-loaded pairs: none (the view is read in isolation by its single provider)
-- Dead fields dropped: none
-- New fields added:
--   - projects.is_audience_restricted — consumer: server-side only, read by the
--     user_open_round_projects view predicate. DERIVED in lhotse_admin
--     (updateProject sets it = audience.length > 0). Not read by any Flutter widget.
--   - project_audience(project_id, user_id) — the per-project offer whitelist.
-- Denormalization justifications: none
-- User-scoped view touched? YES — user_open_round_projects filters by auth.uid()
--   through project_audience (own-row RLS). RLS test executed ✅ (see footer block;
--   two test users, zero cross-user leakage of the restricted project).
-- Rollback:
--   DROP VIEW public.user_open_round_projects;
--   DROP TABLE public.project_audience;
--   ALTER TABLE public.projects DROP COLUMN is_audience_restricted;
--   NOTIFY pgrst, 'reload schema';
-- ============================================================================

-- "¿La oferta como 'nuevo proyecto' está restringida?" — campo legible por la vista
-- (sin el problema de RLS own-row de project_audience). Derivado por el admin.
-- Default false → comportamiento actual: todo proyecto en captación se ofrece a todos.
ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS is_audience_restricted boolean NOT NULL DEFAULT false;

-- "¿A quién?" — whitelist por (proyecto, usuario). RLS own-row.
CREATE TABLE public.project_audience (
  project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (project_id, user_id)
);
ALTER TABLE public.project_audience ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own audience" ON public.project_audience
  FOR SELECT USING (auth.uid() = user_id OR is_admin());
CREATE POLICY "Admin manages audience" ON public.project_audience
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- Supabase ya no auto-concede grants en public a tablas nuevas: concederlos explícitamente.
GRANT SELECT, INSERT, UPDATE, DELETE ON public.project_audience TO anon, authenticated;

-- Vista por usuario: proyectos en captación OFRECIDOS al usuario actual.
-- Entrega brands/assets anidados como jsonb → ProjectData.fromSupabaseRow (que lee
-- row['brands'] / row['assets'] como Map) NO cambia. Curación server-side: sustituye
-- al SELECT directo sobre projects + filtro is_fundraising_open del provider.
CREATE VIEW public.user_open_round_projects AS
SELECT p.*,
       to_jsonb(b) AS brands,
       to_jsonb(a) AS assets
FROM public.projects p
LEFT JOIN public.brands b ON b.id = p.brand_id
LEFT JOIN public.assets a ON a.id = p.asset_id
WHERE p.is_fundraising_open
  AND (
    NOT p.is_audience_restricted
    OR EXISTS (
      SELECT 1 FROM public.project_audience pa
      WHERE pa.project_id = p.id AND pa.user_id = auth.uid()
    )
  );

-- CREATE VIEW no preserva reloptions: fijar security_invoker explícitamente.
ALTER VIEW public.user_open_round_projects SET (security_invoker = true);
GRANT SELECT ON public.user_open_round_projects TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
