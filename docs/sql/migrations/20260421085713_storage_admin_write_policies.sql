-- Admin write access to public content buckets (brand-assets, asset-images,
-- project-images). SELECT policies already exist for anon/authenticated;
-- here we add INSERT/UPDATE/DELETE restricted to users where public.is_admin().
--
-- Context: the admin panel (lhotse_admin) uploads images on behalf of the
-- authenticated admin via server actions that call supabase.storage.upload.
-- Without these policies the upload fails with "new row violates row-level
-- security policy for table objects".

CREATE POLICY "admins can insert brand assets"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'brand-assets' AND public.is_admin());

CREATE POLICY "admins can update brand assets"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'brand-assets' AND public.is_admin())
  WITH CHECK (bucket_id = 'brand-assets' AND public.is_admin());

CREATE POLICY "admins can delete brand assets"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'brand-assets' AND public.is_admin());


CREATE POLICY "admins can insert asset images"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'asset-images' AND public.is_admin());

CREATE POLICY "admins can update asset images"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'asset-images' AND public.is_admin())
  WITH CHECK (bucket_id = 'asset-images' AND public.is_admin());

CREATE POLICY "admins can delete asset images"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'asset-images' AND public.is_admin());


CREATE POLICY "admins can insert project images"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'project-images' AND public.is_admin());

CREATE POLICY "admins can update project images"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'project-images' AND public.is_admin())
  WITH CHECK (bucket_id = 'project-images' AND public.is_admin());

CREATE POLICY "admins can delete project images"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'project-images' AND public.is_admin());
