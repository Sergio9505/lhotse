-- ============================================================================
-- View health audit — run via Supabase MCP (mcp__supabase__execute_sql)
-- Emits three tables:
--   1) views_without_security_invoker  — RLS bypass risks
--   2) column_duplications_across_views — candidates for dedup (review manually)
--   3) potentially_orphan_views         — views without a known Flutter consumer
--
-- The output is raw — interpretation lives in ARCHITECTURE.md principles.
-- `/backend-review` skill wraps this query and produces a structured report.
-- ============================================================================

-- 1) Views missing security_invoker=true (violates principle #11)
WITH view_opts AS (
    SELECT c.relname AS view_name,
           COALESCE(
               (SELECT option_value::boolean
                FROM pg_options_to_table(c.reloptions)
                WHERE option_name = 'security_invoker'),
               false) AS security_invoker
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'v'
      AND n.nspname = 'public'
)
SELECT 'views_without_security_invoker' AS check_name,
       view_name AS detail
FROM view_opts
WHERE NOT security_invoker

UNION ALL

-- 2) Columns appearing in more than one view (review each row manually;
--    justify with principle #1a/#1b or refactor)
SELECT 'column_duplications_across_views' AS check_name,
       column_name || ' → ' || string_agg(view_name, ', ' ORDER BY view_name) AS detail
FROM information_schema.view_column_usage
WHERE view_schema = 'public'
GROUP BY column_name
HAVING COUNT(DISTINCT view_name) > 1

UNION ALL

-- 3) Views whose name is not referenced anywhere.
--    Heuristic: list all public views. The backend-review skill cross-references
--    these with grep results in the Flutter `lib/` tree.
SELECT 'potentially_orphan_views' AS check_name,
       c.relname AS detail
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'v' AND n.nspname = 'public'
ORDER BY check_name, detail;
