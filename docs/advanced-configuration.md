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
## Advanced Configuration Options

The services deployed in containers instantiated using images built from this repository may be
configured in a number of different ways.

##### Table of Contents
* [Environment Variables](#environ)
* [Secrets](#secrets)
* [Apache HTTP ServerName](#servername)
* [Full Control](#full)

## Environment Variables <a name="environ"></a>

Most deployment details may be set using environment variables set for the container. 
The entrypoint scripts will attempt to use values from environment variables and if not
present reasonable defaults will be used. *Note that some defaults like passwords are
easily guessable and not suitable for production deployments*.

The complete list of environment variables available for configuration is listed in
the documentation for each image. See each image directory in this repository for
details.

Below are some examples of common environment variables deployers choose to set for each
component.

### COmanage Registry

| Environment Variable | Description | Default | Example 1 | Example 2 |
| -------------------- | ----------- | --------- | --------- | ------- |
| COMANAGE_REGISTRY_DATASOURCE | database type | Database/Postgres | Database/Postgres | Database/Mysql |
| COMANAGE_REGISTRY_DATABASE_USER| database user | registry_user | comanage | comanage_user |
| COMANAGE_REGISTRY_DATABASE_USER_PASSWORD | database user password | password | AFH9OiyuowiY3Wq6qX0j | qVcsJPo7$@ |
| COMANAGE_REGISTRY_ADMIN_USERNAME | Registry admin login name | registry.admin | admin | karel.novak@my.org |

### PostgreSQL

| Environment Variable | Description | Default | Example 1 | Example 2 |
| -------------------- | ----------- | --------- | --------- | ------- |
| POSTGRES_PASSWORD | database admin password | none | $cu9@2!qp&3R | 4vGb10sI#AI |
| COMANAGE_REGISTRY_POSTGRES_USER | registry database user | registry_user | comanage | comanage_user |
| COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD | registry database user password | password | AFH9OiyuowiY3Wq6qX0j | qVcsJPo7$@ |

### MariaDB

| Environment Variable | Description | Default | Example 1 | Example 2 |
| -------------------- | ----------- | --------- | --------- | ------- |
| MYSQL_ROOT_PASSWORD | database admin password | none | JaMKH5xAB64E9 | 6XET#82NFm& |
| MYSQL_USER | registry database user | registry_user | comanage | comanage_user |
| MYSQL_PASSWORD | registry database user password | none | 9vmKxJGwD!iU | o8rhqq4Sr%R |

### Shibboleth SP

| Environment Variable | Description | Default | Example 1 | Example 2 |
| -------------------- | ----------- | --------- | --------- | ------- |
| SHIBBOLETH_SP_ENTITY_ID | entityID for SP | https://comanage.registry/shibboleth | https://my.org/comanage | https://registry.my.org/shibboleth |
| SHIBBOLETH_SP_SAMLDS_URL | URL for SAML IdP discovery service | https://localhost/registry/pages/eds/index | https://my.org/registry/pages/eds/index | https://discovery.my.org |
| SHIBBOLETH_SP_CERT | SAML certificate | self-signed per-image default |||
| SHIBBOLETH_SP_PRIVKEY | SAML private key | self-signed per-image default |||
| SHIBBOLETH_SP_METADATA_PROVIDER_XML | \<MetadataProvider\> element |  none (empty) | see [Shib SP documenation]() | |

### mod_auth_oidc
Coming soon...

### OpenLDAP slapd
| Environment Variable | Description | Default | Example 1 | Example 2 |
| -------------------- | ----------- | --------- | --------- | ------- |
| OLC_SUFFIX | Suffix for the directory | dc=my,dc=org | dc=some,dc=edu | o=unit,dc=my,dc=org |
| OLC_ROOT_DN | DN for the administrator | cn=admin,dc=my,dc=org | cn=admin,dc=some,dc=edu | cn=admin,ou=service,dc=my,dc=org |
| OLC_ROOT_PW | password for root DN | password | ow&lveo13tH | eaFXZeOs7AK3iJ9w9d0a | akw13%!UU83 |

## Secrets <a name="secrets"></a>

Some deployers prefer not to use environment variables to inject secrets to avoid having
secrets in YAML files saved for example in a code repository.

An alternative is to put the secret in a file mounted into the container and point 
to the file location using an environment variable. For example if the file

```
/run/secrets/comanage_registry_postgres_user_password
```

is mounted in the container and holds the password and the container environment contains

```
COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD_FILE=/run/secrets/comanage_registry_postgres_user_password
```

then the entrypoint script will set the password to the value read from the file.

Here is an example compose file that uses secrets read from files mounted in 
the containers:

```
version: '3.1'

services:

    comanage-registry-database:
        image: mariadb
        volumes:
            - /docker/var/lib/mysql:/var/lib/mysql
        environment:
            - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_root_password
            - MYSQL_DATABASE=registry
            - MYSQL_USER=registry_user
            - MYSQL_PASSWORD_FILE=/run/secrets/mysql_password

    comanage-registry:
        image: comanage-registry:hotfix-2.0.x-basic-auth
        environment:
            - COMANAGE_REGISTRY_DATASOURCE=Database/Mysql
            - COMANAGE_REGISTRY_DATABASE_USER_PASSWORD_FILE=/run/secrets/mysql_password
        ports:
            - "80:80"
            - "443:443"
```

*All configuration details that may be set using an environment variable can also be set
using a file and environment variable of the same name appended with `_FILE`*.

*When present an environment variable pointing to a file inside the container overrides
an otherwise configured environment variable*.

## X.509 Certificates and Private Keys

### COmanage Registry

The certificate and private key files used for HTTPS may
be injected into the COmanage Registry container using environment variables
to point to files mounted into the container. The certificate file should
include the server certificate and any intermediate CA signing certificates
sorted from leaf to root.

For example:

```
version: '3.1'

services:

    comanage-registry-database:
        image: mariadb
        volumes:
            - /docker/var/lib/mysql:/var/lib/mysql
        environment:
            - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_root_password
            - MYSQL_DATABASE=registry
            - MYSQL_USER=registry_user
            - MYSQL_PASSWORD_FILE=/run/secrets/mysql_password

    comanage-registry:
        image: comanage-registry:hotfix-2.0.x-basic-auth
        environment:
            - COMANAGE_REGISTRY_DATASOURCE=Database/Mysql
            - COMANAGE_REGISTRY_DATABASE_USER_PASSWORD_FILE=/run/secrets/mysql_password
            - HTTPS_CERT_FILE=/run/secrets/https_cert_file
            - HTTPS_PRIVKEY_FILE=/run/secrets/https_privkey_file
        ports:
            - "80:80"
            - "443:443"
```

Alternatively you can directly mount files in the container to

```
/etc/apache2/cert.pem
/etc/apache2/privkey.pem
```

If no files are configured the containers use "snakeoil" self-signed certificates
for HTTPS by default.

### Shibboleth SP

The SAML certificate and private key used for decryption (and sometimes signing)
by the Shibboleth SP may be injected into the COmanage Registry container using
environment variables to point to files mounted into the container.

For example:

```
version: '3.1'

services:

    comanage-registry-database:
        image: mariadb
        volumes:
            - /docker/var/lib/mysql:/var/lib/mysql
        environment:
            - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_root_password
            - MYSQL_DATABASE=registry
            - MYSQL_USER=registry_user
            - MYSQL_PASSWORD_FILE=/run/secrets/mysql_password

    comanage-registry:
        image: comanage-registry:hotfix-2.0.x-basic-auth
        environment:
            - COMANAGE_REGISTRY_DATASOURCE=Database/Mysql
            - COMANAGE_REGISTRY_DATABASE_USER_PASSWORD_FILE=/run/secrets/mysql_password
            - HTTPS_CERT_FILE=/run/secrets/https_cert_file
            - HTTPS_PRIVKEY_FILE=/run/secrets/https_privkey_file
            - SHIBBOLETH_SP_CERT=/run/secrets/shibboleth_sp_cert
            - SHIBBOLETH_SP_PRIVKEY=/run/secrets/shibboleth_sp_privkey
        ports:
            - "80:80"
            - "443:443"
```

Alternatively you can directly mount files in the container to

```
/etc/shibboleth/sp-cert.pem
/etc/shibboleth/sp-key.pem
```

If no files are configured the container uses a default self-signed certificate
*this is the same for all images and not suitable for production*.

### OpenLDAP slapd

The certificate, private key, and CA signing file or chain file used for TLS
(port 636 by default) may
be injected into the OpenLDAP slapd container using environment variables
to point to files mounted into the container. 

For example:

```
version: '3.1'

services:

    comanage-registry-database:
        image: mariadb
        volumes:
            - /docker/var/lib/mysql:/var/lib/mysql
        environment:
            - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_root_password
            - MYSQL_DATABASE=registry
            - MYSQL_USER=registry_user
            - MYSQL_PASSWORD_FILE=/run/secrets/mysql_password

    comanage-registry-ldap:
        image: comanage-registry-slapd
        volumes:
            - /docker/var/lib/ldap:/var/lib/ldap
            - /docker/etc/ldap/slapd.d:/etc/ldap/slapd.d
        environment:
            - SLAPD_CERT_FILE=/run/secrets/slapd_cert_file
            - SLAPD_PRIVKEY_FILE=/run/secrets/slapd_privkey_file
            - SLAPD_CHAIN_FILE=/run/secrets/slapd_chain_file
            - OLC_ROOT_PW_FILE=/run/secrets/olc_root_pw
            - OLC_SUFFIX=dc=my,dc=org
            - OLC_ROOT_DN=cn=admin,dc=my,dc=org
        ports:
            - "636:636"
            - "389:389"

    comanage-registry:
        image: comanage-registry:hotfix-2.0.x-basic-auth
        environment:
            - COMANAGE_REGISTRY_DATASOURCE=Database/Mysql
            - COMANAGE_REGISTRY_DATABASE_USER_PASSWORD_FILE=/run/secrets/mysql_password
            - HTTPS_CERT_FILE=/run/secrets/https_cert_file
            - HTTPS_PRIVKEY_FILE=/run/secrets/https_privkey_file
        ports:
            - "80:80"
            - "443:443"
```
## ServerName <a name="servername"></a>

The entrypoint scripts will attempt to parse the appropriate value for the
Apache HTTP Server configuration option `ServerName` from the X.509 certificate
provided for HTTPS.

To override the parsing a deployer may explicitly set the environment variable
`SERVER_NAME`. For example

```
version: '3.1'

services:

    comanage-registry-database:
        image: mariadb
        volumes:
            - /docker/var/lib/mysql:/var/lib/mysql
        environment:
            - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_root_password
            - MYSQL_DATABASE=registry
            - MYSQL_USER=registry_user
            - MYSQL_PASSWORD_FILE=/run/secrets/mysql_password

    comanage-registry:
        image: comanage-registry:hotfix-2.0.x-basic-auth
        environment:
            - COMANAGE_REGISTRY_DATASOURCE=Database/Mysql
            - COMANAGE_REGISTRY_DATABASE_USER_PASSWORD_FILE=/run/secrets/mysql_password
            - HTTPS_CERT_FILE=/run/secrets/https_cert_file
            - HTTPS_PRIVKEY_FILE=/run/secrets/https_privkey_file
            - SERVER_NAME=registry.my.org
        ports:
            - "80:80"
            - "443:443"
```

## Full control <a name="full"></a>

Deployers needing full control may inject configuration and deployment details directly.
The entrypoint scripts will *not* overwrite any details found so directly injected
details always override environment variables.

### COmanage Registry

COmanage Registry expects to find all local configuration details
in the container at `/srv/comanage-registry/local`. A deployer may therefore mount
a directory at that location to provide any and all configuration details. Note, however,
that Registry expects to find a particular directory structure under
`/srv/comanage-registry/local` and will not function properly if the structure is not
found. The entrypoint script will create the necessary structure if it does not find it
so it is recommended to mount an empty directory for the first deployment, let the
entrypoint script create the structure, then later adjust the details as necessary
for your deployment.

### Shibboleth SP

All Shibboleth SP configuration is available inside the container in
`/etc/shibboleth`. A deployer may therefore mount into that directory any
necessary adjustment to the Shibboleth configuration, such as static metadata
files, metadata signing certificates, or advanced attribute filtering 
configurations.

A default set of all configuration files is available in the image.

### OpenLDAP slapd

Since slapd is configured dynamically using standard LDAP operations on the
configuration directory (`cn=config`) the most straightforward way to inject
advanced configuration details at the time the container is *created* is
to customize the entrypoint script.

