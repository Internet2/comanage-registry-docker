#!/bin/bash

# COmanage Registry bash shell utilities
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

if [ -n "$COMANAGE_DEBUG" ]
then
    OUTPUT=/dev/stdout
else
    OUTPUT=/dev/null
fi

##########################################
# Consume injected environment variables
# Globals:
#   See function
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::consume_injected_environment() {

    # Configuration details that may be injected through environment
    # variables or the contents of files.
    local injectable_config_vars

    injectable_config_vars=( 
        COMANAGE_REGISTRY_DATASOURCE
        COMANAGE_REGISTRY_DATABASE
        COMANAGE_REGISTRY_DATABASE_HOST
        COMANAGE_REGISTRY_DATABASE_USER
        COMANAGE_REGISTRY_DATABASE_USER_PASSWORD
        COMANAGE_REGISTRY_EMAIL_FROM
        COMANAGE_REGISTRY_EMAIL_TRANSPORT
        COMANAGE_REGISTRY_EMAIL_HOST
        COMANAGE_REGISTRY_EMAIL_PORT
        COMANAGE_REGISTRY_EMAIL_ACCOUNT
        COMANAGE_REGISTRY_EMAIL_ACCOUNT_PASSWORD
        COMANAGE_REGISTRY_SECURITY_SALT
        COMANAGE_REGISTRY_SECURITY_SEED
        HTTPS_CERT_FILE
        HTTPS_PRIVKEY_FILE
        SERVER_NAME
    )

    # If the file associated with a configuration variable is present then 
    # read the value from it into the appropriate variable. So for example
    # if the variable COMANAGE_REGISTRY_DATASOURCE_FILE exists and its
    # value points to a file on the file system then read the contents
    # of that file into the variable COMANAGE_REGISTRY_DATASOURCE.

    local config_var
    for config_var in "${injectable_config_vars[@]}"
    do
        local file_name
        eval file_name=\$"${config_var}_FILE";

        if [[ -e "$file_name" ]]; then
            declare -g "${config_var}"=`cat $file_name`
        fi
    done
}

##########################################
# Enable non-core plugins
# Globals:
#   COMANAGE_REGISTRY_DIR
#   COMANAGE_REGISTRY_ENABLE_PLUGIN
#   OUTPUT
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::enable_plugins() {

    # Enable any supported non-core plugins if requested.
    if [[ -n "$COMANAGE_REGISTRY_ENABLE_PLUGIN" ]]; then
        local plugins
        local plugin
        plugins=(`echo "$COMANAGE_REGISTRY_ENABLE_PLUGIN" | sed -e 's@,@ @g'`) > "$OUTPUT" 2>&1
        for plugin in "${plugins[@]}"; 
        do 
            echo "Enabling available plugin $plugin..." > "$OUTPUT" 2>&1
            pushd "$COMANAGE_REGISTRY_DIR/local/Plugin" > "$OUTPUT" 2>&1
            ln -s "../../app/AvailablePlugin/$plugin" "$plugin" > "$OUTPUT" 2>&1
            popd > "$OUTPUT" 2>&1
            pushd "$COMANAGE_REGISTRY_DIR/app" > "$OUTPUT" 2>&1
            ./Console/cake database > "$OUTPUT" 2>&1
            popd > "$OUTPUT" 2>&1
        done

        # Clear the caches.
        comanage_utils::registry_clear_cache
    fi
}

##########################################
# Exec to start and become Apache HTTP Server
# Globals:
#   None
# Arguments:
#   Command and arguments to exec
# Returns:
#   Does not return
##########################################
function comanage_utils::exec_apache_http_server() {

    comanage_utils::consume_injected_environment

    comanage_utils::prepare_local_directory

    comanage_utils::prepare_database_config

    comanage_utils::prepare_email_config

    comanage_utils::prepare_https_cert_key

    comanage_utils::prepare_server_name

    comanage_utils::wait_database_connectivity

    comanage_utils::registry_setup

    comanage_utils::registry_upgrade

    comanage_utils::enable_plugins

    comanage_utils::registry_clear_cache

    comanage_utils::tmp_ownership

    # first arg is `-f` or `--some-option`
    if [ "${1#-}" != "$1" ]; then
        set -- apache2-foreground "$@"
    fi

    exec "$@"
}

##########################################
# Prepare database configuration
# Globals:
#   COMANAGE_REGISTRY_DATABASE
#   COMANAGE_REGISTRY_DATABASE_HOST
#   COMANAGE_REGISTRY_DATABASE_USER
#   COMANAGE_REGISTRY_DATABASE_USER_PASSWORD
#   COMANAGE_REGISTRY_DATASOURCE
#   COMANAGE_REGISTRY_DIR
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::prepare_database_config() {

    # If the COmanage Registry database configuration file does not exist
    # then try to create it from injected information with reasonable defaults
    # that aid simple evaluation deployments.
    local database_config
    database_config="$COMANAGE_REGISTRY_DIR/local/Config/database.php"

    if [[ ! -e "$database_config" ]]; then
        cat > "$database_config" <<EOF
<?php

class DATABASE_CONFIG {

  public \$default = array(
    'datasource' => '${COMANAGE_REGISTRY_DATASOURCE:-Database/Postgres}',
    'persistent' => false,
    'host' => '${COMANAGE_REGISTRY_DATABASE_HOST:-comanage-registry-database}',
    'login' => '${COMANAGE_REGISTRY_DATABASE_USER:-registry_user}',
    'password' => '${COMANAGE_REGISTRY_DATABASE_USER_PASSWORD:-password}',
    'database' => '${COMANAGE_REGISTRY_DATABASE:-registry}',
    'prefix' => 'cm_',
  );

}
EOF
    fi
}

##########################################
# Prepare email configuration
# Globals:
#   COMANAGE_REGISTRY_EMAIL_ACCOUNT
#   COMANAGE_REGISTRY_EMAIL_ACCOUNT_PASSWORD
#   COMANAGE_REGISTRY_EMAIL_FROM
#   COMANAGE_REGISTRY_EMAIL_HOST
#   COMANAGE_REGISTRY_EMAIL_PORT
#   COMANAGE_REGISTRY_EMAIL_TRANSPORT
#   COMANAGE_REGISTRY_DIR
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::prepare_email_config() {

    # If the COmanage Registry email configuration file does not exist
    # then try to create it from injected information with reasonable defaults
    # that aid simple evaluation deployments.
    local email_config
    email_config="$COMANAGE_REGISTRY_DIR/local/Config/email.php"

    if [ ! -e "$email_config" ]; then
        cat > "$email_config" <<EOF
<?php

class EmailConfig {

  public \$default = array(
    'from' => ${COMANAGE_REGISTRY_EMAIL_FROM:-array('account@gmail.com' => 'Registry')},
    'transport' => '${COMANAGE_REGISTRY_EMAIL_TRANSPORT:-Smtp}',
    'host' => '${COMANAGE_REGISTRY_EMAIL_HOST:-tls://smtp.gmail.com}',
    'port' => ${COMANAGE_REGISTRY_EMAIL_PORT:-465},
    'username' => '${COMANAGE_REGISTRY_EMAIL_ACCOUNT:-account@gmail.com}',
    'password' => '${COMANAGE_REGISTRY_EMAIL_ACCOUNT_PASSWORD:-password}'
  );
}
EOF
    fi
}

##########################################
# Prepare cert and key for HTTPS
# Globals:
#   HTTPS_CERT_FILE
#   HTTPS_PRIVKEY_FILE
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::prepare_https_cert_key() {

    # If defined use configured location of Apache HTTP Server 
    # HTTPS certificate and key files. The certificate file may also
    # include intermediate CA certificates, sorted from leaf to root.
    if [[ -n "$HTTPS_CERT_FILE" ]]; then
        rm -f /etc/apache2/cert.pem
        cp "$HTTPS_CERT_FILE" /etc/apache2/cert.pem
        chown www-data /etc/apache2/cert.pem
        chmod 0644 /etc/apache2/cert.pem
    fi

    if [[ -n "$HTTPS_PRIVKEY_FILE" ]]; then
        rm -f /etc/apache2/privkey.pem
        cp "$HTTPS_PRIVKEY_FILE" /etc/apache2/privkey.pem
        chown www-data /etc/apache2/privkey.pem
        chmod 0600 /etc/apache2/privkey.pem
    fi
}

##########################################
# Prepare local directory structure
# Globals:
#   COMANAGE_REGISTRY_DIR
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::prepare_local_directory() {

    # Make sure the directory structure we need is available
    # in the data volume for $COMANAGE_REGISTRY_DIR/local
    mkdir -p "$COMANAGE_REGISTRY_DIR/local/Config"
    mkdir -p "$COMANAGE_REGISTRY_DIR/local/Plugin"
    mkdir -p "$COMANAGE_REGISTRY_DIR/local/View/Pages/public"
    mkdir -p "$COMANAGE_REGISTRY_DIR/local/webroot/img"
}

##########################################
# Prepare web server name
# Globals:
#   SERVER_NAME
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::prepare_server_name() {

    # If SERVER_NAME has not been injected try to determine
    # it from the HTTPS_CERT_FILE.
    if [[ -z "$SERVER_NAME" ]]; then
        SERVER_NAME=$(openssl x509 -in /etc/apache2/cert.pem -text -noout | 
                      sed -n '/X509v3 Subject Alternative Name:/ {n;p}' | 
                      sed -E 's/.*DNS:(.*)\s*$/\1/')
        if [[ -z "$SERVER_NAME" ]]; then
            SERVER_NAME=$(openssl x509 -in /etc/apache2/cert.pem -subject -noout | 
                          sed -E 's/subject=.*CN=(.*)\s*/\1/')
        fi
    fi

    # Configure Apache HTTP Server with the server name.
    # This configures the server name for the default Debian
    # Apache HTTP Server configuration but not the server name used
    # by any virtual hosts.
    sed -i -e s@%%SERVER_NAME%%@"${SERVER_NAME:-unknown}"@g /etc/apache2/sites-available/000-comanage.conf

    cat > /etc/apache2/conf-available/server-name.conf <<EOF
ServerName ${SERVER_NAME:-unknown}
EOF

    a2enconf server-name.conf > "$OUTPUT" 2>&1

    # Export the server name so that it may be used by 
    # virtual host configurations.
    export SERVER_NAME
}

##########################################
# Clear CakePHP cache files
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::registry_clear_cache() {

    local cache_dir
    cache_dir="$COMANAGE_REGISTRY_DIR/app/tmp/cache"
    
    if [[ -d $cache_dir ]]; then
        find $cache_dir -type f -exec rm -f {} \;
    fi

}

##########################################
# Run COmanage Registry setup shell command
# Globals:
#   COMANAGE_REGISTRY_ADMIN_GIVEN_NAME
#   COMANAGE_REGISTRY_ADMIN_FAMILY_NAME
#   COMANAGE_REGISTRY_ADMIN_USERNAME
#   COMANAGE_REGISTRY_DIR
#   COMANAGE_REGISTRY_ENABLE_POOLING
#   COMANAGE_REGISTRY_SECURITY_SALT
#   COMANAGE_REGISTRY_SECURITY_SEED
#   OUTPUT
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::registry_setup() {

    # We only want to run the setup script once since it creates
    # state in the database. Until COmanage Registry has a better
    # mechanism for telling us if setup has already been run
    # we create an ephemeral CakePHP script to tell us.
    local setup_already_script
    setup_already_script="$COMANAGE_REGISTRY_DIR/app/Console/Command/SetupAlreadyShell.php"

    cat > $setup_already_script <<"EOF"
<?php

class SetupAlreadyShell extends AppShell {
  var $uses = array('Co');

  function main() {
    $args = array();
    $args['conditions']['Co.name'] = 'COmanage';
    $args['contain'] = false;

    try {
      $co = $this->Co->find('first', $args);
    } catch (CakeException $e) {
      $this->out('Not setup already');
    }

    if(empty($co)) {
      $this->out('Not setup already');
    } else {
      $this->error('Setup already');
    }
  }
}
EOF

    local setup_already
    pushd "$COMANAGE_REGISTRY_DIR/app" > "$OUTPUT" 2>&1
    ./Console/cake setupAlready > "$OUTPUT" 2>&1
    setup_already=$?

    rm -f "$setup_already_script"

    local auto_generated_security

    if [ $setup_already -eq 0 ]; then
        rm -f "$COMANAGE_REGISTRY_DIR/local/Config/security.salt" > "$OUTPUT" 2>&1
        rm -f "$COMANAGE_REGISTRY_DIR/local/Config/security.seed" > "$OUTPUT" 2>&1
        # Run database twice until issue on develop branch is resolved. Since
        # the command is idempotent normally it is not a problem to have it run
        # more than once.
        ./Console/cake database > "$OUTPUT" 2>&1 && \
        ./Console/cake database > "$OUTPUT" 2>&1 && \
        ./Console/cake setup --admin-given-name "${COMANAGE_REGISTRY_ADMIN_GIVEN_NAME}" \
                             --admin-family-name "${COMANAGE_REGISTRY_ADMIN_FAMILY_NAME}" \
                             --admin-username "${COMANAGE_REGISTRY_ADMIN_USERNAME}" \
                             --enable-pooling "${COMANAGE_REGISTRY_ENABLE_POOLING}" > "$OUTPUT" 2>&1
        auto_generated_security=1
    fi

    popd > "$OUTPUT" 2>&1

    # If COmanage Registry CakePHP security salt and seed have been
    # injected and the files do not otherwise exist create them.
    if [[ -n "$COMANAGE_REGISTRY_SECURITY_SALT" && ( -n "$auto_generated_security" || ! -e "$COMANAGE_REGISTRY_DIR/local/Config/security.salt" ) ]]; then
        echo "$COMANAGE_REGISTRY_SECURITY_SALT" > "$COMANAGE_REGISTRY_DIR/local/Config/security.salt"
    fi

    if [[ -n "$COMANAGE_REGISTRY_SECURITY_SEED" && ( -n "$auto_generated_security" || ! -e "$COMANAGE_REGISTRY_DIR/local/Config/security.seed" ) ]]; then
        echo "$COMANAGE_REGISTRY_SECURITY_SEED" > "$COMANAGE_REGISTRY_DIR/local/Config/security.seed"
    fi
}

##########################################
# Run COmanage Registry upgradeVersion shell command
# Globals:
#   COMANAGE_REGISTRY_DATABASE_SCHEMA_FORCE
#   COMANAGE_REGISTRY_DIR
#   OUTPUT
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::registry_upgrade() {

    # We always run upgradeVersion since it will not make any changes
    # if the current and target versions are the same or if
    # an upgrade from the current to the target version is not allowed.

    # First clear the caches.
    comanage_utils::registry_clear_cache

    pushd "$COMANAGE_REGISTRY_DIR/app" > "$OUTPUT" 2>&1
    ./Console/cake upgradeVersion > "$OUTPUT" 2>&1
    popd > "$OUTPUT" 2>&1

    # Force a datbase update if requested. This is helpful when deploying
    # a new version of the code that does not result in a change in the
    # version number and so upgradeVersion does not fire. An example
    # of this scenario is when new code is introduced in the develop
    # branch but before a release happens.
    if [ -n "$COMANAGE_REGISTRY_DATABASE_SCHEMA_FORCE" ]; then
        echo "Forcing a database schema update..." > "$OUTPUT" 2>&1
        pushd "$COMANAGE_REGISTRY_DIR/app" > "$OUTPUT" 2>&1
        ./Console/cake database > "$OUTPUT" 2>&1
        popd > "$OUTPUT" 2>&1
    fi

    # Clear the caches again.
    comanage_utils::registry_clear_cache
}

##########################################
# Set tmp directory file ownership
# Globals:
#   COMANAGE_REGISTRY_DIR
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::tmp_ownership() {

    # Ensure that the web server user owns the tmp directory
    # and all children.
    chown -R www-data:www-data "$COMANAGE_REGISTRY_DIR/app/tmp"

}

##########################################
# Wait until able to connect to database
# Globals:
#   COMANAGE_REGISTRY_DIR
#   OUTPUT
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::wait_database_connectivity() {

    # Create a CakePHP shell to test database connectivity.
    local database_test_script
    database_test_script="$COMANAGE_REGISTRY_DIR/app/Console/Command/DatabaseTestShell.php"

    cat > $database_test_script <<"EOF"
<?php

App::import('Model', 'ConnectionManager');

class DatabaseTestShell extends AppShell {
  function main() {
    try {
      $db = ConnectionManager::getDataSource('default');
    } catch (Exception $e) {
      $this->error("Unable to connect to datasource");
    }
    $this->out("Connected to datasource");
  }
}
EOF

    pushd "$COMANAGE_REGISTRY_DIR/app" > "$OUTPUT" 2>&1

    # Loop until we are able to open a connection to the database.
    until ./Console/cake databaseTest > "$OUTPUT" 2>&1; do
        >&2 echo "Database is unavailable - sleeping"
        sleep 1
    done

    rm -f "$database_test_script"

    popd > "$OUTPUT" 2>&1
}
