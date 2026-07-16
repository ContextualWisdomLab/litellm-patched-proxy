\set ON_ERROR_STOP on

-- Run this file with psql autocommit enabled and without BEGIN/COMMIT.
-- CREATE/DROP INDEX CONCURRENTLY cannot run inside a transaction block.

-- Review the candidate counts before changing production data.
SELECT
    count(*) AS total_rows,
    count(*) FILTER (WHERE checked_at < now() - interval '30 days') AS older_than_30_days,
    count(*) FILTER (WHERE checked_at < now() - interval '60 days') AS older_than_60_days,
    count(*) FILTER (WHERE checked_at < now() - interval '90 days') AS older_than_90_days,
    min(checked_at) AS oldest_check,
    max(checked_at) AS newest_check
FROM "LiteLLM_HealthCheckTable";

-- Replace only an invalid or mismatched latest-state index. \gexec sends each
-- generated CONCURRENTLY statement separately, outside a transaction block.
SELECT format('DROP INDEX CONCURRENTLY %s;', indexrelid::regclass)
FROM pg_index
WHERE indexrelid = to_regclass('"LiteLLM_HealthCheckTable_latest_model_idx"')
  AND (
      NOT indisvalid
      OR indpred IS NOT NULL
      OR indexprs IS NOT NULL
      OR pg_get_indexdef(indexrelid) NOT LIKE
          '% USING btree (model_id, model_name, checked_at DESC, id DESC)'
  )
\gexec

SELECT $sql$
CREATE INDEX CONCURRENTLY "LiteLLM_HealthCheckTable_latest_model_idx"
ON "LiteLLM_HealthCheckTable" (model_id, model_name, checked_at DESC, id DESC);
$sql$
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_index
    WHERE indexrelid = to_regclass('"LiteLLM_HealthCheckTable_latest_model_idx"')
      AND indisvalid
      AND indpred IS NULL
      AND indexprs IS NULL
      AND pg_get_indexdef(indexrelid) LIKE
          '% USING btree (model_id, model_name, checked_at DESC, id DESC)'
)
\gexec

-- Apply the same validity and definition checks to the retention index.
SELECT format('DROP INDEX CONCURRENTLY %s;', indexrelid::regclass)
FROM pg_index
WHERE indexrelid = to_regclass('"LiteLLM_HealthCheckTable_retention_idx"')
  AND (
      NOT indisvalid
      OR indpred IS NOT NULL
      OR indexprs IS NOT NULL
      OR pg_get_indexdef(indexrelid) NOT LIKE
          '% USING btree (checked_at, id)'
  )
\gexec

SELECT $sql$
CREATE INDEX CONCURRENTLY "LiteLLM_HealthCheckTable_retention_idx"
ON "LiteLLM_HealthCheckTable" (checked_at, id);
$sql$
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_index
    WHERE indexrelid = to_regclass('"LiteLLM_HealthCheckTable_retention_idx"')
      AND indisvalid
      AND indpred IS NULL
      AND indexprs IS NULL
      AND pg_get_indexdef(indexrelid) LIKE
          '% USING btree (checked_at, id)'
)
\gexec

-- Retention template: uncomment and run one batch at a time only after approval.
-- WITH expired AS (
--     SELECT id
--     FROM "LiteLLM_HealthCheckTable"
--     WHERE checked_at < now() - interval '90 days'
--     ORDER BY checked_at, id
--     LIMIT 5000
-- )
-- DELETE FROM "LiteLLM_HealthCheckTable" AS history
-- USING expired
-- WHERE history.id = expired.id;

-- This default verification only plans the query; it does not execute it.
EXPLAIN (COSTS, VERBOSE)
SELECT DISTINCT ON (model_id, model_name)
    model_id,
    model_name,
    checked_at,
    status
FROM "LiteLLM_HealthCheckTable"
ORDER BY model_id, model_name, checked_at DESC, id DESC;

-- Optional maintenance-window verification with fresh statistics. These lines
-- execute work and must remain commented until load impact is approved.
-- ANALYZE "LiteLLM_HealthCheckTable";
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT DISTINCT ON (model_id, model_name)
--     model_id,
--     model_name,
--     checked_at,
--     status
-- FROM "LiteLLM_HealthCheckTable"
-- ORDER BY model_id, model_name, checked_at DESC, id DESC;
