-- ============================================================================
-- Migration: user_fi_interest_metrics
-- Principles applied: #2 (request ∝ screen needs), #3 (computed > stored)
-- Consumers:
--   user_fixed_income_contracts → brandFixedIncomeContractsProvider (L2 RF list);
--     new interest_paid_to_date drives the active row's "+{cobrados}€" subtitle;
--     total_interest_earned drives the completed row's total return + subtitle.
-- Co-loaded pairs: none.
-- Dead fields dropped: none.
-- New fields added:
--   user_fixed_income_contracts.interest_paid_to_date NUMERIC — interest
--     payments already cashed (date <= CURRENT_DATE, type='interest').
--   user_fixed_income_contracts.total_interest_earned NUMERIC — lifetime
--     interest recorded on the contract (for completed rows).
-- Denormalization justifications: #3 (computed in view from fixed_income_payments).
-- Rollback: restore previous view def (see git history of this file).
-- User-scoped view touched? YES (user_fixed_income_contracts).
--   RLS isolation still holds (view is security_invoker; base table filtered by user_id).
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
    COALESCE((
      SELECT SUM(p.amount) FROM fixed_income_payments p
      WHERE p.contract_id = c.id
        AND p.type = 'interest'
        AND p.date <= CURRENT_DATE
    ), 0) AS interest_paid_to_date,
    COALESCE((
      SELECT SUM(p.amount) FROM fixed_income_payments p
      WHERE p.contract_id = c.id
        AND p.type = 'interest'
    ), 0) AS total_interest_earned,
    o.name AS offering_name,
    o.guaranteed_rate,
    o.payment_frequency,
    o.brand_id
  FROM fixed_income_contracts c
  JOIN fixed_income_offerings o ON o.id = c.offering_id;

ALTER VIEW user_fixed_income_contracts SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';

COMMIT;
