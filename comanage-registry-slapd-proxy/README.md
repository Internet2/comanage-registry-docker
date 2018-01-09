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
# OpenLDAP slapd proxy for COmanage Registry

Intended to build an OpenLDAP slapd image configured to run as
an LDAP proxy server.

## Build Arguments

No arguments are required for building the image.

The following arguments may be supplied during the build:

```
--build-arg COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION=<slapd base image version>
```

## Build Requirements

This image uses a [multi-stage build](https://docs.docker.com/develop/develop-images/multistage-build/).
It requires that the [OpenLDAP slapd base image](../comanage-registry-slapd-base/README.md) 
be built first.

## Building

```
docker build \
  --build-arg COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION=<slapd base image version> \
  -t comanage-registry-slapd-proxy:<tag> .
```

## Building Example

```
export COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION=1
export COMANAGE_REGISTRY_SLAPD_PROXY_IMAGE_VERSION=1
TAG="${COMANAGE_REGISTRY_SLAPD_IMAGE_VERSION}"
docker build \
  --build-arg COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION} \
  -t comanage-registry-slapd-proxy:$TAG .
```

## Volumes and Data Persistence

This image does not require volume or data persistence when used soley as an LDAP proxy
server and all necessary configuration is injected at run time. 

More complicated deployments may wish to persist some data or configuration. For such deployments
see [OpenLDAP slapd for COmanage Registry Volumes and Data Persistence](../docs/openldap-volumes-and-data-persistence.md).

## Environment Variables

See the [list of environment variables common to slapd images](../docs/slapd-common-environment-variables.md)
including this image.

## Ports

By default the container instantiated from the image binds to 127.0.0.1 and
listens for LDAP protocol traffic on port 389 only. To bind to other or all
network interfaces and listen on port 636 as well override the default
command for the image (see below for details).

## Running

See other documentation in this repository for details on how to orchestrate
running this image with other images using an orchestration tool like
Docker Compose, Docker Swarm, or Kubernetes.

To run this image:

```
docker run -d \
  --name ldapgateway \
  -e SLAPD_CERT_FILE=/run/secrets/slapd_cert_file \
  -e SLAPD_CHAIN_FILE=/run/secrets/slapd_chain_file \
  -e SLAPD_PRIVKEY_FILE=/run/secrets/slapd_privkey_file \
  -v /opt/docker/ldif/proxy_config.ldif:/ldif/config/ldap_gateway_proxy_config.ldif \
  -p 389:389 \
  -p 636:636 \
  comanage-registry-slapd-proxy:2 \
  slapd -d 0 -h 'ldapi:/// ldap:/// ldaps:///' -u openldap -g openldap
```

## Executing LDIF Files

See [Executing LDIF Files](../docs/slapd-ldif.md).

## Logging

The slapd daemon logs to the stdout and
stderr of the container.

## TLS Configuration

See the section on environment variables and the `SLAPD_CERT_FILE`, `SLAPD_CHAIN_FILE`,
and `SLAPD_PRIVKEY_FILE` variables.

Additionally you may bind mount or COPY in an X.509 certificate file, CA chain file,
and associated private key file. For example

```
COPY cert.pem /etc/ldap/slapd.crt
COPY chain.pem /etc/ldap/slapd.ca.crt
COPY privkey.pem /etc/ldap/slapd.key
```
