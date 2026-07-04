#!/usr/bin/env bash
# End-to-end smoke test: stack up → seed → query through DuckDB.
# Green here means storage + catalog + query engine are actually wired correctly.
# Used by both `make smoke` (local) and CI.
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || cp .env.example .env

echo "==> Starting stack..."
docker compose up -d --build --wait minio iceberg-rest duckdb-ui

echo "==> Seeding bronze.events..."
docker compose run --rm --build seed

echo "==> Querying through DuckDB (same wiring the UI uses)..."
# attach.sql prints a "Success" box for CREATE SECRET — keep only the numeric result line.
COUNT=$(docker compose exec -T duckdb-ui duckdb -init /etc/duckdb/attach.sql -noheader -list \
  -c "SELECT count(*) FROM warehouse.bronze.events;" | grep -E '^[0-9]+$' | tail -1)

echo "    bronze.events rows: ${COUNT}"
if [ "${COUNT}" != "5" ]; then
  echo "SMOKE FAILED: expected 5 rows, got '${COUNT}'" >&2
  exit 1
fi

echo "==> Materializing silver + gold (make transform)..."
./scripts/transform.sh >/dev/null

echo "==> Verifying gold layer..."
GOLD=$(docker compose exec -T duckdb-ui duckdb -init /etc/duckdb/attach.sql -noheader -list \
  -c "SELECT count(*) || ':' || sum(purchases) FROM warehouse.gold.daily_activity;" \
  | grep -E '^[0-9]+:[0-9]+$' | tail -1)

echo "    gold rows:purchases = ${GOLD}"
if [ "${GOLD}" != "5:2" ]; then
  echo "SMOKE FAILED: expected gold '5:2', got '${GOLD}'" >&2
  exit 1
fi

echo "==> Verifying bring-your-own-data path (CSV -> Iceberg)..."
BYO=$(docker compose exec -T duckdb-ui duckdb -init /etc/duckdb/attach.sql -noheader -list -c "
DROP TABLE IF EXISTS warehouse.bronze.smoke_weather;
CREATE TABLE warehouse.bronze.smoke_weather AS SELECT * FROM '/data/local/example_weather.csv';
SELECT count(*) FROM warehouse.bronze.smoke_weather;
" | grep -E '^[0-9]+$' | tail -1)

echo "    weather rows loaded: ${BYO}"
if [ "${BYO}" != "3" ]; then
  echo "SMOKE FAILED: expected 3 weather rows, got '${BYO}'" >&2
  exit 1
fi

echo "==> SMOKE PASSED ✅  (storage + catalog + engine + transforms + BYO-data all wired)"
