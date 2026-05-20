-- ============================================================================
-- Migration: latest_user_consents_self_only
-- Principles applied: #4 (no speculative — fix a real bug where the view
--   wasn't readable by the role that actually queries it)
-- Consumers:
--   - currentUserConsentsProvider (Flutter) — reads its own row to seed
--     the marketing toggle + decide the consent gate.
--   - routeAfterAuth (Flutter) — reads to decide /accept-consent vs
--     /onboarding vs /home.
-- Co-loaded pairs: none.
-- Dead fields dropped: none.
-- New fields added: none — schema of the view is unchanged.
-- Denormalization justifications: none.
-- Rollback: restore the previous view body that did `FROM auth.users u`.
--   See git history for the original 20260520180000_consent_log.sql.
-- ============================================================================
--
-- Bug fix: the previous version of this view did `FROM auth.users u` with
-- `security_invoker = true`. The `authenticated` role does NOT have
-- `SELECT` on `auth.users` (only `postgres` does — verified in
-- information_schema.role_table_grants), so when the Flutter client
-- queried the view the underlying SELECT returned 0 rows. Result: after
-- a user accepted Terms + Privacy + Marketing on /accept-consent, the
-- 3 INSERTs into consent_log succeeded but the subsequent re-read of
-- this view came back null → cliente cayó a LatestConsents.none() →
-- routeAfterAuth pensó que faltaban consents y los devolvió al gate.
-- Infinite loop.
--
-- The new version returns a single row per call, built around
-- `auth.uid()` (a SQL function, not a SELECT against auth.users) plus
-- subqueries against `consent_log`, which has an RLS policy letting
-- the user read their own rows. No `FROM auth.users` required.
--
-- Side effect: the view can only be read by an authenticated session
-- and returns only that session's row. Admin cross-user reads still
-- work directly against `consent_log` (RLS allows admins read all).

DROP VIEW IF EXISTS latest_user_consents;

CREATE VIEW latest_user_consents AS
SELECT
  auth.uid() AS user_id,
  COALESCE(
    (SELECT granted FROM consent_log c
      WHERE c.user_id = auth.uid() AND c.consent_type = 'terms_and_conditions'
      ORDER BY c.created_at DESC LIMIT 1),
    false
  ) AS terms_accepted,
  (SELECT created_at FROM consent_log c
    WHERE c.user_id = auth.uid() AND c.consent_type = 'terms_and_conditions'
    ORDER BY c.created_at DESC LIMIT 1) AS terms_accepted_at,
  COALESCE(
    (SELECT granted FROM consent_log c
      WHERE c.user_id = auth.uid() AND c.consent_type = 'privacy_policy'
      ORDER BY c.created_at DESC LIMIT 1),
    false
  ) AS privacy_accepted,
  (SELECT created_at FROM consent_log c
    WHERE c.user_id = auth.uid() AND c.consent_type = 'privacy_policy'
    ORDER BY c.created_at DESC LIMIT 1) AS privacy_accepted_at,
  COALESCE(
    (SELECT granted FROM consent_log c
      WHERE c.user_id = auth.uid() AND c.consent_type = 'marketing'
      ORDER BY c.created_at DESC LIMIT 1),
    false
  ) AS marketing_accepted,
  (SELECT created_at FROM consent_log c
    WHERE c.user_id = auth.uid() AND c.consent_type = 'marketing'
    ORDER BY c.created_at DESC LIMIT 1) AS marketing_accepted_at
WHERE auth.uid() IS NOT NULL;

ALTER VIEW latest_user_consents SET (security_invoker = true);

NOTIFY pgrst, 'reload schema';
