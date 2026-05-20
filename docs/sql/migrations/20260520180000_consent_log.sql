-- ============================================================================
-- Migration: consent_log
-- Principles applied: #1 (single canonical source — consent_log is the
--   append-only audit ledger; latest_user_consents view derives the
--   "current state"), #3 (computed > stored — current consent state is
--   computed from the log, never duplicated).
-- Consumers:
--   - consent_log (write via RPC record_consent or via trigger
--     handle_new_user) → audit / regulatory queries (admin)
--   - latest_user_consents (view) → currentUserConsentsProvider
--     (edit_profile_screen marketing toggle initial state)
-- Co-loaded pairs: none.
-- Dead fields dropped: none.
-- New fields added: tabla nueva consent_log + view nueva
--   latest_user_consents + RPC record_consent — consumers en
--   signup_screen.dart (gating + opt-in) y edit_profile_screen.dart
--   (revoke).
-- Denormalization justifications: none.
-- Rollback:
--   DROP FUNCTION record_consent(TEXT, BOOLEAN, TEXT, TEXT, TEXT, TEXT);
--   DROP VIEW latest_user_consents;
--   DROP TABLE consent_log;
--   -- restore handle_new_user to previous body (see git history).
-- ============================================================================
--
-- RGPD-grade consent log. Tabla append-only que registra cada
-- grant/revoke con dispositivo + IP + timestamp para poder demostrar
-- ante un regulador (GDPR Art. 7.1, accountability principle Art. 5.2).
-- Inserts directos bloqueados por RLS — la app escribe vía RPC
-- record_consent (que rellena ip + user_agent del request) o vía el
-- trigger handle_new_user (al crear cuenta).

CREATE TABLE public.consent_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  consent_type TEXT NOT NULL CHECK (consent_type IN (
    'terms_and_conditions', 'privacy_policy', 'marketing'
  )),
  granted BOOLEAN NOT NULL,
  document_version TEXT,
  platform TEXT,
  os_version TEXT,
  app_version TEXT,
  user_agent TEXT,
  ip_address INET,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX consent_log_user_type_created_idx
  ON consent_log (user_id, consent_type, created_at DESC);

ALTER TABLE consent_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users read own consents" ON consent_log
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "admins read all consents" ON consent_log
  FOR SELECT USING (is_admin());

-- No INSERT/UPDATE/DELETE policies — inserts solo vía SECURITY DEFINER
-- (record_consent RPC) o vía el trigger handle_new_user.

CREATE VIEW latest_user_consents AS
SELECT
  u.id AS user_id,
  COALESCE(
    (SELECT granted FROM consent_log c
      WHERE c.user_id = u.id AND c.consent_type = 'terms_and_conditions'
      ORDER BY c.created_at DESC LIMIT 1),
    false
  ) AS terms_accepted,
  (SELECT created_at FROM consent_log c
    WHERE c.user_id = u.id AND c.consent_type = 'terms_and_conditions'
    ORDER BY c.created_at DESC LIMIT 1) AS terms_accepted_at,
  COALESCE(
    (SELECT granted FROM consent_log c
      WHERE c.user_id = u.id AND c.consent_type = 'privacy_policy'
      ORDER BY c.created_at DESC LIMIT 1),
    false
  ) AS privacy_accepted,
  (SELECT created_at FROM consent_log c
    WHERE c.user_id = u.id AND c.consent_type = 'privacy_policy'
    ORDER BY c.created_at DESC LIMIT 1) AS privacy_accepted_at,
  COALESCE(
    (SELECT granted FROM consent_log c
      WHERE c.user_id = u.id AND c.consent_type = 'marketing'
      ORDER BY c.created_at DESC LIMIT 1),
    false
  ) AS marketing_accepted,
  (SELECT created_at FROM consent_log c
    WHERE c.user_id = u.id AND c.consent_type = 'marketing'
    ORDER BY c.created_at DESC LIMIT 1) AS marketing_accepted_at
FROM auth.users u;

ALTER VIEW latest_user_consents SET (security_invoker = true);

CREATE OR REPLACE FUNCTION record_consent(
  p_consent_type TEXT,
  p_granted BOOLEAN,
  p_document_version TEXT DEFAULT NULL,
  p_platform TEXT DEFAULT NULL,
  p_os_version TEXT DEFAULT NULL,
  p_app_version TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_headers JSON;
  v_user_agent TEXT;
  v_ip TEXT;
  v_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;
  IF p_consent_type NOT IN ('terms_and_conditions','privacy_policy','marketing') THEN
    RAISE EXCEPTION 'invalid consent_type: %', p_consent_type;
  END IF;

  v_headers := current_setting('request.headers', true)::json;
  v_user_agent := v_headers->>'user-agent';
  v_ip := COALESCE(v_headers->>'x-forwarded-for', v_headers->>'x-real-ip');

  INSERT INTO consent_log (
    user_id, consent_type, granted, document_version,
    platform, os_version, app_version, user_agent, ip_address
  ) VALUES (
    v_user_id, p_consent_type, p_granted, p_document_version,
    p_platform, p_os_version, p_app_version, v_user_agent,
    CASE WHEN v_ip ~ '^[0-9a-fA-F:.]+$' THEN v_ip::inet ELSE NULL END
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

GRANT EXECUTE ON FUNCTION record_consent(TEXT, BOOLEAN, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- handle_new_user actualizado: además del INSERT en user_profiles +
-- notification_preferences, inserta los 3 consents iniciales en
-- consent_log con la metadata que envió el cliente.
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

  INSERT INTO public.consent_log
    (user_id, consent_type, granted, document_version, platform, os_version, app_version)
  VALUES
    (NEW.id, 'terms_and_conditions', true, meta_doc_tc, meta_platform, meta_os, meta_app),
    (NEW.id, 'privacy_policy',       true, meta_doc_privacy, meta_platform, meta_os, meta_app),
    (NEW.id, 'marketing',            meta_marketing, NULL, meta_platform, meta_os, meta_app);

  RETURN NEW;
END;
$$;

NOTIFY pgrst, 'reload schema';
