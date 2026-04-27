-- News: dejar de asociarse a una firma y de tener región propia.
--
-- Cambios:
--   - DROP brand_id (la firma deja de aplicar a las noticias).
--   - DROP region (la región se deriva del activo o proyecto asociado).
--   - ADD asset_id (FK opcional a assets) para noticias relacionadas
--     directamente con un activo, sin necesidad de proyecto.
--
-- Decisión consciente: las 10 noticias actuales tienen `region` poblada y
-- 9 tienen `brand_id`. Se acepta perder ese metadato; las que tengan
-- project_id seguirán pudiendo derivar la región desde projects.assets.
-- Las noticias independientes (sin asset ni project) sencillamente no tienen
-- localización geográfica.

ALTER TABLE public.news
  DROP CONSTRAINT IF EXISTS news_brand_id_fkey,
  DROP COLUMN IF EXISTS brand_id,
  DROP COLUMN IF EXISTS region,
  ADD COLUMN asset_id UUID NULL REFERENCES public.assets(id) ON DELETE SET NULL;

NOTIFY pgrst, 'reload schema';
