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

# COmanage Registry mod\_auth\_openidc

Intended to build a COmanage Registry image
using the official PHP 7 with Apache image as the foundation
and providing mod\_auth\_openidc for Apache HTTP Server
as the authentication mechanism. 

## Build

```
export COMANAGE_REGISTRY_VERSION=develop
sed -e s/%%COMANAGE_REGISTRY_VERSION%%/${COMANAGE_REGISTRY_VERSION}/g Dockerfile.template  > Dockerfile
docker build -t comanage-registry:${COMANAGE_REGISTRY_VERSION}-mod-auth-openidc .
```

You can (and should) use build arguments to bootstrap the first
platform administrator. The administrator username is the value
COmanage Registry expects to read from $REMOTE\_USER after
the administrator authenticates using whichever authentication
method is provided:

```
export COMANAGE_REGISTRY_VERSION=develop

export COMANAGE_REGISTRY_ADMIN_GIVEN_NAME=Karel
export COMANAGE_REGISTRY_ADMIN_FAMILY_NAME=Novak
export COMANAGE_REGISTRY_ADMIN_USERNAME=karel.novak@my.org

sed -e s/%%COMANAGE_REGISTRY_VERSION%%/${COMANAGE_REGISTRY_VERSION}/g Dockerfile.template  > Dockerfile
docker build \
  --build-arg COMANAGE_REGISTRY_ADMIN_GIVEN_NAME=${COMANAGE_REGISTRY_ADMIN_GIVEN_NAME} \
  --build-arg COMANAGE_REGISTRY_ADMIN_FAMILY_NAME=${COMANAGE_REGISTRY_ADMIN_FAMILY_NAME} \
  --build-arg COMANAGE_REGISTRY_ADMIN_USERNAME=${COMANAGE_REGISTRY_ADMIN_USERNAME} \
  -t comanage-registry:${COMANAGE_REGISTRY_VERSION}-mod-auth-openidc .
```
## Run

### Database

COmanage Registry requires a relational database. See the 
[PostgreSQL example for COmanage Registry](../comanage-registry-postgres/README.md).

### Network

Create a user-defined network bridge with

```
docker network create --driver=bridge \
  --subnet=192.168.0.0/16 \
  --gateway=192.168.0.100 \
  comanage-registry-internal-network
```

### COmanage Registry Configuration

Create a directory to hold persistent COmanage Registry configuration and
other state such as local plugins and other customizations. In that directory
create a `Config` directory and in it place a `database.php` and `email.php`
configuration file:

```
mkdir -p /opt/comanage-registry/Config

cat >> /opt/comanage-registry/Config/database.php <<"EOF"
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

cat >> /opt/comanage-registry/Config/email.php <<"EOF"
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

### mod\_auth\_openidc Configuration

Mount or COPY mod\_auth\_openidc configuration into the file
`/etc/apache2/conf-enabled/mod-auth-openidc.conf`. The configuration
will usually include

```
OIDCProviderMetadataURL
OIDCRemoteUserClaim
OIDCClientID
OIDCClientSecret
OIDCScope
OIDCCryptoPassphrase
OIDCRedirectURI
```

It should also include a `<Location>` directive to identify the
`OIDCRedirectURI`.

```
<Location /secure/redirect>
  AuthType openid-connect
  Require valid-user
</Location>
```

You may also want to enable logout. For example

```
Redirect /registry/users/logout https://<myserver>/secure/redirect?logout=https%3A%2F%2F<myserver>%2Fregistry%2F
```

### Container

```
docker run -d --name comanage-registry \
  -v /opt/comanage-registry:/local \
  --network comanage-registry-internal-network \
  -p 80:80 -p 443:443 \
  comanage-registry:${COMANAGE_REGISTRY_VERSION}-mod-auth-openidc
```

### Logging

Both Apache HTTP Server and COmanage Registry log to the stdout and
stderr of the container.

### HTTPS Configuration

Mount or COPY in an X.509 certificate file (containing the CA signing certificate(s), if any)
and associated private key file.

```
COPY cert.pem /etc/apache2/cert.pem
COPY privkey.pem /etc/apache2/privkey.pem
```
