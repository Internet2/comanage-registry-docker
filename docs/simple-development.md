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

# Simple Development Sandbox

Follow these steps to build and run a simple deployment of COmanage Registry
suitable for beginning COmanage Registry development.

* Complete all of the steps in 
[Evaluating COmanage Registry using Docker](evaluation.md). Make sure you can
log into COmanage Registry but do not save any changes. Be sure to run
`docker compose down` so that no containers are left running.

* Create a directory somewhere to save the state of the COmanage Registry
database. For example

```
sudo mkdir -p /srv/docker/var/lib/postgresql/data
```

* Clone the COmanage Registry repository somewhere, for example

```
cd $HOME
git clone https://github.com/Internet2/comanage-registry.git
```

* Change directories into the repository you just
cloned and create some necessary files and set appropriate permissions:

```
cd comanage-registry
cp -a app/tmp.dist local/tmp
chmod -R o+rw local/tmp
```

* Tell git to ignore changes the container makes during startup:

```
git update-index --assume-unchanged app/Config/bootstrap.php
```

* Checkout the develop branch or any other branch you want to work
from (you probably do not want to work from master):

```
git checkout develop
```

* Edit the docker-compose.yml file you used previously and add three
volume bind mounts:
  
  1. One volume will mount the directory you created in the above
     step for saving the database state to the directory
     `/var/lib/postgresql/data` inside the database container.
  1. A second volume will mount the `app` directory from the COmanage
     Registry repository clone you created to the
     `/srv/comanage-registry/app` directory inside the 
     COmanage Registry container.
  1. The third volume will mount the `local` directory from the
     COmanage Registry repository clone to the
     `/srv/comanage-registry/local` directory inside the COmanage
     Registry container.

Below is an example. The details will depend where you create the
database state directory and the repository clone. Be sure to
adjust the volume mounts for your deployment.

```
version: '3.1'

services:

    comanage-registry-database:
        image: comanage-registry-postgres
        volumes:
            - /srv/docker/var/lib/postgresql/data:/var/lib/postgresql/data

    comanage-registry:
        image: "comanage-registry:${COMANAGE_REGISTRY_VERSION}-basic-auth"
        volumes:
            - /home/skoranda/comanage-registry/app:/srv/comanage-registry/app
            - /home/skoranda/comanage-registry/local:/srv/comanage-registry/local

        ports:
            - "80:80"
            - "443:443"
```

* Make sure the shell variable `COMANAGE_REGISTRY_VERSION` is still
set (see [Evaluating COmanage Registry using Docker](evaluation.md).)

* Start the services:
```
docker-compose up -d
```

* Browse to port 443 on the host, for example `https://localhost/`. You will have to
  click through the warning from your browser about the self-signed certificate used
  for HTTPS.

* Click `Login` and when prompted enter `registry.admin` as the username and `password`
for the password. 

* Visit the [COmanage Developer Manual](https://spaces.at.internet2.edu/x/FYDVCQ) for
tips and suggestions as well as the [COmanage Coding Style](https://spaces.at.internet2.edu/x/l6_KAQ).

* To stop the services:
```
docker-compose stop
```

* To remove the containers and networks:
```
docker-compose down
```

### Important Notes
The instructions above are *not suitable for a production deployment* 
since the deployed services use default and easily guessed passwords.
