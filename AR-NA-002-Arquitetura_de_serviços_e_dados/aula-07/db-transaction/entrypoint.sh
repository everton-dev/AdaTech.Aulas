#!/usr/bin/env bash
set -Eeuo pipefail

sqlcmd_path="/opt/mssql-tools18/bin/sqlcmd"
if [[ ! -x "${sqlcmd_path}" ]]; then
  sqlcmd_path="/opt/mssql-tools/bin/sqlcmd"
fi

/opt/mssql/bin/sqlservr &
sql_server_pid=$!
initialization_marker="/var/opt/mssql/.geek-store-initialized"

cleanup() {
  kill -TERM "${sql_server_pid}" 2>/dev/null || true
  wait "${sql_server_pid}" 2>/dev/null || true
}
trap cleanup INT TERM

until "${sqlcmd_path}" -C -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -Q "SELECT 1"; do
  echo "Waiting for SQL Server to accept connections..."
  sleep 2
done

until [[ "$("${sqlcmd_path}" -C -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -h -1 -W -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE state <> 0;" 2>/dev/null || true)" == "0" ]]; do
  echo "Waiting for SQL Server databases to finish recovery..."
  sleep 2
done

if [[ ! -f "${initialization_marker}" ]]; then
  for script in /docker-entrypoint-initdb.d/*.sql; do
    echo "Running ${script}..."
    "${sqlcmd_path}" -b -C -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -i "${script}"
  done

  touch "${initialization_marker}"
  echo "Transactional database initialization completed."
else
  echo "Transactional database already initialized; preserving persisted data."
fi

wait "${sql_server_pid}"