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

# Environment Variables Common to Images using Shibboleth SP for Authentication

The environment variables detailed below apply to all COmanage
Registry images in this repository that use the Shibboleth Native SP for
Apache HTTP Server (Shibboleth) for authentication.

## Using Files to Inject Secrets

The image supports the environment variables below and the `_FILE`
[convention](../docs/comanage-registry-common-environment-variables.md):

## Environment Variables

`SHIBBOLETH_SP_CERT`

* Deprecated: Use `SHIBBOLETH_SP_ENCRYPT_CERT`.

`SHIBBOLETH_SP_ENCRYPT_CERT`

* Description: PEM encoded X.509 certificate used for encrypting assertions to be sent to and consumed by the SP.
* Required: Yes
* Default: Image default, not suitable for production use.
* Example: See note below.
* Note: \[[1](#note01)\]

`SHIBBOLETH_SP_ENCRYPT_PRIVKEY`

* Description: Private key associated with the PEM encoded X.509 certificate used for encrypting assertions to be sent to and consumed by the SP.
* Required: Yes
* Default: Image default, not suitable for production use.
* Example: See note below.
* Note: \[[1](#note01)\]

`SHIBBOLETH_SP_ENTITY_ID`

* Description: SAML entityID for the SP.
* Required: Yes
* Default: Image default, not suitable for production use.
* Example: https://myapp.my.org/shibboleth/sp
* Note: \[[2](#note02)\]


`SHIBBOLETH_SP_METADATA_PROVIDER_XML`

* Description: XML stanza for configuring Shibboleth SP metadata consumption.
* Required: Yes
* Default: Image default, not suitable for production use.
* Example: See note below.
* Note: Due to the complex syntax which makes escaping some characters tedious,
most deployers write the configuration into a file and specify the variable
`SHIBBOLETH_SP_METADATA_PROVIDER_XML_FILE`. See also \[[2](#note02)\].

`SHIBBOLETH_SP_PRIVKEY`

* Deprecated: Use `SHIBBOLETH_SP_ENCRYPT_PRIVKEY`.

`SHIBBOLETH_SP_SAMLDS_URL`

* Description: URL for SAML IdP discovery service.
* Required: Yes
* Default: Image default, not suitable for production use.
* Example: https://login-chooser.my.org
* Note: \[[2](#note02)\]

`SHIBBOLETH_SP_SIGNING_CERT`

* Description: PEM encoded X.509 certificate used by the SP for signing authentication requests.
* Required: Yes
* Default: Image default, not suitable for production use.
* Example: See note below.
* Note: \[[1](#note01)\]


`SHIBBOLETH_SP_SIGNING_PRIVKEY`

* Description: Private key associated with the PEM encoded X.509 certificate used by the SP for signing authentication requests.
* Required: Yes
* Default: Image default, not suitable for production use.
* Example: See note below.
* Note: \[[1](#note01)\]

\[<a name="note01">1</a>\]: Many deployers start a container without specifying the variable and then
break into the running container and use the `/etc/shibboleth/keygen.sh` script
to generate the persistent cert and private key pair and copy them out of the container.
Later after escrowing the cert and private key they are injected into the container
using the variable(s).

\[<a name="note02">2</a>\]: While the image allows some Shibboleth SP configurations to be directly
injected using environment variables, most deployers bind mount or COPY the necessary
Shibboleth SP configuration files with local deployment details into the directory `/etc/shibboleth/`.
The image includes the standard example and template configuration files experienced
Shibboleth SP deployers expect to find.
