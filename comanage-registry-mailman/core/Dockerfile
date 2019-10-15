# GNU Mailman 3 for COmanage Registry Dockerfile
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
FROM python:3.6-stretch


#Install all required packages, add user for executing mailman and set execution rights for startup script
RUN apt-get update \
    && apt-get install -y \
        gcc \
        libcurl4-openssl-dev \
        libmariadbclient-dev \
        libpq-dev \
        postgresql-client \
        python3-dev \
    && pip install psycopg2 \
                   mailman==3.2.2 \
                   mailman-hyperkitty==1.1.0 \
                   pymysql \
    && adduser --system mailman

COPY su-exec.c /usr/local/src/
COPY Makefile /usr/local/src/

RUN cd /usr/local/src \
    && make \
    && cp su-exec /usr/local/bin/ \
    && chmod 755 /usr/local/bin/su-exec

# Change the working directory.
WORKDIR /opt/mailman

#Add startup script to container
COPY docker-entrypoint.sh /usr/local/bin/

#Expose the ports for the api (8001) and lmtp (8024)
EXPOSE 8001 8024

ENV MAILMAN_CONFIG_FILE /etc/mailman.cfg

# Patch REST API for COmanage provisioning functionality until patches
# are accepted upstream.
COPY addresses.py /usr/local/lib/python3.6/site-packages/mailman/rest/addresses.py
COPY users.py /usr/local/lib/python3.6/site-packages/mailman/rest/users.py
RUN chmod 644 /usr/local/lib/python3.6/site-packages/mailman/rest/addresses.py /usr/local/lib/python3.6/site-packages/mailman/rest/users.py

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["master", "--force"]
