-- ============================================================================
-- Migration: delete_my_account_rpc
-- Principles applied: #4 (consumer exists)
-- Consumers:
--   - lhotse_app: auth_repository.deleteMyAccount → store-compliant
--     "eliminar cuenta" CTA in profile_screen.
-- Co-loaded pairs: none
-- Dead fields dropped: none
-- New fields added: none (RPC only)
-- Rationale: app/play stores require in-app account deletion. Schema
--   already cascades user-side rows (user_profiles -> notifications,
--   user_requests, notification_preferences; auth.users -> documents,
--   user_onboarding, auth.sessions/identities/...) and SET NULLs the
--   four contract tables (purchase, coinvestment, fixed_income, rental
--   — see migration 20260429161455). A single DELETE FROM auth.users
--   triggered from this SECURITY DEFINER function does the full sweep.
--
-- Security model — the function can ONLY delete the calling user:
--   1. No parameters. The caller cannot pass an arbitrary user_id.
--   2. WHERE id = auth.uid(). auth.uid() reads the caller's signed JWT
--      claim; SECURITY DEFINER does not change that (the body runs with
--      owner privileges, but auth.uid() still returns the *caller*).
--      JWT is signed by GoTrue's JWT_SECRET — clients cannot forge it.
--   3. auth.uid() IS NULL (no JWT) raises 42501 — anon callers blocked.
--   4. REVOKE from PUBLIC/anon + GRANT only to `authenticated`.
--   5. SET search_path locks resolution → no function-hijacking surface.
--   An admin invoking it deletes themselves; impersonation requires
--   forging a signed JWT, which is infeasible.
--
-- Rollback:
--   DROP FUNCTION public.delete_my_account();
-- ============================================================================

CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  uid uuid := auth.uid();
BEGIN
  -- Defence in depth: a NULL auth.uid() would make the DELETE a no-op
  -- (id is NOT NULL in auth.users) — we hard-fail so the client cannot
  -- silently misinterpret a no-op as a successful deletion.
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;
  DELETE FROM auth.users WHERE id = uid;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_my_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;

COMMENT ON FUNCTION public.delete_my_account() IS
  'Self-service account deletion. Wipes auth.users for the calling user (auth.uid()); never touches other users. Downstream FKs cascade user-side rows and SET NULL on contract rows to preserve historical traceability. Store-compliance CTA in lhotse_app profile.';
