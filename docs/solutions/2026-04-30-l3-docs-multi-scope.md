---
date: 2026-04-30
tags: [documents, provider, riverpod, supabase, rls, investments]
related_adrs: []
---

# L3 Docs tab shows empty even when documents exist in the DB

## Symptom
The Docs tab inside each investment detail screen (Coinversión, Compra Directa, Renta Fija, Histórico) showed no documents for an investor who had real documents uploaded to the DB. `valueOrNull ?? []` silently swallowed the empty result with no error visible.

## Diagnosis
`documentsProvider` in `lib/core/data/documents_provider.dart` only queried `scope='investor'` rows keyed by contract ID. Real documents uploaded for the associated project (`scope='project'`) and asset (`scope='asset'`) were never requested, even though the RLS policy already permitted the investor to read them. The provider was the sole point of failure — schema, RLS, and UI wiring were all correct.

## Fix
Replaced the synchronous `_scopedQuery()` helper with an async `_fetchDocuments()` that:
1. Does a PK sub-fetch on the contract table to retrieve `project_id` or `asset_id`.
2. Issues a single `.or(...)` query to `documents` combining investor + project/asset clauses in one round-trip.
3. Scope rules per type: coinversión → investor + project; compra directa → investor + asset + rental (if exists); renta fija → investor only.
Provider signature `({String type, String id})` unchanged — zero callsite changes.

Also replaced all four `valueOrNull ?? const []` call-sites with `.when(loading/error/data)` so future regressions surface immediately.

## Lesson
A provider that only queries one scope will silently omit docs of other scopes that the DB already permits. Scope logic belongs entirely inside the provider, not at the callsite.

## How to avoid next time
When adding a new document scope or investment type, update `_fetchDocuments` in `documents_provider.dart` as the single source of truth. Check `docs/CONVENTIONS.md § Data Layer` for the canonical scope map per type.
