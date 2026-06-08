-- ============================================================================
-- Migration: auth_phone_backfill_remove_ghosts
-- Type: DATA REMEDIATION (no schema/view changes)
-- Principles applied: none structural — fixes data so `auth.users.phone` (the
--   single source of truth for phone login/recovery, per ADR-63) matches the
--   mirror in `user_profiles.phone`.
-- Consumers: none new. No views or columns added/dropped. No Flutter model changes.
-- Co-loaded pairs: n/a.
-- Dead fields dropped: none. New fields added: none.
-- RLS: untouched. No policy, view or `security_invoker` change. The backfill only
--   populates `auth.users.phone`; row visibility is unaffected.
-- Rollback: data-only. The pre-image is captured in the conversation snapshot
--   (Paso 0). To reverse, re-create the 8 deleted phone-only accounts (they had
--   0 contracts and no real profile data) and clear the backfilled phones. There
--   is no automated down migration because re-issuing auth identities is manual.
--
-- Context: the admin panel created accounts writing the phone only to
--   `user_profiles.phone`, never to `auth.users.phone`. SMS password-recovery
--   (`signInWithOtp(phone:)`, default create_user=true) then failed to find the
--   account and created empty "ghost" accounts (viewer, no email, no contracts).
--   This migration (1) removes the 8 ghost accounts, (2) backfills
--   `auth.users.phone` from the profile mirror for the 45 unambiguous accounts,
--   and (3) clears the profile phone for the 5 accounts whose number collides
--   with another account (UNIQUE on auth.users.phone) so they surface in the
--   "missing phone" list for manual admin assignment.
-- ============================================================================

BEGIN;

-- ── Paso 1 — Borrar las 8 cuentas-fantasma (lista explícita de UUID) ─────────
-- ON DELETE CASCADE limpia user_profiles, user_onboarding, consent_log,
-- auth.identities, auth.sessions. Libera los 5 teléfonos que retenían.
DELETE FROM auth.users
WHERE id IN (
  'fe4e34dd-3c06-46f9-a468-ffcbb1cb420b',  -- 34695726265 → diegosole@llabe.com
  '1d86baee-5715-418c-b07e-2014d21deb1b',  -- 34635372315 → alfredo.larranaga.m@gmail.com
  '3c63b26e-3bfd-47a4-95b3-37bb95ca3a6d',  -- 34670632753 → mtorrecilla@idermumbert.com
  '64aa07aa-8655-4e1d-8d96-17604b4f4d74',  -- 34692814023 → juradofilippi@gmail.com
  '3ce607c8-6890-47b6-8017-b85f5861c6eb',  -- 34696053505 → reginavegadiaz@gmail.com
  '5a274e99-f42b-4559-b3ae-d0c8bdf00f6c',  -- 34686705412 → (sin match)
  '35e7b960-a7c0-4826-8664-9d772f45db88',  -- 34659117952 → (sin match)
  '4709bf06-c01f-4875-ad1b-5f970942810e'   -- 34620581958 → (sin match)
);

-- ── Paso 2 — Backfill auth.users.phone desde el mirror, saltando colisiones ──
-- Solo cuentas con teléfono único (no repetido en el set ni presente ya en otra
-- cuenta). No se setea phone_confirmed_at: lo confirmará el OTP del primer
-- recovery. El trigger handle_user_updated sincroniza el valor al perfil.
WITH cand AS (
  SELECT p.id, regexp_replace(p.phone, '[^0-9]', '', 'g') AS norm
  FROM public.user_profiles p
  JOIN auth.users u ON u.id = p.id
  WHERE p.email IS NOT NULL
    AND p.phone IS NOT NULL AND p.phone <> ''
    AND u.phone IS NULL
),
safe AS (
  SELECT c.id, c.norm
  FROM cand c
  WHERE (SELECT count(*) FROM cand c2 WHERE c2.norm = c.norm) = 1
    AND NOT EXISTS (SELECT 1 FROM auth.users u2 WHERE u2.phone = c.norm)
)
UPDATE auth.users u
SET phone = s.norm
FROM safe s
WHERE u.id = s.id;

-- ── Paso 2b — Limpiar el mirror de las cuentas en colisión ───────────────────
-- Tras el Paso 2, las únicas cuentas con email + perfil-phone y auth.phone NULL
-- son las colisiones. Las dejamos sin teléfono también en el perfil (consistente
-- con auth) para que aparezcan en el listado "sin móvil". El guard `u.phone IS
-- NULL` excluye por construcción cualquier cuenta con teléfono ya verificado
-- (un teléfono verificado vive en auth.users.phone, no nulo) — p.ej. la cuenta
-- admin sebascangiano@lhotse.com NO se toca.
UPDATE public.user_profiles p
SET phone = NULL
FROM auth.users u
WHERE u.id = p.id
  AND u.phone IS NULL
  AND p.email IS NOT NULL
  AND p.phone IS NOT NULL AND p.phone <> '';

COMMIT;
