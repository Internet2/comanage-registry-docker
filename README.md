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

# COmanage Registry Docker

This repository contains Dockerfiles, documenation, and other files necessary to
build and deploy a Dockerized version of
[COmanage Registry](https://spaces.internet2.edu/display/COmanage/Home), as well as
other infrastructure commonly deployed with COmanage Registry.

Since COmanage Registry is a web application that requires a relational database
and an authentication mechanism such as 
[Shibboleth](https://www.shibboleth.net/products/service-provider/), 
[mod\_auth\_openidc](https://github.com/zmartzone/mod_auth_openidc),
or just simple [Basic Authentication](https://httpd.apache.org/docs/2.4/mod/mod_auth_basic.html),
this repository includes multiple Dockerfiles to build images that use various
combinations of tools.

## Evaluate COmanage Registry

If you are new to COmanage Registry follow [these instructions](docs/evaluation.md) to build
and run a simple deployment suitable for evaluating COmanage Registry. 

## Building Images

The following link to detailed instructions for building each individual image. See the next
section for links to documentation on how to deploy the images as services.

* [COmanage Registry base image](comanage-registry-base/README.md)
* [COmanage Registry with Basic Authentication](comanage-registry-basic-auth/README.md)
* [COmanage Registry with Shibboleth SP base image](comanage-registry-shibboleth-sp-base/README.md)
* [COmanage Registry with Shibboleth SP](comanage-registry-shibboleth-sp/README.md)
* [COmanage Registry with mod\_auth\_openidc](comanage-registry-mod-auth-openidc/README.md)
* [COmanage Registry for Internet2 TIER base](comanage-registry-internet2-tier-base/README.md)
* [COmanage Registry for Internet2 TIER](comanage-registry-internet2-tier/README.md)
* [PostgreSQL for COmanage Registry](comanage-registry-postgres/README.md)
* [OpenLDAP slapd base for COmanage Registry](comanage-registry-slapd-base/README.md)
* [OpenLDAP slapd for COmanage Registry](comanage-registry-slapd/README.md)
* [OpenLDAP slapd proxy for COmanage Registry](comanage-registry-slapd-proxy/README.md)

## Deploying Images and Running Services

Since COmanage Registry requires a relational database, and because it is often deployed with
other tools like an LDAP directory, multiple images need to be simultanesouly instantiated
as containers. Orchestrating multiple containers to create services is easiest using
tools such as [Docker Compose](https://docs.docker.com/compose/), 
[Docker Swarm](https://docs.docker.com/engine/swarm/), or 
[Kubernetes](https://kubernetes.io/).

The images built from Dockerfiles in this repository may be used with any container
orchestration platform but the documentation demonstrates how to deploy with
Docker Swarm (the simple evaluation scenario above uses Docker Compose).

The following link to detailed instructions for a number of deployment scenarios.

* [COmanage Registry using the Shibboleth SP and PostgreSQL database](docs/shibboleth-sp-postgresql.md)
* [COmanage Registry using the Shibboleth SP and MariaDB database](docs/shibboleth-sp-mariadb.md)
* [COmanage Registry using mod\_auth\_openidc and MariaDB database](docs/mod-auth-openidc-mariadb.md)
* [COmanage Registry using the Internet2 TIER image](docs/comanage-registry-internet2-tier.md)
* [Adding an OpenLDAP Directory](docs/adding-openldap.md)
* [Adding an OpenLDAP proxy server](docs/adding-openldap-proxy.md)

## All Documentation

### Building Images

* [COmanage Registry base image](comanage-registry-base/README.md)
* [COmanage Registry with Basic Authentication](comanage-registry-basic-auth/README.md)
* [COmanage Registry with Shibboleth SP base image](comanage-registry-shibboleth-sp-base/README.md)
* [COmanage Registry with Shibboleth SP](comanage-registry-shibboleth-sp/README.md)
* [COmanage Registry with mod\_auth\_openidc](comanage-registry-mod-auth-openidc/README.md)
* [COmanage Registry for Internet2 TIER base](comanage-registry-internet2-tier-base/README.md)
* [COmanage Registry for Internet2 TIER](comanage-registry-internet2-tier/README.md)
* [PostgreSQL for COmanage Registry](comanage-registry-postgres/README.md)
* [OpenLDAP slapd base for COmanage Registry](comanage-registry-slapd-base/README.md)
* [OpenLDAP slapd for COmanage Registry](comanage-registry-slapd/README.md)
* [OpenLDAP slapd proxy for COmanage Registry](comanage-registry-slapd-proxy/README.md)

### Deploying Services

* [COmanage Registry using the Shibboleth SP and PostgreSQL database](docs/shibboleth-sp-postgresql.md)
* [COmanage Registry using the Shibboleth SP and MariaDB database](docs/shibboleth-sp-mariadb.md)
* [COmanage Registry using mod\_auth\_openidc and MariaDB database](docs/mod-auth-openidc-mariadb.md)
* [COmanage Registry using the Internet2 TIER image](docs/comanage-registry-internet2-tier.md)
* [Adding an OpenLDAP Directory](docs/adding-openldap.md)
* [Adding an OpenLDAP proxy server](docs/adding-openldap-proxy.md)

### Other

* [COmanage Registry Volumes and Data Persistence](docs/volumes-and-data-persistence.md)
* [Evaluating COmanage Registry using Docker](docs/evaluation.md)
* [Environment Variables Common to All Images](docs/comanage-registry-common-environment-variables.md)
* [Environment Variables Common to Images using Shibboleth SP for Authentication](docs/comanage-registry-common-shibboleth-environment-variables.md)
* [Environment Variables Common to All slapd Images](docs/slapd-common-environment-variables.md)
* [Executing LDIF Files](docs/slapd-ldif.md)
* [OpenLDAP slapd for COmanage Registry Volumes and Data Persistence](docs/openldap-volumes-and-data-persistence.md)
