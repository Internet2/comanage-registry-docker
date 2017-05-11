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

# Measure the existing pg_hba.conf file to see if it is the default.
# The default version written will depend on whether or not passwords
# have been injected.
CHECKSUM=`md5sum /var/lib/postgresql/data/pg_hba.conf | awk '{print $1}'`
if [ "$CHECKSUM" = "d3cf011ed2c2f5ff9b7664911969c0f5" ] || [ "$CHECKSUM" = "42f44484c701461a44b713b1b6c0b901" ]
then
    PG_HBA_DEFAULT="1"
else
    PG_HBA_DEFAULT="0"
fi

# If the pg_hba.conf file is the default overwrite a more restrictive
# version.

if [ "$PG_HBA_DEFAULT" = "1" ]
then
    # If a password has been injected require it, otherwise just use samenet trust.
    if [ -n "$COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD" ] 
    then
        cat > /var/lib/postgresql/data/pg_hba.conf <<EOF
local all postgres peer
host $COMANAGE_REGISTRY_POSTGRES_DATABASE $COMANAGE_REGISTRY_POSTGRES_USER 127.0.0.1/32 md5
host $COMANAGE_REGISTRY_POSTGRES_DATABASE $COMANAGE_REGISTRY_POSTGRES_USER samenet md5
EOF

    else
        cat > /var/lib/postgresql/data/pg_hba.conf <<EOF
local all postgres peer
host $COMANAGE_REGISTRY_POSTGRES_DATABASE $COMANAGE_REGISTRY_POSTGRES_USER samenet trust
EOF
    fi
fi
