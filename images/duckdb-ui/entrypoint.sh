#!/bin/sh
# DuckDB UI binds [::1]:4213 (IPv6 loopback) only, and 401s any request whose
# Origin isn't http://localhost:4213 — so the in-container port MUST equal the
# published port. socat bridges IPv4 0.0.0.0:4213 → [::1]:4213 (different address
# families, so both can bind :4213).
# `tail -f /dev/null |` keeps stdin open so the DuckDB CLI stays alive headless.
set -e
socat TCP4-LISTEN:4213,bind=0.0.0.0,fork,reuseaddr TCP6:[::1]:4213 &
exec sh -c 'tail -f /dev/null | duckdb -init /etc/duckdb/init.sql /data/lakestart.duckdb'
