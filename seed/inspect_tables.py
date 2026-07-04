"""X-ray the lakehouse: per-table Iceberg metadata stats.

Shows what's usually invisible — snapshots, data files, sizes — so you can watch
how Iceberg actually works as you seed/transform, and spot bloat early.
Run with: make inspect
"""

import os
from datetime import datetime, timezone

from pyiceberg.catalog import load_catalog

catalog = load_catalog(
    "rest",
    **{
        "uri": os.environ.get("ICEBERG_REST_URL", "http://iceberg-rest:8181"),
        "s3.endpoint": os.environ.get("S3_ENDPOINT", "http://minio:9000"),
        "s3.access-key-id": os.environ.get("S3_ACCESS_KEY", "admin"),
        "s3.secret-access-key": os.environ.get("S3_SECRET_KEY", "password"),
        "s3.path-style-access": "true",
        "s3.region": "us-east-1",
    },
)

HEADER = f"{'table':<28} {'rows':>8} {'files':>6} {'size':>10} {'snapshots':>9}  last commit (UTC)"
print(HEADER)
print("-" * len(HEADER))

total_bytes = 0
for ns in sorted(catalog.list_namespaces()):
    for ident in sorted(catalog.list_tables(ns)):
        table = catalog.load_table(ident)
        snaps = list(table.snapshots())
        current = table.current_snapshot()

        rows = files = size = 0
        last = "-"
        if current:
            # Read per-file metadata (not the snapshot summary — some writers,
            # e.g. DuckDB, don't populate summary size fields).
            fmeta = table.inspect.files()
            files = fmeta.num_rows
            if files:
                rows = sum(x.as_py() or 0 for x in fmeta["record_count"])
                size = sum(x.as_py() or 0 for x in fmeta["file_size_in_bytes"])
            last = datetime.fromtimestamp(
                current.timestamp_ms / 1000, tz=timezone.utc
            ).strftime("%Y-%m-%d %H:%M")

        total_bytes += size
        name = ".".join(ident)
        human = f"{size / 1024:.1f} KB" if size < 1024**2 else f"{size / 1024**2:.1f} MB"
        print(f"{name:<28} {rows:>8} {files:>6} {human:>10} {len(snaps):>9}  {last}")

print("-" * len(HEADER))
print(f"total data size: {total_bytes / 1024**2:.2f} MB")
print(
    "\nTip: every seed/transform adds a snapshot — old ones keep their data files"
    "\nalive on MinIO. Expiring snapshots & compacting files is an engine-side job"
    "\n(not in pyiceberg) — exactly the kind of thing the production pack automates."
)
