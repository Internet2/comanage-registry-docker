#! /bin/bash

# Nginx for GNU Mailman 3 Core for COmanage Registry Dockerfile entrypoint
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

# Configuration details that may be injected through environment
# variables or the contents of files.

injectable_config_vars=( 
    MAILMAN_CORE_HOST
    MAILMAN_CORE_PORT
    MAILMAN_WEB_HOST
    MAILMAN_WEB_PORT
)

# Default values.
MAILMAN_CORE_HOST="mailman-core"
MAILMAN_CORE_PORT="8001"
MAILMAN_WEB_HOST="mailman-web"
MAILMAN_WEB_PORT="8000"

# If the file associated with a configuration variable is present then 
# read the value from it into the appropriate variable. 

for config_var in "${injectable_config_vars[@]}"
do
    eval file_name=\$"${config_var}_FILE";

    if [ -e "$file_name" ]; then
        declare "${config_var}"=`cat $file_name`
    fi
done

# Copy HTTPS certificate and key into place.
if [ -n "${HTTPS_CERT_FILE}" ] && [ -n "${HTTPS_KEY_FILE}" ]; then
    cp "${HTTPS_CERT_FILE}" /usr/local/apache2/conf/server.crt
    cp "${HTTPS_KEY_FILE}" /usr/local/apache2/conf/server.key
    chmod 644 /usr/local/apache2/conf/server.crt
    chmod 600 /usr/local/apache2/conf/server.key
fi

# Copy HTTPS chain file into place.
if [ -n "${HTTPS_CHAIN_FILE}" ]; then
    cp "${HTTPS_CHAIN_FILE}" /usr/local/apache2/conf/ca-chain.crt
    chmod 644 /usr/local/apache2/conf/ca-chain.crt
    sed -i -e 's/^#SSLCertificateChainFile/SSLCertificateChainFile' /usr/local/apache2/conf/httpd.conf
fi

# Wait for the mailman core container to be ready.
until nc -z -w 1 "${MAILMAN_CORE_HOST}" "${MAILMAN_CORE_PORT}"
do
    echo "Waiting for Mailman core container..."
    sleep 1
done

# Wait for the mailman web container to be ready.
until nc -z -w 1 "${MAILMAN_WEB_HOST}" "${MAILMAN_WEB_PORT}"
do
    echo "Waiting for Mailman web container..."
    sleep 1
done

# Start Apache HTTP Server
exec "$@"
