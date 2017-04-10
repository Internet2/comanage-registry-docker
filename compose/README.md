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

# Docker Compose Example for COmanage Registry 

This is an example Docker Compose file to deploy COmanage
Registry with the Shibboleth Native SP for Apache HTTP Server
and a PostgreSQL database.

See the individual image Dockerfile templates and README
files for details on how to prepare the volumes and the
necessary contents including the COmanage Registry 
configuration and the Shibboleth SP configuration.

Change the tag from `COMANAGE_REGISTRY_VERSION-shibboleth-sp`
to `COMANAGE_REGISTRY_VERSION-basic-auth` to quickly deploy
without the need for federation.

## Deploy

```
docker-compose up
```

## Tear Down

```
docker-compose down
```
