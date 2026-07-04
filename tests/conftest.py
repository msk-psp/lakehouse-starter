"""Test harness: run the medallion transforms against an in-memory DuckDB.

No containers required — this is the fast, local trust layer. The SAME .sql files
are executed by the real DuckDB engine in the running stack, so a green test here
means the transform logic itself is correct.
"""

from pathlib import Path

import duckdb
import pytest

TRANSFORMS = Path(__file__).parent.parent / "transforms"


def read_sql(name: str) -> str:
    return (TRANSFORMS / name).read_text()


@pytest.fixture
def con():
    """Fresh in-memory DuckDB with empty bronze/silver/gold schemas."""
    c = duckdb.connect(":memory:")
    for schema in ("bronze", "silver", "gold"):
        c.execute(f"CREATE SCHEMA {schema}")
    yield c
    c.close()


def materialize(con, schema_table: str, sql_file: str) -> None:
    """Run a transform .sql file and store its result as a table."""
    con.execute(f"CREATE OR REPLACE TABLE {schema_table} AS {read_sql(sql_file)}")
