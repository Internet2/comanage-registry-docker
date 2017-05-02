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

# COmanage Registry Docker Simple Evaluation With Persistence

Follow this recipe to spin up an evaluation instance of COmanage Registry
that uses basic authentication with a pre-set login and password. Do *not*
use this recipe for any deployment with security requirements.

This recipe *will* persist data outside of containers.

## Recipe

Begin by creating a directories for the relational database and COmanage
Registry to use to persist data:

```
mkdir /opt/comanage-registry-database
mkdir /opt/comanage-registry-local
```

Next use the `htpasswd` command to generate a password file to be used
with basic authentication. When prompted enter your chose password (twice):

```
htpasswd /opt/comanage-registry-passwords registry.user
```

You may edit that file later to either change the password or add
credenitals for more users.

Next create an internal network for the containers to use:

```
docker network create --driver=bridge \
  --subnet=192.168.0.0/16 \
  --gateway=192.168.0.100 \
  comanage-registry-internal-network
```

Next build a PostgreSQL image to use as the database container:

```
pushd comanage-registry-postgres
docker build -t comanage-registry-postgres .
```

Start the database container and mount the directory you created
for persisting data:

```
docker run -d --name comanage-registry-database \
  --network comanage-registry-internal-network \
  -v /opt/comanage-registry-database:/var/lib/postgresql/data \
  comanage-registry-postgres
```

Next build the COmanage Registry image using basic authentication:

```
popd
pushd comanage-registry-basic-auth
export COMANAGE_REGISTRY_VERSION=hotfix-2.0.x
sed -e s/%%COMANAGE_REGISTRY_VERSION%%/${COMANAGE_REGISTRY_VERSION}/g \
    Dockerfile.template  > Dockerfile
docker build \
    -t comanage-registry:${COMANAGE_REGISTRY_VERSION}-basic-auth .
```

Start the COmanage Registry container and mount the directory you
created for persisting configuration data and the password file
you created for basic authentication:

```
docker run -d --name comanage-registry \
  --network comanage-registry-internal-network \
  -v /opt/comanage-registry-loca:/local \
  -v /opt/comanage-registry-passwords:/etc/apache2/passwords \
  -p 80:80 -p 443:443 \
  comanage-registry:${COMANAGE_REGISTRY_VERSION}-basic-auth
```

The COmanage Registry service is now exposed on the host on which 
Docker is running on ports 80 and 443. For example on your localhost

```
https://localhost/registry/
```

You will need to click through browser warnings about self-signed
certificates for HTTPS.

Click "Login" to login to the registry. For credentials use `registry.user`
and the password you previously set using the `htpasswd` command.

To stop the containers:

```
docker stop comanage-registry
docker stop comanage-registry-database
```

You may edit the COmanage Registry configuration details in
`/opt/comanage-registry-local/Config` and then restart the containers.
For example to enable Registry to send email edit the file

`/opt/comanage-registry-local/Config/email.php` and then restart the containers:

```
docker start comanage-registry-database
docker start comanage-registry
```
The following sections in the [COmanage Registry Technical Manual](https://spaces.internet2.edu/display/COmanage/COmanage+Technical+Manual)
may be helpful:

* [Setting Up Your First CO](https://spaces.internet2.edu/x/F4DPAg)
* [Understanding Registry People Types](https://spaces.internet2.edu/x/RgGnAQ)
* [Registry Administrators](https://spaces.internet2.edu/x/EIDPAg)
* [Registry Enrollment Flow Configuration](https://spaces.internet2.edu/x/RAGnAQ)

To stop the containers and destroy the network:

```
docker stop comanage-registry
docker rm comanage-registry

docker stop comanage-registry-database
docker rm comanage-registry-database

docker network rm comanage-registry-internal-network
```
