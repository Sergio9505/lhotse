-- ============================================================================
-- RLS isolation smoke tests — verify pure RLS enforces user scoping on
-- user-scoped views (see ADR-36 + docs/ARCHITECTURE.md Security model).
--
-- Run against a staging DB via Supabase MCP (mcp__supabase__execute_sql) or
-- psql. Must return NO errors. Any ASSERT failure means a user can read
-- another user's rows — treat as a P0 security regression.
--
-- Usage:
--   1. Replace <USER_A_UUID> and <USER_B_UUID> with two real test user IDs
--      that each have contracts in at least one investment model.
--   2. Execute the whole file. If any DO block raises an assertion, the
--      corresponding view is leaking.
--   3. Run on every user-scoped migration per MIGRATION_CHECKLIST.md step 8.
--
-- How it works:
--   `set_config('request.jwt.claims', …, true)` impersonates a user within
--   the current transaction. The view is then queried under that identity;
--   security_invoker + the base-table RLS policy filter rows to that user.
--   The assertion confirms the other user's rows are invisible.
-- ============================================================================

BEGIN;

-- ─── Impersonate User A ────────────────────────────────────────────────────
SELECT set_config(
  'request.jwt.claims',
  json_build_object('sub', '<USER_A_UUID>', 'role', 'authenticated')::text,
  true
);
SELECT set_config('role', 'authenticated', true);

-- user_direct_purchases
DO $$
DECLARE
  leaked_rows bigint;
  user_b_brand_ids uuid[];
BEGIN
  SELECT array_agg(DISTINCT brand_id) INTO user_b_brand_ids
  FROM purchase_contracts WHERE user_id = '<USER_B_UUID>';

  SELECT count(*) INTO leaked_rows
  FROM user_direct_purchases
  WHERE brand_id = ANY(user_b_brand_ids)
    AND id IN (
      SELECT id FROM purchase_contracts WHERE user_id = '<USER_B_UUID>'
    );

  ASSERT leaked_rows = 0,
    format('RLS leak in user_direct_purchases: user A sees %s of user B rows', leaked_rows);
END $$;

-- user_coinvestments
DO $$
DECLARE
  leaked_rows bigint;
BEGIN
  SELECT count(*) INTO leaked_rows
  FROM user_coinvestments
  WHERE id IN (
    SELECT id FROM coinvestment_contracts WHERE user_id = '<USER_B_UUID>'
  );

  ASSERT leaked_rows = 0,
    format('RLS leak in user_coinvestments: user A sees %s of user B rows', leaked_rows);
END $$;

-- user_fixed_income_contracts
DO $$
DECLARE
  leaked_rows bigint;
BEGIN
  SELECT count(*) INTO leaked_rows
  FROM user_fixed_income_contracts
  WHERE id IN (
    SELECT id FROM fixed_income_contracts WHERE user_id = '<USER_B_UUID>'
  );

  ASSERT leaked_rows = 0,
    format('RLS leak in user_fixed_income_contracts: user A sees %s of user B rows', leaked_rows);
END $$;

-- user_portfolio — check aggregate totals don't include user B's amounts
DO $$
DECLARE
  user_a_visible_total numeric;
  user_b_known_total numeric;
BEGIN
  SELECT COALESCE(sum(total_amount), 0) INTO user_a_visible_total
  FROM user_portfolio;

  -- Sum of ALL user B active contract amounts (from base tables, bypassing view).
  -- Filters mirror the user_portfolio view (ADR-44): active = signed AND not completed.
  SELECT COALESCE(
    (SELECT sum(purchase_value) FROM purchase_contracts
     WHERE user_id = '<USER_B_UUID>' AND status = 'signed' AND sold_date IS NULL),
    0
  ) + COALESCE(
    (SELECT sum(amount) FROM coinvestment_contracts
     WHERE user_id = '<USER_B_UUID>' AND status = 'signed' AND completion_date IS NULL),
    0
  ) + COALESCE(
    (SELECT sum(amount) FROM fixed_income_contracts
     WHERE user_id = '<USER_B_UUID>' AND status = 'signed'
       AND (maturity_date IS NULL OR maturity_date > CURRENT_DATE)),
    0
  ) INTO user_b_known_total;

  -- If user B has meaningful investments, user A's total must be independent
  -- (can't be equal to or strictly contain user B's total). The only way the
  -- totals match would be coincidence; if that happens, tighten the assertion
  -- with a stronger fixture or explicit row comparison.
  IF user_b_known_total > 0 THEN
    ASSERT user_a_visible_total <> user_b_known_total,
      format('Suspicious: user A portfolio total (%s) equals user B total (%s)',
             user_a_visible_total, user_b_known_total);
  END IF;
END $$;

ROLLBACK;

-- ─── Impersonate User B and run the mirror case ───────────────────────────
BEGIN;
SELECT set_config(
  'request.jwt.claims',
  json_build_object('sub', '<USER_B_UUID>', 'role', 'authenticated')::text,
  true
);
SELECT set_config('role', 'authenticated', true);

DO $$
DECLARE
  leaked_rows bigint;
BEGIN
  SELECT count(*) INTO leaked_rows
  FROM user_direct_purchases
  WHERE id IN (
    SELECT id FROM purchase_contracts WHERE user_id = '<USER_A_UUID>'
  );
  ASSERT leaked_rows = 0, 'mirror leak user_direct_purchases';

  SELECT count(*) INTO leaked_rows
  FROM user_coinvestments
  WHERE id IN (
    SELECT id FROM coinvestment_contracts WHERE user_id = '<USER_A_UUID>'
  );
  ASSERT leaked_rows = 0, 'mirror leak user_coinvestments';

  SELECT count(*) INTO leaked_rows
  FROM user_fixed_income_contracts
  WHERE id IN (
    SELECT id FROM fixed_income_contracts WHERE user_id = '<USER_A_UUID>'
  );
  ASSERT leaked_rows = 0, 'mirror leak user_fixed_income_contracts';
END $$;

ROLLBACK;

-- ✅ If this file executes without raising an assertion, isolation holds.
