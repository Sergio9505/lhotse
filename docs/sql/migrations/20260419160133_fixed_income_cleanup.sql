-- ============================================================================
-- Migration: fixed_income_cleanup
-- Principles applied: #4 (no speculative fields), #7 (naming consistency)
-- Consumers:
--   documents (model_type='fixed_income') → documentsProvider reads via
--     investment_detail_screen + new doc icon in _RentaFijaRow (L2).
-- Co-loaded pairs: none.
-- Dead fields dropped:
--   fixed_income_offerings.is_capital_guaranteed (0 Flutter refs)
--   fixed_income_offerings.min_amount            (0 Flutter refs)
--   fixed_income_offerings.description           (all NULL, 0 Flutter refs)
-- Renamed: documents.model_type 'contract' → 'fixed_income' (16 rows).
--   Before: inconsistent with 'purchase' / 'coinvestment' labels used by the
--   other 2 domains. 'contract' is ambiguous across 4 contract types.
-- New fields added: none.
-- Denormalization justifications: n/a.
-- Rollback:
--   UPDATE documents SET model_type = 'contract' WHERE model_type = 'fixed_income';
--   ALTER TABLE fixed_income_offerings ADD COLUMN is_capital_guaranteed BOOLEAN NOT NULL DEFAULT false;
--   ALTER TABLE fixed_income_offerings ADD COLUMN min_amount NUMERIC;
--   ALTER TABLE fixed_income_offerings ADD COLUMN description TEXT;
-- User-scoped view touched? No (only documents table + fixed_income_offerings).
--   `is_active` is kept (reserved for admin panel filter).
-- ============================================================================

BEGIN;

-- 1) Rebuild documents.model_type CHECK to include 'fixed_income' (drop old
--    BEFORE UPDATE so the new value doesn't violate the pre-existing CHECK).
ALTER TABLE documents DROP CONSTRAINT documents_model_type_check;

UPDATE documents SET model_type = 'fixed_income' WHERE model_type = 'contract';

ALTER TABLE documents
  ADD CONSTRAINT documents_model_type_check
  CHECK (model_type IN ('brand','project','purchase','rental','coinvestment','fixed_income','offering'));

-- 2) Drop speculative columns on fixed_income_offerings
ALTER TABLE fixed_income_offerings DROP COLUMN is_capital_guaranteed;
ALTER TABLE fixed_income_offerings DROP COLUMN min_amount;
ALTER TABLE fixed_income_offerings DROP COLUMN description;

NOTIFY pgrst, 'reload schema';

COMMIT;
