.PHONY: up down seed sql test smoke logs ps clean

## up: start the whole lakehouse
up:
	docker compose up -d --build --wait minio iceberg-rest duckdb-ui
	@echo ""
	@echo "  Lakehouse is up:"
	@echo "    MinIO console : http://localhost:9001  (admin / password)"
	@echo "    Iceberg REST  : http://localhost:8181"
	@echo "    DuckDB UI     : http://localhost:4213"
	@echo ""
	@echo "  Next: make seed   then   make sql"

## down: stop everything (keeps data)
down:
	docker compose down

## seed: load sample data into the bronze layer
seed:
	docker compose run --rm --build seed

## sql: where to run queries
sql:
	@echo "Open http://localhost:4213 and run:  SELECT * FROM warehouse.bronze.events;"

## test: fast local unit tests (no docker needed)
test:
	uv run pytest -v

## smoke: full end-to-end integrity check (needs docker)
smoke:
	./scripts/smoke.sh

## logs: tail all logs
logs:
	docker compose logs -f

## ps: show running services
ps:
	docker compose ps

## clean: stop and DELETE all data volumes
clean:
	docker compose down -v
