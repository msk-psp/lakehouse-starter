# LakeStart Production Pack

The free core gets you a lakehouse on one machine. The **Production Pack** is for taking
it to a real, multi-node, on-prem cluster — the stuff that takes teams months to get right.

Built and operated by an engineer who runs exactly this stack in production.

## What you get

- **Pulumi (Python IaC)** to deploy the whole platform on **bare-metal Kubernetes**
  in a small number of reproducible, single-command stacks.
- **Active-active HA** for single-points-of-failure (catalog DB, Airflow scheduler,
  cluster DNS) so a node dying doesn't stop your pipelines.
- **SeaweedFS** with NVMe/HDD tiering (hot/cold data co-located) instead of single-node MinIO.
- **Airflow at scale** (KubernetesExecutor, git-sync CD, dbt + Cosmos bundled image).
- **KubeRay** across heterogeneous GPU nodes for distributed training jobs.
- **MLflow** (experiments + model registry) and **DataHub** (catalog + OpenLineage lineage).
- **Prometheus + Grafana** dashboards for the whole cluster.
- **Runbooks**: upgrades, backup/restore, incident response, compaction/integrity DAGs.

## Formats (draft — pick one to start)

| Tier | What | Price (draft) |
|---|---|---|
| **Guide** | The Production Pack repo + docs (self-serve) | $99–149 |
| **Guide + Q&A** | Above + a 60-min setup call | $299 |
| **Done-with-you** | I set it up on your hardware over a week | $3k–8k |

## Positioning

> "You learned the lakehouse with the free core. When you're ready to run it for real
> on your own servers without a cloud bill, this is the same architecture, hardened."

The free core is the funnel. This is the money.
