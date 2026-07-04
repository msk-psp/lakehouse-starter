#!/usr/bin/env bash
# Materialize the medallion transforms into the live Iceberg catalog:
#   transforms/silver_events.sql        -> warehouse.silver.events
#   transforms/gold_daily_activity.sql  -> warehouse.gold.daily_activity
#
# The SAME .sql files are verified by the unit tests (make test). Here we set the
# catalog context with USE so their catalog-relative names (bronze.events,
# silver.events) resolve inside the `warehouse` Iceberg catalog.
# DuckDB-Iceberg doesn't support CREATE OR REPLACE yet, hence DROP + CREATE.
set -euo pipefail
cd "$(dirname "$0")/.."

SILVER_SQL=$(cat transforms/silver_events.sql)
GOLD_SQL=$(cat transforms/gold_daily_activity.sql)

docker compose exec -T duckdb-ui duckdb -init /etc/duckdb/attach.sql -c "
CREATE SCHEMA IF NOT EXISTS warehouse.silver;
CREATE SCHEMA IF NOT EXISTS warehouse.gold;
USE warehouse.bronze;

DROP TABLE IF EXISTS silver.events;
CREATE TABLE silver.events AS
${SILVER_SQL};

DROP TABLE IF EXISTS gold.daily_activity;
CREATE TABLE gold.daily_activity AS
${GOLD_SQL};

SELECT 'silver.events' AS table_name, count(*) AS rows FROM silver.events
UNION ALL
SELECT 'gold.daily_activity', count(*) FROM gold.daily_activity;
"

echo "==> Transforms materialized: warehouse.silver.events, warehouse.gold.daily_activity"
