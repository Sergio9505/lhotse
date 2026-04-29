-- Allow admin role to read all user_onboarding rows.
-- The existing user policy (auth.uid() = user_id) covers investors reading their own data.
-- RLS policies for the same command are combined with OR, so both coexist safely.
CREATE POLICY "admin_read_user_onboarding"
  ON public.user_onboarding
  FOR SELECT
  TO authenticated
  USING (is_admin());

NOTIFY pgrst, 'reload schema';
