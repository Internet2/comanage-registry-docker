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
## With Basic Authentication, PostgreSQL, and OpenLDAP slapd

* Define the shell variable `COMANAGE_REGISTRY_VERSION` to be the version
of COmanage Registry you want to deploy. See the
[COmanage Registry Release History](https://spaces.internet2.edu/display/COmanage/Release+History)
wiki page for the list of releases. We recommend using the latest release.

Here is an example (but please check the wiki page for the latest release number):

```
export COMANAGE_REGISTRY_VERSION=3.1.1
```

* Build a local image for COmanage Registry if you have not already:

```
pushd comanage-registry-basic-auth
sed -e s/%%COMANAGE_REGISTRY_VERSION%%/${COMANAGE_REGISTRY_VERSION}/g Dockerfile.template  > Dockerfile
docker build -t comanage-registry:${COMANAGE_REGISTRY_VERSION}-basic-auth .
popd
```

* Build a local image of PostgreSQL for COmanage Registry if you have not already:
```
pushd comanage-registry-postgres
docker build -t comanage-registry-postgres .
popd
```

* Build a local image of OpenLDAP slapd for COmanage Registry if you
  have not already:

```
pushd comanage-registry-slapd
docker build -t comanage-registry-slapd .
popd
```

* Create directories to persist the relational database, COmanage Registry
local configuration, OpenLDAP slapd directory data, and slapd 
configuration:
```
mkdir -p /docker/var/lib/postgresql/data
mkdir -p /docker/srv/comanage-registry/local
mkdir -p /docker/var/lib/ldap
mkdir -p /docker/etc/ldap/slapd.d
```

* Create a template docker-compose.yml file that mounts the directories you created
as volumes in the database container:
```
version: '3.1'

services:

    comanage-registry-database:
        image: comanage-registry-postgres
        volumes:
            - /docker/var/lib/postgresql/data:/var/lib/postgresql/data

    comanage-registry-ldap:
        image: comanage-registry-slapd
        volumes:
            - /docker/var/lib/ldap:/var/lib/ldap
            - /docker/etc/ldap/slapd.d:/etc/ldap/slapd.d
        ports:
            - "389:389"

    comanage-registry:
        image: comanage-registry:COMANAGE_REGISTRY_VERSION-basic-auth
        volumes:
            - /docker/srv/comanage-registry/local:/srv/comanage-registry/local
        ports:
            - "80:80"
            - "443:443"
```

* Use sed to set the COmanage Registry version for the image in the 
docker-compose.yml file:

```
sed -i s/COMANAGE_REGISTRY_VERSION/$COMANAGE_REGISTRY_VERSION/ docker-compose.yml
```

* Start the services:
```
docker-compose up -d
```

* Browse to port 443 on the host, for example `https://localhost/`

* Click `Login` and when prompted enter `registry.admin` as the username and `password`
for the password.

See [Advanced Configuration](./advanced-configuration.md) 
for details on setting a non-default administrator username and password.

* The default suffix for the LDAP directory is `dc=my,dc=org`. The
  default directory administrator DN is `cn=admin,dc=my,dc=org`. The
  default password for the default administrator DN is `password`.
  See [Advanced Configuration](docs/advanced-configuration.md) for
  details on how to configure the suffix, administrator DN, and
  password.

* Visit the [COmanage wiki](https://spaces.internet2.edu/display/COmanage)
for details on configuring the COmanage Registry LDAP Provisioner.

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

See [Advanced Configuration](./advanced-configuration.md) for
details on setting non-default passwords.
