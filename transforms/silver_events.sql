-- Silver: cleaned, typed events (one row per raw event).
-- Single source of truth: run by the DuckDB engine in the stack AND by the unit tests.
SELECT
    CAST(user_id AS BIGINT)  AS user_id,
    lower(event)             AS event,
    lower(platform)          AS platform,
    CAST(event_date AS DATE) AS event_date
FROM bronze.events
WHERE event IS NOT NULL
