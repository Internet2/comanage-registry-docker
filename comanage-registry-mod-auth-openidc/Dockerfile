# COmanage Registry Dockerfile template
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
ARG COMANAGE_REGISTRY_IMAGE_VERSION=1
FROM sphericalcowgroup/comanage-registry-base:${COMANAGE_REGISTRY_VERSION}-${COMANAGE_REGISTRY_IMAGE_VERSION} AS comanage

FROM debian:stretch AS building

ENV MOD_AUTH_OPENIDC_SRC_URL https://github.com/zmartzone/mod_auth_openidc/archive/v2.3.10.tar.gz

RUN apt-get update \
      && apt-get install -y --no-install-recommends \
        apache2 \
        apache2-dev \
        automake \
        ca-certificates \
        libcjose0 \
        libcjose-dev \
        libcurl4-openssl-dev \
        libjansson-dev \
        libpcre3-dev \
        libssl-dev \
        pkg-config \
        wget \
      && mkdir -p /tmp/mod_auth_openidc \
      && wget -O mod_auth_openidc.tar.gz "$MOD_AUTH_OPENIDC_SRC_URL" \
      && tar -zxf mod_auth_openidc.tar.gz -C /tmp/mod_auth_openidc --strip-components=1 \
      && cd /tmp/mod_auth_openidc \
      && ./autogen.sh \
      && ./configure --with-apxs2=`which apxs2` \
      && make \
      && make install 

FROM comanage

RUN apt-get update \
        && apt-get install -y --no-install-recommends \
          libcjose0

COPY --from=building /usr/lib/apache2/modules/mod_auth_openidc.so /usr/lib/apache2/modules/mod_auth_openidc.so

RUN echo "LoadModule auth_openidc_module /usr/lib/apache2/modules/mod_auth_openidc.so" > /etc/apache2/mods-available/auth_openidc.load \
      && a2enmod auth_openidc 

COPY 000-comanage.conf /etc/apache2/sites-available/
RUN a2ensite 000-comanage

COPY htaccess /srv/comanage-registry/app/webroot/.htaccess
