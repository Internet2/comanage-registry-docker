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

# Docker Stack Deploy for COmanage Registry 

This is an example Docker compose file to deploy COmanage
Registry with mod_auth_openidc for Apache HTTP Server
for authentication and a MariaDB database using Docker stack deploy.

See the individual image Dockerfile templates and README
files for details on how to prepare the volumes and the
necessary contents including the COmanage Registry 
configuration.

## Deploy

```
docker stack deploy --compose-file comanage-registry-mod-auth-openidc-mariadb-stack.yml comanage-registry
```

## Tear Down

```
docker stack rm comanage-registry
```
