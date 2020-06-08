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

# COmanage Registry Basic Auth

Intended to build a COmanage Registry image using Apache HTTP Server Basic Auth 
(Basic Auth) as the authentication mechanism. 

Basic Auth is only suitable for COmanage Registry deployments
not operating in a federated identity context, or for an introduction
to COmanage Registry. 

See other documentation in this repository for examples on how to build images 
that support federated identity deployments.

## Build Arguments

Building the image requires the following build arguments:

```
--build-arg COMANAGE_REGISTRY_VERSION=<version number>
--build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=<base image version number>
```

## Build Requirements

This image uses a [multi-stage build](https://docs.docker.com/develop/develop-images/multistage-build/)
and requires that the [COmanage Registry base image](../comanage-registry-base/README.md) be built first.

## Building


```
docker build \
  --build-arg COMANAGE_REGISTRY_VERSION=<COmanage Registry version number> \
  --build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=<base image version number> \
  -t comanage-registry:<tag> .
```

## Building Example

```
export COMANAGE_REGISTRY_VERSION=3.2.4
export COMANAGE_REGISTRY_BASE_IMAGE_VERSION=1
export COMANAGE_REGISTRY_BASIC_AUTH_IMAGE_VERSION=1
TAG="${COMANAGE_REGISTRY_VERSION}-basic-auth-${COMANAGE_REGISTRY_BASIC_AUTH_IMAGE_VERSION}" 
docker build \
  --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
  --build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_BASE_IMAGE_VERSION} \
  -t comanage-registry:$TAG .
```

## Volumes and Data Persistence

See [COmanage Registry Volumes and Data Persistence](../docs/volumes-and-data-persistence.md).

## Environment Variables

See the [list of environment variables common to all images](../docs/comanage-registry-common-environment-variables.md)
including this image.

## Authentication

This image supports using Apache HTTP Server Basic Auth (Basic Auth) as the
authentication mechanism. To aid simple deployments for evaluating and
learning COmanage Registry a password file with a single user and password
is included. See the section above on environment variables.

To override the default bind mount or COPY in a password file created
with the `htpasswd` command line tool. For example

```
COPY passwords /etc/apache2/passwords
```

## Ports

The image listens for web traffic on ports 80 and 443. All requests
on port 80 are redirected to port 443.

## Running

See other documentation in this repository for details on how to orchestrate
running this image with other images using an orchestration tool like
Docker Compose, Docker Swarm, or Kubernetes.

To run this image:

```
docker run -d \
  --name comanage-registry \
  -v /opt/comanage-registry-local:/srv/comanage-registry/local \
  -p 80:80 \
  -p 443:443 \
  comanage-registry:3.2.4-basic-auth-1
```

## Logging

Both Apache HTTP Server and COmanage Registry log to the stdout and
stderr of the container.

## HTTPS Configuration

See the section on environment variables and the `HTTPS_CERT_FILE`,
`HTTPS_PRIVKEY_FILE`, and `HTTPS_CHAIN_FILE` variables.

Additionally you may bind mount or COPY in an X.509 certificate file (containing the CA signing certificate(s), if any)
and associated private key file. For example

```
COPY cert.pem /etc/apache2/cert.pem
COPY privkey.pem /etc/apache2/privkey.pem
```
