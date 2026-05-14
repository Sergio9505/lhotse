-- ============================================================================
-- Migration: user_requests
-- Principles applied: #4 (consumer exists), #5 (one feature one migration)
-- Consumers:
--   - lhotse_app: profile_screen._PrivateBanner (vip_access),
--     investments_screen._ContactButton (invest_info)
-- Co-loaded pairs: none
-- Dead fields dropped: none
-- New fields added: entire table public.user_requests
-- Design: single table with `type` text (no CHECK -- type validation lives
--   in Dart UserRequestType enum). One row per (user, type) FOREVER via
--   full UNIQUE constraint -- re-submissions are silent no-ops; the BD
--   never holds more than n_users * |types| rows. Operators move rows
--   through status (pending -> completed | declined); the app only
--   checks existence, not status. admin_notes is operator-only and never
--   read by the Dart client.
-- Rollback:
--   DROP TABLE public.user_requests;
--   NOTIFY pgrst, 'reload schema';
-- ============================================================================

CREATE TABLE public.user_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL
    REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  type text NOT NULL,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'completed', 'declined')),
  admin_notes text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, type)
);

COMMENT ON TABLE public.user_requests IS
  'User-initiated requests captured from the app (VIP upgrade, invest info, future types). One row per (user_id, type) for the lifetime of the user -- operators move it through status; the app only checks existence.';
COMMENT ON COLUMN public.user_requests.admin_notes IS
  'Operator-only notes (calls made, emails sent, follow-up agreements). Never exposed to the end user.';

CREATE INDEX user_requests_status_type_idx
  ON public.user_requests (status, type);

ALTER TABLE public.user_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own requests"
  ON public.user_requests FOR SELECT
  USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Users insert own requests"
  ON public.user_requests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admin manages requests"
  ON public.user_requests FOR UPDATE
  USING (public.is_admin());

CREATE POLICY "Admin deletes requests"
  ON public.user_requests FOR DELETE
  USING (public.is_admin());

CREATE TRIGGER trg_user_requests_updated_at
  BEFORE UPDATE ON public.user_requests
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

NOTIFY pgrst, 'reload schema';
