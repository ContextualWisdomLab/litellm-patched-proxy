\set ON_ERROR_STOP on

SET search_path TO pg_catalog, public;

-- Run this file with psql autocommit enabled and without BEGIN/COMMIT.
-- CREATE/DROP INDEX CONCURRENTLY cannot run inside a transaction block.

DO $preflight$
DECLARE
    target_table_oid regclass := to_regclass('public."LiteLLM_HealthCheckTable"');
    candidate_index_oid regclass;
    index_table_oid oid;
BEGIN
    IF target_table_oid IS NULL THEN
        RAISE EXCEPTION 'required table public."LiteLLM_HealthCheckTable" does not exist';
    END IF;

    FOREACH candidate_index_oid IN ARRAY ARRAY[
        to_regclass('public."LiteLLM_HealthCheckTable_latest_model_idx"'),
        to_regclass('public."LiteLLM_HealthCheckTable_retention_idx"')
    ] LOOP
        CONTINUE WHEN candidate_index_oid IS NULL;

        SELECT i.indrelid
        INTO index_table_oid
        FROM pg_index AS i
        WHERE i.indexrelid = candidate_index_oid;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'relation % exists but is not an index', candidate_index_oid;
        ELSIF index_table_oid <> target_table_oid::oid THEN
            RAISE EXCEPTION 'index % is not owned by public."LiteLLM_HealthCheckTable"; refusing to drop it', candidate_index_oid;
        END IF;
    END LOOP;
END
$preflight$;

-- Read catalog estimates only. This does not scan the history table.
SELECT
    c.reltuples::bigint AS estimated_rows,
    stats.n_live_tup AS statistics_live_rows,
    stats.last_analyze,
    stats.last_autoanalyze,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_relation_size
FROM pg_class AS c
LEFT JOIN pg_stat_user_tables AS stats ON stats.relid = c.oid
WHERE c.oid = 'public."LiteLLM_HealthCheckTable"'::regclass;

-- Replace only an invalid or mismatched latest-state index. \gexec sends each
-- generated CONCURRENTLY statement separately, outside a transaction block.
WITH latest_index AS (
    SELECT
        i.indexrelid,
        i.indisvalid,
        i.indpred IS NULL
        AND i.indexprs IS NULL
        AND i.indrelid = to_regclass('public."LiteLLM_HealthCheckTable"')
        AND i.indnkeyatts = 4
        AND i.indnatts = 4
        AND am.amname = 'btree'
        AND (
            SELECT array_agg(a.attname::text ORDER BY k.ordinality)
            FROM unnest(i.indkey) WITH ORDINALITY AS k(attnum, ordinality)
            JOIN pg_attribute AS a
              ON a.attrelid = i.indrelid
             AND a.attnum = k.attnum
            WHERE k.ordinality <= i.indnkeyatts
        ) = ARRAY['model_id', 'model_name', 'checked_at', 'health_check_id']
        AND coalesce(pg_index_column_has_property(i.indexrelid, 1, 'asc'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 1, 'nulls_last'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 2, 'asc'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 2, 'nulls_last'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 3, 'desc'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 3, 'nulls_first'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 4, 'desc'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 4, 'nulls_first'), false)
            AS matches_definition
    FROM pg_index AS i
    JOIN pg_class AS c ON c.oid = i.indexrelid
    JOIN pg_am AS am ON am.oid = c.relam
    WHERE i.indexrelid = to_regclass('public."LiteLLM_HealthCheckTable_latest_model_idx"')
)
SELECT format('DROP INDEX CONCURRENTLY %s;', indexrelid::regclass)
FROM latest_index
WHERE NOT indisvalid OR NOT matches_definition
\gexec

WITH latest_index AS (
    SELECT
        i.indisvalid,
        i.indpred IS NULL
        AND i.indexprs IS NULL
        AND i.indrelid = to_regclass('public."LiteLLM_HealthCheckTable"')
        AND i.indnkeyatts = 4
        AND i.indnatts = 4
        AND am.amname = 'btree'
        AND (
            SELECT array_agg(a.attname::text ORDER BY k.ordinality)
            FROM unnest(i.indkey) WITH ORDINALITY AS k(attnum, ordinality)
            JOIN pg_attribute AS a
              ON a.attrelid = i.indrelid
             AND a.attnum = k.attnum
            WHERE k.ordinality <= i.indnkeyatts
        ) = ARRAY['model_id', 'model_name', 'checked_at', 'health_check_id']
        AND coalesce(pg_index_column_has_property(i.indexrelid, 1, 'asc'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 1, 'nulls_last'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 2, 'asc'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 2, 'nulls_last'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 3, 'desc'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 3, 'nulls_first'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 4, 'desc'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 4, 'nulls_first'), false)
            AS matches_definition
    FROM pg_index AS i
    JOIN pg_class AS c ON c.oid = i.indexrelid
    JOIN pg_am AS am ON am.oid = c.relam
    WHERE i.indexrelid = to_regclass('public."LiteLLM_HealthCheckTable_latest_model_idx"')
)
SELECT $sql$
CREATE INDEX CONCURRENTLY "LiteLLM_HealthCheckTable_latest_model_idx"
ON "LiteLLM_HealthCheckTable" (model_id, model_name, checked_at DESC, health_check_id DESC);
$sql$
WHERE NOT EXISTS (
    SELECT 1
    FROM latest_index
    WHERE indisvalid AND matches_definition
)
\gexec

-- Apply the same validity and definition checks to the retention index.
WITH retention_index AS (
    SELECT
        i.indexrelid,
        i.indisvalid,
        i.indpred IS NULL
        AND i.indexprs IS NULL
        AND i.indrelid = to_regclass('public."LiteLLM_HealthCheckTable"')
        AND i.indnkeyatts = 2
        AND i.indnatts = 2
        AND am.amname = 'btree'
        AND (
            SELECT array_agg(a.attname::text ORDER BY k.ordinality)
            FROM unnest(i.indkey) WITH ORDINALITY AS k(attnum, ordinality)
            JOIN pg_attribute AS a
              ON a.attrelid = i.indrelid
             AND a.attnum = k.attnum
            WHERE k.ordinality <= i.indnkeyatts
        ) = ARRAY['checked_at', 'health_check_id']
        AND coalesce(pg_index_column_has_property(i.indexrelid, 1, 'asc'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 1, 'nulls_last'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 2, 'asc'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 2, 'nulls_last'), false)
            AS matches_definition
    FROM pg_index AS i
    JOIN pg_class AS c ON c.oid = i.indexrelid
    JOIN pg_am AS am ON am.oid = c.relam
    WHERE i.indexrelid = to_regclass('public."LiteLLM_HealthCheckTable_retention_idx"')
)
SELECT format('DROP INDEX CONCURRENTLY %s;', indexrelid::regclass)
FROM retention_index
WHERE NOT indisvalid OR NOT matches_definition
\gexec

WITH retention_index AS (
    SELECT
        i.indisvalid,
        i.indpred IS NULL
        AND i.indexprs IS NULL
        AND i.indrelid = to_regclass('public."LiteLLM_HealthCheckTable"')
        AND i.indnkeyatts = 2
        AND i.indnatts = 2
        AND am.amname = 'btree'
        AND (
            SELECT array_agg(a.attname::text ORDER BY k.ordinality)
            FROM unnest(i.indkey) WITH ORDINALITY AS k(attnum, ordinality)
            JOIN pg_attribute AS a
              ON a.attrelid = i.indrelid
             AND a.attnum = k.attnum
            WHERE k.ordinality <= i.indnkeyatts
        ) = ARRAY['checked_at', 'health_check_id']
        AND coalesce(pg_index_column_has_property(i.indexrelid, 1, 'asc'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 1, 'nulls_last'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 2, 'asc'), false)
        AND coalesce(pg_index_column_has_property(i.indexrelid, 2, 'nulls_last'), false)
            AS matches_definition
    FROM pg_index AS i
    JOIN pg_class AS c ON c.oid = i.indexrelid
    JOIN pg_am AS am ON am.oid = c.relam
    WHERE i.indexrelid = to_regclass('public."LiteLLM_HealthCheckTable_retention_idx"')
)
SELECT $sql$
CREATE INDEX CONCURRENTLY "LiteLLM_HealthCheckTable_retention_idx"
ON "LiteLLM_HealthCheckTable" (checked_at, health_check_id);
$sql$
WHERE NOT EXISTS (
    SELECT 1
    FROM retention_index
    WHERE indisvalid AND matches_definition
)
\gexec

-- Exact retention counts scan the history table. Keep this query commented and
-- run it only in an approved off-peak window after reviewing current I/O load.
-- SELECT
--     count(*) AS total_rows,
--     count(*) FILTER (WHERE checked_at < now() - interval '30 days') AS older_than_30_days,
--     count(*) FILTER (WHERE checked_at < now() - interval '60 days') AS older_than_60_days,
--     count(*) FILTER (WHERE checked_at < now() - interval '90 days') AS older_than_90_days,
--     min(checked_at) AS oldest_check,
--     max(checked_at) AS newest_check
-- FROM "LiteLLM_HealthCheckTable";

-- Retention template: uncomment and run one batch at a time only after approval.
-- WITH expired AS (
--     SELECT health_check_id
--     FROM "LiteLLM_HealthCheckTable"
--     WHERE checked_at < now() - interval '90 days'
--     ORDER BY checked_at, health_check_id
--     LIMIT 5000
-- )
-- DELETE FROM "LiteLLM_HealthCheckTable" AS history
-- USING expired
-- WHERE history.health_check_id = expired.health_check_id;

-- This default verification only plans the query; it does not execute it.
EXPLAIN (COSTS, VERBOSE)
SELECT DISTINCT ON (model_id, model_name)
    model_id,
    model_name,
    checked_at,
    status
FROM "LiteLLM_HealthCheckTable"
ORDER BY model_id, model_name, checked_at DESC, health_check_id DESC;

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
-- ORDER BY model_id, model_name, checked_at DESC, health_check_id DESC;
