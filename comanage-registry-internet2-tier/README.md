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

# COmanage Registry Internet2 TIER

Intended to build a COmanage Registry image using the Shibboleth Native SP
for Apache HTTP Server (Shibboleth) as the authentication mechanism and that
meets the 
[TIER Docker Container Specification](https://spaces.at.internet2.edu/x/m4ZyBw)
from the
[Internet2 TIER](https://www.internet2.edu/vision-initiatives/initiatives/trust-identity-education-research/)
program.

## Build Arguments

Building the image requires the following build arguments:

```
--build-arg COMANAGE_REGISTRY_VERSION=<version number>
--build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=<base image version number>
--build-arg COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION=<I2 base image version number>
```

## Build Requirements

This image uses a [multi-stage build](https://docs.docker.com/develop/develop-images/multistage-build/).
It requires that the [COmanage Registry base image](../comanage-registry-base/README.md) 
and [Internet2 TIER base image](../comanage-registry-internet2-tier-base/README.md) be built first.

## Building

```
docker build \
  --build-arg COMANAGE_REGISTRY_VERSION=<COmanage Registry version number> \
  --build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=<base image version number> \
  --build-arg COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION=<base image version number> \
  -t comanage-registry:<tag> .
```

## Building Example

```
export COMANAGE_REGISTRY_VERSION=3.2.4
export COMANAGE_REGISTRY_BASE_IMAGE_VERSION=1
export COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION=2
export COMANAGE_REGISTRY_I2_IMAGE_VERSION=1
TAG="${COMANAGE_REGISTRY_VERSION}-internet2-tier-${COMANAGE_REGISTRY_I2_IMAGE_VERSION}"
docker build \
  --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
  --build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_BASE_IMAGE_VERSION} \
  --build-arg COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION} \
  -t comanage-registry:$TAG .
```

## Volumes and Data Persistence

See [COmanage Registry Volumes and Data Persistence](../docs/volumes-and-data-persistence.md).


## Environment Variables

See the [list of environment variables common to all images](../docs/comanage-registry-common-environment-variables.md)
including this image.

See also the
[list of environment variables common to all images using Shibboleth](../docs/comanage-registry-common-shibboleth-environment-variables.md).

Additionally the Internet2 TIER image supports the following environment variables:

`ENV`

* Description: Environment
* Required: No
* Default: None
* Example: PROD
* Note: Usually one of PROD, TEST, or DEV. The value is included in log entries.

`USERTOKEN`

* Description: Deployer supplied
* Required: No
* Default: None
* Example: node01
* Note: The value is included in log entries.

## Authentication

This image supports using the Shibboleth Native SP for Apache HTTP Server (Shibboleth) as the
authentication mechanism. Deployers should configure Shibboleth so that the desired
asserted user attribute is written into `REMOTE_USER`.

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
  -e COMANAGE_REGISTRY_ADMIN_GIVEN_NAME=Julia \
  -e COMANAGE_REGISTRY_ADMIN_FAMILY_NAME=Janseen \
  -e COMANAGE_REGISTRY_ADMIN_USERNAME=julia.janseen@my.org \
  -e SHIBBOLETH_SP_ENTITY_ID=https://myapp.my.org/shibboleth/sp \
  -e SHIBBOLETH_SP_METADATA_PROVIDER_XML_FILE=/etc/shibboleth/my-org-metadata.xml \
  -v /opt/comanage-registry-local:/srv/comanage-registry/local \
  -v /etc/shibboleth/sp-encrypt-cert.pem:/etc/shibboleth/sp-encrypt-cert.pem \
  -v /etc/shibboleth/sp-encrypt-key.pem:/etc/shibboleth/sp-encrypt-key.pem \
  -v /etc/shibboleth/my-org-metadata.xml:/etc/shibboleth/my-org-metadata.xml \
  -p 80:80 \
  -p 443:443 \
  comanage-registry:3.2.4-internet2-tier-1
```

## Logging

Apache HTTP Server, COmanage Registry, Shibboleth, and supervisord all log to the stdout and
stderr of the container.

The logging configuration meets version 1 of the
[TIER Docker Container Specification](https://spaces.at.internet2.edu/x/m4ZyBw).

## HTTPS Configuration

See the section on environment variables and the `HTTPS_CERT_FILE` and
`HTTPS_PRIVKEY_FILE` variables.

Additionally you may bind mount or COPY in an X.509 certificate file (containing the CA signing certificate(s), if any)
and associated private key file. For example

```
COPY cert.pem /etc/httpd/cert.pem
COPY privkey.pem /etc/httpd/privkey.pem
```
