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

# MariaDB for COmanage Registry

A simple example demonstrating how to create and image and container
based on MariaDB to use with COmanage Registry containers. 

## Build

There is no image to build. You can directly use the official MariaDB
image hosted on DockerHub.

## Run

Create a user-defined network bridge with

```
docker network create --driver=bridge \
  --subnet=192.168.0.0/16 \
  --gateway=192.168.0.100 \
  comanage-registry-internal-network
```

and then mount a host directory such as `/tmp/mariadb-data`
to `/var/lib/mysql` inside the container to persist
data. Use the environment variables

```
MYSQL_ROOT_PASSWORD
MYSQL_DATABASE
MYSQL_USER
MYSQL_PASSWORD
```

to set the password for the MySQL root user, the name of the COmanage
Registry database, and the name and password of the database user. For example

```
docker run -d --name comanage-registry-database \
  --network comanage-registry-internal-network \
  -v /tmp/mariadb-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=XXXXXXXX \
  -e MYSQL_DATABASE=registry \
  -e MYSQL_USER=registry_user \
  -e MYSQL_PASSWORD=xxxxxxxx \
  mariadb
```
