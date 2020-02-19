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

ARG PHP_VERSION=7.3.13
ARG PHP_SRC_URL=https://github.com/php/php-src/archive/php-${PHP_VERSION}.tar.gz

RUN yum -y install epel-release \
        && yum clean all

RUN yum -y update \
        && yum -y install \
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
            wget \
        && yum clean all

WORKDIR /usr/local/src

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

RUN rm -rf php-src \
    && yum -y remove \
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
            wget \
    && yum clean all
