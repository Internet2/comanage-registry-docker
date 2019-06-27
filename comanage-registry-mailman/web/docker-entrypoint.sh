#! /bin/bash

# GNU Mailman 3 Core for COmanage Registry Dockerfile entrypoint
#
# This bash script borrows heavily from a script by Abhilash Raj for 
# GNU Mailman 3. See https://github.com/maxking/docker-mailman
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

set -e

function wait_for_postgres () {
    # Check if the postgres database is up and accepting connections before
    # moving forward.
    # TODO: Use python's psycopg2 module to do this in python instead of
    # installing postgres-client in the image.
    until psql $MAILMAN_DATABASE_URL -c '\l'; do
        >&2 echo "Postgres is unavailable - sleeping"
        sleep 1
    done
    >&2 echo "Postgres is up - continuing"
}

function wait_for_mysql () {
    # Check if MySQL is up and accepting connections.
    HOSTNAME=$(python <<EOF
try:
    from urllib.parse import urlparse
except ImportError:
    from urlparse import urlparse
o = urlparse('$MAILMAN_DATABASE_URL')
print(o.hostname)
EOF
)
    until mysqladmin ping --host "$HOSTNAME" --silent; do
        >&2 echo "MySQL is unavailable - sleeping"
        sleep 1
    done
    >&2 echo "MySQL is up - continuing"
}


function check_or_create () {
    # Check if the path exists, if not, create the directory.
    if [[ ! -e dir ]]; then
        echo "$1 does not exist, creating ..."
        mkdir "$1"
    fi
}

# Configuration details that may be injected through environment
# variables or the contents of files.

injectable_config_vars=( 
    HYPERKITTY_API_KEY
    MAILMAN_DATABASE_URL
    MAILMAN_REST_PASSWORD
    MAILMAN_WEB_SECRET_KEY
)

# If the file associated with a configuration variable is present then 
# read the value from it into the appropriate variable. 

for config_var in "${injectable_config_vars[@]}"
do
    eval file_name=\$"${config_var}_FILE";

    if [ -e "$file_name" ]; then
        declare "${config_var}"=`cat $file_name`
        export "${config_var}"=`cat $file_name`
    fi
done

# Django needs DATABASE_URL.
if [[ MAILMAN_DATABASE_URL ]]; then
    export DATABASE_URL="$MAILMAN_DATABASE_URL"
fi

# Wait for the mailman core container to be ready.
if [[ ! -v MAILMAN_CORE_HOST ]];
then
    export MAILMAN_CORE_HOST="mailman-core"
fi

if [[ ! -v MAILMAN_CORE_PORT ]];
then
    export MAILMAN_CORE_PORT=8001
fi

until nc -z -w 1 "${MAILMAN_CORE_HOST}" "${MAILMAN_CORE_PORT}"
do
    echo "Waiting for Mailman core container..."
    sleep 1
done

# Set SECRET_KEY which is required by the Django code.
if [[ -v MAILMAN_WEB_SECRET_KEY ]]; then
    export SECRET_KEY="$MAILMAN_WEB_SECRET_KEY"
fi

# Check if $SECRET_KEY is defined, if not, bail out.
if [[ ! -v SECRET_KEY ]]; then
    echo "SECRET_KEY is not defined. Aborting."
    exit 1
fi

# Check if $MAILMAN_DATABASE_URL is defined, if not, use a standard sqlite database.
#
# If the $MAILMAN_DATABASE_URL is defined and is postgres, check if it is available
# yet. Do not start the container before the postgresql boots up.
#
# If the $MAILMAN_DATABASE_URL is defined and is mysql, check if the database is
# available before the container boots up.
#
# TODO: Check the database type and detect if it is up based on that. For now,
# assume that postgres is being used if MAILMAN_DATABASE_URL is defined.

if [[ ! -v MAILMAN_DATABASE_URL ]]; then
    echo "MAILMAN_DATABASE_URL is not defined. Using sqlite database..."
    export MAILMAN_DATABASE_URL=sqlite://mailmanweb.db
    export MAILMAN_DATABASE_TYPE='sqlite'
fi

if [[ "$MAILMAN_DATABASE_TYPE" = 'postgres' ]]
then
    wait_for_postgres
elif [[ "$MAILMAN_DATABASE_TYPE" = 'mysql' ]]
then
    wait_for_mysql
fi

# Check if we are in the correct directory before running commands.
if [[ ! $(pwd) == '/opt/mailman-web' ]]; then
    echo "Running in the wrong directory...switching to /opt/mailman-web"
    cd /opt/mailman-web
fi

# Check if the logs directory is setup.
if [[ ! -e /opt/mailman-web-data/logs/mailmanweb.log ]]; then
    echo "Creating log file for mailman web"
    mkdir -p /opt/mailman-web-data/logs/
    touch /opt/mailman-web-data/logs/mailmanweb.log
fi

if [[ ! -e /opt/mailman-web-data/logs/uwsgi.log ]]; then
    echo "Creating log file for uwsgi.."
    touch /opt/mailman-web-data/logs/uwsgi.log
fi

# Check if the settings_local.py file exists, if yes, copy it too.
if [[ -e /opt/mailman-web-data/settings_local.py ]]; then
    echo "Copying settings_local.py ..."
    cp /opt/mailman-web-data/settings_local.py /opt/mailman-web/settings_local.py
    chown mailman:mailman /opt/mailman-web/settings_local.py
fi

# Collect static for the django installation.
python manage.py collectstatic --noinput

# Migrate all the data to the database if this is a new installation, otherwise
# this command will upgrade the database.
python manage.py migrate

# If MAILMAN_ADMIN_USER and MAILMAN_ADMIN_EMAIL is defined create a new
# superuser for Django. There is no password setup so it can't login yet unless
# the password is reset.
if [[ -v MAILMAN_ADMIN_USER ]] && [[ -v MAILMAN_ADMIN_EMAIL ]];
then
    echo "Creating admin user $MAILMAN_ADMIN_USER ..."
    python manage.py createsuperuser --noinput --username "$MAILMAN_ADMIN_USER"\
           --email "$MAILMAN_ADMIN_EMAIL" 2> /dev/null || \
        echo "Superuser $MAILMAN_ADMIN_USER already exists"
fi

# If SERVE_FROM_DOMAIN is defined then rename the default `example.com`
# domain to the defined domain.
if [[ -v SERVE_FROM_DOMAIN ]];
then
    echo "Setting $SERVE_FROM_DOMAIN as the default domain ..."
    python manage.py shell -c \
    "from django.contrib.sites.models import Site; Site.objects.filter(domain='example.com').update(domain='$SERVE_FROM_DOMAIN', name='$SERVE_FROM_DOMAIN')"
fi

# Create a mailman user with the specific UID and GID and do not create home
# directory for it. Also chown the logs directory to write the files.
chown mailman:mailman /opt/mailman-web-data -R

exec $@
