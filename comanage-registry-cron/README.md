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

# COmanage Registry Cron

Intended to build a COmanage Registry image that uses cron to execute
COmanage Registry [JobShell](https://spaces.at.internet2.edu/x/m4MQBg) jobs.
(See also [Registry Installation - Cron](https://spaces.at.internet2.edu/x/voD4Ag)).

## Build Arguments

Building the image requires the following build arguments:

```
--build-arg COMANAGE_REGISTRY_VERSION=<version number>
--build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=<base image version number>
```

## Build Requirements

This image uses a [multi-stage build](https://docs.docker.com/develop/develop-images/multistage-build/).
It requires that the [COmanage Registry base image](../comanage-registry-base/README.md) 
be built first.

## Building

```
docker build \
  --build-arg COMANAGE_REGISTRY_VERSION=<COmanage Registry version number> \
  --build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=<base image version number> \
  -t comanage-registry-cron:<tag> .
```

## Building Example

```
export COMANAGE_REGISTRY_VERSION=3.3.0
export COMANAGE_REGISTRY_BASE_IMAGE_VERSION=1
export COMANAGE_REGISTRY_CRON_IMAGE_VERSION=1
TAG="${COMANAGE_REGISTRY_VERSION}-${COMANAGE_REGISTRY_CRON_IMAGE_VERSION}"

docker build \
  --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
  --build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_BASE_IMAGE_VERSION} \
  -t comanage-registry-cron:$TAG .
```

## Volumes and Data Persistence

This image does not require data persistence using volumes, but it is often convenient
to use the same volume for this image as is used for COmanage Registry so that the
JobShell code easily uses the same database configuration used for COmanage Registry.
See [COmanage Registry Volumes and Data Persistence](../docs/volumes-and-data-persistence.md).

If you do not use the same volume that is used with COmanage Registry you need 
to inject the necessary environment variables so that the container can create
the database configuration file dynamically. See the next section for details.

## Environment Variables

See the [list of environment variables common to all images](../docs/comanage-registry-common-environment-variables.md)
including this image. Since this image does not run a webserver many of the environment variables will
be ignored by containers instantiated from this image.

If you use the same volume that is used with COmanage Registry then you should
set the environment variable

```
COMANAGE_REGISTRY_NO_DATABASE_CONFIG
```

to any value so that the cron container does not attempt to also create
the database configuration file along with the COmanage Registry container.
Failure to do so may lead to a race condition where the cron container
writes an incorrect database configuration file because it does not
have access to the same details as the full COmanage Registry container.

If you do *not* use the same volume that is used with COmanage Registry be sure
to set the environment variables

* `COMANAGE_REGISTRY_DATASOURCE`
* `COMANAGE_REGISTRY_DATABASE`
* `COMANAGE_REGISTRY_DATABASE_HOST`
* `COMANAGE_REGISTRY_DATABASE_USER`
* `COMANAGE_REGISTRY_DATABASE_USER_PASSWORD`

so that the container is able to write its own database configuration file
and connect to the database.

See also the next section for details on how to specify the location of
the crontab file.

## Crontab File

When the container starts it will install a crontab file that is used by
cron to execute COmanage Registry COmanage Registry [JobShell](https://spaces.at.internet2.edu/x/m4MQBg) jobs.
The container will look for a crontab file at

```
/srv/comanage-registry/local/crontab
```
by default. If you are using the same volume as for COmanage Registry then you only
need to add the desired crontab file to that volume. Alternatively you may provide
a unique volume and add the crontab file to it (also be sure to inject the necessary
environment variables so that the container can connect to the database--see above).

You may also specify the location of the crontab file to install using the
environment variable

```
COMANAGE_REGISTRY_CRONTAB
```

If no crontab file is found the container uses this default crontab file:

```
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=""
# Deprecated job to run expirations, syncorgsources, and groupvalidity tasks (until Registry v4.0.0)
0 1 * * * cd /srv/comanage-registry/app && ./Console/cake job -q
# Run the job queue for CO 1 every 5 minutes starting at minute 0
0-59/5 * * * * cd /srv/comanage-registry/app && ./Console/cake job -q -r -c 1
```

## Authentication

The image does not run a webserver and does not require authentication.

## Ports

The image does not run a webserver and does not listen on any ports.

## Running

See other documentation in this repository for details on how to orchestrate
running this image with other images using an orchestration tool like
Docker Compose, Docker Swarm, or Kubernetes.

**Note that only one container instantiated from this image should run at
any given time. There is currently no cross-process locking for COmanage
Registry JobShell jobs.**

To run this image:

```
docker run -d \
  --name comanage-registry-cron \
  -v /opt/comanage-registry-local:/srv/comanage-registry/local \
  comanage-registry-cron:3.3.0-1
```

## Logging

The cron process logs to the stdout and stderr of the container.

