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
## With Basic Authentication, MariaDB, and persisted data

* Define `COMANAGE_REGISTRY_VERSION`. Currently we recommend

```
export COMANAGE_REGISTRY_VERSION=hotfix-2.0.x
```

* Build a local image for COmanage Registry if you have not already:

```
pushd comanage-registry-basic-auth
sed -e s/%%COMANAGE_REGISTRY_VERSION%%/${COMANAGE_REGISTRY_VERSION}/g Dockerfile.template  > Dockerfile
docker build -t comanage-registry:${COMANAGE_REGISTRY_VERSION}-basic-auth .
popd
```

* It is not necessary to build a local image of MariaDB for COmanage Registry. You can
use the [official MariaDB image from Docker Hub](https://hub.docker.com/_/mariadb/).


* Create a directory to persist data in the relational database:
```
mkdir -p /docker/var/lib/mysql
mkdir -p /docker/srv/comanage-registry/local
```

* Create a docker-compose.yml file. Be sure to replace the password examples
below with your own choices.
```
version: '3.1'

services:

    comanage-registry-database:
        image: mariadb
        volumes:
            - /docker/var/lib/mysql:/var/lib/mysql
        environment:
            - MYSQL_ROOT_PASSWORD=tkrT3MI4H2otxGMuxqoE
            - MYSQL_DATABASE=registry
            - MYSQL_USER=registry_user
            - MYSQL_PASSWORD=vy4O6XF58gl1fMpf6rRg

    comanage-registry:
        image: comanage-registry:hotfix-2.0.x-basic-auth
        volumes:
            - /docker/srv/comanage-registry/local:/srv/comanage-registry/local
        environment:
            - COMANAGE_REGISTRY_DATASOURCE=Database/Mysql
              # Password below must be same as for MYSQL_PASSWORD above
            - COMANAGE_REGISTRY_DATABASE_USER_PASSWORD=vy4O6XF58gl1fMpf6rRg
        ports:
            - "80:80"
            - "443:443"
```

* Start the services:
```
docker-compose up -d
```

* Browse to port 443 on the host, for example `https://localhost/`

* Click `Login` and when prompted enter `registry.admin` as the username and `password`
for the password.

* Visit the [COmanage wiki](https://spaces.internet2.edu/display/COmanage/Setting+Up+Your+First+CO)
to learn how to create your first collaborative organization (CO) and begin using
the platform.

* To stop the services:
```
docker-compose stop
```

* To remove the containers and networks:
```
docker-compose down
```

Even though the containers have been removed the data is persisted. You may
bring up the services again and resume where you left off.

### Important Notes
The instructions above are *not suitable for a production deployment* 
because the deployed services use default and easily guessed passwords.




