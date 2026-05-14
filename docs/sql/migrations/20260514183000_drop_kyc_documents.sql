-- ============================================================================
-- Migration: drop_kyc_documents
-- Principles applied: #4 (no speculative storage -- KYC feature not in scope)
-- Consumers: none after this migration (kyc_provider + KycScreen + profile
--   row removed from Flutter app in same PR)
-- Co-loaded pairs: none
-- Dead fields dropped: entire table public.kyc_documents (156 rows)
-- Rollback: re-create table from migration history if KYC re-enabled
-- ============================================================================
DROP TABLE IF EXISTS public.kyc_documents;
NOTIFY pgrst, 'reload schema';
