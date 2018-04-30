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
FROM centos:centos7 AS php-build

RUN yum -y install epel-release

RUN yum -y update && yum -y install \
        autoconf \
        bison \
        gcc \
        httpd-devel \
        libargon2-devel \
        libcurl-devel \
        libedit-devel \
        libsodium-devel \
        libxml2-devel \
        libxslt-devel \
        make \
        mariadb-devel \
        openldap-devel \
        openssl-devel \
        postgresql-devel \
        re2c \
        wget

WORKDIR /usr/local/src

ARG PHP_VERSION=7.2.3
ARG PHP_SRC_URL=https://github.com/php/php-src/archive/php-${PHP_VERSION}.tar.gz

RUN mkdir php-src \
        && wget -O php-src.tar.gz ${PHP_SRC_URL} \
        && tar zxf php-src.tar.gz -C php-src --strip-components=1 \
        && rm php-src.tar.gz

ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"

RUN cd php-src \
        && ./buildconf --force \
        && ./configure \
            --disable-cgi \
            --enable-mbstring \
            --enable-mysqlnd \
            --with-apxs2=/usr/bin/apxs \
            --with-config-file-path=/usr/local/etc/php \
            --with-config-file-scan-dir=/usr/local/etc/php/conf.d \
            --with-curl \
            --with-ldap \
            --with-libdir=lib64 \
            --with-libedit \
            --with-mysqli \
            --with-openssl \
            --with-password-argon2 \
            --with-pdo-mysql \
            --with-pdo-pgsql \
            --with-pgsql \
            --with-sodium \
            --with-xsl \
            --with-zlib \
        && export CFLAGS="$PHP_CFLAGS" \
        && export CPPFLAGS="$PHP_CPPFLAGS" \
        && export LDFLAGS="$PHP_LDFLAGS" \
        && make -j "$(nproc)" \
        && make install 

FROM centos:centos7

RUN yum -y install epel-release

COPY shibboleth.repo /etc/yum.repos.d/

RUN yum -y update && yum -y install \
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
        shibboleth \
        supervisor \
        wget \
        zlib

COPY --from=php-build /usr/lib64/httpd/modules/libphp7.so /usr/lib64/httpd/modules/
COPY --from=php-build /usr/local/lib/php /usr/local/lib/php/
COPY --from=php-build /usr/local/include/php /usr/local/include/php/
COPY --from=php-build /usr/local/bin /usr/local/bin/

ARG COMANAGE_REGISTRY_VERSION
ARG COMANAGE_REGISTRY_SRC_URL=https://github.com/Internet2/comanage-registry/archive/${COMANAGE_REGISTRY_VERSION}.tar.gz

LABEL comanage_registry_version=${COMANAGE_REGISTRY_VERSION}
LABEL comanage_registry_src_url=${COMANAGE_REGISTRY_SRC_URL}

ENV COMANAGE_REGISTRY_DIR /srv/comanage-registry

WORKDIR "$COMANAGE_REGISTRY_DIR"

RUN mkdir -p "${COMANAGE_REGISTRY_DIR}" \
        && wget -O comanage.tar.gz ${COMANAGE_REGISTRY_SRC_URL} \
        && tar -zxf comanage.tar.gz -C ${COMANAGE_REGISTRY_DIR} --strip-components=1 \
        && rm -f comanage.tar.gz \
        && rm -f ${COMANAGE_REGISTRY_DIR}/app/tmp \
        && cp -r ${COMANAGE_REGISTRY_DIR}/app/tmp.dist ${COMANAGE_REGISTRY_DIR}/app/tmp \
        && chown -R apache:apache ${COMANAGE_REGISTRY_DIR}/app/tmp \
        && cd /var/www/html \
        && ln -s ${COMANAGE_REGISTRY_DIR}/app/webroot registry \
        && rm -rf ${COMANAGE_REGISTRY_DIR}/local/* \
        && ln -s ${COMANAGE_REGISTRY_DIR}/local /local 

COPY 000-comanage.conf /etc/httpd/conf.d/
COPY 10-php7.conf /etc/httpd/conf.modules.d/
COPY php.conf /etc/httpd/conf.d/
COPY supervisord.conf /usr/local/etc/supervisord.conf
COPY shibd.logger /etc/shibboleth/
COPY native.logger /etc/shibboleth/
COPY httpd.conf /etc/httpd/conf/

RUN ln -sfT /dev/stdout /var/log/httpd/access_log \
    && ln -sfT /dev/stdout /var/log/httpd/error_log \
    && ln -sfT /dev/stdout /var/log/httpd/ssl_error_log \
    && ln -sfT /dev/stdout /var/log/httpd/ssl_access_log \
    && ln -sfT /dev/stdout /var/log/shibboleth-www/native.log \
    && ln -sfT /dev/stdout /var/log/shibboleth-www/native_warn.log \
    && cd /etc/httpd/conf.d \
    && rm -f autoindex.conf ssl.conf userdir.conf welcome.conf \
    && cd /etc/httpd \
    && ln -s /etc/pki/tls/certs/localhost.crt cert.pem \
    && ln -s /etc/pki/tls/private/localhost.key privkey.pem

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

EXPOSE 80 443

VOLUME ["/srv/comanage-registry/local"]

VOLUME ["/etc/shibboleth"]

COPY docker-comanage-entrypoint /usr/local/bin/
COPY docker-comanage-shibboleth-sp-entrypoint /usr/local/bin/

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/usr/local/etc/supervisord.conf"]
