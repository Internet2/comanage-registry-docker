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

This recipe uses docker-compose rather than docker stacks. Version
1.13.0 or higher of docker-compose is required:

```
$ docker-compose --version
docker-compose version 1.13.0, build 1719ceb
```

## Recipe

Define `COMANAGE_REGISTRY_VERSION` for the version you wish to deploy.
The current recommendation for deploying with Docker is

```
export COMANAGE_REGISTRY_VERSION=hotfix-2.0.x
```

Build images for COmanage Registry with Shibboleth SP, OpenLDAP,
and PostgreSQL for COmanage Registry using the Dockerfile templates
and instructions for the individual components:

* [COmanageRegistry with Shibboleth SP](../../comanage-registry-shibboleth-sp/README.md)
* [PostgreSQL for COmanage Regsitry](../../comanage-registry-postgres/README.md)
* [OpenLDAP slapd for COmanage Registry](../../comanage-registry-slapd/README.md)

Copy the [docker-compose yaml file](../../comanage-registry-compose/comanage-registry-shibboleth-sp-postgres-compose.yml)
for COmanage Registry with Shibboleth SP and PostgreSQL:

```
cp comanage-registry-shibboleth-sp-postgres-compose.yml docker-compose.yml
```

Examine `docker-compose.yml` and adjust configuration details as necessary
for your deployment. See the documentation for the individual components for
details on which configuration details may be injected using environment
variables and files. 

Note especially the value for `COMANAGE_REGISTRY_ADMIN_USERNAME`.
This is the value that the Shibboleth SP expects to consume in a SAML
assertion from the IdP that authenticates the first platform administrator.
By default the Shibboleth SP will expect to consume that identifier
from the eduPersonPrincipalName attribute asserted for the admin by the IdP.

The instructions that follow assume you are using the locations
of files and directories shown in the example docker-compose file.

Create directories to hold secrets and other deployment
details, PostgresSQL data, slapd directory data,
and slapd configuration data:


```
mkdir -p /opt/comanage-registry-deployment/secrets
mkdir -p /opt/comanage-registry-deployment/postgres-data
mkdir -p /opt/comanage-registry-deployment/slapd-data
mkdir -p /opt/comanage-registry-deployment/slapd-config
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
    > /opt/comanage-registry-deployment/secrets/postgres_password
```

Create a file with the password for the COmanage Registry database user:

```
echo 'DqiMMWjzVOotAHX8WL9J' \
    > /opt/comanage-registry-deployment/secrets/comanage_registry_postgres_user_password
```

Use the slappasswd tool (package `slapd` on Debian) to create a strong hash for a strong
password for the directory root DN:

```
slappasswd -c '$6$rounds=5000$%.86s'
```

Store the hash in a file:

```
echo '{CRYPT}$6$rounds=5000$kER6wkUF91t4.r79$7OLbtO0qF9K9tQlVJAxpWFem.0KmnyWn1/1K0sVSEQELRuj87sc7GtJT7HpWBr8JfZHlbsG9ifrqN6EmJchQ8/' \
   > /opt/comanage-registry-deployment/secrets/olc_root_pw
```

Create a file with the password for the SMTP account that COmanage Registry
uses to send email:

```
echo '6CDYjyuEWPRiC5MwCnRp' \
 > /opt/comanage-registry-deployment/secrets/comanage_registry_email_account_password
```

Create a file with salt that COmanage Registry uses for some hashing
operations:

```
echo 'PdidP9nbU71rBzfasiM6lCVVEkHGZx4wOtAT6s6u' \
    > /opt/comanage-registry-deployment/secrets/comanage_registry_security_salt
```

Create a file with a security seed that COmanage Registry uses (must be all digits):

```
echo '44558711202925048514618319254' 
    > /opt/comanage-registry-deployment/secrets/comanage_registry_security_seed
```

Put the X.509 certificate, private key, and chain files in place for slapd:

```
cp cert.pem /opt/comanage-registry-deployment/secrets/slapd_cert_file
cp privkey.pem /opt/comanage-registry-deployment/secrets/slapd_privkey_file
cp chain.pem /opt/comanage-registry-deployment/secrets/slapd_chain_file
```

Put the X.509 certificate, private key, and chain files in place
for Apache HTTP Server for HTTPS (it is likely these are the same as
for slapd):

```
cp cert.pem /opt/comanage-registry-deployment/secrets/https_cert_file
cp privkey.pem /opt/comanage-registry-deployment/secrets/https_privkey_file
cp chain.pem /opt/comanage-registry-deployment/secrets/https_chain_file
```

Put the Shibboleth SP SAML certificate and key files in place:

```
cp sp-cert.pem /opt/comanage-registry-deployment/secrets/shibboleth_sp_cert_file
cp sp-key.pem /opt/comanage-registry-deployment/secrets/shibboleth_sp_privkey_file
```

Create a file with the Shibboleth SP metadata configuration. This example
creates an XML comment which allows the Shibboleth daemon shibd to start,
but for a production scenario you will want to create a file with any
valid `<MetadataProvider>` configuration. See the Shibboleth SP documentation
for details.

```
echo '<!--<MetadataProvider type="XML" file="partner-metadata.xml"/>-->' \
    > /opt/comanage-registry-deployment/secrets/shibboleth_sp_metadata_provider_xml
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

To stop the services run

```
docker-compose stop
```

To remove the containers (leaving the PostgreSQL and OpenLDAP slapd directory
data) run

```
docker-compose down
```


