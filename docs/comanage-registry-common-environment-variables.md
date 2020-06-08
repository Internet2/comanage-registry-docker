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

# Environment Variables Common to All Images

The environment variables detailed below apply to all COmanage
Registry images in this repository.

## Using Files to Inject Secrets

The COmanage Registry images support the convention of an associated
environment variable ending with ```_FILE``` to indicate a path
relative to the container from which the value for an environment
variable should be read.

For example if the environment variable ```COMANAGE_REGISTRY_DATABASE_USER_PASSWORD_FILE```
exists and its value is the path to a readable file, then the contents of the
file will be read into the environment variable ```COMANAGE_REGISTRY_DATABASE_USER_PASSWORD```.

If both an environment variable and the associated ```_FILE``` environment variable
are defined the associated ```_FILE``` environment variable takes precedence, 
provided that the file it points to exists and is readable.

## Environment Variables

```COMANAGE_REGISTRY_ADMIN_GIVEN_NAME```

* Description: Given name for first platform administrator
* Required: yes
* Default: Registry
* Example: Julia
* Note: \[[1](#note01)\]
 
```COMANAGE_REGISTRY_ADMIN_FAMILY_NAME```

* Description: Family name for first platform administrator
* Required: yes
* Default: Admin
* Example: Janssen
* Note: \[[1](#note01)\]

```COMANAGE_REGISTRY_ADMIN_USERNAME```

* Description: Username name for first platform administrator
* Required: yes
* Default: registry.admin
* Example: julia.janseen@my.org
* Note: \[[1](#note01)\]

```COMANAGE_REGISTRY_DATASOURCE```

* Description: database type
* Required: yes
* Default: Database/Postgres
* Example: Database/Mysql
* Note: \[[2](#note02)\]

```COMANAGE_REGISTRY_DATABASE```

* Description: database name
* Required: yes
* Default: registry
* Example: comanage_registry
* Note: \[[2](#note02)\]

```COMANAGE_REGISTRY_DATABASE_HOST```

* Description: database server host
* Required: yes
* Default: comanage-registry-database
* Example: database-server.my.org
* Note: \[[2](#note02)\]

```COMANAGE_REGISTRY_DATABASE_USER```

* Description: database username
* Required: yes
* Default: registry_user
* Example: comanage-user
* Note: \[[2](#note02)\]

```COMANAGE_REGISTRY_DATABASE_USER_PASSWORD```

* Description: database user password
* Required: yes
* Default: password
* Example: O5Yhtt6TLOxNjo93fmB9
* Note: \[[2](#note02)\]

```COMANAGE_REGISTRY_EMAIL_FROM```

* Description: Default email "From" for emails sent by COmanage Registry
* Required: yes
* Default: ```array('account@gmail.com' => 'Registry')```
* Example: registry@my.org
* Note: \[[3](#note03)\]
* Note: This is a [CakePHP email configuration value](https://book.cakephp.org/2.0/en/core-utility-libraries/email.html).

```COMANAGE_REGISTRY_EMAIL_TRANSPORT```

* Description: Email transport
* Required: yes
* Default: Smtp
* Example: Smtp
* Note: \[[3](#note03)\]

```COMANAGE_REGISTRY_EMAIL_HOST```

* Description: Email server host
* Required: yes
* Default: ```tls://smtp.gmail.com```
* Example: smtp.my.org
* Note: \[[3](#note03)\]

```COMANAGE_REGISTRY_EMAIL_PORT```

* Description: Email server port
* Required: yes
* Default: 465
* Example: 25
* Note: \[[3](#note03)\]

```COMANAGE_REGISTRY_EMAIL_ACCOUNT```

* Description: Email server account
* Required: no
* Default: account@gmail.com
* Example: comanage-registry-smtp@my.org
* Note: \[[3](#note03)\]

```COMANAGE_REGISTRY_EMAIL_ACCOUNT_PASSWORD```

* Description: Email server account password
* Required: no
* Default: password
* Example: Sw5x71ToBHBEr4VqpRxD
* Note: \[[3](#note03)\]

```COMANAGE_REGISTRY_ENABLE_PLUGIN```

* Description: Comma separated list of non-core plugins to enable
* Required: no
* Default: none
* Example: IdentifierEnroller,LdapIdentifierValidator,MailmanProvisioner

```COMANAGE_REGISTRY_NO_DATABASE_CONFIG```

* Description: Do not write a database configuration file if environment variable is set.
* Required: no
* Default: not set
* Example: 1
* Note: If the environment variable is set to any value then the entrypoint script will
not attempt to write the database configuration file ```database.php```. This 
environment variable is often used with the `comanage-registry-cron` image when it
shares a bind mounted directory with the COmanage Registry image.

```COMANAGE_REGISTRY_NO_EMAIL_CONFIG```

* Description: Do not write an email configuration file if environment variable is set.
* Required: no
* Default: not set
* Example: 1
* Note: If the environment variable is set to any value then the entrypoint script will
not attempt to write the email configuration file ```email.php```. This 
environment variable is often used with the `comanage-registry-cron` image when it
shares a bind mounted directory with the COmanage Registry image.


```COMANAGE_REGISTRY_SECURITY_SALT```

* Description: Security salt used when hashing. Must be 40 or more characters from the set [0-9a-zA-Z].
* Required: no
* Default: automatically generated if not provided
* Example: VuUq2mnXC0Cco8uKcjO1rDdP2lVC3lgP970QP2XY
* Note: If present the environment variable is read the first time the container is
started and written to the persistent volume (or bind mount) in the 
configuration file ```security.salt```. Later changes to the environment
variable are *not* reflected in the file which must be
edited directly.

```COMANAGE_REGISTRY_SECURITY_SEED```

* Description: Security seed used for encrypt/decrypt
* Required: no
* Default: automatically generated if not provided
* Example: 47072649794709969916818407654
* Note: If present the environment variable is read the first time the container is
started and written to the persistent volume (or bind mount) in the 
configuration file ```security.seed```. Later changes to the environment
variable are *not* reflected in the file which must be
edited directly.

```COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN```

* Description: Apache HTTP Server virtual host name
* Required: no
* Default: Obtained from inspecting HTTPS x509 certificate file if present, otherwise "unknown"
* Example: registry.my.org

```HTTPS_CERT_FILE```

* Description: path to file containing x509 certificate for HTTPS
* Required: no
* Default: automatically generated self-signed certificate
* Example: /run/secrets/https_cert_file
* Note: The path is relative to the running container.

```HTTPS_PRIVKEY_FILE```

* Description: path to file containing x509 private key for HTTPS
* Required: no
* Default: automatically generated private key
* Example: /run/secrets/https_privkey_file
* Note: The path is relative to the running container.

```HTTPS_CHAIN_FILE```

* Description: path to file containing x509 certificate signing chain for HTTPS, if not specified then `HTTPS_CERT_FILE` much contain a full signing chain for the certificate.
* Required: no
* Default: none
* Example: /run/secrets/https_chain_file
* Note: The path is relative to the running container.


```SERVER_NAME```

* Deprecated. Use ```COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN```.

\[<a name="note01">1</a>\]: The environment variable is read the first time the container is
started and saved to the COmanage Registry database.  Later changes to the environment
variable are *not* reflected in the database state.

\[<a name="note02">2</a>\]: The environment variable is read the first time the container is
started and written to the persistent volume (or bind mount) in the 
configuration file ```database.php```. Later changes to the environment
variable are *not* reflected in the configuration file which must be
edited directly.

\[<a name="note03">3</a>\]: The environment variable is read the first time the container is
started and written to the persistent volume (or bind mount) in the 
configuration file ```email.php```. Later changes to the environment
variable are *not* reflected in the configuration file which must be
edited directly.

