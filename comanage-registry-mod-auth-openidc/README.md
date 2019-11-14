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

# COmanage Registry mod_auth_openidc

Intended to build a COmanage Registry image using the mod_auth_openidc
module for Apache HTTP Server as the authentication mechanism. 

## Build Arguments

Building the image requires the following build arguments:

```
--build-arg COMANAGE_REGISTRY_VERSION=<version number>
--build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=<base image version number>
```

Additionally the following build argument may be specified:

```
--build-arg MOD_AUTH_OPENIDC_SRC_URL=<URL for mod_auth_openidc source tarball>
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
  -t comanage-registry:<tag> .
```

## Building Example

```
export COMANAGE_REGISTRY_VERSION=3.2.1
export COMANAGE_REGISTRY_BASE_IMAGE_VERSION=1
export COMANAGE_REGISTRY_MOD_AUTH_OPENIDC_IMAGE_VERSION=1
TAG="${COMANAGE_REGISTRY_VERSION}-mod-auth-openidc-${COMANAGE_REGISTRY_MOD_AUTH_OPENIDC_IMAGE_VERSION}"

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

This image supports using the mod_auth_openidc module for Apache HTTP Server as the
authentication mechanism. Deployers should bind mount or COPY in the Apache HTTP Server
configuration file `/etc/apache2/conf-enabled/mod-auth-openidc.conf` that contains
the necessary OIDC client, secret, redirect URI, and other mod_auth_openidc
integration details.

An example `mod-auth-openidc.conf` configuration is

```
OIDCProviderMetadataURL https://cilogon.org/.well-known/openid-configuration
OIDCRemoteUserClaim sub

OIDCClientID cilogon:/client_id/3815e327237181f2ca55e39c305a5706
OIDCClientSecret w5TmBFgrLEZVl7P3VYw5

OIDCScope "openid email profile org.cilogon.userinfo"
OIDCCryptoPassphrase X7iAVpP9c3vr3WTsxrd7

OIDCRedirectURI https://registry.cilogon.org/secure/redirect

<Location /secure/redirect>
  AuthType openid-connect
  Require valid-user
</Location>
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
  -e COMANAGE_REGISTRY_ADMIN_GIVEN_NAME=Julia \
  -e COMANAGE_REGISTRY_ADMIN_FAMILY_NAME=Janseen \
  -e COMANAGE_REGISTRY_ADMIN_USERNAME=http://cilogon.org/serverA/users/22981
  -v /opt/comanage-registry-local:/srv/comanage-registry/local \
  -v mod-auth-openidc.conf:/etc/apache2/conf-enabled/mod-auth-openidc.conf \
  -p 80:80 \
  -p 443:443 \
  comanage-registry:3.2.1-mod-auth-openidc-1
```

## Logging

Apache HTTP Server and COmanage Registry log to the stdout and
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
