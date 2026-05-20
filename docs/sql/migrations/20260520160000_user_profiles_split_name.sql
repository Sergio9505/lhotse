-- ============================================================================
-- Migration: user_profiles_split_name
-- Principles applied: #1 (single canonical source — first_name + last_name
--   become the writeable source of truth), #3 (computed > stored — full_name
--   becomes a generated column derived from the two parts)
-- Consumers:
--   - currentUserProfileProvider (UserProfile) → SignupScreen, EditProfileScreen,
--     ProfileScreen (display)
--   - admin lookups.ts / coinvestment-investors.ts / document-vinculos.ts /
--     audience-picker / investor-cell / 5+ contract forms / guard.ts /
--     timeline.ts → all READ full_name; unchanged thanks to the generated column.
-- Co-loaded pairs: none.
-- Dead fields dropped: none (full_name re-added immediately as generated).
-- New fields added:
--   · user_profiles.first_name — consumer: SignupScreen, EditProfileScreen,
--     UserCreateForm, UserProfileForm
--   · user_profiles.last_name — same consumers
--   · user_profiles.full_name (now GENERATED) — same readers as before
-- Denormalization justifications: full_name remains as a generated column to
--   keep the 10+ existing readers stable without code churn. The column is
--   computed by the DB so writers cannot drift.
-- Rollback:
--   ALTER TABLE user_profiles DROP COLUMN full_name;
--   UPDATE user_profiles SET full_name = TRIM(COALESCE(first_name,'') || ' ' || COALESCE(last_name,''));
--   ALTER TABLE user_profiles DROP COLUMN first_name, DROP COLUMN last_name;
--   -- then re-create full_name as a regular TEXT column with the original
--   -- handle_new_user() trigger that wrote it directly.
-- ============================================================================

ALTER TABLE user_profiles
  ADD COLUMN first_name TEXT,
  ADD COLUMN last_name TEXT;

-- Backfill: split full_name at the first space. Imperfect for Spanish
-- (two surnames stuck into last_name as a single string) but editable
-- afterwards.
UPDATE user_profiles
   SET first_name = NULLIF(SPLIT_PART(full_name, ' ', 1), ''),
       last_name  = NULLIF(
         TRIM(SUBSTRING(full_name FROM POSITION(' ' IN full_name) + 1)),
         ''
       )
 WHERE full_name IS NOT NULL AND full_name <> '';

-- Replace full_name with a STORED generated column. ALTER COLUMN cannot
-- convert a regular column to generated; DROP + ADD instead.
ALTER TABLE user_profiles DROP COLUMN full_name;

-- Generation expression must be IMMUTABLE — concat_ws() is STABLE, so
-- use || + COALESCE + TRIM (all IMMUTABLE) inside a CASE.
ALTER TABLE user_profiles
  ADD COLUMN full_name TEXT
    GENERATED ALWAYS AS (
      CASE
        WHEN first_name IS NULL AND last_name IS NULL THEN NULL
        ELSE NULLIF(TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')), '')
      END
    ) STORED;

-- Update the auth trigger to write first_name + last_name from the new
-- metadata keys. Falls back to splitting the legacy 'full_name' meta key
-- on the first space, so signups in flight during the deploy gap still
-- land first_name correctly.
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  meta_first text := NEW.raw_user_meta_data->>'first_name';
  meta_last  text := NEW.raw_user_meta_data->>'last_name';
  meta_full  text := NEW.raw_user_meta_data->>'full_name';
BEGIN
  IF meta_first IS NULL AND meta_last IS NULL AND meta_full IS NOT NULL THEN
    meta_first := SPLIT_PART(meta_full, ' ', 1);
    meta_last  := NULLIF(TRIM(SUBSTRING(meta_full FROM POSITION(' ' IN meta_full) + 1)), '');
  END IF;

  INSERT INTO public.user_profiles (id, email, phone, first_name, last_name)
  VALUES (
    NEW.id, NEW.email, NEW.phone,
    NULLIF(meta_first, ''),
    NULLIF(meta_last, '')
  );

  INSERT INTO public.notification_preferences (user_id) VALUES (NEW.id);

  RETURN NEW;
END;
$$;

NOTIFY pgrst, 'reload schema';
