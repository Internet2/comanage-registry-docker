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

# COmanage Registry with Shibboleth SP and MariaDB

Follow these steps to build and run COmanage Registry
using the Shibboleth SP for authentication and MariaDB
as the relational database.

* Install Docker. These instructions require version 17.05 or higher.

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
export COMANAGE_REGISTRY_VERSION=3.2.1
```

* Define the shell variable `COMANAGE_REGISTRY_BASE_IMAGE_VERSION` to be the
version of the base image you are about to build:

```
export COMANAGE_REGISTRY_BASE_IMAGE_VERSION=1
```

* Build the base COmanage Registry image:

```
pushd comanage-registry-base
TAG="${COMANAGE_REGISTRY_VERSION}-${COMANAGE_REGISTRY_BASE_IMAGE_VERSION}"
docker build \
  --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
  -t comanage-registry-base:${TAG} .
popd
```

* Define the shell variable `COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION`
to be the version of the base Shibboleth SP image you are about to build:

```
export COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION=1
```

* Build the base Shibboleth SP image:

```
pushd comanage-registry-shibboleth-sp-base
TAG="${COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION}"
docker build \
    -t comanage-registry-shibboleth-sp-base:$TAG . 
popd
```

* Define the shell variable `COMANAGE_REGISTRY_SHIBBOLETH_SP_IMAGE_VERSION`
to be the version of the image you are about to build:

```
export COMANAGE_REGISTRY_SHIBBOLETH_SP_IMAGE_VERSION=1
export COMANAGE_REGISTRY_SHIBBOLETH_SP_VERSION=3.2.1
```

* Build an image for COmanage Registry that uses the Shibboleth SP
for authentication:

```
pushd comanage-registry-shibboleth-sp
TAG="${COMANAGE_REGISTRY_VERSION}-shibboleth-sp-${COMANAGE_REGISTRY_SHIBBOLETH_SP_IMAGE_VERSION}"
docker build \
    --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
    --build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_BASE_IMAGE_VERSION} \
    --build-arg COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION} \
    --build-arg COMANAGE_REGISTRY_SHIBBOLETH_SP_VERSION=${COMANAGE_REGISTRY_SHIBBOLETH_SP_VERSION} \
    -t comanage-registry:$TAG .
popd
```

* Initialize the Docker Swarm:

```
docker swarm init
```

* Create secrets for the database root password, the COmanage Registry database
password, the HTTPS certificate (and CA signing chain) and private key files,
and the Shibboleth SP encryption certificate and private key files (be sure
to choose your own values and do not use the examples below):

```
echo "jPkrc3TUijfmT3vi1ZKw" | docker secret create mariadb_root_password - 

echo "ayFjKFHTre74A0k8k1mq" | docker secret create mariadb_password - 

echo "ayFjKFHTre74A0k8k1mq" | docker secret create comanage_registry_database_user_password - 

docker secret create https_cert_file fullchain.cert.pem

docker secret create https_privkey_file privkey.pem

docker secret create shibboleth_sp_encrypt_cert sp-encrypt-cert.pem

docker secret create shibboleth_sp_encrypt_privkey sp-encrypt-key.pem
```

* Create directories on the Docker engine host(s) for state files
and other files including the Shibboleth SP configuration files:

```
sudo mkdir -p /srv/docker/var/lib/mysql
sudo mkdir -p /srv/docker/srv/comanage-registry/local
sudo mkdir -p /srv/docker/etc/shibboleth
```

* Copy Shibboleth SP configuration files into place to be mounted
into the running container. Your Shibboleth SP configuration should
result in the primary identifier attribute you expect to be asserted by the SAML
IdP(s) to populate `REMOTE_USER` so that it can be read by COmanage Registry.
A common choice is to populate `REMOTE_USER` with eduPersonPrincipalName, but
the details will depend on your SAML federation choices.


```
cp shibboleth2.xml /srv/docker/etc/shibboleth/
cp attribute-map.xml /srv/docker/etc/shibboleth/
cp saml-metadata.xml /src/docker/etc/shibboleth/
```

* Define shell variables for the first COmanage Registry platform
  administrator, for example:

```
export COMANAGE_REGISTRY_ADMIN_GIVEN_NAME=Karel
export COMANAGE_REGISTRY_ADMIN_FAMILY_NAME=Novak
export COMANAGE_REGISTRY_ADMIN_USERNAME=karel.novak@my.org
```

The username should be the value you expect to be asserted by the
SAML IdP for the first platform administrator. The Shibboleth SP
configuration should be such that the value is populated into
`REMOTE_USER` where it will be read when the first platform 
administrator logs into COmanage Registry.

* Define a shell variable with the fully-qualified domain name for
the virtual host from which COmanage Registry will be served. For 
example

```
export COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN=registry.my.org
```

* Create a Docker Swarm services stack description (compose) file in YAML format:

```
version: '3.1'

services:

    comanage-registry-database:
        image: mariadb:10.2
        volumes:
            - /srv/docker/var/lib/mysql:/var/lib/mysql
        environment:
            - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mariadb_root_password
            - MYSQL_DATABASE=registry
            - MYSQL_USER=registry_user
            - MYSQL_PASSWORD_FILE=/run/secrets/mariadb_password
        secrets:
            - mariadb_root_password
            - mariadb_password
        networks:
            - default
        deploy:
            replicas: 1

    comanage-registry:
        image: comanage-registry:${COMANAGE_REGISTRY_VERSION}-shibboleth-sp-${COMANAGE_REGISTRY_SHIBBOLETH_SP_IMAGE_VERSION}
        volumes:
            - /srv/docker/srv/comanage-registry/local:/srv/comanage-registry/local
            - /srv/docker/etc/shibboleth/shibboleth2.xml:/etc/shibboleth/shibboleth2.xml
            - /srv/docker/etc/shibboleth/attribute-map.xml:/etc/shibboleth/attribute-map.xml
            - /srv/docker/etc/shibboleth/saml-metadata.xml:/etc/shibboleth/saml-metadata.xml
        environment:
            - COMANAGE_REGISTRY_ADMIN_GIVEN_NAME=${COMANAGE_REGISTRY_ADMIN_GIVEN_NAME}
            - COMANAGE_REGISTRY_ADMIN_FAMILY_NAME=${COMANAGE_REGISTRY_ADMIN_FAMILY_NAME}
            - COMANAGE_REGISTRY_ADMIN_USERNAME=${COMANAGE_REGISTRY_ADMIN_USERNAME}
            - COMANAGE_REGISTRY_DATASOURCE=Database/Mysql
            - COMANAGE_REGISTRY_DATABASE_USER_PASSWORD_FILE=/run/secrets/comanage_registry_database_user_password
            - COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN=${COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN}
            - HTTPS_CERT_FILE=/run/secrets/https_cert_file
            - HTTPS_PRIVKEY_FILE=/run/secrets/https_privkey_file
            - SHIBBOLETH_SP_ENCRYPT_CERT=/run/secrets/shibboleth_sp_encrypt_cert
            - SHIBBOLETH_SP_ENCRYPT_PRIVKEY=/run/secrets/shibboleth_sp_encrypt_privkey
        secrets:
            - comanage_registry_database_user_password
            - https_cert_file
            - https_privkey_file
            - shibboleth_sp_encrypt_cert
            - shibboleth_sp_encrypt_privkey
        networks:
            - default
        ports:
            - "80:80"
            - "443:443"
        deploy:
            replicas: 1

secrets:
    comanage_registry_database_user_password:
        external: true
    mariadb_root_password:
        external: true
    mariadb_password:
        external: true
    shibboleth_sp_encrypt_cert:
        external: true
    shibboleth_sp_encrypt_privkey:
        external: true
    https_cert_file:
        external: true
    https_privkey_file:
        external: true
```

* Deploy the COmanage Registry service stack:

```
docker stack deploy --compose-file comanage-registry-stack.yml comanage-registry
```

Since this is the first initialization of the containers it will take some
time for the database tables to be created. The Apache HTTP Server and
Shibboleth SP daemons will not be started until the entrypoint scripts
detect that the database has been initialized.

You may monitor the progress of the database container using

```
docker service logs -f comanage-registry-database
```

and the progress of the COmanage Registry container using

```
docker service logs -f comanage-registry
```

* After the Apache HTTP Server has started browse to port 443 on the host. 

* Click `Login` to initiate a SAML authentication flow. After authenticating at
  the SAML IdP the Shibboleth SP should consume the SAML assertion and populate
  `REMOTE_USER` with the value for the username for the first platform
  administrator.

* During the first instantiation of the COmanage Registry service the entrypoint
script will have created the template file 

```
Config/email.php
```

in the directory `/srv/docker/srv/comanage-registry/local` on the Docker engine
host. Edit that file to configure how COmanage Registry should connect to an
SMTP server to send outgoing email.

* Visit the [COmanage wiki](https://spaces.internet2.edu/display/COmanage/Setting+Up+Your+First+CO)
to learn how to create your first collaborative organization (CO) and begin using
the platform.

* To stop the services:
```
docker stack rm comanage-registry
```
