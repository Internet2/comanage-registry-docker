# slapd base Dockerfile for use with COmanage Registry
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
FROM debian:jessie

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        ldap-utils \
        slapd \
    && cp -a /var/lib/ldap /var/lib/ldap.dist \
    && cp -a /etc/ldap/slapd.d /etc/ldap/slapd.d.dist \
    && apt-get clean 

ARG OLC_SUFFIX
ARG OLC_ROOT_DN
ARG OLC_ROOT_PW

ENV OLC_SUFFIX ${OLC_SUFFIX:-dc=my,dc=org}
ENV OLC_ROOT_DN ${OLC_ROOT_DN:-cn=admin,dc=my,dc=org}
ENV OLC_ROOT_PW ${OLC_ROOT_PW:-password}

RUN mkdir /schema \
    && mkdir -p /ldif/admin/first \
    && mkdir -p /ldif/config/first

COPY edumember.ldif /etc/ldap/schema/
COPY eduperson.ldif /etc/ldap/schema/
COPY openssh-lpk.ldif /etc/ldap/schema/
COPY voperson.ldif /etc/ldap/schema/

VOLUME [ "/var/lib/ldap", "/etc/ldap/slapd.d" ]

COPY comanage_ldap_utils.sh /usr/local/lib/

EXPOSE 389

CMD ["slapd", "-d", "256", "-h", "ldapi:/// ldap://127.0.0.1", "-u", "openldap", "-g", "openldap"]
