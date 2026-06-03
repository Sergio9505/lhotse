-- ============================================================================
-- Migration: documents_vehicle_and_setnull
-- Principles applied: #1 (a document/contract belongs to a vehicle — person OR
--   company — modelled once, symmetric to contracts), #4 (consumers: lhotse_app
--   investments/search via RLS; lhotse_admin document forms).
-- Domain:
--   · A contract/document vehicle is user_id OR investor_company_id. Deleting a
--     user OR a company must SET NULL the vehicle (unlink, never destroy the
--     contract/doc) → the previous "exactly one" CHECK on contracts blocked that
--     (SET NULL left both null), so it's relaxed to "at most one" (orphan
--     allowed). The app enforces "exactly one" at create/edit time (Zod).
--   · documents gains investor_company_id so investor-scope docs of a company
--     contract are visible to that company's members (RLS), mirroring contracts.
--   · documents.user_id moves CASCADE → SET NULL (deleting a user unlinks their
--     docs, consistent with contracts and with company deletion).
-- Consumers: lhotse_app documentsProvider/allUserDocumentsProvider (read via
--   RLS, no user_id filter) → members see company docs automatically; search +
--   strategy inherit. lhotse_admin document create/edit forms (vehicle picker).
-- Rollback: restore the four "<>" CHECKs; DROP documents.investor_company_id +
--   its CHECK/index; restore documents_user_id_fkey ON DELETE CASCADE; restore
--   the previous "documents readable by scope" policy. NOTIFY pgrst.
-- ============================================================================

-- 1) Relax the contract vehicle CHECK: "at most one" (allow orphan after SET NULL).
ALTER TABLE public.coinvestment_contracts
  DROP CONSTRAINT coinvestment_contracts_vehicle_chk,
  ADD CONSTRAINT coinvestment_contracts_vehicle_chk
    CHECK (NOT (user_id IS NOT NULL AND investor_company_id IS NOT NULL));
ALTER TABLE public.purchase_contracts
  DROP CONSTRAINT purchase_contracts_vehicle_chk,
  ADD CONSTRAINT purchase_contracts_vehicle_chk
    CHECK (NOT (user_id IS NOT NULL AND investor_company_id IS NOT NULL));
ALTER TABLE public.fixed_income_contracts
  DROP CONSTRAINT fixed_income_contracts_vehicle_chk,
  ADD CONSTRAINT fixed_income_contracts_vehicle_chk
    CHECK (NOT (user_id IS NOT NULL AND investor_company_id IS NOT NULL));
ALTER TABLE public.rental_contracts
  DROP CONSTRAINT rental_contracts_vehicle_chk,
  ADD CONSTRAINT rental_contracts_vehicle_chk
    CHECK (NOT (user_id IS NOT NULL AND investor_company_id IS NOT NULL));

-- 2) documents gains the company vehicle (symmetric to contracts).
ALTER TABLE public.documents
  ADD COLUMN investor_company_id uuid NULL
    REFERENCES public.investor_companies(id) ON DELETE SET NULL,
  ADD CONSTRAINT documents_investor_vehicle_chk
    CHECK (scope <> 'investor'
           OR NOT (user_id IS NOT NULL AND investor_company_id IS NOT NULL));
CREATE INDEX documents_investor_company_id_idx
  ON public.documents (investor_company_id) WHERE investor_company_id IS NOT NULL;

-- Relax the scope/FK coherence CHECK: investor docs may carry user_id OR
-- investor_company_id (or neither, once orphaned by a SET NULL). The "at most
-- one vehicle" rule lives in documents_investor_vehicle_chk; the app enforces
-- "exactly one" at create/edit time.
ALTER TABLE public.documents
  DROP CONSTRAINT documents_scope_fk_coherence,
  ADD CONSTRAINT documents_scope_fk_coherence CHECK (
    (scope = 'project' AND project_id IS NOT NULL AND asset_id IS NULL
       AND user_id IS NULL AND investor_company_id IS NULL)
    OR (scope = 'asset' AND asset_id IS NOT NULL AND project_id IS NULL
       AND user_id IS NULL AND investor_company_id IS NULL)
    OR (scope = 'investor' AND project_id IS NULL AND asset_id IS NULL)
  );

-- 3) documents.user_id: CASCADE → SET NULL (unlink, don't destroy).
ALTER TABLE public.documents
  DROP CONSTRAINT documents_user_id_fkey,
  ADD CONSTRAINT documents_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

-- 4) Widen the documents SELECT policy to honour the company vehicle.
DROP POLICY "documents readable by scope" ON public.documents;
CREATE POLICY "documents readable by scope" ON public.documents FOR SELECT USING (
  is_admin()
  OR (scope = 'investor' AND (
        user_id = auth.uid()
        OR (investor_company_id IS NOT NULL AND investor_company_id = public.auth_company_id())
  ))
  OR (scope = 'project' AND EXISTS (
        SELECT 1 FROM coinvestment_contracts cc
        WHERE cc.project_id = documents.project_id
          AND (cc.user_id = auth.uid()
               OR (cc.investor_company_id IS NOT NULL
                   AND cc.investor_company_id = public.auth_company_id()))
  ))
  OR (scope = 'asset' AND (
        EXISTS (SELECT 1 FROM purchase_contracts pc
                WHERE pc.asset_id = documents.asset_id
                  AND (pc.user_id = auth.uid()
                       OR (pc.investor_company_id IS NOT NULL
                           AND pc.investor_company_id = public.auth_company_id())))
        OR EXISTS (SELECT 1 FROM rental_contracts rc
                   WHERE rc.asset_id = documents.asset_id
                     AND (rc.user_id = auth.uid()
                          OR (rc.investor_company_id IS NOT NULL
                              AND rc.investor_company_id = public.auth_company_id())))
        OR EXISTS (SELECT 1 FROM coinvestment_contracts cc
                   JOIN projects p ON p.id = cc.project_id
                   WHERE p.asset_id = documents.asset_id
                     AND (cc.user_id = auth.uid()
                          OR (cc.investor_company_id IS NOT NULL
                              AND cc.investor_company_id = public.auth_company_id())))
  ))
);

NOTIFY pgrst, 'reload schema';
