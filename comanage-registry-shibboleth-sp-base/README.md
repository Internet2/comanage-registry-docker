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

# COmanage Registry Shibboleth SP Base

Intended to build a Shibboleth SP for Apache HTTP Server image intended to be used with
[COmanage Registry](https://spaces.internet2.edu/display/COmanage/Home).

The image built from this Dockerfile is primarily intended to be used
as a base for building other COmanage Registry images using Dockerfile 
multi-stage build functionality. 

## Build Arguments

The following arguments *may* be provided when building but are not required
since the Dockerfile uses the latest recommended values:

```
--build-arg LOG4SHIB_URL=<URL to log4shib source tarball>
--build-arg OPENSAMLC_URL=<URL to opensaml source tarball>
--build-arg SHIBBOLETH_SP_URL=<URL to Shibboleth SP source tarball>
--build-arg XERCESC_URL=<URL to xerces-c source tarball>
--build-arg XMLSECC_URL=<URL to xml-security-c source tarball>
--build-arg XMLTOOLING_URL=<URL to xmltooling source tarball>
```

## Building

```
docker build \
  -t comanage-registry-shibboleth-sp-base:<tag> .
```

## Building Example

```
export COMANAGE_REGISTRY_SHIBBOLETH_SP_VERSION=3.1.0
export COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION=1
TAG="${COMANAGE_REGISTRY_SHIBBOLETH_SP_VERSION}-${COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION}"
docker build \
    -t comanage-registry-shibboleth-sp-base:$TAG .
```
