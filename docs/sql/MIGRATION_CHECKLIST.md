# Migration checklist

Every Supabase migration in this project begins with a header block answering these questions. The header is mandatory — it's the audit trail the `/backend-review` skill reads.

## Header template

```sql
-- ============================================================================
-- Migration: <short_slug>
-- Principles applied: #<n> (name), #<n> (name), …
-- Consumers (Flutter providers reading new/changed views):
--   - <view_name> → <providerName> (<list|detail|tab>)
-- Co-loaded pairs: [<view_a>, <view_b>] → disjoint on columns ✅
--   (cite per ARCHITECTURE.md principle #9)
-- Dead fields dropped: <col>, <col> (0 Flutter refs verified via grep)
-- New fields added: <col> — consumer: <screen.section>
-- Denormalization justifications (if any): <col> snapshot (#1a) | list identity (#1b)
-- Rollback: see <down.sql or describe reversal>
-- ============================================================================
```

## Questions every migration answers

1. **Which principles from ARCHITECTURE.md apply?** Cite by number. If none, question the need for the migration.
2. **Which Flutter providers consume these views?** If none, the migration creates an orphan (violates anti-pattern).
3. **Are there co-loaded views in the same screen?** If yes, run `audits/view_health.sql` to verify disjoint columns.
4. **Are fields being dropped?** Confirm grep in `lib/` returns zero references BEFORE the migration.
5. **Are fields being added?** Name the exact consumer (screen + section). If there's no consumer, the field is speculative (violates #4).
6. **Any duplication introduced?** Must cite #1a (immutable snapshot) or #1b (list display identity). Anything else is a violation.
7. **Rollback path?** Either a companion `down.sql` or a description of how to reverse.
8. **User-scoped view touched?** (involves `user_id` on base tables or equivalent). If yes: run `docs/sql/tests/rls_user_isolation.sql` against staging with two test users and assert zero leakage. The header must include `RLS test executed ✅`. See ADR-36.

## Pre-flight commands

Before `apply_migration`:

```sql
-- Check current columns for the views you're about to modify
SELECT column_name FROM information_schema.columns
WHERE table_name = '<view_name>' ORDER BY ordinal_position;

-- Check co-loaded overlaps
\i docs/sql/audits/view_health.sql

-- For each dropped field, verify zero Flutter references
-- (run grep in your terminal)
```

## After `apply_migration`

1. `flutter analyze` must pass.
2. Update Dart models (remove/add fields) in the same PR.
3. Hot restart and smoke-test the affected screens.
4. If the migration changed a view co-loaded with another, run `view_health.sql` again to confirm no new overlap.

## When the checklist blocks you

Header saying "no consumer yet" = stop. Fields without consumers don't get merged. Either build the consumer in the same PR, or delay the migration.

Header saying "duplication justified by #1b" but the field isn't in a list view = stop. Challenge the justification.
