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

FROM python:2.7-stretch

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        libc-dev \
        libcurl4-openssl-dev \
        libmariadbclient-dev \
        netcat-traditional \
        postgresql-client \
        sassc \
    && pip install --upgrade pip \
    && pip install django-allauth==0.35.0 \  
        django-appconf==1.0.2 \    
        django-compressor==2.2 \     
        django-extensions==2.0.7 \    
        django-gravatar2==1.4.2 \   
        django-haystack==2.8.1 \   
        django-mailman3==1.1.0 \   
        django-paintstore==0.2 \     
        django-picklefield==1.0.0 \    
        django-q==0.9.4 \    
        djangorestframework==3.8.2 \
    && pip install django==1.11 \
    && pip install mailmanclient==3.1.1 \
        postorius==1.1.2 \
        hyperkitty==1.1.4 \
        django-mailman3==1.1.0 \
        whoosh \
        uwsgi \
        psycopg2 \
        dj-database-url \
        mysqlclient \
        typing \
    && adduser --system --no-create-home --group mailman

# Add needed files for uwsgi server + settings for django
COPY mailman-web /opt/mailman-web

# Overlay customized template for Postorius login
COPY login.html /usr/local/lib/python2.7/site-packages/django_mailman3/templates/account/

RUN chown -R mailman:mailman /opt/mailman-web/ \
    && chmod u+x /opt/mailman-web/manage.py

# Add startup script to container
COPY docker-entrypoint.sh /usr/local/bin/

WORKDIR /opt/mailman-web

# Expose port 8000 for http and port 8080 for uwsgi
# (see web/mailman-web/uwsgi.ini#L2-L4)
EXPOSE 8000 8080

# Use stop signal for uwsgi server
STOPSIGNAL SIGINT

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["uwsgi", "--ini", "/opt/mailman-web/uwsgi.ini"]
