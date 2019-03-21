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

# OpenLDAP slapd for COmanage Registry Volumes and Data Persistence

The OpenLDAP for COmanage Registry image *requires* two persistent directories into which
state files will be written. 

*The persistent directories must be provided either using Docker volumes
or bind mounts.*

Note that when the image is only used as an LDAP proxy the persistent directories
are not strictly necessary, provided all necessary configuration is injected
at run time.

The paths for the directories inside the container that must be mounted
are 

```
/var/lib/ldap
```

and

```
/etc/ldap/slapd.d
```

For example to use bind mounts from the local Docker engine host:

```
sudo mkdir -p /opt/docker/var/lib/ldap
sudo mkdir -p /opt/docker/etc/ldap/slapd.d
```

and then when instantiating the container

```
docker run -d \
  --name comanage-registry-ldap \
  -v /opt/docker/var/lib/ldap:/var/lib/ldap \
  -v /opt/docker/etc/ldap/slapd.d:/etc/ldap/slapd.d \
  -p 389:389 \
  -p 636:636 \
  comanage-registry-slapd:2
```

After the image is instantiated into a container for the first time
the entrypoint script will create the necessary base configuration,
schema, and LMBD files for storing directory state, and bootstrap the directory
using the values for the suffix, root DN, and root DN password
injected at runtime using environment variables.

*After the first instantiation of the container later restarts will not overwrite
the suffix, root DN, and root DN password even if the
values for the environment variables change*.


