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

# COmanage Registry Shibboleth SP Base

## What it is 
This Dockerfile and associated files are used to build a Shibboleth SP
for Apache HTTP Server image intended to be used with
[COmanage Registry](https://spaces.internet2.edu/display/COmanage/Home).

The image built from this Dockerfile is primarily intended to be used
as a base for building other COmanage Registry images using Dockerfile 
multi-stage build functionality. 

It may, however, be used by itself and includes functional entrypoint
scripts for the Apache HTTP Server and Shibboleth shibd daemon. The
image uses Supervisord for managing the Apache and shibd daemon
processes.

## How To

* Clone this repository:

```
git clone https://github.com/Internet2/comanage-registry-docker.git
cd comanage-registry-docker
```

* Build a local image:

```
pushd comanage-registry-basic-shibboleth-sp-base
docker build -t comanage-registry-shibboleth-sp-base
popd
```

* Run:

Without any additional configuration the container will run and the Apache
and shibd daemons will start, but because the Shibboleth SP requires federation
with a SAML Identity Provider (IdP) a proper SAML Web SSO flow until the SP
has been fully configured.

To configure the Shibboleth SP and Apache the following environment variables may 
bet set at container start time:

| Environment Variable | Description | Default | Example 1 | Example 2 |
| -------------------- | ----------- | --------- | --------- | ------- |
| HTTPS_CERT_FILE | path to certificate | self-signed image default | /var/run/secrets/https_cert_file | /cert.pem |
| HTTPS_PRIVKEY_FILE | path to private key | self-signed image default | /var/run/secrets/https_privkey_file | /key.pem |
| SERVER_NAME | FQDN | unknown | registry.my.org | comanage.my.org |
| SHIBBOLETH_SP_ENTITY_ID | SAML entityID | https://comanage.registry/shibboleth | https://registry.my.org/shibboleth | https://comanage.my.org/shibboleth | 
| SHIBBOLETH_SP_CERT | path to SAML cert | image default | /var/run/secrets/shibboleth_cert_file | /sp-cert.pem |
| SHIBBOLETH_SP_PRIVKEY | path to SAML private key | image default | /var/run/secrets/shibboleth_privkey_file | /sp-key.pem |
| SHIBBOLETH_SP_SAMLDS_URL | URL for SAML DS | https://localhost/registry/pages/eds/index | https://registry.my.org/registry/pages/eds/index | https://my.org/disco |
| SHIBBOLETH_SP_METADATA_PROVIDER_XML_FILE | path to Shibboleth SP metadata XML config stanza | none | /var/run/secrets/shibboleth_metadata_config | /metdata.xml |

For more complex Shibboleth SP configurations mount in the necessary
configuration files into the directory `/etc/shibboleth`
instead of setting environment variables.

Here is an example `docker run` to start a container using an X.509
certificate and private key for HTTPS from Let's Encrypt and a
previously generated SAML SP certificate and private key:

```
docker run -d --name comanage-registry-shibboleth-sp-base \
  -v ${PWD}/fullchain.pem:/tmp/https_cert_file \
  -v ${PWD}/privkey.pem:/tmp/https_privkey_file \
  -v ${PWD}/sp-cert.pem:/tmp/sp-cert.pem \
  -v ${PWD}/sp-key.pem:/tmp/sp-key.pem \
  -e HTTPS_CERT_FILE=/tmp/https_cert_file \
  -e HTTPS_PRIVKEY_FILE=/tmp/https_privkey_file \
  -e SHIBBOLETH_SP_ENTITY_ID=https://registry.my.org/shibboleth \
  -e SHIBBOLETH_SP_CERT=/tmp/sp-cert.pem \
  -e SHIBBOLETH_SP_PRIVKEY=/tmp/sp-key.pem \
  -p 80:80 -p 443:443 \
  comanage-registry-shibboleth-sp-base
```

Here is an example of how to use the image in a multi-stage build: 

```
FROM comanage-registry-shibboleth-sp-base as shibboleth-sp

COPY --from=shibboleth-sp /opt/shibboleth-sp /opt/shibboleth-sp/
COPY --from=shibboleth-sp /etc/shibboleth /etc/shibboleth/
COPY --from=shibboleth-sp /etc/apache2/mods-available/shib2.load /etc/apache2/mods-available/shib2.load
COPY --from=shibboleth-sp /usr/local/bin/docker-apache-entrypoint /usr/local/bin/docker-apache-entrypoint
COPY --from=shibboleth-sp /usr/local/bin/docker-shibd-entrypoint /usr/local/bin/docker-shibd-entrypoint
COPY --from=shibboleth-sp /usr/local/bin/apache2-foreground /usr/local/bin/apache2-foreground

RUN /usr/sbin/useradd --system _shibd \
      && mkdir -p /var/run/shibboleth \
      && chown _shibd:_shibd /var/run/shibboleth \
      && chown -R _shibd:_shibd /opt/shibboleth-sp/var \
      && chown _shibd:_shibd /etc/shibboleth/sp-cert.pem \
      && chown _shibd:_shibd /etc/shibboleth/sp-key.pem \
      && mkdir -p /var/log/supervisor

RUN a2enmod shib2 \
      && a2enmod rewrite \
```

