-- Admin: full SELECT on the documents bucket (needed for createSignedUrl via /api/docs/sign)
CREATE POLICY "admins can read documents"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'documents' AND is_admin());

-- Users: SELECT iff the associated documents row is readable under table RLS.
-- The EXISTS runs as the calling user, so it inherits "documents readable by scope":
--   scope=investor  → user_id = auth.uid()
--   scope=project   → EXISTS coinvestment_contracts for that project
--   scope=asset     → EXISTS purchase/rental/coinvestment contracts for that asset
-- This means an investor can fetch the file iff they can read the row — no logic duplication.
CREATE POLICY "users can read accessible documents"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'documents'
    AND EXISTS (
      SELECT 1 FROM public.documents d
      WHERE d.file_url = storage.objects.name
    )
  );
