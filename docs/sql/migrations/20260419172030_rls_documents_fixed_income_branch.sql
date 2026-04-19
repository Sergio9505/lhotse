-- ============================================================================
-- Migration: rls_documents_fixed_income_branch
-- Principles applied: #12 (RLS as canonical authorization source)
-- Consumers: documentsProvider (read-only) for L2 _RentaFijaRow docs icon.
-- Context:
--   20260419160133_fixed_income_cleanup renamed documents.model_type
--   'contract' → 'fixed_income' but left the SELECT RLS policy matching
--   only 'contract'. Result: authenticated users saw 0 rows because the
--   CASE fell through to ELSE false. This migration replaces the policy
--   with a branch for 'fixed_income' (and keeps the rest identical).
-- Rollback: DROP POLICY + recreate with 'contract' branch (see git history).
-- User-scoped view touched? No, but RLS on the documents table is touched.
--   Run docs/sql/tests/rls_user_isolation.sql to verify isolation still holds.
-- ============================================================================

BEGIN;

DROP POLICY "users can read accessible documents" ON documents;

CREATE POLICY "users can read accessible documents"
  ON documents FOR SELECT
  USING (
    CASE model_type
      WHEN 'brand' THEN (EXISTS (
        SELECT 1 FROM purchase_contracts pc
          WHERE pc.brand_id = documents.model_id AND pc.user_id = auth.uid()
        UNION ALL
        SELECT 1 FROM coinvestment_contracts cc
          JOIN projects p ON p.id = cc.project_id
          WHERE p.brand_id = documents.model_id AND cc.user_id = auth.uid()
        UNION ALL
        SELECT 1 FROM fixed_income_contracts c
          JOIN fixed_income_offerings o ON o.id = c.offering_id
          WHERE o.brand_id = documents.model_id AND c.user_id = auth.uid()
      ))
      WHEN 'project' THEN (EXISTS (
        SELECT 1 FROM coinvestment_contracts cc
          WHERE cc.project_id = documents.model_id AND cc.user_id = auth.uid()
        UNION ALL
        SELECT 1 FROM purchase_contracts pc
          JOIN assets a ON a.id = pc.asset_id
          JOIN projects proj ON proj.asset_id = a.id
          WHERE proj.id = documents.model_id AND pc.user_id = auth.uid()
      ))
      WHEN 'purchase' THEN (EXISTS (
        SELECT 1 FROM purchase_contracts pc
          WHERE pc.id = documents.model_id AND pc.user_id = auth.uid()
      ))
      WHEN 'rental' THEN (EXISTS (
        SELECT 1 FROM rental_contracts rc
          JOIN purchase_contracts pc ON pc.asset_id = rc.asset_id
          WHERE rc.id = documents.model_id AND pc.user_id = auth.uid()
      ))
      WHEN 'coinvestment' THEN (EXISTS (
        SELECT 1 FROM coinvestment_contracts cc
          WHERE cc.id = documents.model_id AND cc.user_id = auth.uid()
      ))
      WHEN 'fixed_income' THEN (EXISTS (
        SELECT 1 FROM fixed_income_contracts c
          WHERE c.id = documents.model_id AND c.user_id = auth.uid()
      ))
      WHEN 'offering' THEN true
      ELSE false
    END
  );

NOTIFY pgrst, 'reload schema';

COMMIT;
