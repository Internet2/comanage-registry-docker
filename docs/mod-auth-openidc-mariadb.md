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

# COmanage Registry with mod\_auth\_openidc and MariaDB

Follow these steps to build and run COmanage Registry
using mod\_auth\_openidc for authentication and MariaDB
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

* Define the shell variable `COMANAGE_REGISTRY_MOD_AUTH_OPENIDC_IMAGE_VERSION`
to be the version of the image you are about to build:

```
export COMANAGE_REGISTRY_MOD_AUTH_OPENIDC_IMAGE_VERSION=1
```

* Build an image for COmanage Registry that uses mod\_auth\_openidc
for authentication:

```
pushd comanage-registry-mod-auth-openidc
TAG="${COMANAGE_REGISTRY_VERSION}-mod-auth-openidc-${COMANAGE_REGISTRY_MOD_AUTH_OPENIDC_IMAGE_VERSION}"
docker build \
    --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
    --build-arg COMANAGE_REGISTRY_BASE_IMAGE_VERSION=${COMANAGE_REGISTRY_BASE_IMAGE_VERSION} \
    -t comanage-registry:$TAG .
popd
```

* Initialize the Docker Swarm:

```
docker swarm init
```

* Create secrets for the database root password, the COmanage Registry database
password, the HTTPS certificate (and CA signing chain) and private key files,
(be sure to choose your own values and do not use the examples below):

```
echo "jPkrc3TUijfmT3vi1ZKw" | docker secret create mariadb_root_password - 

echo "ayFjKFHTre74A0k8k1mq" | docker secret create mariadb_password - 

echo "ayFjKFHTre74A0k8k1mq" | docker secret create comanage_registry_database_user_password - 

docker secret create https_cert_file fullchain.cert.pem

docker secret create https_privkey_file privkey.pem

```

* Create directories on the Docker engine host(s) for database,
COmanage Registry, and mod\_auth\_openidc files.

```
sudo mkdir -p /srv/docker/var/lib/mysql
sudo mkdir -p /srv/docker/srv/comanage-registry/local
sudo mkdir -p /srv/docker/etc/apache2/conf-enabled
```

* Create the mod\_auth\_openidc configuration file 
`/srv/docker/etc/apache2/conf-enabled/mod-auth-openidc.conf` 
with the necessary OIDC client, secret, redirect URI, and other
mod\_auth\_openidc integration details.

An example mod-auth-openidc.conf configuration is (be sure to choose
your own values and do not use the examples below):

```
OIDCProviderMetadataURL https://cilogon.org/.well-known/openid-configuration
OIDCRemoteUserClaim sub

OIDCClientID cilogon:/client_id/3815e327237181f2ca55e39c305a5706
OIDCClientSecret w5TmBFgrLEZVl7P3VYw5

OIDCScope "openid email profile org.cilogon.userinfo"
OIDCCryptoPassphrase X7iAVpP9c3vr3WTsxrd7

OIDCRedirectURI https://registry.cilogon.org/secure/redirect

<Location /secure/redirect>
  AuthType openid-connect
  Require valid-user
</Location>
```

* Define shell variables for the first COmanage Registry platform
  administrator, for example:

```
export COMANAGE_REGISTRY_ADMIN_GIVEN_NAME=Karel
export COMANAGE_REGISTRY_ADMIN_FAMILY_NAME=Novak
export COMANAGE_REGISTRY_ADMIN_USERNAME=http://cilogon.org/serverA/users/22981
```

The username should be the value you expect to be asserted by the
OIDC OP for the first platform administrator. The mod\_auth\_openidc
configuration should be such that the value is populated into
`REMOTE_USER` where it will be read when the first platform 
administrator logs into COmanage Registry. The default
for mod\_auth\_openidc is to populate `REMOTE_USER` with the 
OIDC sub claim.

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
        image: comanage-registry:${COMANAGE_REGISTRY_VERSION}-mod-auth-openidc-${COMANAGE_REGISTRY_MOD_AUTH_OPENIDC_IMAGE_VERSION}
        volumes:
            - /srv/docker/srv/comanage-registry/local:/srv/comanage-registry/local
            - /srv/docker/etc/apache2/conf-enabled/mod-auth-openidc.conf:/etc/apache2/conf-enabled/mod-auth-openidc.conf
        environment:
            - COMANAGE_REGISTRY_ADMIN_GIVEN_NAME=${COMANAGE_REGISTRY_ADMIN_GIVEN_NAME}
            - COMANAGE_REGISTRY_ADMIN_FAMILY_NAME=${COMANAGE_REGISTRY_ADMIN_FAMILY_NAME}
            - COMANAGE_REGISTRY_ADMIN_USERNAME=${COMANAGE_REGISTRY_ADMIN_USERNAME}
            - COMANAGE_REGISTRY_DATASOURCE=Database/MySQL
            - COMANAGE_REGISTRY_DATABASE_USER_PASSWORD_FILE=/run/secrets/comanage_registry_database_user_password
            - COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN=${COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN}
            - HTTPS_CERT_FILE=/run/secrets/https_cert_file
            - HTTPS_PRIVKEY_FILE=/run/secrets/https_privkey_file
        secrets:
            - comanage_registry_database_user_password
            - https_cert_file
            - https_privkey_file
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
    mariadb_root_password
        external: true
    mariadb_password
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
time for the database tables to be created. The Apache HTTP Server
will not be started until the entrypoint scripts detect that the
database has been initialized.

You may monitor the progress of the database container using

```
docker service logs -f comanage-registry-database
```

and the progress of the COmanage Registry container using

```
docker service logs -f comanage-registry
```

* After the Apache HTTP Server has started browse to port 443 on the host. 

* Click `Login` to initiate an OIDC authentication flow. After authenticating at
  the OIDC OP the mod\_auth\_openidc module should consume the OIDC identity token and populate
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