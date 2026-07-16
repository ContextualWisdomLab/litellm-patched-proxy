-- Review the candidate counts before changing production data.
SELECT
    count(*) AS total_rows,
    count(*) FILTER (WHERE checked_at < now() - interval '30 days') AS older_than_30_days,
    count(*) FILTER (WHERE checked_at < now() - interval '60 days') AS older_than_60_days,
    count(*) FILTER (WHERE checked_at < now() - interval '90 days') AS older_than_90_days,
    min(checked_at) AS oldest_check,
    max(checked_at) AS newest_check
FROM "LiteLLM_HealthCheckTable";

-- Supports DISTINCT ON (model_id, model_name) ORDER BY checked_at DESC without
-- blocking normal writes while the index is built.
CREATE INDEX CONCURRENTLY IF NOT EXISTS
    "LiteLLM_HealthCheckTable_latest_model_idx"
ON "LiteLLM_HealthCheckTable" (model_id, model_name, checked_at DESC);

-- Retention template: uncomment and run one batch at a time only after approval.
-- WITH expired AS (
--     SELECT id
--     FROM "LiteLLM_HealthCheckTable"
--     WHERE checked_at < now() - interval '90 days'
--     ORDER BY checked_at
--     LIMIT 5000
-- )
-- DELETE FROM "LiteLLM_HealthCheckTable" AS history
-- USING expired
-- WHERE history.id = expired.id;

-- Confirm that the latest-state query uses the composite index after ANALYZE.
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT ON (model_id, model_name)
    model_id,
    model_name,
    checked_at,
    status
FROM "LiteLLM_HealthCheckTable"
ORDER BY model_id, model_name, checked_at DESC;
