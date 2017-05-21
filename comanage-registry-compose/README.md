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

# Docker compose for COmanage Registry 

This is an example docker-compose file to deploy COmanage
Registry with the Shibboleth SP
for authentication, PostgreSQL database, and OpenLDAP
slapd using docker-compose (as opposed to Docker stack).

See the individual image Dockerfile templates and README
files for details on how to inject 
necessary deployment details and secrets.

## Deploy

```
docker-compose --compose-file comanage-registry-shibboleth-sp-postgres-compose.yml up -d
```

## Tear Down

```
docker-compose --compose-file comanage-registry-shibboleth-sp-postgres-compose.yml down
```
