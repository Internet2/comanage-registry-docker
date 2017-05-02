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

## What it is
Dockerfile templates and associated files to 
build images for 
[COmanage Registry](https://spaces.internet2.edu/display/COmanage/Home), as well as
documentation and recipes for both simple deployments to use for evaluating
COmanage Registry and deployments ready for production.

## What is here

* [Dockerfile templates](#Dockerfile-templates)
* [Simple deployment for evaluation, no persistence](recipes/simple-no-persistence/README.md)
* [Simple deployment for evaluation with persistence](recipes/simple-with-persistence/README.md)
* [Production deployment using Docker stacks with mod_auth_openidc and MariaDB](recipes/production-mod-auth-openidc-mariadb/README.md)


## Dockerfile templates

* [COmanage Registry](comanage-registry/README.md) (no authentication, primarily for developers)
* [COmanage Registry with Basic Authentication](comanage-registry-basic-auth/README.md)
* [COmanage Registry with Shibboleth](comanage-registry-shibboleth-sp/README.md) Native SP for Apache Authentication
* [Example PostgreSQL](comanage-registry-postgres/README.md) image for use with COmanage Registry
* [Example MariaDB](comanage-registry-mariadb/README.md) image for use with COmanage Registry
* [Example OpenLDAP slapd](comanage-registry-slapd/README.md) image for use with COmanage Registry
* [Example Docker Compose](compose/README.md) file for deploying COmanage Registry
