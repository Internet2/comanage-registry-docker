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

# COmanage Registry Internet2 TIER Base Image

Intended to build a COmanage Registry for Internet2 TIER base image
using CentOS 7 as the operating system and building PHP from source.

By itself the image built from this Dockerfile does **not** provide
COmanage Registry.

The image built from this Dockerfile is used as the base
for the Internet2 TIER image that includes COmanage Registry
with the Shibboleth Native SP for Apache HTTP Server (Shibboleth)
as the authentication mechanism.

## Build Arguments

No arguments are required for the build but the following argument
may be provided to override the default:

```
--build-arg PHP_VERSION=<PHP version number>
```

## Building

```
docker build \
    -t comanage-registry-internet2-tier-base:<tag> .
```

## Building Example

```
export COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION=2
TAG="${COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION}"
docker build \
    -t comanage-registry-internet2-tier-base:${TAG} .
```
