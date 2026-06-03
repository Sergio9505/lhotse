-- ============================================================================
-- Migration: investor_companies_and_user_crm_fields
-- Principles applied: #1 (single canonical source — company name + HubSpot
--   company id live ONCE in investor_companies, referenced by user_profiles
--   instead of duplicated per contact), #4 (consumer exists: lhotse_admin
--   /investor-companies CRUD + user detail company picker), #5 (one feature
--   one migration)
-- Domain note: investor_companies are the PRIVATE companies an investor
--   belongs to (their patrimonial/holding company from the HubSpot CRM export),
--   NOT the group's firms (those are `brands`, public). The Flutter app never
--   reads this table — admin-only.
-- Consumers:
--   - lhotse_admin: /investor-companies (list/create/edit/delete),
--     user detail drawer company picker (user_profiles.company_id),
--     investor import backfill.
--   - lhotse_app: none (RLS admin-only; app does not query it).
-- Co-loaded pairs: none.
-- Dead fields dropped: none.
-- New fields added:
--   · table public.investor_companies (id, name, hubspot_company_id, ts)
--   · user_profiles.postal_code — CSV "Código postal"
--   · user_profiles.province — CSV "Provincia"
--   · user_profiles.hubspot_contact_id — CSV "ID de registro - Contact"
--   · user_profiles.company_id — FK → investor_companies (the investor's company)
-- Denormalization justifications: none — investor_companies is the normalized
--   home for company data; user_profiles only keeps the FK + contact-level CRM
--   fields (postal_code, province, hubspot_contact_id).
-- Rollback:
--   ALTER TABLE public.user_profiles
--     DROP COLUMN company_id, DROP COLUMN hubspot_contact_id,
--     DROP COLUMN province, DROP COLUMN postal_code;
--   DROP TABLE public.investor_companies;
--   NOTIFY pgrst, 'reload schema';
-- ============================================================================

-- 1) The investor's company (private CRM entity, distinct from `brands`).
CREATE TABLE public.investor_companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  hubspot_company_id text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.investor_companies IS
  'Private companies an investor belongs to (patrimonial/holding/employer), sourced from the HubSpot CRM export. NOT the group firms (see brands). Admin-only; the app never reads this.';

-- One HubSpot company ↔ one row. Partial: locally-created companies may have no
-- HubSpot id and must not collide on NULL.
CREATE UNIQUE INDEX investor_companies_hubspot_company_id_key
  ON public.investor_companies (hubspot_company_id)
  WHERE hubspot_company_id IS NOT NULL;

ALTER TABLE public.investor_companies ENABLE ROW LEVEL SECURITY;

-- Admin-only and PRIVATE (unlike brands, which are public to anon/authenticated).
CREATE POLICY "Admin reads investor companies"
  ON public.investor_companies FOR SELECT
  USING (public.is_admin());

CREATE POLICY "Admin inserts investor companies"
  ON public.investor_companies FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY "Admin updates investor companies"
  ON public.investor_companies FOR UPDATE
  USING (public.is_admin());

CREATE POLICY "Admin deletes investor companies"
  ON public.investor_companies FOR DELETE
  USING (public.is_admin());

CREATE TRIGGER trg_investor_companies_updated_at
  BEFORE UPDATE ON public.investor_companies
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Table is private: grant only to authenticated (admins); RLS narrows to
-- is_admin(). NOT granted to anon — invisible to the public Data API.
GRANT SELECT, INSERT, UPDATE, DELETE ON public.investor_companies TO authenticated;

-- 2) Contact-level CRM fields + company FK on user_profiles (all nullable).
ALTER TABLE public.user_profiles
  ADD COLUMN postal_code        text NULL,
  ADD COLUMN province           text NULL,
  ADD COLUMN hubspot_contact_id text NULL,
  ADD COLUMN company_id         uuid NULL
    REFERENCES public.investor_companies(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX user_profiles_hubspot_contact_id_key
  ON public.user_profiles (hubspot_contact_id)
  WHERE hubspot_contact_id IS NOT NULL;

CREATE INDEX user_profiles_company_id_idx
  ON public.user_profiles (company_id);

NOTIFY pgrst, 'reload schema';
