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

# COmanage Registry Docker for Production with Shibboleth SP and PostgreSQL using docker-compose

Follow this recipe as an example production deployment of COmanage Registry
with the Shibboleth SP for authentication, a PostgreSQL database, and
an OpenLDAP slapd directory server. 

This recipe uses docker-compose rather than Docker service stacks. Version
1.13.0 or higher of docker-compose is required:

```
$ docker-compose --version
docker-compose version 1.13.0, build 1719ceb
```

## Recipe

* Define the shell variable `COMANAGE_REGISTRY_VERSION` to be the version
of COmanage Registry you want to deploy. See the
[COmanage Registry Release History](https://spaces.internet2.edu/display/COmanage/Release+History)
wiki page for the list of releases. We recommend using the latest release.

Here is an example (but please check the wiki page for the latest release number):

```
export COMANAGE_REGISTRY_VERSION=3.1.1
```

* Build a local image for COmanage Registry if you have not already (building the
  Shibboleth SP from source takes time):

```
pushd comanage-registry-shibboleth-sp
sed -e s/%%COMANAGE_REGISTRY_VERSION%%/${COMANAGE_REGISTRY_VERSION}/g Dockerfile.template  > Dockerfile
docker build -t comanage-registry:${COMANAGE_REGISTRY_VERSION}-shibboleth-sp .
popd
```

* Build a local image of PostgreSQL for COmanage Registry if you have not already:

```
pushd comanage-registry-postgres
docker build -t comanage-registry-postgres .
popd
```

* Build a local image of OpenLDAP slapd for COmanage Registry if you have not already:

```
pushd comanage-registry-slapd
docker build -t comanage-registry-slapd .
popd
```

* Create directories to persist the relational database, COmanage Registry
local configuration, slapd configuration, slapd directory data, and to
hold secrets and other injected details:
```
mkdir -p /docker/var/lib/postgresql/data
mkdir -p /docker/srv/comanage-registry/local
mkdir -p /docker/var/lib/ldap
mkdir -p /docker/etc/ldap/slapd.d
mkdir -p /docker/run/secrets
```

Below we create and store secrets in files using simple commands but you 
could use any configuration management or deployment orchestration tool
you like such as Puppet, Chef, Ansible, Salt, or whichever tool is your
favorite. Be sure to create your own secrets and do not reuse the examples
below.

Create a file with the password for the postgres user (that is, the 
equivalent of a "root" password for the database):

```
echo 'xyt8Op3BCwdI5ETcVfQM' \
    > /docker/run/secrets/postgres_password
```

Create a file with the password for the COmanage Registry database user:

```
echo 'DqiMMWjzVOotAHX8WL9J' \
    > /docker/run/secrets/comanage_registry_postgres_user_password
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
cp cert.pem /docker/run/secrets/slapd_cert_file
cp privkey.pem /docker/run/secrets/slapd_privkey_file
cp chain.pem /docker/run/secrets/slapd_chain_file
```

Put the X.509 certificate and private key files in place
for Apache HTTP Server for HTTPS. The certificate file should
include the server certificate and any intermediate CA signing 
certificates sorted from leaf to root:

```
cp cert.pem /docker/run/secrets/https_cert_file
cp privkey.pem /docker/run/secrets/https_privkey_file
```

Put the Shibboleth SP SAML certificate and key files in place:

```
cp sp-cert.pem /docker/run/secrets/shibboleth_sp_cert_file
cp sp-key.pem /docker/run/secrets/shibboleth_sp_privkey_file
```

Create a file with the Shibboleth SP metadata configuration. This example
creates an XML comment which allows the Shibboleth daemon shibd to start,
but for a production scenario you will want to create a file with any
valid `<MetadataProvider>` configuration. See the Shibboleth SP documentation
for details.

```
echo '<!--<MetadataProvider type="XML" file="partner-metadata.xml"/>-->' \
    > /docker/run/secrets/shibboleth_sp_metadata_provider_xml
```

* Create a template docker-compose.yml by adjusting the example below:

```
version: '3.1'

services:

    comanage-registry-database:
        image: comanage-registry-postgres
        volumes:
            - /docker/var/lib/postgresql/data:/var/lib/postgresql/data
            - /docker/run/secrets:/run/secrets
        environment:
            - POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password
            - COMANAGE_REGISTRY_POSTGRES_USER_PASSWORD_FILE=/run/secrets/comanage_registry_postgres_user_password

    comanage-registry-ldap:
        image: comanage-registry-slapd
        volumes:
            - /docker/var/lib/ldap:/var/lib/ldap
            - /docker/etc/ldap/slapd.d:/etc/ldap/slapd.d
            - /docker/run/secrets:/run/secrets
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
        image: comanage-registry:COMANAGE_REGISTRY_VERSION-shibboleth-sp
        volumes:
            - /docker/srv/comanage-registry/local:/srv/comanage-registry/local
            - /docker/run/secrets:/run/secrets
        environment:
            - COMANAGE_REGISTRY_ADMIN_GIVEN_NAME=Karel
            - COMANAGE_REGISTRY_ADMIN_FAMILY_NAME=Novak
            - COMANAGE_REGISTRY_ADMIN_USERNAME=karel.novak@my.org
            - COMANAGE_REGISTRY_DATABASE_USER_PASSWORD_FILE=/run/secrets/comanage_registry_postgres_user_password
            - SHIBBOLETH_SP_ENTITY_ID=https://my.org/shibboleth
            - SHIBBOLETH_SP_CERT=/run/secrets/shibboleth_sp_cert_file
            - SHIBBOLETH_SP_PRIVKEY=/run/secrets/shibboleth_sp_privkey_file
            - SHIBBOLETH_SP_SAMLDS_URL=https://my.org/registry/pages/eds/index
            - SHIBBOLETH_SP_METADATA_PROVIDER_XML_FILE=/run/secrets/shibboleth_sp_metadata_provider_xml
            - HTTPS_CERT_FILE=/run/secrets/https_cert_file
            - HTTPS_PRIVKEY_FILE=/run/secrets/https_privkey_file

        ports:
            - "80:80"
            - "443:443"
```

Note especially the value for `COMANAGE_REGISTRY_ADMIN_USERNAME`.
This is the value that the Shibboleth SP expects to consume in a SAML
assertion from the IdP that authenticates the first platform administrator.
By default the Shibboleth SP will expect to consume that identifier
from the eduPersonPrincipalName attribute asserted for the admin by the IdP.

* Use sed to set the COmanage Registry version for the image in the 
docker-compose.yml file:

```
sed -i s/COMANAGE_REGISTRY_VERSION/$COMANAGE_REGISTRY_VERSION/ docker-compose.yml
```

Bring up the services using docker-compose:

```
docker-compose up -d
```

COmanage Registry will be exposed on port 443 (HTTP). Use a web browser
to browse, for example, to

```
https://localhost/registry/
```

If you have properly federated the Shibboleth SP with the IdP that the
first platform administrator will use you can click on "Login" and be
redirected to the IdP for authentication.

Production deployments need to send email, usually using an authenticated
account on a SMTP server. You may configure the details for your SMTP server
by editing the file `email.php` that the entrypoint script automatically
creates in `/docker/srv/comanage-registry/local/Config`.

To stop the services run

```
docker-compose stop
```

To remove the containers run

```
docker-compose down
```

