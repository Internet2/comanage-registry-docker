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

# Adding OpenLDAP for COmanage Registry

Follow these steps to build and add OpenLDAP slapd
as a managed service to an existing COmanage Registry service stack.

* Complete the instructions for deploying COmanage Registry with
a relational database. Choose one of
  * [COmanage Registry using the Shibboleth SP and PostgreSQL database](shibboleth-sp-postgresql.md),
  * [COmanage Registry using the Shibboleth SP and MariaDB database](shibboleth-sp-mariadb.md),
  * [COmanage Registry using mod\_auth\_openidc and MariaDB database](mod-auth-openidc-mariadb.md),
  * [COmanage Registry using the Internet2 TIER image](comanage-registry-internet2-tier.md).

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

* Define the shell variable `COMANAGE_REGISTRY_SLAPD_IMAGE_VERSION`
to be the version of the image you are about to build:

```
export COMANAGE_REGISTRY_SLAPD_IMAGE_VERSION=1
```

* Build the slapd image:

```
pushd comanage-registry-slapd
TAG="${COMANAGE_REGISTRY_SLAPD_IMAGE_VERSION}"
docker build \
    --build-arg COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_SLAPD_BASE_IMAGE_VERSION} \
    -t comanage-registry-slapd:$TAG . 
popd
```

* Use the [slappasswd OpenLDAP password utility](https://linux.die.net/man/8/slappasswd)
to create a hashed password value.

* Create a secret to store the hashed password value you just created
(be sure to use your own value and not the example below):

```
echo "{SSHA}emcy1JA+mxbHH0PMPcnasE9apBStAMks" | docker secret create olc_root_pw
```

* Create directories on the Docker engine host(s) for state files:

```
sudo mkdir -p /srv/docker/var/lib/ldap
sudo mkdir -p /srv/docker/etc/slapd.d
```

* Define shell variables for the directory suffix and root DN,
  for example:

```
export OLC_SUFFIX=dc=my,dc=org
export OLC_ROOT_DN=cn=admin,dc=my,dc=org
```

* Edit the Docker Swarm services stack description (compose) file you previously
created and add the following service description after the existing services:

```
comanage-registry-ldap:
    image: comanage-registry-slapd:${COMANAGE_REGISTRY_SLAPD_IMAGE_VERSION}
    command: ["slapd", "-d", "256", "-h", "ldapi:/// ldap:///", "-u", "openldap", "-g", "openldap"]
    volumes:
        - /srv/docker/var/lib/ldap:/var/lib/ldap
        - /srv/docker/etc/slapd.d:/etc/ldap/slapd.d
    environment:
        - OLC_ROOT_PW_FILE=/run/secrets/olc_root_pw
        - OLC_SUFFIX=${OLC_SUFFIX}
        - OLC_ROOT_DN=${OLD_ROOT_DN}
    secrets:
        - olc_root_pw
    networks:
        - default
    deploy:
        replicas: 1
```

* Be sure to also edit the services stack description file and add
the `olc_root_pw` secret to the list of secrets.

* Deploy the COmanage Registry service stack:

```
docker stack deploy --compose-file comanage-registry-stack.yml comanage-registry
```

You may monitor the progress of the slapd container using

```
docker service logs -f comanage-registry-ldap
```

The container does not bootstrap any structure in the directory, i.e. it
does not create any `ou=people` or `ou=groups` branches that are usually
used with COmanage Registry.  To have the container create the necessary
structure for your deployment see [Executing LDIF Files](slapd-ldif.md).

To use TLS for connections to slapd (either on port 636 using ldaps://
or via `START_TLS` on port 389) define the environment variables
`SLAPD_CERT_FILE`, `SLAPD_CHAIN_FILE`, and `SLAPD_PRIVKEY_FILE`
and then change the `command` above to be

```
command: ["slapd", "-d", "256", "-h", "ldapi:/// ldap:/// ldaps:///", "-u", "openldap", "-g", "openldap"]
```
