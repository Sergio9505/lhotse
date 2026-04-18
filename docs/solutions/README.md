# Solutions log

Searchable record of non-obvious problems solved in this project. Purpose: when a similar problem reappears, finding the previous fix should take 30 seconds (grep by symptom) instead of rediscovering it.

## When to add an entry

After a task where any of the following was true:
- The diagnosis was non-obvious (took more than "read the error, fix the line")
- The fix touched multiple layers (DB + model + screen)
- You learned something worth NOT forgetting
- A principle in `ARCHITECTURE.md` or a rule in `CONVENTIONS.md` emerged or got reinforced

When to NOT add an entry:
- Trivial fixes (typo, single-line)
- One-off issues that won't recur
- Pure UI tweaks with no systemic lesson

## File naming

`YYYY-MM-DD-short-slug.md` — date-prefixed so `ls` shows chronologically. Slug is the problem, not the fix (so you grep for the symptom you'll remember months later).

Examples:
- `2026-04-18-coinvestment-contract-view-duplication.md`
- `2026-03-05-stale-riverpod-provider-after-logout.md`

## Template

Copy `_template.md` when adding a new entry.

## Index

The index below is hand-maintained. If this file exceeds 40 entries, switch to a script that regenerates it from frontmatter.

### 2026-04

- [2026-04-18 — Coinvestment contract view duplication](2026-04-18-coinvestment-contract-view-duplication.md) — Two co-loaded views shared identity columns; fix led to full backend architecture system (ADR-35 + ARCHITECTURE.md)
- [2026-04-18 — Redundant user_id filter masking RLS bugs](2026-04-18-rls-as-canonical-auth-source.md) — Client-side user filter was redundant with RLS and could hide broken policies; adopted pure RLS + isolation tests (ADR-36)
- [2026-04-18 — Mortgage fields leaking into L2 list view](2026-04-18-mortgage-view-split.md) — 4 tab-only fields shipped on every L2 row; split to `purchase_mortgage_details` + `has_financing` gate (ADR-35 applied)
- [2026-04-18 — Hardcoded `.select('...')` with dropped column → silent empty list](2026-04-18-hardcoded-select-strings-silent-failure.md) — L2 direct purchases rendered empty after a view refactor; sweep rule extended to cover hardcoded select strings
