-- Public bucket for mixed media (cover videos + PDF brochures) consumed by the
-- investor app. Separated from *-images buckets to keep image policies strict
-- and avoid mixing content types with different CDN/size expectations.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'public-media',
  'public-media',
  true,
  31457280, -- 30 MiB
  ARRAY['video/mp4', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE
SET public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Public read (anyone can stream the cover video / download the PDF).
DROP POLICY IF EXISTS "public can read public media" ON storage.objects;
CREATE POLICY "public can read public media"
  ON storage.objects FOR SELECT
  TO anon, authenticated
  USING (bucket_id = 'public-media');

-- Admins can write (INSERT/UPDATE/DELETE). Mirrors the pattern used for
-- project-images. Requires is_admin() helper that already exists.
DROP POLICY IF EXISTS "admins can insert public media" ON storage.objects;
CREATE POLICY "admins can insert public media"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'public-media' AND is_admin());

DROP POLICY IF EXISTS "admins can update public media" ON storage.objects;
CREATE POLICY "admins can update public media"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'public-media' AND is_admin())
  WITH CHECK (bucket_id = 'public-media' AND is_admin());

DROP POLICY IF EXISTS "admins can delete public media" ON storage.objects;
CREATE POLICY "admins can delete public media"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'public-media' AND is_admin());
