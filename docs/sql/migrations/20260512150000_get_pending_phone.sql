-- ============================================================================
-- Migration: get_pending_phone
-- Principles applied: #2 (SoT — auth.users.phone_change is server canonical),
--                     #3 (computed accessor, not stored duplicate)
-- Consumers: get_pending_phone() RPC → AuthRepository.getPendingPhone()
--   used by SplashScreen + LoginScreen to resume mid-OTP signup when the
--   user cleared the app between attachPhone and verifyPhoneChangeOtp.
-- Co-loaded pairs: none
-- Dead fields dropped: none
-- New fields added: none
-- Rollback: DROP FUNCTION public.get_pending_phone();
--
-- Why server-side RPC: the gotrue Dart SDK (^2.19.0) does not expose
-- auth.users.phone_change in the local User class. Persisting the pending
-- phone in SharedPreferences was rejected (does not survive device switch).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_pending_phone()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $function$
DECLARE
  v_phone_change TEXT;
  v_confirmed TIMESTAMPTZ;
BEGIN
  SELECT u.phone_change, u.phone_confirmed_at
  INTO v_phone_change, v_confirmed
  FROM auth.users u
  WHERE u.id = auth.uid();

  -- Already verified → no pending phone.
  IF v_confirmed IS NOT NULL THEN
    RETURN NULL;
  END IF;

  -- No phone change in flight.
  IF v_phone_change IS NULL OR v_phone_change = '' THEN
    RETURN NULL;
  END IF;

  RETURN v_phone_change;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_pending_phone() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_pending_phone() TO authenticated;

NOTIFY pgrst, 'reload schema';
