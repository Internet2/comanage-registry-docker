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

# Adding OpenLDAP Proxy for COmanage Registry

Follow these steps to build and add an OpenLDAP slapd
proxy as a managed service to an existing COmanage Registry service stack.
An OpenLDAP slapd proxy is often deployed with slapd servers configured
for high availability using either "multi-master" or "mirror mode"
approaches. See the [slapd-ldap](https://linux.die.net/man/5/slapd-ldap)
man page for details on the LDAP backend used to instantiate a slapd
proxy and the OpenLDAP documentation on [replication](http://www.openldap.org/doc/admin24/replication.html)
for details on both the multi-master and mirror mode architectures.

* Define the shell variable `COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION` to be the
version of the base image you are about to build:

```
export COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION=1
```

* Build the base image:

```
pushd comanage-registry-slapd-base
TAG="${COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION}"
docker build \
  -t comanage-registry-slapd-base:${TAG} .
popd
```

* Define the shell variable `COMANAGE_REGISTRY_SLAPD_PROXY_IMAGE_VERSION`
to be the version of the image you are about to build:

```
export COMANAGE_REGISTRY_SLAPD_PROXY_IMAGE_VERSION=1
```

* Build the slapd image:

```
pushd comanage-registry-slapd-proxy
TAG="${COMANAGE_REGISTRY_SLAPD_PROXY_IMAGE_VERSION}"
docker build \
    --build-arg COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION} \
    -t comanage-registry-shibboleth-slapd-proxy:$TAG . 
popd
```

* Edit the Docker Swarm services stack description (compose) file you previously
created and add the following service description after the existing services:

```
comanage-registry-ldap-proxy:
    image: comanage-registry-slapd-proxy:${COMANAGE_REGISTRY_SLAPD_PROXY_IMAGE_VERSION}
    command: ["slapd", "-d", "256", "-h", "ldapi:/// ldap:///", "-u", "openldap", "-g", "openldap"]
    networks:
        - default
    deploy:
        replicas: 1
```

* Deploy the COmanage Registry service stack:

```
docker stack deploy --compose-file comanage-registry-stack.yml comanage-registry
```

You may monitor the progress of the slapd proxy container using

```
docker service logs -f comanage-registry-ldap-proxy
```

When run as a proxy slapd does not require any state be saved but
the deployer must configure the LDAP backend before slapd will
proxy any requests.

To have the container create the necessary
LDAP backend configuration for your deployment see [Executing LDIF Files](slapd-ldif.md)
and use a LDIF file like (be sure to modify as necessary for your own
deployment, and pay special attention to the olcAccess configuration you
wish to use)

```
dn: olcDatabase=ldap,cn=config
changetype: add
objectClass: olcDatabaseConfig
objectClass: olcLDAPConfig
olcDatabase: ldap
olcSuffix: dc=mycampus,dc=org
olcDbURI: "ldap://ldap-01 ldap://ldap-02"
olcDbQuarantine: 60,+
olcAccess: {0}to * by * write
```

To use TLS for connections to slapd (either on port 636 using ldaps://
or via `START_TLS` on port 389) define the environment variables
`SLAPD_CERT_FILE`, `SLAPD_CHAIN_FILE`, and `SLAPD_PRIVKEY_FILE`
and then change the `command` above to be

```
command: ["slapd", "-d", "256", "-h", "ldapi:/// ldap:/// ldaps:///", "-u", "openldap", "-g", "openldap"]
```

Also change the LDAP backend configuration to include

```
olcSecurity: tls=256
```
