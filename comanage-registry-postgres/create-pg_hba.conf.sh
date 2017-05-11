#!/bin/bash 

# COmanage Registry PostgreSQL pg_hba.conf creation script
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

mkdir -p /etc/postgres

if [ -n "$COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD" ]
then

    cat >> /etc/postgres/pg_hba.conf <<EOF
local all postgres peer
host $COMANAGE_REGISTRY_POSTGRES_DATABASE $COMANAGE_REGISTRY_POSTGRES_USER 127.0.0.1/32 md5
host $COMANAGE_REGISTRY_POSTGRES_DATABASE $COMANAGE_REGISTRY_POSTGRES_USER samenet md5
EOF

else
    cat >> /etc/postgres/pg_hba.conf <<EOF
local all postgres peer
host $COMANAGE_REGISTRY_POSTGRES_DATABASE $COMANAGE_REGISTRY_POSTGRES_USER samenet trust
EOF

fi
