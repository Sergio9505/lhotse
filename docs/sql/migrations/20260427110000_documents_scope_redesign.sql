-- Migration: documents_scope_redesign
-- Replaces polymorphic (model_type, model_id) with scope + typed FKs.
-- Scopes: 'project' | 'asset' | 'investor'
-- All 96 existing rows are investor-scope contract documents and are backfilled.

BEGIN;

-- ============================================================
-- 1. Add new columns (all nullable until backfill)
-- ============================================================
ALTER TABLE public.documents
  ADD COLUMN scope text,
  ADD COLUMN project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  ADD COLUMN asset_id uuid REFERENCES public.assets(id) ON DELETE CASCADE,
  ADD COLUMN user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN related_project_id uuid REFERENCES public.projects(id) ON DELETE SET NULL,
  ADD COLUMN related_asset_id uuid REFERENCES public.assets(id) ON DELETE SET NULL,
  ADD COLUMN related_coinvestment_id uuid REFERENCES public.coinvestment_contracts(id) ON DELETE SET NULL,
  ADD COLUMN related_purchase_id uuid REFERENCES public.purchase_contracts(id) ON DELETE SET NULL,
  ADD COLUMN related_rental_id uuid REFERENCES public.rental_contracts(id) ON DELETE SET NULL,
  ADD COLUMN related_fixed_income_id uuid REFERENCES public.fixed_income_contracts(id) ON DELETE SET NULL;

-- ============================================================
-- 2. Backfill existing rows (all investor-scope)
-- ============================================================

-- coinvestment (56 rows)
UPDATE public.documents d SET
  scope = 'investor',
  user_id = c.user_id,
  related_coinvestment_id = d.model_id,
  related_project_id = c.project_id
FROM public.coinvestment_contracts c
WHERE d.model_type = 'coinvestment' AND d.model_id = c.id;

-- purchase (24 rows)
UPDATE public.documents d SET
  scope = 'investor',
  user_id = p.user_id,
  related_purchase_id = d.model_id,
  related_asset_id = p.asset_id
FROM public.purchase_contracts p
WHERE d.model_type = 'purchase' AND d.model_id = p.id;

-- fixed_income (16 rows)
UPDATE public.documents d SET
  scope = 'investor',
  user_id = f.user_id,
  related_fixed_income_id = d.model_id
FROM public.fixed_income_contracts f
WHERE d.model_type = 'fixed_income' AND d.model_id = f.id;

-- ============================================================
-- 3. Make scope NOT NULL and add CHECK constraints
-- ============================================================
ALTER TABLE public.documents
  ALTER COLUMN scope SET NOT NULL,
  ADD CONSTRAINT documents_scope_values CHECK (
    scope IN ('project', 'asset', 'investor')
  ),
  ADD CONSTRAINT documents_scope_fk_coherence CHECK (
    (scope = 'project'  AND project_id IS NOT NULL AND asset_id  IS NULL AND user_id IS NULL)
    OR (scope = 'asset' AND asset_id   IS NOT NULL AND project_id IS NULL AND user_id IS NULL)
    OR (scope = 'investor' AND user_id IS NOT NULL AND project_id IS NULL AND asset_id IS NULL)
  ),
  ADD CONSTRAINT documents_related_only_for_investor CHECK (
    scope = 'investor'
    OR (
      related_project_id IS NULL AND related_asset_id IS NULL
      AND related_coinvestment_id IS NULL AND related_purchase_id IS NULL
      AND related_rental_id IS NULL AND related_fixed_income_id IS NULL
    )
  );

-- ============================================================
-- 4. Drop obsolete polymorphic columns
-- ============================================================
ALTER TABLE public.documents
  DROP COLUMN model_type,
  DROP COLUMN model_id;

-- ============================================================
-- 5. Indexes
-- ============================================================
CREATE INDEX idx_documents_project ON public.documents(project_id)               WHERE scope = 'project';
CREATE INDEX idx_documents_asset   ON public.documents(asset_id)                 WHERE scope = 'asset';
CREATE INDEX idx_documents_user    ON public.documents(user_id)                  WHERE scope = 'investor';
CREATE INDEX idx_documents_coinv   ON public.documents(related_coinvestment_id)  WHERE related_coinvestment_id IS NOT NULL;
CREATE INDEX idx_documents_purch   ON public.documents(related_purchase_id)      WHERE related_purchase_id     IS NOT NULL;
CREATE INDEX idx_documents_rent    ON public.documents(related_rental_id)        WHERE related_rental_id       IS NOT NULL;
CREATE INDEX idx_documents_fi      ON public.documents(related_fixed_income_id)  WHERE related_fixed_income_id IS NOT NULL;

-- ============================================================
-- 6. RLS — replace CASE-on-model_type with scope-based policy
-- ============================================================
DROP POLICY IF EXISTS "users can read accessible documents" ON public.documents;

CREATE POLICY "documents readable by scope" ON public.documents
FOR SELECT TO authenticated
USING (
  -- Investor scope: only the owner
  (scope = 'investor' AND user_id = auth.uid())

  -- Project scope: anyone with a coinvestment in that project
  OR (scope = 'project' AND EXISTS (
    SELECT 1 FROM public.coinvestment_contracts cc
    WHERE cc.project_id = documents.project_id
      AND cc.user_id = auth.uid()
  ))

  -- Asset scope: anyone with a contract on that asset
  OR (scope = 'asset' AND (
    EXISTS (
      SELECT 1 FROM public.purchase_contracts pc
      WHERE pc.asset_id = documents.asset_id AND pc.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.rental_contracts rc
      WHERE rc.asset_id = documents.asset_id AND rc.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.coinvestment_contracts cc
      JOIN public.projects p ON p.id = cc.project_id
      WHERE p.asset_id = documents.asset_id AND cc.user_id = auth.uid()
    )
  ))

  -- Admin always
  OR is_admin()
);

NOTIFY pgrst, 'reload schema';

COMMIT;
