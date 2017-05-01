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

# COmanage Registry Docker Simple Evaluation No Persistence

Follow this recipe to spin up an evaluation instance of COmanage Registry
that uses basic authentication with a pre-set login and password. Do *not*
use this recipe for any deployment with security requirements.

This recipe will *not* persist data. All data will be lost when the containers
are removed.

## Recipe

Begin by creating an internal network for the containers to use:

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

Start the database container:

```
docker run -d --name comanage-registry-database \
  --network comanage-registry-internal-network \
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

Start the COmanage Registry container:

```
docker run -d --name comanage-registry \
  --network comanage-registry-internal-network \
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

Click "Login" to login to the registry. For credentials use

```
login    : registry.user
password : password
```

To stop the containers and destroy the network:

```
docker stop comanage-registry
docker stop comanage-registry-database
docker network rm comanage-registry-internal-network
```


