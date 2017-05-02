#!/bin/bash

# COmanage Registry PostgreSQL Dockerfile entrypoint
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

if [[ -f "${COMANAGE_REGISTRY_POSTGRES_DATABASE_FILE}" ]]; then
    COMANAGE_REGISTRY_POSTGRES_DATABASE=`cat ${COMANAGE_REGISTRY_POSTGRES_DATABASE_FILE}`
    export COMANAGE_REGISTRY_POSTGRES_DATABASE
fi

if [[ -f "${COMANAGE_REGISTRY_POSTGRES_USER_FILE}" ]]; then
    COMANAGE_REGISTRY_POSTGRES_USER=`cat ${COMANAGE_REGISTRY_POSTGRES_USER_FILE}`
    export COMANAGE_REGISTRY_POSTGRES_USER
fi

if [[ -f "${COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD_FILE}" ]]; then
    COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD=`cat ${COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD_FILE}`
    export COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD
fi

exec "/docker-entrypoint.sh" "$@"
