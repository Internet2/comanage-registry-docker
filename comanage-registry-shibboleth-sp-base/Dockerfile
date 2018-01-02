# Dockerfile for Shibboleth SP for COmanage Registry
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
FROM debian:9

RUN apt-get update \
      && apt-get install -y --no-install-recommends \
            apache2 \
            apache2-dev \
            file \
            gcc \
            g++ \
            libboost-dev \
            libcurl4-openssl-dev \
            libssl1.0-dev \
            libssl1.0.2 \
            make \
            wget \
            zlib1g-dev

ARG LOG4SHIB_URL=http://shibboleth.net/downloads/log4shib/latest/log4shib-1.0.9.tar.gz

RUN wget -O log4shib.tar.gz "${LOG4SHIB_URL}" \
      && mkdir -p src \
      && tar -zxf log4shib.tar.gz -C src --strip-components=1 \
      && rm -f log4shib.tar.gz \
      && cd src \
      && LD_FLAGS=-lpthread CXXFLAGS="-fPIC -std=gnu++98" ./configure --disable-static \
            --disable-doxygen \ 
            --prefix=/opt/shibboleth-sp \
            --build=x86_64 \
      && LD_FLAGS=-lpthread make \
      && make -j 2 install \
      && cd .. \
      && rm -r src 

ARG XERCESC_URL=http://ftp.wayne.edu/apache//xerces/c/3/sources/xerces-c-3.2.0.tar.gz

RUN wget -O xerces.tar.gz "${XERCESC_URL}" \
      && mkdir -p src \
      && tar -zxf xerces.tar.gz -C src --strip-components=1 \
      && rm -f xerces.tar.gz \
      && cd src \
      && CXXFLAGS="-std=gnu++98" ./configure --prefix=/opt/shibboleth-sp \
      && make -j 2 \
      && make install \
      && cd .. \
      && rm -r src 

ARG XMLSECC_URL=http://ftp.wayne.edu/apache/santuario/c-library/xml-security-c-1.7.3.tar.gz

RUN wget -O xmlsecc.tar.gz "${XMLSECC_URL}" \
      && mkdir -p src \
      && tar -zxf xmlsecc.tar.gz -C src --strip-components=1 \
      && rm -f xmlsecc.tar.gz \
      && cd src \
      && CXXFLAGS="-std=gnu++98" ./configure --prefix=/opt/shibboleth-sp \
            --with-xerces=/opt/shibboleth-sp \
            --with-openssl=/usr \
            --disable-static \
            --without-xalan \
      && make -j 2 \
      && make install \
      && cd .. \
      && rm -r src 

ARG XMLTOOLING_URL=http://shibboleth.net/downloads/c++-opensaml/latest/xmltooling-1.6.2.tar.gz

RUN wget -O xmltooling.tar.gz "${XMLTOOLING_URL}" \
      && mkdir -p src \
      && tar -zxf xmltooling.tar.gz -C src --strip-components=1 \
      && rm -f xmltooling.tar.gz \
      && cd src \
      && CXXFLAGS="-fPIC -std=gnu++98" ./configure --prefix=/opt/shibboleth-sp \
            --with-log4shib=/opt/shibboleth-sp \
            -C \
      && make -j 2 \
      && make install \
      && cd .. \
      && rm -r src 

ARG OPENSAMLC_URL=http://shibboleth.net/downloads/c++-opensaml/latest/opensaml-2.6.1.tar.gz

RUN wget -O opensamlc.tar.gz "${OPENSAMLC_URL}" \
      && mkdir -p src \
      && tar -zxf opensamlc.tar.gz -C src --strip-components=1 \
      && rm -f opensamlc.tar.gz \
      && cd src \
      && CXXFLAGS="-std=gnu++98" ./configure --prefix=/opt/shibboleth-sp \
            --with-log4shib=/opt/shibboleth-sp \
            -C \
      && make -j 2 \
      && make install \
      && cd .. \
      && rm -r src 

ARG SHIBBOLETH_SP_URL=http://shibboleth.net/downloads/service-provider/latest/shibboleth-sp-2.6.1.tar.gz

RUN wget -O shibboleth-sp.tar.gz "${SHIBBOLETH_SP_URL}" \
      && mkdir -p src \
      && tar -zxf shibboleth-sp.tar.gz -C src --strip-components=1 \
      && rm -f shibboleth-sp.tar.gz \
      && cd src \
      && CXXFLAGS="-std=gnu++98" ./configure --prefix=/opt/shibboleth-sp \
            --with-log4shib=/opt/shibboleth-sp \
            --with-saml=/opt/shibboleth-sp \
            --with-xerces=/opt/shibboleth-sp \
            --with-xmlsec=/opt/shibboleth-sp \
            --with-xmltooling=/opt/shibboleth-sp \
            --enable-apache-24 \
            --with-apxs24=/usr/bin/apxs \
            --disable-adfs \
            --disable-obc \
      && make -j 2 \
      && make install \
      && cd .. \
      && rm -r src 

COPY shib2.load /etc/apache2/mods-available

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

RUN apt-get update && apt-get install -y \
      && apt-get purge -y \
         apache2-dev \
         file \
         gcc \
         g++ \
         libboost-dev \
         libcurl4-openssl-dev \
         libssl-dev \
         make \
      && apt-get clean

COPY 000-site.conf /etc/apache2/sites-available/000-site.conf
COPY 000-site-behind-proxy.conf /etc/apache2/sites-available/000-site-behind-proxy.conf

RUN a2enmod headers \
      && a2enmod ssl \
      && a2enmod rewrite \
      && a2dissite 000-default.conf \
      && a2ensite 000-site.conf \
      && a2disconf other-vhosts-access-log \
      && cd /etc/apache2 \
      && ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem cert.pem \
      && ln -s /etc/ssl/private/ssl-cert-snakeoil.key privkey.pem

COPY shibboleth2.xml.template /etc/shibboleth/shibboleth2.xml.template
COPY supervisord.conf /usr/local/etc/supervisord.conf

COPY docker-apache-entrypoint /usr/local/bin/
COPY docker-shibd-entrypoint /usr/local/bin/
COPY apache2-foreground /usr/local/bin/

WORKDIR /var/www

EXPOSE 80 443

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/usr/local/etc/supervisord.conf"]
