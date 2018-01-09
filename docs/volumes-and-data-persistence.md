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

# COmanage Registry Volumes and Data Persistence

COmanage Registry requires a relational database. See other documentation in 
this repository for examples of how to orchestrate a COmanage Registry container
together with an container providing a relational database service, and for details on how
to configure the COmanage Registry container to connect to the database.

Additionally COmanage Registry *requires* a persistent directory into which
a few files and a specific directory structure needed by COmanage Registry
will be written. 

*The persistent directory must be provided either using a Docker volume
or a bind mount.*

The directory path inside the container that must be mounted
is `/src/comanage-registry/local`.

For example to use a bind mount from the local Docker engine host:

```
sudo mkdir -p /opt/comanage-registry-local
```

and then when instantiating the container

```
docker run -d \
  --name comanage-registry \
  -v /opt/comanage-registry-local:/srv/comanage-registry/local \
  -p 80:80 \
  -p 443:443 \
  comanage-registry:3.2.1-shibboleth-sp-1
```

After the image is instantiated into a container for the first time
the entrypoint script will create the necessary directory structure
along with the `database.php`, `email.php`, and other necessary configuration files using
database, email server, and other details found in 
[environment variables](./comanage-registry-common-environment-variables.md).

*After the first instantiation of the container later restarts will not overwrite
database, email, or any other details in the persistent directory, even if the
values for the environment variables change*.


