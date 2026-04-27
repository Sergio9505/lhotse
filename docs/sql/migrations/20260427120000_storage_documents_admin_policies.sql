-- Admin write access to the documents bucket.
-- Context: the admin panel (lhotse_admin) uploads PDFs on behalf of the
-- authenticated admin via server actions. Without these policies the upload
-- fails with "new row violates row-level security policy for table objects".
-- Mirrors the pattern of 20260421085713_storage_admin_write_policies.sql,
-- which covered brand-assets / asset-images / project-images but omitted documents.

CREATE POLICY "admins can insert documents"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'documents' AND public.is_admin());

CREATE POLICY "admins can update documents"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'documents' AND public.is_admin())
  WITH CHECK (bucket_id = 'documents' AND public.is_admin());

CREATE POLICY "admins can delete documents"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'documents' AND public.is_admin());
