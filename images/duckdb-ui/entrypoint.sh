#!/bin/sh
# DuckDB UI binds loopback only — and resolves localhost to ::1 (IPv6) inside
# the container — so socat bridges 0.0.0.0:4213 (IPv4, host-reachable) → [::1]:4214.
# `tail -f /dev/null |` keeps stdin open so the DuckDB CLI stays alive headless.
set -e
socat TCP4-LISTEN:4213,bind=0.0.0.0,fork,reuseaddr TCP6:[::1]:4214 &
exec sh -c 'tail -f /dev/null | duckdb -init /etc/duckdb/init.sql /data/lakestart.duckdb'
