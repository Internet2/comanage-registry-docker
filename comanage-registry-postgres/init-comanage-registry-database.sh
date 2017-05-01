#!/bin/bash -x

# COmanage Registry PostgreSQL entrypoint
#
# Portions licensed to the University Corporation for Advanced Internet
# Development, Inc. ("UCAID") under one or more contributor license agreements.
# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
#
# UCAID licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with the
# License. You may obtain a copy of the License at:
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

if [ -n "$COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD" ]
then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER $COMANAGE_REGISTRY_POSTGRES_USER WITH ENCRYPTED PASSWORD '$COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD';
    CREATE DATABASE $COMANAGE_REGISTRY_POSTGRES_DATABASE;
    GRANT ALL PRIVILEGES ON DATABASE $COMANAGE_REGISTRY_POSTGRES_DATABASE TO $COMANAGE_REGISTRY_POSTGRES_USER;
EOSQL

else
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER $COMANAGE_REGISTRY_POSTGRES_USER;
    CREATE DATABASE $COMANAGE_REGISTRY_POSTGRES_DATABASE;
    GRANT ALL PRIVILEGES ON DATABASE $COMANAGE_REGISTRY_POSTGRES_DATABASE TO $COMANAGE_REGISTRY_POSTGRES_USER;
EOSQL

fi
