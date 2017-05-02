<!--
COmanage Registry Docker documentation

Portions licensed to the University Corporation for Advanced Internet
Development, Inc. ("UCAID") under one or more contributor license agreements.
See the NOTICE file distributed with this work for additional information
regarding copyright ownership.

UCAID licenses this file to you under the Apache License, Version 2.0
(the "License"); you may not use this file except in compliance with the
License. You may obtain a copy of the License at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->

# PostgreSQL for COmanage Registry

A simple example demonstrating how to create an image and container
based on PostgreSQL to use with COmanage Registry containers. 

## Build

```
docker build -t comanage-registry-postgres .
```

## Run

Create a user-defined network bridge with

```
docker network create --driver=bridge \
  --subnet=192.168.0.0/16 \
  --gateway=192.168.0.100 \
  comanage-registry-internal-network
```

and then mount a host directory such as `/tmp/postgres-data`
to `/var/lib/postgresql/data` inside the container to persist
data, eg.

```
docker run -d --name comanage-registry-database \
  --network comanage-registry-internal-network \
  -v /tmp/postgres-data:/var/lib/postgresql/data \
  comanage-registry-postgres
```

You can use the following environment variables with the image:

* `POSTGRES_USER`: superuser (default is `postgres`)
* `POSTGRES_PASSWORD`: password for superuser (no default)
* `COMANAGE_REGISTRY_POSTGRES_DATABASE`: COmanage Registry database (default is `registry`)
* `COMANAGE_REGISTRY_POSTGRES_USER`: COmanage Registry database user (default is `registry_user`)
* `COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD`: password for database user (no default)

For example:

```
docker run -d --name comanage-registry-database \
  --network comanage-registry-internal-network \
  -v /tmp/postgres-data:/var/lib/postgresql/data \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=superuser_password \
  -e COMANAGE_REGISTRY_POSTGRES_DATABASE=registry \
  -e COMANAGE_REGISTRY_POSTGRES_USER=registry_user \
  -e COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD=password \
  comanage-registry-postgres
```

You may also set environment variables that point to files from which to read
the same details, for example

```
docker run -d --name comanage-registry-database \
  --network comanage-registry-internal-network \
  -v /tmp/postgres-data:/var/lib/postgresql/data \
  -e POSTGRES_USER_FILE=/run/secrets/postgres_user \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password \
  -e COMANAGE_REGISTRY_POSTGRES_DATABASE_FILE=/run/secrets/comanage_registry_postgres_database \
  -e COMANAGE_REGISTRY_POSTGRES_USER_FILE=/run/secrets/comanage_registry_postgres_user \
  -e COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD_FILE=/run/secrets/comanage_registry_postgres_user_password \
  comanage-registry-postgres
```

If you do not set a password for the superuser or the COmanage Registry user then
any client with access to the container may connect to the database.
