.PHONY: help up down seed transform sql test smoke doctor inspect logs ps clean

## help: list all commands
help:
	@grep -E '^## ' Makefile | sed 's/^## /  make /'
.DEFAULT_GOAL := help

## up: start the whole lakehouse
up:
	docker compose up -d --build --wait minio iceberg-rest duckdb-ui
	@echo ""
	@echo "  Lakehouse is up:"
	@echo "    MinIO console : http://localhost:9001  (admin / password)"
	@echo "    Iceberg REST  : http://localhost:8181"
	@echo "    DuckDB UI     : http://localhost:4213"
	@echo ""
	@echo "  Next: make seed  →  make transform  →  make sql"

## down: stop everything (keeps data)
down:
	docker compose down

## seed: load sample data into the bronze layer
seed:
	docker compose run --rm --build seed

## transform: materialize silver + gold Iceberg tables from bronze
transform:
	./scripts/transform.sh

## sql: where to run queries
sql:
	@echo "Open http://localhost:4213 and run:  SELECT * FROM warehouse.gold.daily_activity;"

## test: fast local unit tests (no docker needed)
test:
	uv run pytest -v

## smoke: full end-to-end integrity check (needs docker)
smoke:
	./scripts/smoke.sh

## doctor: diagnose a running (or broken) stack layer by layer
doctor:
	./scripts/doctor.sh

## inspect: X-ray the lakehouse — per-table snapshots, files, sizes
inspect:
	docker compose run --rm --build --entrypoint python seed /app/seed/inspect_tables.py

## logs: tail all logs
logs:
	docker compose logs -f

## ps: show running services
ps:
	docker compose ps

## clean: stop and DELETE all data volumes
clean:
	docker compose down -v
