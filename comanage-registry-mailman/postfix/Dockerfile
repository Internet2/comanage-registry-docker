# Postfix for Mailman 3 for COmanage Registry Dockerfile
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
FROM debian:stretch


RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postfix \
        rsyslog \
        supervisor \
        #syslog-ng \
    && apt-get clean

COPY supervisord.conf /usr/local/etc/
COPY docker-postfix-entrypoint /usr/local/bin/

RUN ln -sfT /dev/stdout /var/log/mail.log \
    && ln -sfT /dev/stdout /var/log/mail.info \
    && ln -sfT /dev/stdout /var/log/mail.warn \
    && ln -sfT /dev/stdout /var/log/mail.err

COPY main.cf /etc/postfix/main.cf
COPY master.cf /etc/postfix/master.cf

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/usr/local/etc/supervisord.conf"]
