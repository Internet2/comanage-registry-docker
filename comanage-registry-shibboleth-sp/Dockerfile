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
FROM sphericalcowgroup/comanage-registry-base:${COMANAGE_REGISTRY_VERSION} AS comanage

FROM sphericalcowgroup/comanage-registry-shibboleth-sp-base AS shib-base

FROM comanage

COPY --from=shib-base /opt/shibboleth-sp /opt/shibboleth-sp/
COPY --from=shib-base /opt/shibboleth-sp/etc/shibboleth/shib2.load /etc/apache2/mods-available/

RUN /usr/sbin/useradd --system _shibd \
      && mkdir -p /var/run/shibboleth \
      && chown _shibd:_shibd /var/run/shibboleth \
      && chown -R _shibd:_shibd /opt/shibboleth-sp/var \
      && cp -a /opt/shibboleth-sp/etc/shibboleth /etc/shibboleth \
      && rm -f /etc/shibboleth/shibboleth2.xml \
      && chown _shibd:_shibd /etc/shibboleth/sp-cert.pem \
      && chown _shibd:_shibd /etc/shibboleth/sp-key.pem \
      && cd /opt/shibboleth-sp/etc \
      && rm -rf shibboleth \
      && ln -s /etc/shibboleth shibboleth \
      && a2enmod shib2 \
      && apt-get install -y --no-install-recommends supervisor \
      && mkdir -p /var/log/supervisor

COPY supervisord.conf /usr/local/etc/supervisord.conf

COPY docker-comanage-shibboleth-sp-entrypoint /usr/local/bin/

# expose Shibboleth SP configuration files
VOLUME ["/etc/shibboleth"]

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/usr/local/etc/supervisord.conf"]
