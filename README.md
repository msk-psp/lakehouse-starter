# 🧊 LakeStart — a self-hosted Iceberg lakehouse, in one command

> Run a production-shaped **Apache Iceberg lakehouse on your own machine or servers** —
> no cloud vendor, no lock-in, no $2k AWS bill to learn on.
> `docker compose up` → first `SELECT *` in **5 minutes**, not 5 days.

[![ci](https://github.com/msk-psp/lakehouse-starter/actions/workflows/ci.yml/badge.svg)](https://github.com/msk-psp/lakehouse-starter/actions/workflows/ci.yml)

---

## Why this exists

Setting up an Iceberg lakehouse "properly" means wiring together a catalog, S3-compatible
storage, an ingestion layer, a query engine, and a medallion (bronze/silver/gold) model
layout. In practice teams burn **days to months** before their first query runs.

LakeStart gives you the whole thing, pre-wired and opinionated, so you can:

- **Learn** Iceberg on real infra without touching AWS.
- **Prototype** a lakehouse for your team before committing to a cloud vendor.
- **Self-host** a small lakehouse on a homelab / on-prem box and actually keep it.

Everything here is **open source (Apache-2.0)** and runs on a laptop.

---

## What's inside (the free core)

| Component | What it does | Port |
|---|---|---|
| **MinIO** | S3-compatible object storage (your data lake) | `9000` / console `9001` |
| **Iceberg REST catalog** | The table catalog every engine talks to | `8181` |
| **PostgreSQL** | Catalog metadata backend | `5432` |
| **DuckDB UI** | Browser SQL over your Iceberg tables — the only engine you need | `4213` |
| **Medallion transforms** | Bronze → Silver → Gold SQL, unit-tested | — |

Deliberately **no Spark**: DuckDB is the single query engine. Fewer containers,
faster startup, and the whole stack fits in a laptop's RAM.

```bash
git clone <this-repo> && cd lakehouse-starter
cp .env.example .env
make up        # brings up the whole lakehouse
make seed      # loads sample data into bronze (via pyiceberg)
make sql       # → open http://localhost:4213, run: SELECT * FROM warehouse.bronze.events;
```

---

## Trust: how you know this actually works

Two test layers, both in CI on every push **and weekly** (so upstream image drift
gets caught even when the repo is idle):

1. **Unit tests** (`make test`, no docker) — the bronze→silver→gold SQL in
   `transforms/` runs against in-memory DuckDB with known inputs and asserted outputs.
   The *same files* are executed in the live stack, so green = the logic is right.
2. **Smoke test** (`make smoke`, docker) — brings up the full stack, seeds bronze
   through the REST catalog, then queries it back through DuckDB using the exact
   wiring the UI uses. Green = storage + catalog + engine are correctly plumbed.

---

## Architecture

```
        ┌──────────────┐      ┌───────────────────┐
seed    │  pyiceberg   │─────▶│  Iceberg REST     │
──────▶ └──────────────┘      │  catalog (:8181)  │
                              └─────────┬─────────┘
        ┌──────────────┐                │ metadata → PostgreSQL
query   │  DuckDB UI   │────────────────┤
◀────── │  (:4213)     │                │ data → MinIO / S3 (:9000)
        └──────────────┘                ▼
                              bronze → silver → gold  (transforms/)
```

## Repo layout

```text
docker-compose.yml     The whole lakehouse
.env.example           Config you copy to .env
Makefile               up / seed / sql / test / smoke
seed/                  Sample data loader (pyiceberg)
transforms/            Medallion SQL (bronze → silver → gold), unit-tested
tests/                 pytest suite for the transforms
images/duckdb-ui/      Browser SQL image
images/seed/           Seed job image
scripts/smoke.sh       End-to-end integrity check
docs/PRO.md            Production hardening pack (K8s, HA, MLflow, KubeRay)
```

---

## Free core vs. Production pack

The core above is everything you need to **learn and prototype**. Taking a lakehouse to
production (bare-metal Kubernetes, HA, GPU compute, lineage, model registry) is a
different job — that's the **[Production Pack](docs/PRO.md)**:

- Pulumi (Python IaC) to deploy the whole platform on **bare-metal Kubernetes**, single command
- **Active-active HA** for the SPoF components (catalog, scheduler)
- **SeaweedFS** NVMe/HDD tiering instead of single-node MinIO
- **KubeRay** for distributed / GPU training jobs
- **MLflow + DataHub** (model registry + lineage) and Airflow at scale
- Operational **runbooks**

→ Built by an engineer who runs exactly this stack in production. See [docs/PRO.md](docs/PRO.md).

## License

Core: Apache-2.0. Use it, fork it, ship it.
