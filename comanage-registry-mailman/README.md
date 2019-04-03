<!--
GNU Mailman 3 for COmanage Registry Docker documentation

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

# GNU Mailman 3 for COmanage Registry Docker

## What it is
Docker version of [GNU Mailman 3](http://www.list.org/) for use with
[COmanage Registry](https://spaces.internet2.edu/display/COmanage/Home).

The instructions below detail how to build and then run a suite of 
services to deploy GNU Mailman 3 for use with a separate COmanage Registry
deployment. The suite of services include:

1. **mailman-core**: GNU Mailman 3 core services including the REST API server.

1. **mailman-web**: GNU Mailman 3 web interface.

1. **database**: Relational database, currently PostgreSQL, required by GNU Mailman 3.

1. **postfix**: MTA needed for sending and receiving mail.

1. **apache**: Apache HTTP Server with Shibboleth SP as a web proxy for GNU Mailman 3 REST and web interface.

## How To

* Install Docker. These instructions require version 17.03.1 or higher.

* The instructions below assume you are deploying the service stack using either Docker Swarm
or [Docker Compose](https://docs.docker.com/compose/). If you are deploying using Docker Compose then
install the Docker Compose script. These instructions require version 1.13.0 or higher.

* Clone this repository:

```
git clone https://github.com/Internet2/comanage-registry-docker.git
cd comanage-registry-docker
```

* Build and tag the images used for each of the services
(you may use your own repository instead of "sphericalcowgroup")

```
pushd comanage-registry-mailman/core
docker build -t sphericalcowgroup/mailman-core:0.2.1 .
popd

pushd comanage-registry-mailman/web
docker build -t sphericalcowgroup/mailman-web:0.2.1 .
popd

pushd comanage-registry-mailman/apache-shib
docker build -t sphericalcowgroup/mailman-core-apache-shib .
popd

pushd comanage-registry-mailman/postfix
docker build -t sphericalcowgroup/mailman-postfix .
popd

```

* Gather or create the following secrets and other information to be injected (be sure
to substitute your own secrets and do not use the examples below):

  * A password for the PostgreSQL user, eg. `gECPnaqXVID80TlRS5ZG`.

  * An API key for GNU Mailman 3 Hyperkitty (web front end), eg. `HbTKLdrhRxUX96f5bD2g`.

  * A secret key used by Django for signing cookies, eg. `fPe7d9e0PKF8ryySOow0`.

  * A password for the GNU Mailman 3 REST user, eg. `K6gfcC9uHQMXr448Kmdi`.

  * An X.509 certificate for HTTPS for Apache HTTP Server (Apache). The server certificate and any subordinate
CA signing certificates (except for the trust root) should be in a single file, eg. `fullchain.pem`.

  * The associated private key for the X.509 HTTPS certificate, eg. `privkey.pem`.

* Create the directory structure on the Docker engine hosts needed for the services 
to save local state, eg.

```
mkdir -p /opt/mailman/core
mkdir -p /opt/mailman/web
mkdir -p /opt/mailman/database
mkdir -p /opt/mailman/shib
```

* If you are using Docker Compose to deploy the service stack copy the file
`docker-compose.yaml`. Review the services configuration. You MUST make at least the following
changes (some environment variables are set for more than one service):

  * `MAILMAN_DATABASE_URL`: URL of the form `postgres://mailman:PASSWORD@database/mailmandb` where `PASSWORD` is the 
  password for the PostgreSQL database.

  * `HYPERKITT_API_KEY`: API key for GNU Mailman 3 Hyperkitty (web front end)

  * `MAILMAN_REST_PASSWORD`: A password for the GNU Mailman 3 REST user

  * `SERVE_FROM_DOMAIN`: The domain name from which Django (web front end) will be served.

  * `MAILMAN_ADMIN_EMAIL`: The email address of the first GNU Mailman 3 administrator.

  * `MAILMAN_WEB_SECRET_KEY`: A secret key used by Django for signing cookies.

  * `POSTGRES_PASSWORD`: The PostgreSQL database password.

  * `POSTFIX_MAILNAME`: The domain name from which Postfix will be receiving and sending mail.

  * Copy the Nginx X.509 certificate chain file, private key, and DH param files and edit the
  `volumes` for the `ngnix` service as necessary to mount the files into the container.

* If you are using Docker Swarm to deploy the service stack copy the file `mailman-stack.yml`.
Review the services configuration. Create the necessary Swarm secrets, eg.

```
echo "postgres://mailman:gECPnaqXVID80TlRS5ZG@database/mailmandb" | docker secret create mailman_database_url -
echo "HbTKLdrhRxUX96f5bD2g" | docker secret create hyperkitty_api_key -
echo "K6gfcC9uHQMXr448Kmdi" | docker secret create mailman_rest_password -
echo "fPe7d9e0PKF8ryySOow0" | docker secret create mailman_web_secret_key -
echo "gECPnaqXVID80TlRS5ZG" | docker secret create postgres_password -
docker secret create https_cert_file fullchain.pem
docker secret create https_key_file privkey.pem
```

Additionally you MUST also make at least the following changes to the stack compose file `mailman-stack.yml`:

  * `MAILMAN_ADMIN_EMAIL`: The email address of the first GNU Mailman 3 administrator.

  * `POSTFIX_MAILNAME`: The domain name from which Postfix will be receiving and sending mail.

* Start the services. If you are using Docker Compose then run

```
docker-compose up -d
```

If you are using Docker Swarm then run

```
docker stack deploy --compose-file mailman-stack.yml mailman
```

* It can take as long as 30 seconds for the GNU Mailman 3 core service to be ready. The other
services wait until detecting that core is ready. Monitor the `apache` service with

```
docker-compose logs -f --tail=100 apache
```

or

```
docker service logs --tail=100 -f mailman_apache
```

until Apache is ready. You should see something like

```
2019-04-03 12:27:55,389 CRIT Set uid to user 0
2019-04-03 12:27:55,391 INFO supervisord started with pid 1
2019-04-03 12:27:56,394 INFO spawned: 'shibd' with pid 8
2019-04-03 12:27:56,399 INFO spawned: 'apache2' with pid 9
Waiting for Mailman core container...
2019-04-03 12:27:57,491 INFO success: shibd entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
2019-04-03 12:27:57,492 INFO success: apache2 entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
Waiting for Mailman core container...
Waiting for Mailman core container...
Waiting for Mailman core container...
Waiting for Mailman web container...
Waiting for Mailman web container...
Waiting for Mailman web container...
[Wed Apr 03 13:48:41.263252 2019] [mpm_event:notice] [pid 9:tid 140569797922880] AH00489: Apache/2.4.38 (Unix) OpenSSL/1.1.0j configured -- resuming normal operations
[Wed Apr 03 13:48:41.284857 2019] [core:notice] [pid 9:tid 140569797922880] AH00094: Command line: 'httpd -D FOREGROUND'
```

* Browse to port 443 on the host and authenticate using an identity provider (IdP) federated
with the Shibboleth SP.

* Visit the [COmanage wiki](https://spaces.internet2.edu/display/COmanage/Mailman+Provisioning+Plugin)
to learn how to enable and configure the Mailman Provisioning Plugin for COmanage Registry.

* To stop the services:

```
docker-compose down
```

or

```
docker stack rm mailman
```

## Useful commands for Docker Compose

```
docker-compose up -d 

docker-compose ps

docker-compose logs mailman-core

docker-compose logs database

docker-compose logs mailman-web

docker-compose logs postfix

docker-compose logs apache

docker-compose logs -f --tail=100 mailman-core

docker-compose logs -f --tail=100 database

docker-compose logs -f --tail=100 mailman-web

docker-compose logs -f --tail=100 postfix

docker-compose logs -f --tail=100 apache

docker-compose down
```

## Useful commands for Docker Swarm

```
docker stack deploy --compose-file mailman-stack.yml mailman

docker stack ls

docker service ls

docker stack ps mailman

docker service logs mailman_mailman-core

docker service logs mailman_mailman-web

docker service logs mailman_apache

docker service logs mailman_database

docker service logs mailman_postfix

docker service logs --tail=100 -f mailman_mailman-core

docker service logs --tail=100 -f mailman_mailman-web

docker service logs --tail=100 -f mailman_apache

docker service logs --tail=100 -f mailman_postfix

docker stack rm mailman
```
