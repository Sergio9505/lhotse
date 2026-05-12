-- ============================================================================
-- Migration: signup_phone_sync
-- Principles applied: #2 (single source of truth — auth.users.phone),
--                     #5 (denormalization only with sync trigger)
-- Consumers (Flutter providers reading new/changed views):
--   - user_profiles.phone → currentUserProfileProvider (Profile screen, recovery flow)
--   - auth.users.phone    → AuthRepository.sendRecoveryOtp / verifyRecoveryOtp
-- Co-loaded pairs: none (touches signup trigger only)
-- Dead fields dropped: none
-- New fields added: none (phone column already exists on user_profiles, nullable)
-- Denormalization justifications: user_profiles.phone is a read-only mirror of
--   auth.users.phone — kept here because RLS/joins target user_profiles, not
--   auth.users (#1a — readable replica synced via trigger).
-- Rollback: drop trg_handle_user_updated + handle_user_updated(); restore the
--   previous handle_new_user() body (without phone).
-- ============================================================================

-- 1) Extend handle_new_user() to copy phone from auth.users on INSERT
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  INSERT INTO public.user_profiles (id, email, phone, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.phone,
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  );

  INSERT INTO public.notification_preferences (user_id)
  VALUES (NEW.id);

  INSERT INTO public.kyc_documents (user_id, doc_type) VALUES
    (NEW.id, 'id_passport'),
    (NEW.id, 'proof_of_address'),
    (NEW.id, 'source_of_funds'),
    (NEW.id, 'framework_agreement');

  RETURN NEW;
END;
$function$;

-- 2) Sync phone updates from auth.users → user_profiles
CREATE OR REPLACE FUNCTION public.handle_user_updated()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  -- Only act when phone changes; ignore other auth.users mutations.
  IF NEW.phone IS DISTINCT FROM OLD.phone THEN
    UPDATE public.user_profiles
    SET phone = NEW.phone
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_handle_user_updated ON auth.users;
CREATE TRIGGER trg_handle_user_updated
AFTER UPDATE ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_user_updated();

-- 3) Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
