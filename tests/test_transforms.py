"""Unit tests for the medallion transforms (bronze -> silver -> gold)."""

from datetime import date

from conftest import materialize


def load_bronze(con, rows):
    con.executemany(
        "INSERT INTO bronze.events (user_id, event, platform, event_date) VALUES (?, ?, ?, ?)",
        rows,
    )


def setup_bronze_table(con):
    con.execute(
        "CREATE TABLE bronze.events (user_id BIGINT, event VARCHAR, platform VARCHAR, event_date DATE)"
    )


# ── Silver ──────────────────────────────────────────────────────────────

def test_silver_lowercases_and_types(con):
    setup_bronze_table(con)
    load_bronze(con, [(1, "SignUp", "Web", date(2026, 1, 1))])

    materialize(con, "silver.events", "silver_events.sql")
    row = con.execute("SELECT user_id, event, platform, event_date FROM silver.events").fetchone()

    assert row == (1, "signup", "web", date(2026, 1, 1))


def test_silver_drops_null_events(con):
    setup_bronze_table(con)
    load_bronze(
        con,
        [
            (1, "login", "ios", date(2026, 1, 1)),
            (2, None, "web", date(2026, 1, 1)),  # should be filtered out
        ],
    )

    materialize(con, "silver.events", "silver_events.sql")
    count = con.execute("SELECT count(*) FROM silver.events").fetchone()[0]

    assert count == 1


# ── Gold ────────────────────────────────────────────────────────────────

def test_gold_daily_aggregates(con):
    setup_bronze_table(con)
    load_bronze(
        con,
        [
            (1, "login", "web", date(2026, 1, 1)),
            (2, "login", "web", date(2026, 1, 1)),
            (1, "purchase", "web", date(2026, 1, 1)),  # same user again
            (3, "login", "ios", date(2026, 1, 1)),
        ],
    )
    materialize(con, "silver.events", "silver_events.sql")
    materialize(con, "gold.daily_activity", "gold_daily_activity.sql")

    web = con.execute(
        "SELECT events, active_users, purchases FROM gold.daily_activity WHERE platform = 'web'"
    ).fetchone()

    # web: 3 events, 2 distinct users (1 and 2), 1 purchase
    assert web == (3, 2, 1)


def test_gold_counts_distinct_users(con):
    setup_bronze_table(con)
    load_bronze(
        con,
        [
            (5, "login", "ios", date(2026, 1, 2)),
            (5, "purchase", "ios", date(2026, 1, 2)),  # same user, so active_users = 1
        ],
    )
    materialize(con, "silver.events", "silver_events.sql")
    materialize(con, "gold.daily_activity", "gold_daily_activity.sql")

    active = con.execute("SELECT active_users FROM gold.daily_activity").fetchone()[0]
    assert active == 1
