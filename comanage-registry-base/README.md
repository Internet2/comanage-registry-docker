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

# COmanage Registry Base Image

Intended to build a COmanage Registry base image
using the official PHP with Apache image as the foundation.

By itself the image built from this Dockerfile does **not** provide any
method for authentication and is not suitable for deployment. 

The image built from this Dockerfile is used as the base
for images that include an authentication mechanism.
See other documentation in this
repository for examples on how to build images on this
one that include authentication methods like Basic Auth,
Shibboleth SP, and mod\_auth\_openidc.

## Build Arguments

Building the image requires the following build argument:

```
--build-arg COMANAGE_REGISTRY_VERSION=<COmanage Registry version number>
```

## Building

```
docker build \
    --build-arg COMANAGE_REGISTRY_VERSION=<COmanage Registry version number> \
    -t comanage-registry-base:<tag> .
```

## Building Example

```
export COMANAGE_REGISTRY_VERSION=3.2.1
export COMANAGE_REGISTRY_BASE_IMAGE_VERSION=1
TAG="${COMANAGE_REGISTRY_VERSION}-${COMANAGE_REGISTRY_BASE_IMAGE_VERSION}"
docker build \
  --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
  -t comanage-registry-base:${TAG} .
```
