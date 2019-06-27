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
ARG COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION=1

FROM comanage-registry-base:${COMANAGE_REGISTRY_VERSION}-${COMANAGE_REGISTRY_BASE_IMAGE_VERSION} AS comanage

FROM comanage-registry-internet2-tier-base:${COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION} AS php-build

FROM centos:centos7

ARG COMANAGE_REGISTRY_VERSION
ENV COMANAGE_REGISTRY_VERSION ${COMANAGE_REGISTRY_VERSION}
LABEL comanage_registry_version=${COMANAGE_REGISTRY_VERSION}

ARG COMANAGE_REGISTRY_BASE_IMAGE_VERSION
ENV COMANAGE_REGISTRY_BASE_IMAGE_VERSION ${COMANAGE_REGISTRY_BASE_IMAGE_VERSION}
LABEL comanage_registry_base_image_version=${COMANAGE_REGISTRY_BASE_IMAGE_VERSION}

ARG COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION
ENV COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION ${COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION}
LABEL comanage_registry_i2_base_image_version=${COMANAGE_REGISTRY_I2_BASE_IMAGE_VERSION}

ARG COMANAGE_REGISTRY_DIR
ENV COMANAGE_REGISTRY_DIR ${COMANAGE_REGISTRY_DIR:-/srv/comanage-registry}
LABEL comanage_registry_dir=${COMANAGE_REGISTRY_DIR}

RUN yum -y install epel-release

COPY shibboleth.repo /etc/yum.repos.d/

RUN yum -y update && yum -y install \
        cronie \
        httpd \
        libargon2 \
        libcurl \
        libedit \
        libsodium \
        libxml2 \
        libxslt \
        mod_ssl \
        mariadb-libs \
        postgresql \
        python-pip \
        shibboleth \
        sudo \
        wget \
        zlib \
    && pip install --upgrade pip \
    && pip install supervisor \
    && yum clean -y all

COPY --from=php-build /usr/lib64/httpd/modules/libphp7.so /usr/lib64/httpd/modules/
COPY --from=php-build /usr/local/lib/php /usr/local/lib/php/
COPY --from=php-build /usr/local/include/php /usr/local/include/php/
COPY --from=php-build /usr/local/bin /usr/local/bin/

COPY --from=comanage ${COMANAGE_REGISTRY_DIR} ${COMANAGE_REGISTRY_DIR}/
COPY --from=comanage /etc/apache2/apache-include-directory-registry /etc/httpd/
COPY --from=comanage /etc/apache2/apache-include-virtual-host-port443-base /etc/httpd/
COPY --from=comanage /etc/apache2/apache-include-virtual-host-port80-redirect /etc/httpd/
COPY --from=comanage /usr/local/lib/comanage_utils.sh /usr/local/lib/
COPY --from=comanage /usr/local/lib/comanage_shibboleth_sp_utils.sh /usr/local/lib/
COPY --from=comanage /usr/local/bin/docker-comanage-entrypoint /usr/local/bin/

COPY 000-comanage.conf /etc/httpd/conf.d/
COPY 10-php7.conf /etc/httpd/conf.modules.d/
COPY php.conf /etc/httpd/conf.d/
COPY supervisord.conf /usr/local/etc/supervisord.conf
COPY shibd.logger /etc/shibboleth/
COPY native.logger /etc/shibboleth/
COPY httpd.conf /etc/httpd/conf/
COPY sendtierbeacon.sh /usr/local/bin/sendtierbeacon.sh
COPY setupcron.sh /usr/local/bin/setupcron.sh
COPY docker-comanage-entrypoint /usr/local/bin/
COPY docker-comanage-shibboleth-sp-entrypoint /usr/local/bin/
COPY docker-supervisord-entrypoint /usr/local/bin/

RUN cd /etc/httpd/conf.d \
    && rm -f autoindex.conf ssl.conf userdir.conf welcome.conf \
    && cd /etc/httpd \
    && ln -s /etc/pki/tls/certs/localhost.crt cert.pem \
    && ln -s /etc/pki/tls/private/localhost.key privkey.pem \
    && chmod 755 /usr/local/bin/sendtierbeacon.sh \
    && chmod 755 /usr/local/bin/setupcron.sh \
    && /usr/local/bin/setupcron.sh \
    && cd /var/www/html \
    && ln -s ${COMANAGE_REGISTRY_DIR}/app/webroot registry \
    && rm -rf ${COMANAGE_REGISTRY_DIR}/local/* \
    && chown -R apache:apache ${COMANAGE_REGISTRY_DIR}/app/tmp \
    && rm -f /etc/shibboleth/shibboleth2.xml

# Allow values for first administrator bootstrapped into the
# platform to be specified at image build time, in addition to
# being injected at run time through the entrypoint script.
ARG COMANAGE_REGISTRY_ADMIN_GIVEN_NAME
ARG COMANAGE_REGISTRY_ADMIN_FAMILY_NAME
ARG COMANAGE_REGISTRY_ADMIN_USERNAME
ARG COMANAGE_REGISTRY_ENABLE_POOLING

# Set simple defaults for first administrator bootstrapped into the
# platform to make simple evaluation of the platform easier.
ENV COMANAGE_REGISTRY_ADMIN_GIVEN_NAME ${COMANAGE_REGISTRY_ADMIN_GIVEN_NAME:-Registry}
ENV COMANAGE_REGISTRY_ADMIN_FAMILY_NAME ${COMANAGE_REGISTRY_ADMIN_FAMILY_NAME:-Admin}
ENV COMANAGE_REGISTRY_ADMIN_USERNAME ${COMANAGE_REGISTRY_ADMIN_USERNAME:-registry.admin}
ENV COMANAGE_REGISTRY_ENABLE_POOLING ${COMANAGE_REGISTRY_ENABLE_POOLING:-No}

VOLUME ${COMANAGE_REGISTRY_DIR}/local /etc/shibboleth

EXPOSE 80 443

# TIER Beacon Opt-out
#
# Completely uncomment the following ENV line to prevent the containers from
# sending analytics information to Internet2.  With the default/release
# configuration, it will only send product (Shibb/Grouper/COmanage) and version
# (3.3.1-17040, etc) once daily between midnight and 4am.  There is no
# configuration or private information collected or sent.  This data helps with
# the scaling and funding of TIER.  Please do not disable it if you find the
# TIER tools useful.  To keep it commented, keep multiple comments on the
# following line (to prevent other scripts from processing it).
#####     ENV TIER_BEACON_OPT_OUT True

ENV TIER_RELEASE=180501
ENV TIER_MAINTAINER=tier

ENTRYPOINT ["docker-supervisord-entrypoint"]
