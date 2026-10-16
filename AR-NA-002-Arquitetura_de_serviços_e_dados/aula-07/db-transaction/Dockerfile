FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

COPY scripts/ /docker-entrypoint-initdb.d/
COPY entrypoint.sh /usr/local/bin/database-entrypoint.sh

RUN chmod +x /usr/local/bin/database-entrypoint.sh

USER mssql

ENTRYPOINT ["/usr/local/bin/database-entrypoint.sh"]