-- Shared wiring: extensions + S3 secret + Iceberg REST catalog attach.
-- Used by BOTH the UI server startup (init.sql) and the CI smoke test,
-- so a green smoke test proves the exact wiring the UI uses.

INSTALL iceberg;  LOAD iceberg;
INSTALL httpfs;   LOAD httpfs;

SET enable_progress_bar = true;
SET enable_object_cache = true;

-- S3 / MinIO endpoint — credentials come from the container env.
CREATE OR REPLACE SECRET minio_s3 (
    TYPE s3,
    KEY_ID getenv('S3_ACCESS_KEY'),
    SECRET getenv('S3_SECRET_KEY'),
    ENDPOINT getenv('S3_ENDPOINT'),
    URL_STYLE 'path',
    USE_SSL false
);

-- Attach the Iceberg REST catalog as `warehouse`.
-- Query like: SELECT * FROM warehouse.bronze.events;
ATTACH IF NOT EXISTS 'warehouse' AS warehouse (
    TYPE ICEBERG,
    AUTHORIZATION_TYPE 'none',
    ENDPOINT getenv('ICEBERG_REST_URL')
);
