#!/bin/bash
set -e

#    CREATE USER registry_user WITH PASSWORD 'tigger';

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER registry_user;
    CREATE DATABASE registry;
    GRANT ALL PRIVILEGES ON DATABASE registry TO registry_user;
EOSQL
