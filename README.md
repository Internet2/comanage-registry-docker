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
Docker version of [COmanage
Registry](https://spaces.internet2.edu/display/COmanage/Home).

COmanage Registry is a web application that requires a relational database
and an authentication mechanism such as 
[Shibboleth](http://shibboleth.net/products/service-provider.html), 
[SimpleSAMLphp](https://simplesamlphp.org/), 
[mod_auth_openidc](https://github.com/pingidentity/mod_auth_openidc),
or just simple [Basic Authentication](https://httpd.apache.org/docs/2.4/mod/mod_auth_basic.html).
Since COmanage Registry itself is agnostic about the database and authentication
mechanism used this repository includes multiple Dockerfiles to build images that use various
combinations of tools.

## How To

* Install Docker. These instructions require version 17.03.1 or higher.

* Install [Docker Compose](https://docs.docker.com/compose/). These instructions require 
version 1.13.0 or higher.

* Clone this repository:

```
git clone https://github.com/Internet2/comanage-registry-docker.git
cd comanage-registry-docker
```

* Define `COMANAGE_REGISTRY_VERSION`. Currently we recommend

```
export COMANAGE_REGISTRY_VERSION=3.1.0
```

* Build a local image for COmanage Registry:

```
pushd comanage-registry-basic-auth
sed -e s/%%COMANAGE_REGISTRY_VERSION%%/${COMANAGE_REGISTRY_VERSION}/g Dockerfile.template  > Dockerfile
docker build -t comanage-registry:${COMANAGE_REGISTRY_VERSION}-basic-auth .
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
        image: comanage-registry:3.1.0-basic-auth
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

See [Advanced Configuration](docs/advanced-configuration.md) 
for details on setting a non-default administrator username and password.

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
in the [docs directory](docs/README.md) or follow these direct links:

* [Persist data using host-mounted volumes](docs/basic-auth-postgres-persist.md)
* [Use MariaDB instead of PostgreSQL](docs/basic-auth-mariadb-persist.md)
* [Add OpenLDAP slapd for provisioning](docs/openldap-slapd.md)
* [Advanced configuration](docs/advanced-configuration.md)
* [Complete example recipe for production deployment](docs/shibboleth-sp-postgres-compose.md)
* [Using Docker service stacks and Docker secrets](docs/mod-auth-oidc-mariadb-stacks.md)





