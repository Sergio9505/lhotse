-- ============================================================================
-- Migration: news_gallery_media
-- Principles applied: #1b (list display identity — image_url stays as cover)
-- Consumers: news (no view) → newsProvider, newsByIdProvider
--   - gallery_media (new) → NewsDetailScreen hero carousel
--   - image_url (kept)  → LhotseNewsCard (feed/archive/L3 lists)
-- Co-loaded pairs: none (news has no derived views; consumed directly)
-- Dead fields dropped: none
-- New fields added: gallery_media — consumer: NewsDetailScreen.hero
-- Denormalization justifications: image_url remains as denormalized cover
--   (#1b list display identity — 5 list-row call-sites read it; spending one
--    extra column avoids forcing every list query to extract gallery_media[0]
--    server-side).
-- Rollback: ALTER TABLE news DROP COLUMN gallery_media;
-- ============================================================================
--
-- Shape mirrors assets/projects (see 20260429130000_gallery_media.sql):
--   [{ "type": "image" | "video", "url": "..." }, ...]
-- Today the news form restricts uploads to type='image', but the schema is
-- kept symmetric so a future "video carousel" extension does not require a
-- second migration. Per ADR-62 the hero gives precedence to news.video_url
-- when set, so gallery_media is purely additive for image-only news.

-- Per-element shape validation (type ∈ {image,video} + non-empty url) is
-- enforced in the application layer (zod in admin, Dart parser in app).
-- Postgres CHECK only verifies "it's a jsonb array" because per-element
-- checks require subqueries, which CHECK does not allow.
ALTER TABLE news
  ADD COLUMN gallery_media jsonb NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE news
  ADD CONSTRAINT news_gallery_media_is_array
    CHECK (jsonb_typeof(gallery_media) = 'array');

-- Backfill: existing rows with image_url → single-image gallery.
UPDATE news
   SET gallery_media = jsonb_build_array(
         jsonb_build_object('type', 'image', 'url', image_url)
       )
 WHERE image_url IS NOT NULL
   AND image_url <> ''
   AND gallery_media = '[]'::jsonb;

NOTIFY pgrst, 'reload schema';
