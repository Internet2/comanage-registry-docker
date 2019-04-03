# COmanage Registry Dockerfile
#
# Portions licensed to the University Corporation for Advanced Internet
# Development, Inc. ("UCAID") under one or more contributor license agreements.
# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
#
# UCAID licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with the
# License. You may obtain a copy of the License at:
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
ARG COMANAGE_REGISTRY_VERSION=develop
ARG COMANAGE_REGISTRY_BASE_IMAGE_VERSION=1
ARG COMANAGE_REGISTRY_SHIBBOLETH_SP_VERSION="3.0.4"
ARG COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION=1

FROM comanage-registry-shibboleth-sp-base:${COMANAGE_REGISTRY_SHIBBOLETH_SP_VERSION}-${COMANAGE_REGISTRY_SHIBBOLETH_SP_BASE_IMAGE_VERSION} AS shib-base

FROM comanage-registry-base:${COMANAGE_REGISTRY_VERSION}-${COMANAGE_REGISTRY_BASE_IMAGE_VERSION} AS comanage-registry-base

FROM httpd:2.4

RUN apt-get update && apt-get install -y \
         curl \
         libssl1.0.2 \
         netcat-traditional \
         procps \
         supervisor \
      && apt-get clean \
      && mkdir -p /var/log/supervisor

COPY --from=shib-base /opt/shibboleth-sp /opt/shibboleth-sp/

RUN /usr/sbin/useradd --system _shibd \
      && mkdir -p /var/run/shibboleth \
      && chown _shibd:_shibd /var/run/shibboleth \
      && chown -R _shibd:_shibd /opt/shibboleth-sp/var \
      && cp -a /opt/shibboleth-sp/etc/shibboleth /etc/shibboleth \
      && rm -f /etc/shibboleth/shibboleth2.xml \
      && chown _shibd:_shibd /etc/shibboleth/sp-signing-cert.pem \
      && chown _shibd:_shibd /etc/shibboleth/sp-signing-key.pem \
      && chown _shibd:_shibd /etc/shibboleth/sp-encrypt-cert.pem \
      && chown _shibd:_shibd /etc/shibboleth/sp-encrypt-key.pem \
      && cd /opt/shibboleth-sp/etc \
      && rm -rf shibboleth \
      && ln -s /etc/shibboleth shibboleth

COPY --chown=_shibd:_shibd shibd.logger /etc/shibboleth/shibd.logger
COPY --chown=_shibd:_shibd native.logger /etc/shibboleth/native.logger

COPY --from=comanage-registry-base /usr/local/lib/comanage_shibboleth_sp_utils.sh /usr/local/lib/comanage_shibboleth_sp_utils.sh

COPY supervisord.conf /usr/local/etc/supervisord.conf

COPY httpd.conf /usr/local/apache2/conf/
COPY start.sh /usr/local/bin/apache-httpd-start.sh
COPY shibd-start.sh /usr/local/bin/shibd-start.sh

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/usr/local/etc/supervisord.conf"]
