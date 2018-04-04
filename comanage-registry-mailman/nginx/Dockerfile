# Nginx for GNU Mailman 3 for COmanage Registry Dockerfile
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
    && apt-get install --no-install-recommends --no-install-suggests -y \
        netcat-traditional \
        nginx \
        nginx-extras

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

COPY nginx.conf /etc/nginx/nginx.conf
COPY start.sh /usr/local/sbin/nginx-start.sh

ENTRYPOINT ["/usr/local/sbin/nginx-start.sh"]

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
