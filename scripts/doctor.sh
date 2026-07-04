#!/usr/bin/env bash
# Self-diagnosis: check every layer and print a pass/fail table.
# Run this before opening an issue — paste its output into the report.
set -uo pipefail
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
check() {  # check <name> <command...>
  local name=$1; shift
  if "$@" >/dev/null 2>&1; then
    printf "  ✅ %s\n" "$name"; PASS=$((PASS+1))
  else
    printf "  ❌ %s\n" "$name"; FAIL=$((FAIL+1))
  fi
}

echo "LakeStart doctor"
echo "----------------"
check "docker daemon reachable"           docker info
check ".env exists (cp .env.example .env)" test -f .env
check "minio container healthy"           sh -c 'docker compose ps minio --format "{{.Status}}" | grep -q healthy'
check "iceberg-rest container healthy"    sh -c 'docker compose ps iceberg-rest --format "{{.Status}}" | grep -q healthy'
check "duckdb-ui container running"       sh -c 'docker compose ps duckdb-ui --format "{{.Status}}" | grep -q Up'
check "catalog answers (:8181/v1/config)" curl -sf -m 5 http://localhost:8181/v1/config -o /dev/null
check "MinIO console answers (:9001)"     curl -sf -m 5 http://localhost:9001 -o /dev/null
check "DuckDB UI answers (:4213)"         curl -sf -m 5 http://localhost:4213/ -o /dev/null
# Iceberg catalogs don't expose information_schema; listing tables is the liveness probe.
catalog_check() {
  docker compose exec -T duckdb-ui duckdb -init /etc/duckdb/attach.sql \
    -c "FROM (SHOW ALL TABLES) SELECT count(*) WHERE database = 'warehouse'" 2>/dev/null \
    | grep -qE '[0-9]'
}
check "warehouse catalog queryable"       catalog_check

echo "----------------"
echo "  ${PASS} passed, ${FAIL} failed"
if [ "$FAIL" -gt 0 ]; then
  echo
  echo "  Something's off. Common fixes: make up (stack down), make clean && make up (fresh start)."
  echo "  Still stuck? Attach this output + 'docker compose logs' to a GitHub issue."
  exit 1
fi
echo "  All good — your lakehouse is healthy."
