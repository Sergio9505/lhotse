-- ============================================================================
-- Migration: contract_investment_vehicle
-- Principles applied: #1 (the investment vehicle — personal vs company — is a
--   property of each contract, modelled once per contract, not duplicated on
--   the person), #4 (consumer exists: lhotse_admin contract forms + lhotse_app
--   portfolio), #5 (one feature one migration)
-- Domain: a contract is held EITHER by a natural person (user_id) OR through an
--   investor company (investor_company_id) — XOR. The same person can hold a
--   personal contract and a company-vehicle contract simultaneously. In the
--   app, a user sees their personal contracts plus the contracts of the company
--   they belong to (user_profiles.company_id), resolved entirely via RLS — the
--   user_portfolio view is security_invoker and does not filter by user itself.
-- Consumers:
--   - lhotse_admin: contract create/edit forms (vehicle selector), contract
--     lists/detail, investor_companies CRUD (address).
--   - lhotse_app: portfolio (user_portfolio / user_coinvestments views) now also
--     surfaces company-vehicle contracts to every member of that company via the
--     widened SELECT RLS policy.
-- New fields added:
--   · investor_companies.{address, city, postal_code}
--   · {coinvestment,purchase,fixed_income,rental}_contracts.investor_company_id
-- Rollback:
--   ALTER TABLE <each>_contracts DROP CONSTRAINT <each>_contracts_vehicle_chk,
--     DROP COLUMN investor_company_id;  -- + restore old SELECT policy
--   DROP FUNCTION public.auth_company_id();
--   ALTER TABLE investor_companies DROP COLUMN address, DROP COLUMN city,
--     DROP COLUMN postal_code;
--   NOTIFY pgrst, 'reload schema';
-- ============================================================================

-- 1) Company address (from the HubSpot "e" export).
ALTER TABLE public.investor_companies
  ADD COLUMN address     text NULL,
  ADD COLUMN city        text NULL,
  ADD COLUMN postal_code text NULL;

-- 2) Investment vehicle on each contract: user_id XOR investor_company_id.
--    Existing rows all have user_id set + company null → XOR holds.
ALTER TABLE public.coinvestment_contracts
  ADD COLUMN investor_company_id uuid NULL
    REFERENCES public.investor_companies(id) ON DELETE SET NULL,
  ADD CONSTRAINT coinvestment_contracts_vehicle_chk
    CHECK ((user_id IS NOT NULL) <> (investor_company_id IS NOT NULL));
CREATE INDEX coinvestment_contracts_investor_company_id_idx
  ON public.coinvestment_contracts (investor_company_id);

ALTER TABLE public.purchase_contracts
  ADD COLUMN investor_company_id uuid NULL
    REFERENCES public.investor_companies(id) ON DELETE SET NULL,
  ADD CONSTRAINT purchase_contracts_vehicle_chk
    CHECK ((user_id IS NOT NULL) <> (investor_company_id IS NOT NULL));
CREATE INDEX purchase_contracts_investor_company_id_idx
  ON public.purchase_contracts (investor_company_id);

ALTER TABLE public.fixed_income_contracts
  ADD COLUMN investor_company_id uuid NULL
    REFERENCES public.investor_companies(id) ON DELETE SET NULL,
  ADD CONSTRAINT fixed_income_contracts_vehicle_chk
    CHECK ((user_id IS NOT NULL) <> (investor_company_id IS NOT NULL));
CREATE INDEX fixed_income_contracts_investor_company_id_idx
  ON public.fixed_income_contracts (investor_company_id);

ALTER TABLE public.rental_contracts
  ADD COLUMN investor_company_id uuid NULL
    REFERENCES public.investor_companies(id) ON DELETE SET NULL,
  ADD CONSTRAINT rental_contracts_vehicle_chk
    CHECK ((user_id IS NOT NULL) <> (investor_company_id IS NOT NULL));
CREATE INDEX rental_contracts_investor_company_id_idx
  ON public.rental_contracts (investor_company_id);

-- 3) Helper: the company the current auth user belongs to. SECURITY DEFINER +
--    empty search_path to avoid RLS recursion / search_path hijacking
--    (same approach as is_admin()).
CREATE OR REPLACE FUNCTION public.auth_company_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT company_id FROM public.user_profiles WHERE id = auth.uid();
$$;

-- 4) Widen the per-user SELECT policies so members also see their company's
--    contracts. Admin ALL policies (is_admin()) are untouched.
DROP POLICY "users can read own coinvestment contracts" ON public.coinvestment_contracts;
CREATE POLICY "users can read own coinvestment contracts"
  ON public.coinvestment_contracts FOR SELECT
  USING (
    user_id = auth.uid()
    OR (investor_company_id IS NOT NULL AND investor_company_id = public.auth_company_id())
  );

DROP POLICY "users can read own purchase contracts" ON public.purchase_contracts;
CREATE POLICY "users can read own purchase contracts"
  ON public.purchase_contracts FOR SELECT
  USING (
    user_id = auth.uid()
    OR (investor_company_id IS NOT NULL AND investor_company_id = public.auth_company_id())
  );

DROP POLICY "Users read own fixed income contracts" ON public.fixed_income_contracts;
CREATE POLICY "Users read own fixed income contracts"
  ON public.fixed_income_contracts FOR SELECT
  USING (
    user_id = auth.uid()
    OR (investor_company_id IS NOT NULL AND investor_company_id = public.auth_company_id())
  );

DROP POLICY "users can read own rental contracts" ON public.rental_contracts;
CREATE POLICY "users can read own rental contracts"
  ON public.rental_contracts FOR SELECT
  USING (
    user_id = auth.uid()
    OR (investor_company_id IS NOT NULL AND investor_company_id = public.auth_company_id())
  );

NOTIFY pgrst, 'reload schema';
