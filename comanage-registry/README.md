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

# COmanage Registry Base

Intended to build a COmanage Registry base image
using the official PHP 7 with Apache image as the foundation.

The image built from this template does **not** provide any
method for authentication. See other templates in this
repository for examples on how to build images on this
one that include authentication methods like Basic Auth,
Shibboleth Native SP for Apache, and OIDC.

## Configuration

### Environment Variables

The following environment variables may be set to inject deployment
details into a container built from this image:

| Environment Variable | Description | Default | Example 1 | Example 2 |
| -------------------- | ----------- | --------- | --------- | ------- |
| COMANAGE_REGISTRY_ADMIN_FAMILY_NAME | Registry admin family name | Admin | Novak | Sanchez |
| COMANAGE_REGISTRY_ADMIN_GIVEN_NAME | Registry admin given name | Registry | Karel | Michelle |
| COMANAGE_REGISTRY_ADMIN_USERNAME | Registry admin login name | registry.admin | admin | karel.novak@my.org |
| COMANAGE_REGISTRY_DATABASE | database name | registry | registry_db | comanage |
| COMANAGE_REGISTRY_DATABASE_HOST | database server hostname | comanage-registry-database | | |
| COMANAGE_REGISTRY_DATABASE_USER| database user | registry_user | comanage | comanage_user |
| COMANAGE_REGISTRY_DATABASE_USER_PASSWORD | database user password | password | AFH9OiyuowiY3Wq6qX0j | qVcsJPo7$@ |
| COMANAGE_REGISTRY_DATASOURCE | database type | Database/Postgres | Database/Postgres | Database/Mysql |
| COMANAGE_REGISTRY_EMAIL_FROM | From: address | array('account@gmail.com' => 'Registry') | 'registry@my.org' | array('registry@my.org' => 'My Org Registry') |
| COMANAGE_REGISTRY_EMAIL_TRANSPORT | mail transport | Smtp | | |
| COMANAGE_REGISTRY_EMAIL_HOST | mail host | tls://smtp.gmail.com | smtp.my.org | mail.my.org |
| COMANAGE_REGISTRY_EMAIL_PORT | mail port | 465 | 25 | 587 |
| COMANAGE_REGISTRY_EMAIL_ACCOUNT | mail server account | account@gmail.com | mail_bot | registry |
| COMANAGE_REGISTRY_EMAIL_ACCOUNT_PASSWORD | mail server password | password | d6WE2fpwAw | xp790Mu3q6 |
| COMANAGE_REGISTRY_SECURITY_SALT | CakePHP security salt | automatically generated | e8RrE9X3pVnozrupHSHo4GTLqL380LuU7X7LKj42 | |
| COMANAGE_REGISTRY_SECURITY_SEED | CakePHP security seed | automatically generated | 62259808467736132961503540721 | |
| HTTPS_CERT_FILE | HTTPS X.509 certificate | automatically generated self-signed | | |
| HTTPS_PRIVKEY_FILE | HTTPS private key | automatically generated self-signed | | |
| SERVER_NAME | web server name | parsed from HTTPS X.509 certificate | | |


### Finer Control

For finer control over the configuration of COmanage Registry and the
CakePHP framework create a directory to hold persistent COmanage Registry configuration and
other state such as local plugins and other customizations. In that directory
create a `Config` directory and in it place a `database.php` and `email.php`
configuration file:

```
mkdir -p /docker/srv/comanage-registry/local/Config

cat > /docker/srv/comanage-registry/local/Config/database.php <<"EOF"
<?php

class DATABASE_CONFIG {

  public $default = array(
    'datasource' => 'Database/Postgres',
    'persistent' => false,
    'host' => 'comanage-registry-database',
    'login' => 'registry_user',
    'password' => 'password',
    'database' => 'registry',
    'prefix' => 'cm_',
  );

}
EOF

cat > /docker/srv/comanage-registry/local/Config/email.php <<"EOF"
<?php

class EmailConfig {

  public $default = array(
    'transport' => 'Smtp',
    'host' => 'tls://smtp.gmail.com',
    'port' => 465,
    'username' => 'account@gmail.com',
    'password' => 'password'
  );
}
EOF
```

When creating the container mount the directory you created, eg.

```
docker run -d --name comanage-registry \
  -v /docker/srv/comanage-registry/local:/local 
  -p 80:80 -p 443:443 \
  comanage-registry:${COMANAGE_REGISTRY_VERSION}
```

### HTTPS Configuration

In preferred you may mount or COPY in an X.509 certificate file (containing the CA signing certificate(s), if any)
and associated private key file. 

```
COPY cert.pem /etc/apache2/cert.pem
COPY privkey.pem /etc/apache2/privkey.pem
```
