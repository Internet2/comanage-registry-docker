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

# COmanage Registry Docker for Production with mod\_auth\_openidc and MariaDB using Docker stacks, swarm, and secrets

Follow this recipe as an example production deployment of COmanage Registry
with mod\_auth\_openidc for authentication, a MariaDB database, and
an OpenLDAP slapd directory server. 

This recipe uses Docker service stacks, swarm, and secrets rather than docker-compose. 

## Recipe

* Define `COMANAGE_REGISTRY_VERSION`. Currently we recommend

```
export COMANAGE_REGISTRY_VERSION=hotfix-2.0.x
```

* Build a local image for COmanage Registry if you have not already:

```
pushd comanage-registry-mod-auth-openidc
sed -e s/%%COMANAGE_REGISTRY_VERSION%%/${COMANAGE_REGISTRY_VERSION}/g Dockerfile.template  > Dockerfile
docker build -t comanage-registry:${COMANAGE_REGISTRY_VERSION}-mod-auth-openidc .
popd
```

* It is not necessary to build a local image for the MariaDB container. The official MariaDB image
is sufficient.

* Build a local image of OpenLDAP slapd for COmanage Registry if you have not already:

```
pushd comanage-registry-slapd
docker build -t comanage-registry-slapd .
popd
```

* Create directories to persist the relational database, COmanage Registry
local configuration, slapd configuration, slapd directory data:
```
mkdir -p /docker/var/lib/mysql
mkdir -p /docker/srv/comanage-registry/local
mkdir -p /docker/var/lib/ldap
mkdir -p /docker/etc/ldap/slapd.d
```

* Create a single node swarm:
```
docker swarm init
```

Store secrets and inject other deployment details using Docker secrets.
Be sure to create your own secrets and do not reuse the examples
below.


Create a root password for the MariaDB database:
```
echo "4vdecnEHzwUNKA1FlvgE" | docker secret create mysql_root_password - 
```

Create a password, used by MariaDB, for the COmanage Registry database user:

```
echo "34MF72AyBWgaTm3OLbc9" | \
    docker secret create mysql_registry_user_password - 
```

Store that same password again to be used by the COmanage Registry container:

```
echo "202ZIBSipiP2cOhoTDFK" | \
    docker secret create comanage_registry_database_user_password - 
```

Obtain the OIDC client secret and the mod\_auth\_openidc OIDC crypto
passphrase and store them as secrets:

```
echo "myproxy:oa4mp,2012:/client_id/630031683213792271192646355167031832" \
    | docker secret create oidc_client_id -


echo "g4bu5n0jTfHnwKvf2itz" | docker secret create oidc_crypto_passphrase -
```

Use the slappasswd tool (package `slapd` on Debian) to create a strong hash for a strong
password for the directory root DN:

```
slappasswd -c '$6$rounds=5000$%.86s'
```

Store the hash in a file:

```
echo '{CRYPT}$6$rounds=5000$kER6wkUF91t4.r79$7OLbtO0qF9K9tQlVJAxpWFem.0KmnyWn1/1K0sVSEQELRuj87sc7GtJT7HpWBr8JfZHlbsG9ifrqN6EmJchQ8/' \
   > /docker/run/secrets/olc_root_pw
```

Put the X.509 certificate, private key, and chain files in place for slapd:

```
docker secret create slapd_cert_file cert.pem
docker secret create slapd_privkey_file privkey.pem
docker secret create slapd_chain_file chain.pem
```

Put the X.509 certificate and private key files in place
for Apache HTTP Server for HTTPS. The certificate file should
include the server certificate and any intermediate CA signing 
certificates sorted from leaf to root:

```
docker secret create https_cert_file fullchain.pem
docker secret create https_privkey_file privkey.pem
```

* Create a docker-compose.yml by adjusting the example below:

```
version: '3.1'

services:

    comanage-registry-database:
        image: mariadb
        volumes:
            - /srv/docker/var/lib/mysql:/var/lib/mysql
        environment:
            - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_root_password 
            - MYSQL_DATABASE=registry
            - MYSQL_USER=registry_user
            - MYSQL_PASSWORD_FILE=/run/secrets/mysql_registry_user_password
        secrets:
            - mysql_root_password
            - mysql_registry_user_password
        networks:
            - default
        deploy:
            replicas: 1

    comanage-registry-ldap:
        image: comanage-registry-slapd
        volumes:
            - /srv/docker/var/lib/ldap:/var/lib/ldap
            - /srv/docker/etc/ldap/slapd.d:/etc/ldap/slapd.d
        environment:
            - SLAPD_CERT_FILE=/run/secrets/slapd_cert_file
            - SLAPD_PRIVKEY_FILE=/run/secrets/slapd_privkey_file
            - SLAPD_CHAIN_FILE=/run/secrets/slapd_chain_file
            - OLC_ROOT_PW_FILE=/run/secrets/olc_root_pw
            - OLC_SUFFIX=dc=my,dc=org
            - OLC_ROOT_DN=cn=admin,dc=my,dc=org
        secrets:
            - slapd_cert_file
            - slapd_privkey_file
            - slapd_chain_file
            - olc_root_pw
        networks:
            - default
        ports:
            - "636:636"
            - "389:389"
        deploy:
            replicas: 1

    comanage-registry:
        image: comanage-registry:hotfix-2.0.x
        volumes:
            - /srv/docker/srv/comanage-registry/local:/srv/comanage-registry/local
        environment:
            - OIDC_CLIENT_ID=myproxy:oa4mp,2012:/client_id/zC8kr2KG5wBxWIQ6YLu0
            - OIDC_CLIENT_SECRET_FILE=/run/secrets/oidc_client_secret 
            - OIDC_PROVIDER_METADATA_URL=https://cilogon.org/.well-known/openid-configuration
            - OIDC_CRYPTO_PASSPHRASE_FILE=/run/secrets/oidc_crypto_passphrase 
            - REGISTRY_HOST=registry.my.org
            - HTTPS_CERT_FILE=/run/secrets/https_cert_file 
            - HTTPS_PRIVKEY_FILE=/run/secrets/https_privkey_file 
            - COMANAGE_REGISTRY_ADMIN_USERNAME=http://cilogon.org/serverA/users/22981
            - COMANAGE_REGISTRY_DATASOURCE=Database/Mysql
            - COMANAGE_REGISTRY_DATABASE_USER_PASSWORD_FILE=/run/secrets/comanage_registry_database_user_password
            - COMANAGE_REGISTRY_EMAIL_TRANSPORT=Smtp
            - COMANAGE_REGISTRY_EMAIL_HOST=smtp.ncsa.uiuc.edu
            - COMANAGE_REGISTRY_EMAIL_PORT=25
        secrets:
            - comanage_registry_database_user_password
            - oidc_client_secret
            - oidc_crypto_passphrase
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
    mysql_root_password:
        external: true
    mysql_registry_user_password:
        external: true  
    slapd_cert_file:
        external: true
    slapd_privkey_file:
        external: true
    slapd_chain_file:
        external: true
    olc_root_pw:
        external: true
    oidc_client_secret:
        external: true
    oidc_crypto_passphrase:
        external: true
    https_cert_file:
        external: true
    https_privkey_file:
        external: true
```

Note especially the value for `COMANAGE_REGISTRY_ADMIN_USERNAME`.
This is the value that mod\_auth\_openidc expects to consume in the
ID token from the OP that authenticates the first platform administrator.
By default mod\_auth\_openidc will expect to consume that identifier
from the sub claim asserted for the admin by the OP.

Bring up the services using docker stack deploy:

```
docker stack deploy --compose-file docker-compose.yml comanage-registry
```

COmanage Registry will be exposed on port 443 (HTTP). Use a web browser
to browse, for example, to

```
https://localhost/registry/
```

If you have properly federated the OIDC client with the OP that the
first platform administrator will use you can click on "Login" and be
redirected to the OP for authentication.

Production deployments need to send email, usually using an authenticated
account on a SMTP server. You may configure the details for your SMTP server
by editing the file `email.php` that the entrypoint script automatically
creates in `/docker/srv/comanage-registry/local/Config`.

To stop the services and tear down the stack run

```
docker stack rm comanage-registry
```

