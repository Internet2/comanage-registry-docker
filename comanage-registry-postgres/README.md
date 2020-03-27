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

Intended to build a PostgreSQL image for use with COmanage Registry.

## Build Arguments

No arguments are required for building the image.

The following arguments may be supplied during the build:

```
--build-arg COMANAGE_REGISTRY_POSTGRES_DATABASE=<name of database to use with COmanage Registry>
--build-arg COMANAGE_REGISTRY_POSTGRES_USER=<database username>
--build-arg COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD=<database password>
```

## Building

```
docker build \
  -t comanage-registry-postgres:<tag> .
```

## Building Example

```
export COMANAGE_REGISTRY_POSTGRES_IMAGE_VERSION=1
TAG="${COMANAGE_REGISTRY_POSTGRES_IMAGE_VERSION}"
docker build \
  -t comanage-registry-postgres:$TAG .
```

## Volumes and Data Persistence

You must provide a volume or bind mount that mounts to `/var/lib/postgresql/data`
inside the container to persist data saved to the relational database.

## Environment Variables

The image supports the environment variables below and the `_FILE`
[convention](../docs/comanage-registry-common-environment-variables.md):

`POSTGRES_USER`

* Description: superuser
* Required: yes
* Default: `postgres`
* Example: `db_user`
* Note: Most deployers use the default.

`POSTGRES_PASSWORD`

* Description: password for superuser
* Required: yes
* Default: value of COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD
* Example: `l7cX28O3mt03y41EndjM`

`COMANAGE_REGISTRY_POSTGRES_DATABASE`

* Description: COmanage Registry database
* Required: yes
* Default: `registry`
* Example: `comanage_registry`

`COMANAGE_REGISTRY_POSTGRES_USER`

* Description: COmanage Registry database user
* Required: yes
* Default: `registry_user`
* Example: `comanage_registry_user`

`COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD`

* Description: password for database user
* Required: yes
* Default: `password`
* Example: `5Aw9SzS4xqYi7daHw57c`

## Authentication

Authentication is not required to connect from within the container,
but any client connecting from another host/container must provide
a password.

## Ports

The image listens for traffic on port 5432.

## Running

See other documentation in this repository for details on how to orchestrate
running this image with other images using an orchestration tool like
Docker Compose, Docker Swarm, or Kubernetes.

To run this image:

```
docker run -d \
  --name comanage-registry-database \
  -v /tmp/postgres-data:/var/lib/postgresql/data \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=superuser_password \
  -e COMANAGE_REGISTRY_POSTGRES_DATABASE=registry \
  -e COMANAGE_REGISTRY_POSTGRES_USER=registry_user \
  -e COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD=password \
  comanage-registry-postgres
```

## Logging

PostgreSQL logs to the stdout and stderr of the container.

## Connecting

After breaking into the container you may connect to the
COmanage Registry database as the COmanage Registry database
user by running

```
psql -h 127.0.0.1 ${COMANAGE_REGISTRY_POSTGRES_DATABASE} ${COMANAGE_REGISTRY_POSTGRES_USER}
```

For example

```
# psql -h 127.0.0.1 registry registry_user
Password for user registry_user: 
psql (9.6.12)
Type "help" for help.

registry=>
```

## Backups

A common strategy for backing up the database is to run another temporary
container that executes the `pg_dump` command. You need to be sure that the
temporary container and the database container use the same network.

An example is

```
docker run \
    -it \
    --rm \
    --network _default \
    comanage-registry-postgres \
    bash -c \
    'PGPASSWORD="password" \
    pg_dump \
        -h comanage-registry-database \
        -U registry_user \
        registry'
```

The output from the `pg_dump` command is sent to the stdout of the temporary
container and may be redirected to a file.

