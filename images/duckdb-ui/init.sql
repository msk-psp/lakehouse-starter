-- UI startup: shared wiring + headless UI server.
.read /etc/duckdb/attach.sql

-- The UI server must run on the SAME port the browser sees (4213): it compares
-- the request's Origin header against http://localhost:<ui_local_port> and
-- returns 401 on mismatch. It binds ::1 (IPv6) only; socat (entrypoint.sh)
-- bridges IPv4 0.0.0.0:4213 -> [::1]:4213 — no conflict across address families.
CALL start_ui_server();
