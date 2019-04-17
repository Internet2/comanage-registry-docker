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
# OpenLDAP slapd base for COmanage Registry

Intended to build an OpenLDAP slapd base image used by other
images in this repository as part of a
[multi-stage](https://docs.docker.com/develop/develop-images/multistage-build/)
build.

## Build Arguments

No arguments are required for building the image.

The following arguments may be supplied during the build:

```
--build-arg OLC_SUFFIX=<directory suffix>
--build-arg OLC_ROOT_DN=<directory root DN>
--build-arg OLC_ROOT_PW=<root DN password, usually hashed>
```

## Building

```
docker build \
  -t comanage-registry-slapd-base:<tag> .
```

## Building Example

```
export COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION=1
TAG="${COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION}"
docker build \
  -t comanage-registry-slapd-base:$TAG .
```
