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

# Evaluating COmanage Registry using Docker

Follow these steps to build and run a simple deployment of COmanage Registry
suitable for evaluation purposes.

* Install Docker. These instructions require version 17.05 or higher.

* Install [Docker Compose](https://docs.docker.com/compose/). These instructions require 
version 1.13.0 or higher.

* Clone this repository:

```
git clone https://github.com/Internet2/comanage-registry-docker.git
cd comanage-registry-docker
```

* Define the shell variable `COMANAGE_REGISTRY_VERSION` to be the version
of COmanage Registry you want to deploy. See the
[COmanage Registry Release History](https://spaces.internet2.edu/display/COmanage/Release+History)
wiki page for the list of releases. We recommend using the latest release.

Here is an example (but please check the wiki page for the latest release number):

```
export COMANAGE_REGISTRY_VERSION=3.2.4
```

* Build the base COmanage Registry image:

```
pushd comanage-registry-base
docker build \
    --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
    -t comanage-registry-base:${COMANAGE_REGISTRY_VERSION}-1 .
popd
```

* Build an image for COmanage Registry that uses basic authentication:

```
pushd comanage-registry-basic-auth
docker build \
    --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
    -t comanage-registry:${COMANAGE_REGISTRY_VERSION}-basic-auth .
popd
```

* Build a local image of PostgreSQL for COmanage Registry:

```
pushd comanage-registry-postgres
docker build -t comanage-registry-postgres .
popd
```

* Create a docker-compose.yml file:

```
version: '3.1'

services:

    comanage-registry-database:
        image: comanage-registry-postgres

    comanage-registry:
        image: "comanage-registry:${COMANAGE_REGISTRY_VERSION}-basic-auth"
        ports:
            - "80:80"
            - "443:443"
```

* Start the services:
```
docker-compose up -d
```

* Browse to port 443 on the host, for example `https://localhost/`. You will have to
  click through the warning from your browser about the self-signed certificate used
  for HTTPS.

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

### Important Notes
The instructions above are *not suitable for a production deployment* for two reasons:

1. The deployed services use default and easily guessed passwords.
2. No data is persisted. When the containers are destroyed so is your data.

## Next Steps
To evolve your COmanage Registry deployment examine the documentation
in the [docs directory](./README.md).


