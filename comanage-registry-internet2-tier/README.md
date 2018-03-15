# COmanage Registry Internet2 TIER Docker

## What it is
Docker version of [COmanage
Registry](https://spaces.internet2.edu/display/COmanage/Home) packaged to meet
the specifications of the 
[Internet2 TIER](https://www.internet2.edu/vision-initiatives/initiatives/trust-identity-education-research/)
program.

COmanage Registry is a web application that requires a relational database
and an authentication mechanism such as 
[Shibboleth](http://shibboleth.net/products/service-provider.html). 

## How To

* Install Docker. These instructions require version 17.03.1 or higher.

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
pushd comanage-registry-internet2-tier
docker build \
    --build-arg COMANAGE_REGISTRY_VERSION=${COMANAGE_REGISTRY_VERSION} \
    -t comanage-registry:${COMANAGE_REGISTRY_VERSION}-internet2-tier .
popd
```

* Create directories to store local state files:

```
sudo mkdir -p /srv/docker/internet2-tier/srv/comanage-registry/local
sudo mkdir -p /srv/docker/internet2-tier/var/lib/mysql
sudo mkdir -p /srv/docker/internet2-tier/var/lib/ldap
sudo mkdir -p /srv/docker/internet2-tier/etc/ldap/slapd.d
```

* Initialize Docker Swarm:

```
docker swarm init
```

* Hash a password to use as the LDAP admin password:

```
/usr/sbin/slappasswd -c '$6$rounds=5000$%.86s'
```

* Create Docker Swarm secrets (please be sure to substitute your own secrets):


```
echo "88cdfwOgQ1OblrHPNTyY" | docker secret create mysql_root_password - 

echo "5zY87knHxbP3sVQstRW2" | docker secret create mysql_password - 

echo "5zY87knHxbP3sVQstRW2" | docker secret create comanage_registry_database_user_password - 

echo "qselvrfaomxktlra" | docker secret create comanage_registry_email_account_password -

docker secret create https_cert_file fullchain.pem

docker secret create https_privkey_file privkey.pem

docker secret create shibboleth_sp_cert sp-cert.pem

docker secret create shibboleth_sp_privkey sp-key.pem

echo '{CRYPT}$6$rounds=5000$HHDyV7yz4yn4FH/d$eAg9uXbSnxvCCTZ8GstprFryip3Br111tArqsIaBDCF2Rm7tciEivDLCjpcMVT7OL.Lg5QKjEUM.C5UA2DNuf1' \
    | docker secret create olc_root_pw -

docker secret create slapd_cert_file cert.pem

docker secret create slapd_privkey_file privkey.pem

docker secret create slapd_chain_file chain.pem
```

* Create a Docker compose file:

```
version: '3.1'

services:
    comanage-registry:
        image: comanage-registry:3.1.0-internet2-tier
        volumes:
            - /srv/docker/internet2-tier/srv/comanage-registry/local:/srv/comanage-registry/local
        environment:
            - COMANAGE_REGISTRY_DATASOURCE=Database/Mysql
            - COMANAGE_REGISTRY_DATABASE=registry
            - COMANAGE_REGISTRY_DATABASE_HOST=comanage-registry-database
            - COMANAGE_REGISTRY_DATABASE_USER=registry_user
            - COMANAGE_REGISTRY_DATABASE_USER_PASSWORD_FILE=/run/secrets/comanage_registry_database_user_password
            - COMANAGE_REGISTRY_EMAIL_FROM=registry@some.org
            - COMANAGE_REGISTRY_EMAIL_TRANSPORT=Smtp
            - COMANAGE_REGISTRY_EMAIL_HOST=tls://smtp.some.org
            - COMANAGE_REGISTRY_EMAIL_PORT=465
            - COMANAGE_REGISTRY_EMAIL_ACCOUNT=registry@some.org
            - COMANAGE_REGISTRY_EMAIL_ACCOUNT_PASSWORD_FILE=/run/secrets/comanage_registry_email_account_password
            - COMANAGE_REGISTRY_ADMIN_GIVEN_NAME=Emma
            - COMANAGE_REGISTRY_ADMIN_FAMILY_NAME=Sanchez
            - COMANAGE_REGISTRY_ADMIN_USERNAME=emma.sanchez@some.org
            - HTTPS_CERT_FILE=/run/secrets/https_cert_file
            - HTTPS_PRIVKEY_FILE=/run/secrets/https_privkey_file
            - SERVER_NAME=registry.some.org
            - SHIBBOLETH_SP_CERT=/run/secrets/shibboleth_sp_cert
            - SHIBBOLETH_SP_PRIVKEY=/run/secrets/shibboleth_sp_privkey
        secrets:
            - comanage_registry_database_user_password
            - comanage_registry_email_account_password
            - https_cert_file
            - https_privkey_file
            - shibboleth_sp_cert
            - shibboleth_sp_privkey
        networks:
            - default
        ports:
            - "80:80"
            - "443:443"
        logging:
            driver: syslog
            options:
                tag: "comanage_registry"
        deploy:
            replicas: 1

    comanage-registry-database:
        image: mariadb:10.2
        volumes:
            - /srv/docker/internet2-tier/var/lib/mysql:/var/lib/mysql
        environment:
            - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_root_password
            - MYSQL_DATABASE=registry
            - MYSQL_USER=registry_user
            - MYSQL_PASSWORD_FILE=/run/secrets/mysql_password
        secrets:
            - mysql_root_password
            - mysql_password
        networks:
            - default
        logging:
            driver: syslog
            options:
                tag: "mariadb"
        deploy:
            replicas: 1

    comanage-registry-ldap:
        image: sphericalcowgroup/comanage-registry-slapd
        command: ["slapd", "-d", "256", "-h", "ldapi:/// ldap:/// ldaps:///", "-u", "openldap", "-g", "openldap"]
        volumes:
            - /srv/docker/development/var/lib/ldap:/var/lib/ldap
            - /srv/docker/development/etc/ldap/slapd.d:/etc/ldap/slapd.d
        environment:
            - SLAPD_CERT_FILE=/run/secrets/slapd_cert_file
            - SLAPD_PRIVKEY_FILE=/run/secrets/slapd_privkey_file
            - SLAPD_CHAIN_FILE=/run/secrets/slapd_chain_file
            - OLC_ROOT_PW_FILE=/run/secrets/olc_root_pw
            - OLC_SUFFIX=dc=sphericalcowgroup,dc=com
            - OLC_ROOT_DN=cn=admin,dc=sphericalcowgroup,dc=com
        secrets:
            - slapd_cert_file
            - slapd_privkey_file
            - slapd_chain_file
            - olc_root_pw
        networks:
            - default
        logging:
            driver: syslog
            options:
                tag: "openldap"
        ports:
            - "636:636"
            - "389:389"
        deploy:
            replicas: 1

secrets:
    mysql_root_password:
        external: true
    mysql_password:
        external: true
    comanage_registry_database_user_password:
        external: true
    comanage_registry_email_account_password:
        external: true
    https_cert_file:
        external: true
    https_privkey_file:
        external: true
    shibboleth_sp_cert:
        external: true
    shibboleth_sp_privkey:
        external: true
    slapd_cert_file:
        external: true
    slapd_privkey_file:
        external: true
    slapd_chain_file:
        external: true
    olc_root_pw:
        external: true

```

* Start the services:

```
docker stack deploy comanage-registry
```

* Visit the [COmanage wiki](https://spaces.internet2.edu/display/COmanage/Setting+Up+Your+First+CO)
to learn how to create your first collaborative organization (CO) and begin using
the platform.

* To stop the services:
```
docker stack rm comanage-registry
```

## Advanced Configuration Options

* [Environment Variables](#environ)
* [Apache HTTP ServerName](#servername)
* [X.509 Certificates and Private Keys](#certskeys)
* [Full Control](#full)

## Environment Variables <a name="environ"></a>

All deployment details for COmanage Registry may be configured using environment variables set for the container. 
The set of possible environment variables is listed below.

The entrypoint scripts will attempt to use values from environment variables and if not
present reasonable defaults will be used. *Note that some defaults like passwords are
easily guessable and not suitable for production deployments*.

For secrets such as passwords you may wish to use the environment variable with
`_FILE` appended and set the value to a path. The entrypoint scripts will read the
file to find the value to use. For example to set the database user password to the
value `dEodxlXQE2dKl8own7T2` you can for the container either set the environment variable

```
COMANAGE_REGISTRY_DATABASE_USER_PASSWORD=dEodxlXQE2dKl8own7T2
```

or instead ensure that inside the container the file 
`/db_password` contains
on a single line the value `dEodxlXQE2dKl8own7T2` and then set the 
environment variable

*When present an environment variable pointing to a file inside the container overrides
an otherwise configured environment variable*.

```
COMANAGE_REGISTRY_DATABASE_USER_PASSWORD_FILE=/db_password
```

Some deployment details for the Shibboleth SP may be set using environment variables, but most
deployments will prefer to mount or COPY in `/etc/shibboleth/shibboleth2.xml` to be able
to configure SAML federation details.

### COmanage Registry

* COMANAGE_REGISTRY_ADMIN_GIVEN_NAME:
  * Description: platform admin given name
  * Default: Registry
  * Example 1: Scott
  * Example 2: Himari

* COMANAGE_REGISTRY_ADMIN_FAMILY_NAME:
  * Description: platform admin family name
  * Default: Admin
  * Example 1: Koranda
  * Example 2: Tanaka

* COMANAGE_REGISTRY_ADMIN_USERNAME:
  * Description: platform admin username identifier (often eduPersonPrincipalName)
  * Default: registry.admin
  * Example 1: scott.koranda@sphericalcowgroup.com
  * Example 2: himaritanaka@some.org

* COMANAGE_REGISTRY_DATASOURCE
  * Description: database type
  * Default: Database/Postgres
  * Example 1: Database/Mysql
  * Example 2: Database/Postgres

* COMANAGE_REGISTRY_DATABASE
  * Description: name of the database
  * Default: registry
  * Example 1: comanage_registry
  * Example 2: COmanageRegistryDB

* COMANAGE_REGISTRY_DATABASE_HOST
  * Description: hostname of the database server
  * Default: comanage-registry-database
  * Example 1: comanage-registry-database
  * Example 2: my-db-container

* COMANAGE_REGISTRY_DATABASE_USER
  * Description: database username
  * Default: registry_user
  * Example 1: comanage
  * Example 2: comanage_user

* COMANAGE_REGISTRY_DATABASE_USER_PASSWORD
  * Description: database user password
  * Default: password
  * Example 1: AFH9OiyuowiY3Wq6qX0j
  * Example 2: qVcsJPo7$@

* COMANAGE_REGISTRY_EMAIL_FROM
  * Description: default From used by Registry for sending email
  * Default: none
  * Example 1: registry@some.org
  * Example 2: skoranda@gmail.com

* COMANAGE_REGISTRY_EMAIL_TRANSPORT
  * Description: email transport mechanism
  * Default: Smtp
  * Example 1: Smtp
  * Example 2: MyCustom

* COMANAGE_REGISTRY_EMAIL_PORT
  * Description: email transport port
  * Default: 465
  * Example 1: 465
  * Example 2: 25

* COMANAGE_REGISTRY_EMAIL_HOST
  * Description: email server host
  * Default: tls://smtp.gmail.com
  * Example 1: smtp.my.org
  * Example 2: mail.some.org

* COMANAGE_REGISTRY_EMAIL_ACCOUNT
  * Description: email server account
  * Default: none
  * Example 1: skoranda@gmail.com
  * Example 2: registry_email_sender

* COMANAGE_REGISTRY_EMAIL_ACCOUNT_PASSWORD
  * Description: email server account password
  * Default: none
  * Example 1: 82P3mt1T0PByZRHNQ6he
  * Example 2: ak&&u1$@

* COMANAGE_REGISTRY_SECURITY_SALT
  * Description: security salt value
  * Default: auto-generated at initial deployment if not specified
  * Example 1: wciEjD1KbX9Q8nB3YdWItFuzEoRdf6l5BpoCuTHm
  * Example 2: JpmKTdO88NX6RsCIVnru6hV79zKOfvjGk0tTG0Cb

* COMANAGE_REGISTRY_SECURITY_SEED
  * Description: security seed value
  * Default: auto-generated at initial deployment if not specified
  * Example 1: 32616298446590535751260992683
  * Example 2: 21812581423282761029813528278

* HTTPS_CERT_FILE
  * Description: X.509 certificate and CA chain in PEM format for use with Apache HTTP Server to serve HTTPS
  * Default: self-signed auto-generated certificate

* HTTPS_KEY_FILE
  * Description: Associated private key for HTTPS in PEM format
  * Default: private key for self-signed auto-generated certificate

* SERVER_NAME
  * Description: ServerName for Apache HTTP Server virtual host configuration
  * Default: none, parsed from X.509 certificate if not defined
  * Example 1: registry.some.org
  * Example 2: comanage.my.edu

### MariaDB

* MYSQL_ROOT_PASSWORD
  * Description: password for root user
  * Default: none
  * Example 1: ukZd7IZDRfOqgF82938A
  * Example 2: 28hvua3%,2

* MYSQL_DATABASE
  * Description: name of the database, must be same as set for COmanage Registry container
  * Default: none
  * Example 1: comanage_registry
  * Example 2: COmanageRegistryDB

* MYSQL_USER:
  * Description: database username, must be same as set for COmanage Registry container
  * Default: none
  * Example 1: comanage
  * Example 2: comanage_user

* MYSQL_PASSWORD_FILE:
  * Description: database user password, must be same as set for COmanage Registry container
  * Default: none
  * Example 1: AFH9OiyuowiY3Wq6qX0j
  * Example 2: qVcsJPo7$@

### Shibboleth SP

* SHIBBOLETH_SP_CERT
  * Description: SAML certificate
  * Default: self-signed per-image, must be copied out to persist

* SHIBBOLETH_SP_ENTITY_ID 
  * Description: entityID for SP
  * Default: none
  * Example 1: https://comanage.registry/shibboleth
  * Example 2: https://my.org/comanage

* SHIBBOLETH_SP_METADATA_PROVIDER_XML
  * Description: Shibboleth SP metadata provider element
  * Default: none

* SHIBBOLETH_SP_PRIVKEY
  * Description: SAML private key
  * Default: self-signed per-image, must be copied out to persist

* SHIBBOLETH_SP_SAMLDS_URL
  * Description: URL for SAML IdP discovery service
  * Default: none
  * Example 1: https://my.org/registry/pages/eds/index
  * Exammple 2: https://discovery.my.org 

### OpenLDAP slapd

* OLC_ROOT_DN
  * Description: DN for the administrator
  * Default: cn=admin,dc=my,dc=org
  * Exammle 1: cn=admin,dc=some,dc=edu
  * Example 2: cn=admin,ou=service,dc=my,dc=org 

* OLC_ROOT_PW
  * Description: hashed password for root DN
  * Default: none
  * Example 1: See compose file above

* OLC_SUFFIX
  * Description: Suffix for the directory
  * Default: dc=my,dc=org
  * Example 1: dc=some,dc=edu 
  * Example 2: o=unit,dc=my,dc=org

* SLAPD_CERT_FILE
  * Description: X.509 certificate in PEM format for use with OpenLDAP Server to serve ldaps://
  * Default: none

* SLAPD_CHAIN_FILE
  * Description: CA certificate chain in PEM format
  * Default: none

* SLAPD_KEY_FILE
  * Description: Associated private key for ldaps:// in PEM format
  * Default: none

## X.509 Certificates and Private Keys <a name="certskeys"></a>

### COmanage Registry

The certificate and private key files used for HTTPS may
be injected into the COmanage Registry container using environment variables
to point to files mounted into the container. The certificate file should
include the server certificate and any intermediate CA signing certificates
sorted from leaf to root.

Alternatively you can directly mount files in the container to

```
/etc/apache2/cert.pem
/etc/apache2/privkey.pem
```

If no files are configured the containers use self-signed certificates
for HTTPS by default.

### Shibboleth SP

The SAML certificate and private key used for decryption (and sometimes signing)
by the Shibboleth SP may be injected into the COmanage Registry container using
environment variables to point to files mounted into the container.

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

## ServerName <a name="servername"></a>

The entrypoint scripts will attempt to parse the appropriate value for the
Apache HTTP Server configuration option `ServerName` from the X.509 certificate
provided for HTTPS.

To override the parsing a deployer may explicitly set the environment variable
`SERVER_NAME`. 

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
