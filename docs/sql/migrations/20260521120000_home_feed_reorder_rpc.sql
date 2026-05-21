-- ============================================================================
-- Migration: home_feed_reorder_rpc
-- Principles applied: #1 (single canonical write path for reorder).
-- Consumers:
--   - lhotse_admin: reorderHomeFeed Server Action (drag-and-drop in /home-feed)
-- Co-loaded pairs: none
-- Dead fields dropped: none
-- New fields added: none (RPC only)
-- Rationale: the previous client-side renumber did two passes of N UPDATEs
--   each (Pass 1: temporary negatives to dodge the UNIQUE(sort_order)
--   constraint; Pass 2: final positive values). The passes were sequential
--   await calls in JS with no transactional wrapper. If Pass 2 errored or
--   the request was aborted between passes (timeout, navigation, transient
--   network error), the rows stayed permanently with negative sort_order
--   values — exactly what was observed in production (6 rows stuck at
--   -1..-6). Moving the renumber into a SECURITY DEFINER plpgsql function
--   collapses both passes into a single transaction: either both succeed
--   or both roll back; nothing can persist a negative value.
--
-- Also switches the spacing from gaps-of-10 (10, 20, 30, …) to
-- consecutive 1..N. The gap was cargo-culted from the original seed; the
-- reorder always renumbers every row (the client sends the full ordered
-- list), so the gap never bought anything. 1..N matches the visible
-- index in the admin UI.
--
-- Security model:
--   1. SECURITY DEFINER + explicit `is_admin()` check — same defence as the
--      existing RLS policies on admin-only writes. Defence in depth alongside
--      the Server Action's requireAdmin() guard.
--   2. SET search_path = public locks function resolution.
--   3. REVOKE from PUBLIC/anon + GRANT only to `authenticated`.
--
-- Rollback:
--   DROP FUNCTION public.reorder_home_feed(uuid[]);
-- ============================================================================

CREATE OR REPLACE FUNCTION public.reorder_home_feed(ordered_ids uuid[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Forbidden' USING ERRCODE = '42501';
  END IF;

  -- Pass 1: temporary negatives to dodge the UNIQUE(sort_order) constraint.
  UPDATE home_feed_items hf
  SET    sort_order = -(o.idx)::int
  FROM   unnest(ordered_ids) WITH ORDINALITY AS o(id, idx)
  WHERE  hf.id = o.id;

  -- Pass 2: final positive renumbering 1..N. Whole function runs in a
  -- single transaction, so any failure here rolls back Pass 1 too.
  UPDATE home_feed_items hf
  SET    sort_order = (o.idx)::int
  FROM   unnest(ordered_ids) WITH ORDINALITY AS o(id, idx)
  WHERE  hf.id = o.id;
END;
$$;

REVOKE ALL ON FUNCTION public.reorder_home_feed(uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reorder_home_feed(uuid[]) TO authenticated;

COMMENT ON FUNCTION public.reorder_home_feed(uuid[]) IS
  'Atomic renumber of home_feed_items.sort_order to 1..N matching the given UUID order. Admin-only (defence in depth alongside Server Action requireAdmin guard). Two UPDATEs (temporary negatives, then 1..N positives) inside a single plpgsql transaction so a mid-flight failure can never leave negative sort_order values persisted.';

NOTIFY pgrst, 'reload schema';
