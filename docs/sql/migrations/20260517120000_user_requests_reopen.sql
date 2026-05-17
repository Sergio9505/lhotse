-- ============================================================================
-- Migration: user_requests_reopen
-- Principles applied: #4 (consumer exists)
-- Consumers:
--   - lhotse_app: user_requests_provider (existence check + insert)
--   - lhotse_admin: app/(admin)/requests (list + edit, no code change)
-- Co-loaded pairs: none
-- Dead fields dropped: none
-- New fields added: none (constraint swap)
-- Rationale: declined rows stay as history; uniqueness now applies only to
--   active rows (pending/completed). A user whose request was declined can
--   submit again -> a new row in pending. The operator keeps the full audit
--   trail (every decline is preserved with its admin_notes).
-- Rollback:
--   DROP INDEX public.user_requests_user_id_type_active_uniq;
--   ALTER TABLE public.user_requests
--     ADD CONSTRAINT user_requests_user_id_type_key UNIQUE (user_id, type);
--   NOTIFY pgrst, 'reload schema';
-- ============================================================================

ALTER TABLE public.user_requests
  DROP CONSTRAINT user_requests_user_id_type_key;

CREATE UNIQUE INDEX user_requests_user_id_type_active_uniq
  ON public.user_requests (user_id, type)
  WHERE status <> 'declined';

NOTIFY pgrst, 'reload schema';
