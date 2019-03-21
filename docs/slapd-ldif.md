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
## Executing LDIF Files

The entrypoint script for the slapd images will use the `ldapmodify` command to execute LDIF files
with a `.ldif` extension found under the path `/ldif/` inside the container.
More specifically:

* Files found under `/ldif/admin/` will be executed using simple authentication
as the directory root user and the unhashed directory root user password injected using
the environment variable `OLC_ROOT_PASSWORD` in order to affect the directory, such
as bootstrapping a tree structure or adding system accounts.

* Files found under `/ldif/admin/first/` will be executed as above but only
during the first bootstrap or startup of the container and not on subsequent
startup.

* Files found under `/ldif/config/` will be executed using SASL authentication as
the container root user in order to affect slapd configuration, such as adjusting
access control and configuring modules.

* Files found under `/ldif/config/first/` will be executed as above but only
during the first bootstrap or startup of the container and not on subsequent
startup.

Any variables of the form `%%.+%%` in the LDIF will be substituted with the
value from an injected environment variable without the `%%` characters. The
`_FILE` convention is respected.  For example if the LDIF file contains

```
dn: uid=syncrepl,o=system,dc=my,dc=org
changetype: add
uid: syncrepl
ou: system
description: special account for SyncRepl
objectClass: account
objectClass: simpleSecurityObject
userPassword: %%SYNCREPL_USER_PASSWORD_HASH_FILE%%
```

and the environment variable `SYNCREPL_USER_PASSWORD_HASH_FILE` is defined
and points to the file `/var/run/secrets/syncrepl_user_password_hash` with 
contents

```
{SSHA}emcy1JA+mxbHH0PMPcnasE9apBStAMks
```

then the LDIF executed will be

```
dn: uid=syncrepl,o=system,dc=my,dc=org
changetype: add
uid: syncrepl
ou: system
description: special account for SyncRepl
objectClass: account
objectClass: simpleSecurityObject
userPassword: {SSHA}emcy1JA+mxbHH0PMPcnasE9apBStAMks
```
