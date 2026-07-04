-- UI startup: shared wiring + headless UI server.
.read /etc/duckdb/attach.sql

-- The UI server binds 127.0.0.1 inside the container; socat (see entrypoint.sh)
-- forwards 0.0.0.0:4213 -> 127.0.0.1:4214 so the host can reach it.
SET ui_local_port = 4214;
CALL start_ui_server();
