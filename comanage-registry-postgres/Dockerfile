# COmanage Registry Dockerfile template
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
FROM postgres:9.6

ENV INIT_DIR /docker-entrypoint-initdb.d

RUN mkdir -p "$INIT_DIR"

COPY init-comanage-registry-database.sh "$INIT_DIR/init-comanage-registry-database.sh"
COPY create-pg_hba.conf.sh "$INIT_DIR/create-pg_hba.conf.sh"
COPY comanage-registry-postgres-entrypoint.sh /usr/local/bin/comanage-registry-postgres-entrypoint.sh

RUN chmod 0755 "$INIT_DIR/init-comanage-registry-database.sh"
RUN chmod 0755 "$INIT_DIR/create-pg_hba.conf.sh"
RUN chmod 0755 /usr/local/bin/comanage-registry-postgres-entrypoint.sh

ARG COMANAGE_REGISTRY_POSTGRES_DATABASE
ARG COMANAGE_REGISTRY_POSTGRES_USER
ARG COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD

ENV COMANAGE_REGISTRY_POSTGRES_DATABASE ${COMANAGE_REGISTRY_POSTGRES_DATABASE:-registry}
ENV COMANAGE_REGISTRY_POSTGRES_USER ${COMANAGE_REGISTRY_POSTGRES_USER:-registry_user}
ENV COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD ${COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD:-password}

ENV POSTGRES_PASSWORD ${COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD:-password}

ENTRYPOINT ["/usr/local/bin/comanage-registry-postgres-entrypoint.sh"]

CMD ["postgres"]
