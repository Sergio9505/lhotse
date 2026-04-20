-- ============================================================================
-- Migration: user_fi_has_documents
-- Principles applied: #2 (request ∝ screen needs), #3 (computed > stored), #8 (views as API)
-- Consumers:
--   user_fixed_income_contracts → brandFixedIncomeContractsProvider (L2 RF list);
--     new `has_documents` flag drives the conditional doc icon in _RentaFijaRow
--     without firing N per-row queries to `documents`.
-- Co-loaded pairs: none.
-- Dead fields dropped: none.
-- New fields added: user_fixed_income_contracts.has_documents BOOLEAN
--   (derived — EXISTS on documents for this contract).
-- Denormalization justifications: #3 (computed in view, not stored).
-- Rollback: restore previous view def (without has_documents).
-- User-scoped view touched? Yes (user_fixed_income_contracts).
--   RLS test can be re-run at apply time.
-- ============================================================================

BEGIN;

DROP VIEW IF EXISTS user_fixed_income_contracts;

CREATE VIEW user_fixed_income_contracts AS
  SELECT
    c.id,
    c.offering_id,
    c.amount,
    c.term_months,
    c.start_date,
    c.maturity_date,
    c.status,
    (c.maturity_date IS NOT NULL AND c.maturity_date < CURRENT_DATE) AS is_completed,
    EXISTS (
      SELECT 1 FROM documents d
      WHERE d.model_type = 'fixed_income' AND d.model_id = c.id
    ) AS has_documents,
    o.name AS offering_name,
    o.guaranteed_rate,
    o.payment_frequency,
    o.brand_id
  FROM fixed_income_contracts c
  JOIN fixed_income_offerings o ON o.id = c.offering_id;

ALTER VIEW user_fixed_income_contracts SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';

COMMIT;
