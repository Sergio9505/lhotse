-- Coinvestment contracts: extend status to include 'completed' and derive from dates.
--
-- Status semantics (derived from dates by the admin server action; the column
-- exists for API consumers that don't want to recompute it):
--   pending   -> start_date IS NULL
--   signed    -> start_date IS NOT NULL AND completion_date IS NULL
--   completed -> completion_date IS NOT NULL
--   cancelled -> manual override; not produced by the deriver
--
-- 1. Drop the old check, add a new one that includes 'completed'.
ALTER TABLE coinvestment_contracts
  DROP CONSTRAINT chk_coinvestment_contracts_status;

ALTER TABLE coinvestment_contracts
  ADD CONSTRAINT chk_coinvestment_contracts_status
  CHECK (status IN ('pending', 'signed', 'completed', 'cancelled'));

-- 2. Default to 'pending' (a fresh row with no dates is pending).
ALTER TABLE coinvestment_contracts
  ALTER COLUMN status SET DEFAULT 'pending';

-- 3. Backfill existing rows with the derived value.
UPDATE coinvestment_contracts
SET status = CASE
  WHEN status = 'cancelled' THEN 'cancelled'
  WHEN completion_date IS NOT NULL THEN 'completed'
  WHEN start_date IS NOT NULL THEN 'signed'
  ELSE 'pending'
END;
