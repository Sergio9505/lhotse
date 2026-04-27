-- Moves `logo_on_dark_media` from home_feed_items to the source entity tables
-- (assets, projects, news, brands) and renames it to `use_light_overlay`.
--
-- Semantics: true  = render overlaid chrome (logo Lhotse, back button, etc.)
--                    in light/white on this thumbnail.
--            false = render in dark/black.
--
-- Rationale: the flag describes the thumbnail image, not the feed slot. Placing
-- it on the source table couples it to the image it describes, avoids drift when
-- thumbnails change, and lets any UI surface reuse the same signal.

ALTER TABLE public.assets   ADD COLUMN use_light_overlay boolean NOT NULL DEFAULT true;
ALTER TABLE public.projects ADD COLUMN use_light_overlay boolean NOT NULL DEFAULT true;
ALTER TABLE public.news     ADD COLUMN use_light_overlay boolean NOT NULL DEFAULT true;
ALTER TABLE public.brands   ADD COLUMN use_light_overlay boolean NOT NULL DEFAULT true;

-- Backfill from home_feed_items.logo_on_dark_media (semantically equivalent).
UPDATE public.assets   a SET use_light_overlay = h.logo_on_dark_media
  FROM public.home_feed_items h WHERE h.source_type = 'asset'   AND h.source_id = a.id;
UPDATE public.projects p SET use_light_overlay = h.logo_on_dark_media
  FROM public.home_feed_items h WHERE h.source_type = 'project' AND h.source_id = p.id;
UPDATE public.news     n SET use_light_overlay = h.logo_on_dark_media
  FROM public.home_feed_items h WHERE h.source_type = 'news'    AND h.source_id = n.id;
UPDATE public.brands   b SET use_light_overlay = h.logo_on_dark_media
  FROM public.home_feed_items h WHERE h.source_type = 'brand'   AND h.source_id = b.id;

ALTER TABLE public.home_feed_items DROP COLUMN logo_on_dark_media;

-- Admin write policies for home_feed_items (only SELECT existed before).
CREATE POLICY "admins can insert home_feed_items"
  ON public.home_feed_items FOR INSERT TO authenticated
  WITH CHECK (is_admin());

CREATE POLICY "admins can update home_feed_items"
  ON public.home_feed_items FOR UPDATE TO authenticated
  USING (is_admin());

CREATE POLICY "admins can delete home_feed_items"
  ON public.home_feed_items FOR DELETE TO authenticated
  USING (is_admin());

NOTIFY pgrst, 'reload schema';
