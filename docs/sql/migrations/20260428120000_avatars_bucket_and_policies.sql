-- ============================================================================
-- Migration: avatars_bucket_and_policies
-- Principles applied: none (storage bucket + policies, not a DB schema change)
-- Consumers (Flutter providers reading new/changed views): none (storage only)
-- Co-loaded pairs: n/a
-- Dead fields dropped: none
-- New fields added: none
-- Denormalization justifications: n/a
-- Rollback: DROP POLICY ... / DELETE FROM storage.buckets WHERE id = 'avatars'
-- Note: retroactive versioning — bucket and policies already exist in prod
--       (created manually 2026-04-14). This migration is idempotent.
-- ============================================================================

-- Bucket: avatars (public — avatar URLs are not secret, cache-busted via ?v=)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  2097152, -- 2 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Policy: authenticated users can INSERT their own avatar
-- Path format: {uid}/avatar.jpg — foldername[1] must equal auth.uid()::text
DROP POLICY IF EXISTS "users can upload own avatar" ON storage.objects;
CREATE POLICY "users can upload own avatar"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Policy: authenticated users can UPDATE (overwrite) their own avatar
DROP POLICY IF EXISTS "users can update own avatar" ON storage.objects;
CREATE POLICY "users can update own avatar"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Policy: authenticated users can DELETE their own avatar
DROP POLICY IF EXISTS "users can delete own avatar" ON storage.objects;
CREATE POLICY "users can delete own avatar"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Public read: anyone can read avatars (bucket is public, but explicit policy
-- keeps the intent documented and survives bucket privacy setting changes)
DROP POLICY IF EXISTS "avatars are publicly readable" ON storage.objects;
CREATE POLICY "avatars are publicly readable"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'avatars');
