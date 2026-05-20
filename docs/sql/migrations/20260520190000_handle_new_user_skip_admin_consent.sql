-- ============================================================================
-- Migration: handle_new_user_skip_admin_consent
-- Principles applied: #4 (no speculative — only insert consent rows when
--   the client signals explicit consent via metadata)
-- Consumers:
--   - consent_log (write path via trigger) → unchanged structure
--   - onboarding_controller (Flutter) reads latest_user_consents on init
--     and shows the consent gate when terms_accepted IS false
-- Co-loaded pairs: none.
-- Dead fields dropped: none.
-- New fields added: none — only trigger body change.
-- Denormalization justifications: none.
-- Rollback: restore the previous handle_new_user body that inserted the
--   three consent_log rows unconditionally (see git history for the
--   20260520180000_consent_log.sql migration body).
-- ============================================================================
--
-- Fix: admin-created users were getting three FABRICATED consent_log
-- rows because the previous trigger inserted them unconditionally.
-- That breaks RGPD Art. 7.1 (consent must be demonstrably given by
-- the data subject). Now the trigger only inserts when the public
-- signup flow explicitly attached the document_version metadata —
-- i.e., the user pressed the checkbox. Admin-created users land with
-- zero consent rows and accept inside the onboarding flow's new
-- consent step.

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  meta_first text := NEW.raw_user_meta_data->>'first_name';
  meta_last  text := NEW.raw_user_meta_data->>'last_name';
  meta_full  text := NEW.raw_user_meta_data->>'full_name';
  meta_marketing boolean := COALESCE(
    (NEW.raw_user_meta_data->>'marketing_consent')::boolean, false
  );
  meta_doc_tc TEXT      := NEW.raw_user_meta_data->>'document_version_terms';
  meta_doc_privacy TEXT := NEW.raw_user_meta_data->>'document_version_privacy';
  meta_platform TEXT    := NEW.raw_user_meta_data->>'platform';
  meta_os TEXT          := NEW.raw_user_meta_data->>'os_version';
  meta_app TEXT         := NEW.raw_user_meta_data->>'app_version';
BEGIN
  IF meta_first IS NULL AND meta_last IS NULL AND meta_full IS NOT NULL THEN
    meta_first := SPLIT_PART(meta_full, ' ', 1);
    meta_last  := NULLIF(TRIM(SUBSTRING(meta_full FROM POSITION(' ' IN meta_full) + 1)), '');
  END IF;

  INSERT INTO public.user_profiles (id, email, phone, first_name, last_name)
  VALUES (NEW.id, NEW.email, NEW.phone, NULLIF(meta_first, ''), NULLIF(meta_last, ''));

  INSERT INTO public.notification_preferences (user_id) VALUES (NEW.id);

  -- Consent rows ONLY when the public signup explicitly attached the
  -- document_version metadata. Admin-created users (via
  -- auth.admin.createUser without consent metadata) land with zero rows
  -- and must accept inside the onboarding consent step on their first
  -- session.
  IF meta_doc_tc IS NOT NULL THEN
    INSERT INTO public.consent_log
      (user_id, consent_type, granted, document_version, platform, os_version, app_version)
    VALUES
      (NEW.id, 'terms_and_conditions', true, meta_doc_tc, meta_platform, meta_os, meta_app),
      (NEW.id, 'privacy_policy',       true, meta_doc_privacy, meta_platform, meta_os, meta_app),
      (NEW.id, 'marketing',            meta_marketing, NULL, meta_platform, meta_os, meta_app);
  END IF;

  RETURN NEW;
END;
$$;

NOTIFY pgrst, 'reload schema';
