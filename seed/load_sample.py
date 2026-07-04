"""Seed the lakehouse with a small sample dataset so `SELECT *` works immediately.

Writes a `bronze.events` Iceberg table via pyiceberg + the REST catalog.
No Spark required. Run with: make seed
"""

import os
from datetime import date

import pyarrow as pa
from pyiceberg.catalog import load_catalog

REST_URL = os.environ.get("ICEBERG_REST_URL", "http://iceberg-rest:8181")
S3_ENDPOINT = os.environ.get("S3_ENDPOINT", "http://minio:9000")
S3_ACCESS_KEY = os.environ.get("S3_ACCESS_KEY", "admin")
S3_SECRET_KEY = os.environ.get("S3_SECRET_KEY", "password")

catalog = load_catalog(
    "rest",
    **{
        "uri": REST_URL,
        "s3.endpoint": S3_ENDPOINT,
        "s3.access-key-id": S3_ACCESS_KEY,
        "s3.secret-access-key": S3_SECRET_KEY,
        "s3.path-style-access": "true",
        "s3.region": "us-east-1",
    },
)

# Sample "events" — pretend product analytics data
events = pa.table(
    {
        "user_id": pa.array([1, 2, 3, 4, 5], type=pa.int64()),
        "event": pa.array(["signup", "login", "purchase", "login", "purchase"]),
        "platform": pa.array(["web", "ios", "web", "android", "ios"]),
        "event_date": pa.array(
            [
                date(2026, 1, 1),
                date(2026, 1, 1),
                date(2026, 1, 2),
                date(2026, 1, 2),
                date(2026, 1, 3),
            ],
            type=pa.date32(),
        ),
    }
)

catalog.create_namespace_if_not_exists("bronze")
table = catalog.create_table_if_not_exists("bronze.events", schema=events.schema)
table.overwrite(events)

print(f"Seeded bronze.events with {table.scan().to_arrow().num_rows} rows.")
