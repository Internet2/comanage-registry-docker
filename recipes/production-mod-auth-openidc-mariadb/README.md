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

# COmanage Registry Docker for Production with mod_auth_openidc and MariaDB

Follow this recipe as an example production deployment of COmanage Registry
with mod_auth_openidc for authentication, a MariaDB database, and
an OpenLDAP slapd directory server. 

This recipe uses a single node Docker swarm with secrets.

## Recipe

Begin by creating the swarm:

```
docker swarm init
```

Create an overlay network:

```
docker network create \
    --driver overlay \
    --subnet 10.0.9.0/24 \
    --opt encrypted \
    comanage-registry-internal-network
```

Store the secrets (be sure to create and store your own secrets):

```
echo "vvd8cnEHzwUAKA1FEvgE" | docker secret create mysql_root_password - 

echo "ePqoNOipDc3737n7XJfc" | docker secret create mysql_registry_user_password - 

echo "some_client_id" | docker secret create oidc_client_id -

echo "some_client_secret" | docker secret create oidc_client_secret -

echo "https://my.service.org/.well-known/openid-configuration" \
    | docker secret create oidc_provider_metadata_url -

echo "hwL5OIVkEBr34Az2OrLC" | docker secret create oidc_crypto_passphrase -

echo "registry.my.org" | docker secret create registry_host -

docker secret create https_cert_file my.org.crt

docker secret create https_privkey_file my.org.key

docker secret create https_chain_file chain.pem

docker secret create slapd_cert_file my.org.crt

docker secret create slapd_privkey_file my.org.key

docker secret create slapd_chain_file chain.pem
```

Choose a password for the slapd root DN and use the 
`slappasswd` command line tool to generate a hash of the password:

```
slappasswd -c '$6$rounds=5000$%.86s'
```

Store the hash as a secret:

```
echo '{CRYPT}$6$rounds=5000$PvNNFYcGZgiswGxp$mGU2iXuKGkDBRpv4VU1ZTli/S9MZy8DQzj66zpLuHnNQFJ5/ADv3Ij3jsKeGhJq3kFn8yv9RMhEDb/CFoCXxf1' | docker secret create olc_root_pw -
```

Create directories on the Docker host to persist data:

```
mkdir -p /opt/mariadb-data
mkdir -p /opt/slapd-data
mkdir -p /opt/slapd-config
mkdir -p /opt/comanage-registry-local/Config
```

Create the files `database.php` and `email.php` in `/opt/comanage-registry-loca/Config`:

```
# cat database.php 
<?php

class DATABASE_CONFIG {

  public $default = array(
    'datasource' => 'Database/Mysql',
    'persistent' => false,
    'host' => 'comanage-registry-database',
    'login' => 'registry_user',
    'password' => 'password',
    'database' => 'registry',
    'prefix' => 'cm_',
  );

}

# cat email.php 
<?php

class EmailConfig {

    public $default = array(
        'transport' => 'Smtp',
        'from' => array('help@my.org' => 'My Org'),
                'host' => 'smtp.my.org',
                'port' => 25,
                'timeout' => 30
    );
}

```

Deploy the COmanage Registry stack:

```
docker stack deploy --compose-file comanage-registry-mod-auth-openidc-mariadb-stack.yml \
    comanage-registry
```

To deprovision the stack:

```
docker stack rm comanage-registry
```
