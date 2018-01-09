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

# Environment Variables Common to All slapd Images

The environment variables detailed below apply to all OpenLDAP slapd for
COmanage Registry images in this repository.

## Using Files to Inject Secrets

The COmanage Registry images support the convention of an associated
environment variable ending with ```_FILE``` to indicate a path
relative to the container from which the value for an environment
variable should be read.

For example if the environment variable ```OLC_ROOT_DN_PASSWORD_FILE```
exists and its value is the path to a readable file, then the contents of the
file will be read into the environment variable ```OLC_ROOT_DN_PASSWORD```.

If both an environment variable and the associated ```_FILE``` environment variable
are defined the associated ```_FILE``` environment variable takes precedence, 
provided that the file it points to exists and is readable.

## Environment Variables

```
OLC_ROOT_DN
```

* Description: DN for the directory root user
* Required: yes
* Default: cn=admin,dc=my,dc=org
* Example: cn=directoryAdministrator,dc=some,dc=university,dc=org
* Note: \[[1](#note01)\]

```
OLC_ROOT_DN_PASSWORD
```

* Description: Unhashed password for the root DN used by the entrypoint script to execute
  any injected LDIF as the root DN user
* Required: no
* Default: none
* Example: KaVJ1FIH5IrRr6R5LElX
* Note: The environment variable `OLC_ROOT_DN` is used to set the hashed password for the root
DN during the bootstrapping of the directory. This environment variable is used to inject
the unhashed password so that the entrypoint script can execute injected LDIF as the root DN
user. If no LDIF is injected that needs to be executed as the root DN than this environment
variable is not necessary.


```
OLC_ROOT_PW
```

* Description: Password (usually hashed) for the root DN
* Required: yes
* Default: password
* Example: {SSHA}emcy1JA+mxbHH0PMPcnasE9apBStAMks
* Note: See the [slappasswd OpenLDAP password utility](https://linux.die.net/man/8/slappasswd) for details on how to
  create a hashed password value.  See also \[[1](#note01)\].

```
OLC_SUFFIX
```

* Description: Suffix for the directory
* Required: yes
* Default: dc=my,dc=org
* Example: dc=some,dc=university,dc=edu
* Note: \[[1](#note01)\]

```
SLAPD_CERT_FILE
```

* Description: Path inside the container to an X.509 certificate to use for TLS
* Required: no
* Default: none
* Example: /run/secrets/slapd_cert_file

```
SLAPD_CHAIN_FILE
```

* Description: Path inside the container to the certificate authority signing certificate corresponding to the X.509
  certificate to use for TLS
* Required: no
* Default: none
* Example: /run/secrets/slapd_chain_file

```
SLAPD_PRIVKEY_FILE
```

* Description: Path inside the container to the private key associated with the X.509 certificate for TLS
* Required: no
* Default: none
* Example: /run/secrets/slapd_privkey_file


\[<a name="note01">1</a>\]: The environment variable is read the first time the container is
started and used to bootstrap the directory.  Later changes to the environment
variable are *not* reflected in the directory state.
