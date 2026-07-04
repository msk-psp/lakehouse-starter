# DuckDB CLI + browser UI, single-responsibility image.
FROM ubuntu:24.04

# Keep close to latest: the UI web app is served from ui.duckdb.org (always newest)
# and an old ui extension can fail its handshake with 401s on /localToken.
ARG DUCKDB_VERSION=1.5.4

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates wget unzip socat && \
    rm -rf /var/lib/apt/lists/* && \
    ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
      amd64) DUCKDB_ARCH=linux-amd64 ;; \
      arm64) DUCKDB_ARCH=linux-arm64 ;; \
      *) echo "unsupported arch: $ARCH" && exit 1 ;; \
    esac && \
    wget -q "https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_VERSION}/duckdb_cli-${DUCKDB_ARCH}.zip" -O /tmp/duckdb.zip && \
    unzip -q /tmp/duckdb.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/duckdb && \
    rm /tmp/duckdb.zip

COPY attach.sql /etc/duckdb/attach.sql
COPY init.sql /etc/duckdb/init.sql
COPY entrypoint.sh /usr/local/bin/duckdb-ui-entrypoint
RUN chmod +x /usr/local/bin/duckdb-ui-entrypoint

WORKDIR /data

EXPOSE 4213

ENTRYPOINT ["/usr/local/bin/duckdb-ui-entrypoint"]
