#!/bin/bash

set -e

# Environment variables for customization
: "${POSTGRES_USER:=postgres}"
: "${POSTGRES_PASSWORD:=postgres}"
: "${POSTGRES_REPLICATION_PASSWORD:=replication123pass}"
: "${POSTGRES_DB:=mydb}"
: "${DATA_DIR:=/var/lib/postgresql/data}"
: "${BOOTSTRAP_NODE:=false}"  # Set to true only on the initial leader node
: "${PATRONI_CONFIG_FILE:=/venv/etc/patroni.yml}"

echo "Starting Patroni for host: $(hostname)"

# Substitute {{ .Host }} in patroni.yml dynamically
if grep -q '{{ .Host }}' "$PATRONI_CONFIG_FILE"; then
    sed -i "s/{{ .Host }}/$(hostname)/g" "$PATRONI_CONFIG_FILE"
fi

mkdir -p "$DATA_DIR"
chown -R postgres:postgres "$DATA_DIR"
chmod -R 0700 "$DATA_DIR"

# Check if the data directory is a valid PostgreSQL cluster
if [ -f "$DATA_DIR/PG_VERSION" ]; then
    echo "Data directory $DATA_DIR contains an existing PostgreSQL cluster. Skipping initdb."
    chown -R postgres:postgres "$DATA_DIR"
    chmod -R 0700 "$DATA_DIR"
elif [ "$BOOTSTRAP_NODE" = "true" ]; then
    # Initialize PostgreSQL data directory (only for bootstrap node)
    echo "Initializing PostgreSQL in $DATA_DIR (bootstrap node)"
    gosu postgres initdb -D "$DATA_DIR"

    # Ensure permissions after initdb
    chown -R postgres:postgres "$DATA_DIR"
    chmod -R 0700 "$DATA_DIR"
    
    # Start Postgres temporarily to create user/db
    gosu postgres pg_ctl -D "$DATA_DIR" -o "-F -p 5432" start
    gosu postgres psql -v ON_ERROR_STOP=1 --username "postgres" --dbname "postgres" <<-EOSQL
        CREATE USER $POSTGRES_USER WITH ENCRYPTED PASSWORD '$POSTGRES_PASSWORD';
        CREATE USER $POSTGRES_REPLICATION_USERNAME WITH REPLICATION ENCRYPTED PASSWORD '$POSTGRES_REPLICATION_PASSWORD';
        CREATE DATABASE $POSTGRES_DB;
        GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO postgres;
        GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;
        ALTER USER $POSTGRES_USER WITH SUPERUSER;
EOSQL
    gosu postgres pg_ctl -D "$DATA_DIR" stop
else
    echo "Data directory $DATA_DIR is empty and BOOTSTRAP_NODE is false. Patroni will attempt to clone from the leader."
fi

# Start Patroni
exec gosu postgres /venv/bin/patroni "$PATRONI_CONFIG_FILE"