-- Drop unused mime_type column from documents.
--
-- Rationale: the column was never populated by the admin upload flow
-- (parseBase always wrote NULL) and the Flutter app parses but never
-- renders the field. It's pure dead weight on the schema.

ALTER TABLE documents DROP COLUMN IF EXISTS mime_type;

NOTIFY pgrst, 'reload schema';
