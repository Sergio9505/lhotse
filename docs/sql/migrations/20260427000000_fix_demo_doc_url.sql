-- ============================================================================
-- Migration: fix_demo_doc_url
-- Principles applied: #4 (no speculative fields — fixes existing data only)
-- Consumers (Flutter providers reading new/changed views):
--   - documents.file_url → openSupabaseDoc util (lib/core/utils/open_supabase_doc.dart)
-- Co-loaded pairs: n/a (data UPDATE, not schema)
-- Dead fields dropped: none
-- New fields added: none
-- Denormalization justifications: n/a
-- Rollback: UPDATE documents
--          SET file_url = 'https://www.w3.org/WAI/WCAG21/Techniques/pdf/sample.pdf'
--          WHERE file_url = 'https://www.orimi.com/pdf-test.pdf';
-- ============================================================================

-- The previous demo URL (W3C WCAG21 sample PDF) returned 404 — verified via
-- curl. The W3C reorganised the WCAG content tree at some point and the file
-- moved or was removed. Replacing all 96 seed docs with a publicly stable
-- alternative so the doc preview flow (Quick Look on iOS / Intent.ACTION_VIEW
-- on Android) works end-to-end during demo.
UPDATE documents
SET file_url = 'https://www.orimi.com/pdf-test.pdf'
WHERE file_url = 'https://www.w3.org/WAI/WCAG21/Techniques/pdf/sample.pdf';
