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
# Configure console (stdout) logging
# Globals:
#   COMANAGE_REGISTRY_DIR
#   OUTPUT
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::configure_console_logging() {
    sed -ie 's/'"'"'engine'"'"' => '"'"'FileLog'"'"'/'"'"'engine'"'"' => '"'"'ConsoleLog'"'"'/' "$COMANAGE_REGISTRY_DIR/app/Config/bootstrap.php" 
}

##########################################
# Configure TIER logging
# Globals:
#   ENV
#   USERTOKEN
#   OUTPUT
# Arguments:
#   NONE
# Returns:
#   None
##########################################
function comanage_utils::configure_tier_logging() {

    comanage_utils::manage_tier_environment

    # Create pipes to use for COmanage Registry instead of standard log files.
    rm -f "$COMANAGE_REGISTRY_DIR/app/tmp/logs/error.log" > "$OUTPUT" 2>&1
    rm -f "$COMANAGE_REGISTRY_DIR/app/tmp/logs/debug.log" > "$OUTPUT" 2>&1
    mkfifo -m 666 "$COMANAGE_REGISTRY_DIR/app/tmp/logs/error.log" > "$OUTPUT" 2>&1
    mkfifo -m 666 "$COMANAGE_REGISTRY_DIR/app/tmp/logs/debug.log" > "$OUTPUT" 2>&1

    # Format any output from COmanange Registry into standard TIER form.
    (cat <> "$COMANAGE_REGISTRY_DIR/app/tmp/logs/error.log" | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "comanage_registry;error.log;%s;%s;%s\n", ENV, UT, $0; fflush()}' 1>/tmp/logpipe)&
    (cat <> "$COMANAGE_REGISTRY_DIR/app/tmp/logs/debug.log" | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "comanage_registry;debug.log;%s;%s;%s\n", ENV, UT, $0; fflush()}' 1>/tmp/logpipe)&
}

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
    
    echo "Examining environment variables..." > "$OUTPUT" 

    # Configuration details that may be injected through environment
    # variables or the contents of files.
    local injectable_config_vars

    injectable_config_vars=( 
        COMANAGE_REGISTRY_ADMIN_GIVEN_NAME
        COMANAGE_REGISTRY_ADMIN_FAMILY_NAME
        COMANAGE_REGISTRY_ADMIN_USERNAME
        COMANAGE_REGISTRY_CRONTAB
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
        COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN
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
            echo "Set ${config_var} to be contents of ${file_name}" > "$OUTPUT"
        fi
    done

    echo "Done examining environment variables" > "$OUTPUT"
}

##########################################
# Deploy crontab file
# Globals:
#   COMANAGE_REGISTRY_DIR
#   COMANAGE_REGISTRY_CRONTAB
#   OUTPUT
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::deploy_crontab() {

    local crontab
    
    if [[ -n "$COMANAGE_REGISTRY_CRONTAB" ]]; then
        crontab="$COMANAGE_REGISTRY_CRONTAB"
    else
        crontab="$COMANAGE_REGISTRY_DIR/local/crontab"
    fi

    if [[ -f "$crontab" ]]; then
        echo "Deploying crontab $crontab..." > "$OUTPUT" 2>&1
        /usr/bin/crontab -u www-data $crontab > "$OUTPUT" 2>&1
    fi
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

    comanage_utils::configure_console_logging

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
# Exec to start and become cron
# Globals:
#   None
# Arguments:
#   Command and arguments to exec
# Returns:
#   Does not return
##########################################
function comanage_utils::exec_cron() {

    comanage_utils::consume_injected_environment

    comanage_utils::configure_console_logging

    comanage_utils::prepare_local_directory

    comanage_utils::prepare_database_config

    comanage_utils::wait_database_connectivity

    comanage_utils::registry_clear_cache

    comanage_utils::tmp_ownership

    comanage_utils::deploy_crontab

    comanage_utils::start_syslogd

    exec "$@"
}

##########################################
# Manage TIER environment variables
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::manage_tier_environment() {
    
    # If ENV or USERTOKEN as injected by the deployer contain a semi-colon remove it.
    if [[ ${ENV} =~ .*";".* ]]; then
        ENV=`echo ${ENV} | tr -d ';'`
        export ENV
    fi

    if [[ ${USERTOKEN} =~ .*";".* ]]; then
        USERTOKEN=`echo ${USERTOKEN} | tr -d ';'`
        export USERTOKEN
    fi

    # If ENV or USERTOKEN as injected by the deployer contain a space remove it.
    if [[ ${ENV} =~ [[:space:]] ]]; then
        ENV=`echo ${ENV} | tr -d [:space:]`
        export ENV
    fi

    if [[ ${USERTOKEN} =~ [[:space:]] ]]; then
        USERTOKEN=`echo ${USERTOKEN} | tr -d [:space:]`
        export USERTOKEN
    fi
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
#   OUTPUT
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
        echo "Wrote new database configuration file ${database_config}" > "$OUTPUT"
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
        echo "Wrote new email configuration file ${email_config}" > "$OUTPUT"
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

    local cert_path
    local privkey_path
    local web_user

    if [[ -e '/etc/debian_version' ]]; then
        cert_path='/etc/apache2/cert.pem'
        privkey_path='/etc/apache2/privkey.pem'
        web_user='www-data'
    elif [[ -e '/etc/centos-release' ]]; then
        cert_path='/etc/httpd/cert.pem'
        privkey_path='/etc/httpd/privkey.pem'
        web_user='apache'
    fi

    # If defined use configured location of Apache HTTP Server 
    # HTTPS certificate and key files. The certificate file may also
    # include intermediate CA certificates, sorted from leaf to root.
    if [[ -n "${HTTPS_CERT_FILE}" ]]; then
        rm -f "${cert_path}"
        cp "${HTTPS_CERT_FILE}" "${cert_path}"
        chown "${web_user}" "${cert_path}"
        chmod 0644 "${cert_path}"
        echo "Copied HTTPS certificate file ${HTTPS_CERT_FILE} to ${cert_path}" > "$OUTPUT"
        echo "Set ownership of ${cert_path} to ${web_user}" > "$OUTPUT"
    fi

    if [[ -n "${HTTPS_PRIVKEY_FILE}" ]]; then
        rm -f "${privkey_path}"
        cp "${HTTPS_PRIVKEY_FILE}" "${privkey_path}"
        chown "${web_user}" "${privkey_path}"
        chmod 0600 "${privkey_path}"
        echo "Copied HTTPS private key file ${HTTPS_PRIVKEY_FILE} to ${privkey_path}" > "$OUTPUT"
        echo "Set ownership of ${privkey_path} to ${web_user}" > "$OUTPUT"
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
    local directories

    declare -a directories=("Config"
                            "Plugin"
                            "View/Pages/public"
                            "webroot/img"
                            )

    local dir
    local full_path
    for dir in "${directories[@]}"
    do
        full_path="${COMANAGE_REGISTRY_DIR}/local/${dir}"
        if [[ ! -d "${full_path}" ]]; then
            mkdir -p "${full_path}" > "$OUTPUT" 2>&1
            echo "Created directory ${full_path}"
        fi
    done
}

##########################################
# Prepare web server name
# Globals:
#   SERVER_NAME
#   COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::prepare_server_name() {
    
    # SERVER_NAME is deprecated in favor of COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN
    # and will not be supported in a future version.
    if [[ -n "$SERVER_NAME" ]]; then
        echo "SERVER_NAME is deprecated and will not be supported in a future version"
        echo "Use COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN instead of SERVER_NAME"
        if [[ -z "$COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN" ]]; then
            COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN="${SERVER_NAME}"
            echo "SERVER_NAME=${SERVER_NAME} has been injected" > "$OUTPUT"
            echo "Setting COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN=${COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN}"
        fi
    fi

    # If COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN has not been injected try to determine
    # it from the HTTPS_CERT_FILE.
    if [[ -z "$COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN" ]]; then
        COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN=$(openssl x509 -in /etc/apache2/cert.pem -text -noout | 
                      sed -n '/X509v3 Subject Alternative Name:/ {n;p}' | 
                      sed -E 's/.*DNS:(.*)\s*$/\1/')
        if [[ -n "$COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN" ]]; then
            echo "Set COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN=${COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN} using Subject Alternative Name from x509 certificate" > "$OUTPUT"
        else
            COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN=$(openssl x509 -in /etc/apache2/cert.pem -subject -noout | 
                          sed -E 's/subject=.*CN=(.*)\s*/\1/')
            if [[ -n "$COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN" ]]; then
                echo "Set COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN=${COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN} using CN from x509 certificate" > "$OUTPUT"
            fi
        fi
    fi

    # Configure Apache HTTP Server with the server name.
    # This configures the server name for the default Debian
    # Apache HTTP Server configuration but not the server name used
    # by any virtual hosts.
    if [[ -e '/etc/debian_version' ]]; then
        cat > /etc/apache2/conf-available/server-name.conf <<EOF
ServerName ${COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN:-unknown}
EOF
        a2enconf server-name.conf > "$OUTPUT" 2>&1
    fi

    # Export the server name so that it may be used by 
    # Apache HTTP Server virtual host configurations.
    export COMANAGE_REGISTRY_VIRTUAL_HOST_FQDN
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
        echo "Cleared COmanage Registry CakePHP cache files in ${cache_dir}" > "$OUTPUT"
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
    echo "Testing if COmanage Registry setup has been done previously..." > "$OUTPUT"
    ./Console/cake setupAlready > "$OUTPUT" 2>&1
    setup_already=$?

    rm -f "$setup_already_script"

    local auto_generated_security

    if [ $setup_already -eq 0 ]; then
        echo "COmanage Registry setup has not been done previously" > "$OUTPUT"
        rm -f "$COMANAGE_REGISTRY_DIR/local/Config/security.salt" > "$OUTPUT" 2>&1
        rm -f "$COMANAGE_REGISTRY_DIR/local/Config/security.seed" > "$OUTPUT" 2>&1
        echo "Running ./Console/cake database..." > "$OUTPUT"
        ./Console/cake database > "$OUTPUT" 2>&1
        echo "Running ./Console/cake setup..." > "$OUTPUT"
        ./Console/cake setup --admin-given-name "${COMANAGE_REGISTRY_ADMIN_GIVEN_NAME}" \
                             --admin-family-name "${COMANAGE_REGISTRY_ADMIN_FAMILY_NAME}" \
                             --admin-username "${COMANAGE_REGISTRY_ADMIN_USERNAME}" \
                             --enable-pooling "${COMANAGE_REGISTRY_ENABLE_POOLING}" > "$OUTPUT" 2>&1
        echo "Set admin given name ${COMANAGE_REGISTRY_ADMIN_GIVEN_NAME}" > "$OUTPUT"
        echo "Set admin family name ${COMANAGE_REGISTRY_ADMIN_FAMILY_NAME}" > "$OUTPUT"
        echo "Set admin username ${COMANAGE_REGISTRY_ADMIN_USERNAME}" > "$OUTPUT"
        echo "Set enable pooling to ${COMANAGE_REGISTRY_ENABLE_POOLING}" > "$OUTPUT"
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
    echo "Running ./Console/cake upgradeVersion..." > "$OUTPUT"
    ./Console/cake upgradeVersion > "$OUTPUT" 2>&1
    echo "Done running ./Console/cake upgradeVersion" > "$OUTPUT"
    echo "You may ignore errors reported above if the Current and Target versions are the same" > "$OUTPUT"
    popd > "$OUTPUT" 2>&1

    # Force a datbase update if requested. This is helpful when deploying
    # a new version of the code that does not result in a change in the
    # version number and so upgradeVersion does not fire. An example
    # of this scenario is when new code is introduced in the develop
    # branch but before a release happens.
    if [ -n "$COMANAGE_REGISTRY_DATABASE_SCHEMA_FORCE" ]; then
        echo "Forcing a database schema update..." > "$OUTPUT" 
        pushd "$COMANAGE_REGISTRY_DIR/app" > "$OUTPUT" 2>&1
        ./Console/cake database > "$OUTPUT" 2>&1
        echo "Done forcing database schema update" > "$OUTPUT" 
        popd > "$OUTPUT" 2>&1
    fi

    # Clear the caches again.
    comanage_utils::registry_clear_cache
}

##########################################
# Start syslogd from busybox for use with cron
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_utils::start_syslogd() {

    /sbin/syslogd -O /proc/1/fd/1 -S

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
    local tmp_dir
    local ownership

    if [[ -e '/etc/debian_version' ]]; then
        ownership='www-data:www-data'
    elif [[ -e '/etc/centos-release' ]]; then
        ownership='apache:apache'
    fi

    tmp_dir="${COMANAGE_REGISTRY_DIR}/app/tmp"

    chown -R "${ownership}" "${tmp_dir}"

    echo "Recursively set ownership of ${tmp_dir} to ${ownership}" > "$OUTPUT"

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
    echo "Testing database availability..." > "$OUTPUT"
    until ./Console/cake databaseTest > "$OUTPUT" 2>&1; do
        >&2 echo "Database is unavailable - sleeping"
        sleep 1
    done

    rm -f "$database_test_script"

    echo "Database is available" > "$OUTPUT"

    popd > "$OUTPUT" 2>&1
}
