#!/bin/bash

# LDAP bash shell utilties for COmanage Registry slapd entrypoint
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

if [[ -n "${LDAP_DEBUG}" ]]; then
    OUTPUT=/dev/stdout
    set -x
else
    OUTPUT=/dev/null
fi

##########################################
# Add a hyphen to an LDIF file to indicate multiple ldapmodify entries.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_ldap_utils::add_hyphen() {
    local file_name="$1"
    if [[ -s $file_name ]]; then
        echo "-" >> $file_name
    fi
}

##########################################
# Add additional schemas if not already defined.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_ldap_utils::add_schemas() {
    # Array of schema files to be considered.
    declare -a schema_files=()

    # Schema required by COmanage.
    local comanage_required="edumember eduperson openssh-lpk voperson"
    local schema_dir="/etc/ldap/schema"
    local schema_name
    for schema_name in ${comanage_required}; do
        schema_files+=("${schema_dir}/${schema_name}.ldif")
    done

    # Schema injected at deployment time.
    local file_name
    for file_name in /schema/*; do
        schema_files+=("${file_name}")
    done

    # Loop over all schema files.
    for file_name in "${schema_files[@]}"; do

        # Parse schema name from the LDIF file.
        schema_name=`head -n 1 "${file_name}" |
            sed 's/dn: cn=\(.\+\),cn=schema,cn=config/\1/'`

        # If schema is not already installed add it.
        if ! comanage_ldap_utils::schema_installed ${schema_name}; then
                ldapmodify -Y EXTERNAL -H ldapi:/// -a \
                    -f "${file_name}"  > "${OUTPUT}" 2>&1
        fi

    done
}

##########################################
# Bootstrap the directory.
# Globals:
#   OLC_SUFFIX
#   OLC_ROOT_DN
#   OLC_ROOT_PW
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_ldap_utils::bootstrap() {
    local suffix="${OLC_SUFFIX:-dc=my,dc=org}"
    local root_dn="${OLC_ROOT_DN:-cn=admin,dc=my,dc=org}"
    local root_pw="${OLC_ROOT_PW:-password}"

    # Parse the domain, rdn, and the value of rdn from the OLC_SUFFIX
    local domain=`echo ${suffix} | sed -e 's/dc=//g' -e 's/,/./g'`
    local rdn=`echo ${suffix} | sed -E -e 's/^([^=]+)=[^=,]+.*/\1/'`
    local rdn_value=`echo ${suffix} | sed -E -e 's/^[^=]+=([^=,]+).*/\1/'`

    # Parse the rdn and its value from the OLC_ROOT_DN
    local admin_rdn=`echo ${root_dn} | sed -E -e 's/^([^=]+)=[^=,]+.*/\1/'`
    local admin_rdn_value=`echo ${root_dn} | \
        sed -E -e 's/^[^=]+=([^=,]+).*/\1/'`
    
    # Create a temporary password and its hash that will be used to
    # bootstrap the OLC_SUFFIX. It is later replaced by the OLC_ROOT_PW hash.
    local olc_root_pw_tmp=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | \
        fold -w 32 | head -n 1`
    local olc_root_pw_tmp_hash=`/usr/sbin/slappasswd -s ${olc_root_pw_tmp}`

    # Copy over the distribution files created by Debian installation of slapd
    # so that we can start slapd.
    mkdir -p /var/lib/ldap
    cp -a /var/lib/ldap.dist/* /var/lib/ldap/
    chown -R openldap:openldap /var/lib/ldap

    mkdir -p /etc/ldap/slapd.d
    cp -a /etc/ldap/slapd.d.dist/* /etc/ldap/slapd.d/
    chown -R openldap:openldap /etc/ldap/slapd.d

    # Start slapd listening only on socket.
    comanage_ldap_utils::start_slapd_socket

    # Reconfigure slapd to look in /var/lib/ldap.dist for the default
    # directory created by the Debian slapd installation.
    cat <<EOF > /tmp/modify.ldif
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcDbDirectory
olcDbDirectory: /var/lib/ldap.dist
EOF

    ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/modify.ldif > "${OUTPUT}" 2>&1 

    rm -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    # Kill slapd and remove the directory created by the Debian installation
    # that was copied over and used to allow slapd to start initially.
    comanage_ldap_utils::stop_slapd_socket
    rm -f /var/lib/ldap/* 

    # Start slapd again listening only on socket.
    comanage_ldap_utils::start_slapd_socket

    # Load the syncprov module.
    cat <<EOF > /tmp/modify.ldif
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: syncprov
EOF

    ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    rm -f /tmp/modify.ldif > "${OUTPUT}" 2>&1
    
    # Configure the directory with the injected suffix but the temporary
    # password.
    cat <<EOF > /tmp/modify.ldif
dn: olcDatabase={2}mdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
olcDatabase: {2}mdb
olcDbDirectory: /var/lib/ldap
olcSuffix: ${suffix}
olcLastMod: TRUE
olcRootDN: ${root_dn}
olcRootPW: ${olc_root_pw_tmp_hash}
olcAccess: {0}to dn.base="${root_dn}" by sockname.regex=/var/run/slapd/
 ldapi auth by users none by * none
olcAccess: {1}to attrs=userPassword,shadowLastChange by self auth by an
 onymous auth by * none
olcAccess: {2}to * by * none
olcDbCheckpoint: 512 30
olcDbIndex: objectClass eq,pres
olcDbIndex: ou,cn,mail,surname,givenname eq,pres,sub
olcDbIndex: entryCSN eq
olcDbIndex: entryUUID eq
olcDbMaxSize: 1073741824
EOF

    ldapmodify -Y EXTERNAL -H ldapi:/// -a \
        -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    rm -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    # Configure slapd to use a better password hash.
    cat <<EOF > /tmp/modify.ldif
dn: cn=config
changetype: modify
add: olcPasswordCryptSaltFormat
olcPasswordCryptSaltFormat: \$6\$rounds=5000$%.86s
-
add: olcPasswordHash
olcPasswordHash: {CRYPT}
EOF

    ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    rm -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    # Create the actual contents of the directory and the admin DN
    # with the injected password hash.
    cat <<EOF > /tmp/modify.ldif
dn: ${suffix}
objectClass: dcObject
objectClass: organization
o: ${domain}
${rdn}: ${rdn_value}

dn: ${root_dn}
objectClass: simpleSecurityObject
objectClass: organizationalRole
${admin_rdn}: ${admin_rdn_value}
description: LDAP administrator
userPassword: ${root_pw}
EOF

    ldapmodify -x -D ${root_dn} -w ${olc_root_pw_tmp} -H ldapi:/// -a \
        -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    rm -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    # Remove the temporary root password from the directory configuration.
    cat <<EOF > /tmp/modify.ldif
dn: olcDatabase={2}mdb,cn=config
changetype: modify
delete: olcRootPW
EOF

    ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    rm -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    # Add the syncprov overlay.
    cat <<EOF > /tmp/modify.ldif
dn: olcOverlay=syncprov,olcDatabase={2}mdb,cn=config
changetype: add
objectClass: olcSyncProvConfig
olcOverlay: syncprov
olcSpCheckpoint: 10 1
EOF

    ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    rm -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    # Stop slapd.
    comanage_ldap_utils::stop_slapd_socket
}

##########################################
# Bootstrap the proxy.
# Globals:
#   OLC_SUFFIX
#   OLC_ROOT_DN
#   OLC_ROOT_PW
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_ldap_utils::bootstrap_proxy() {
    local olc_root_pw_tmp=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | 
        fold -w 32 | head -n 1`
    local olc_root_pw_tmp_hash=`/usr/sbin/slappasswd -s ${olc_root_pw_tmp}`

    # Start slapd listening only on socket.
    comanage_ldap_utils::start_slapd_socket

    # Set the olcRootPW for the default mdb database to a random
    cat <<EOF > /tmp/modify.ldif
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: ${olc_root_pw_tmp_hash}
-
replace: olcAccess
olcAccess: {0}to * by * none
EOF

    ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    rm -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    # Load the back_ldap module.
    cat <<EOF > /tmp/modify.ldif
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: back_ldap
EOF

    ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    rm -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    # Enable the ldap backend.
cat <<EOF > /tmp/modify.ldif
dn: olcBackend={1}ldap,cn=config
objectClass: olcBackendConfig
olcBackend: ldap
EOF

    ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/modify.ldif > "${OUTPUT}" 2>&1

    rm -f /tmp/modify.ldif > "${OUTPUT}" 2>&1
    
    # Stop slapd.
    comanage_ldap_utils::stop_slapd_socket
}

##########################################
# Configure TLS if necessary files exist.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_ldap_utils::configure_tls() {
    if [[ -f /etc/ldap/slapd.crt && -f /etc/ldap/slapd.key ]]; then
        local ldif=/tmp/add.ldif
        touch $ldif

        if ! comanage_ldap_utils::tls_attribute_exists \
            olcTLSCertificateFile; then
            cat <<EOF >> $ldif
add: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/slapd.crt
EOF
        fi

        if ! comanage_ldap_utils::tls_attribute_exists \
            olcTLSCertificateKeyFile; then
            comanage_ldap_utils::add_hyphen $ldif
            cat <<EOF >> $ldif
add: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ldap/slapd.key
EOF
        fi

        if ! comanage_ldap_utils::tls_attribute_exists \
            olcTLSCipherSuite; then
            comanage_ldap_utils::add_hyphen $ldif
            cat <<EOF >> $ldif
add: olcTLSCipherSuite
olcTLSCipherSuite: SECURE256
EOF
        fi

        if ! comanage_ldap_utils::tls_attribute_exists olcTLSProtocolMin; then
            comanage_ldap_utils::add_hyphen $ldif
            cat <<EOF >> $ldif
add: olcTLSProtocolMin
olcTLSProtocolMin: 3.2
EOF
        fi

        if [[ -f /etc/ldap/slapd.ca.crt ]]; then
            if ! comanage_ldap_utils::tls_attribute_exists \
                olcTLSCACertificateFile; then
                comanage_ldap_utils::add_hyphen $ldif
                cat <<EOF >> $ldif
add: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ldap/slapd.ca.crt
EOF
            fi
        fi

        if [[ -s $ldif ]]; then
            cat <<EOF > /tmp/modify.ldif
dn: cn=config
changetype: modify
EOF
            cat $ldif >> /tmp/modify.ldif
            ldapmodify -Y EXTERNAL -H ldapi:/// -c \
                -f /tmp/modify.ldif > "${OUTPUT}" 2>&1
            rm -f /tmp/modify.ldif > "${OUTPUT}" 2>&1
            rm -f $ldif > "${OUTPUT}" 2>&1

        fi
    fi
}

##########################################
# Copy certificate and secret files.
# Globals:
#   SLAPD_CERT_FILE
#   SLAPD_PRIVKEY_FILE
#   SLAPD_CHAIN_FILE
#   OLC_ROOT_DN_PASSWORD
#   OLC_ROOT_DN_PASSWORD_FILE
#   OLC_ROOT_PW_FILE
#   OLC_ROOT_PW
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_ldap_utils::copy_cert_and_secrets() {
    if [[ -f "${SLAPD_CERT_FILE}" ]]; then
        cp ${SLAPD_CERT_FILE} /etc/ldap/slapd.crt
    fi

    if [[ -f "${SLAPD_PRIVKEY_FILE}" ]]; then
        cp ${SLAPD_PRIVKEY_FILE} /etc/ldap/slapd.key
    fi

    if [[ -f "${SLAPD_CHAIN_FILE}" ]]; then
        cp ${SLAPD_CHAIN_FILE} /etc/ldap/slapd.ca.crt
    fi

    if [[ -f "${OLC_ROOT_PW_FILE}" ]]; then
        OLC_ROOT_PW=`cat ${OLC_ROOT_PW_FILE}`
    fi

    if [[ -f "${OLC_ROOT_DN_PASSWORD_FILE}" ]]; then
        OLC_ROOT_DN_PASSWORD=`cat ${OLC_ROOT_DN_PASSWORD_FILE}`
    fi
}

##########################################
# Exec this script to become slapd
# Globals:
#   LDAP_BOOTSTRAP
# Arguments:
#   Command and arguments to exec
# Returns:
#   Does not return
##########################################
function comanage_ldap_utils::exec_slapd() {
    comanage_ldap_utils::copy_cert_and_secrets

    # Only bootstrap the directory if it does not already exist.
    if [[ ! -f /var/lib/ldap/data.mdb && \
        ! -f /etc/ldap/slapd.d/cn=config.ldif ]]; then
        # Set flag that we are bootstrapping the directory.
        LDAP_BOOTSTRAP=1
        comanage_ldap_utils::bootstrap
    fi

    # Start slapd listening only on UNIX socket.
    comanage_ldap_utils::start_slapd_socket

    # Add extra schemas not included with Debian OpenLDAP.
    comanage_ldap_utils::add_schemas

    # Configure TLS.
    comanage_ldap_utils::configure_tls

    # Process input LDIF.
    comanage_ldap_utils::process_ldif

    # Stop slapd listening on UNIX socket.
    comanage_ldap_utils::stop_slapd_socket

    # Always set user and group in case external source of user and
    # group mappings to numeric UID and GID is being used, such as
    # COPY in of /etc/passwd.
    chown -R openldap:openldap /var/lib/ldap
    chown -R openldap:openldap /etc/ldap/slapd.d

    exec "$@"
}

##########################################
# Exec this script to become slapd proxy
# Globals:
#   None
# Arguments:
#   Command and arguments to exec
# Returns:
#   Does not return
##########################################
function comanage_ldap_utils::exec_slapd_proxy() {
    comanage_ldap_utils::copy_cert_and_secrets

    # Set flag that we are bootstrapping the directory. The proxy deployment
    # using ldap backend saves no state so every boot is a bootstrap.
    LDAP_BOOTSTRAP=1

    # Bootstrap the directory.
    comanage_ldap_utils::bootstrap_proxy

    # Start slapd listening only on UNIX socket.
    comanage_ldap_utils::start_slapd_socket

    # Add extra schemas not included with Debian OpenLDAP.
    comanage_ldap_utils::add_schemas

    # Configure TLS.
    comanage_ldap_utils::configure_tls

    # Process input LDIF.
    comanage_ldap_utils::process_ldif

    # Stop slapd listening on UNIX socket.
    comanage_ldap_utils::stop_slapd_socket

    # Always set user and group in case external source of user and
    # group mappings to numeric UID and GID is being used, such as
    # COPY in of /etc/passwd.
    chown -R openldap:openldap /var/lib/ldap
    chown -R openldap:openldap /etc/ldap/slapd.d

    exec "$@"
}

##########################################
# Loop ldapmodify over a set of LDIF files with environment variable 
# substitutions.
#
# Globals:
#   OLC_ROOT_DN
#   OLC_ROOT_DN_PASSWORD
# Arguments:
#   Set of LDIF files
#   String "admin" or "config"
# Returns:
#   None
##########################################
function comanage_ldap_utils::loop_ldapmodify() {
    local auth
    local ldif
    local newldif
    local replacement
    local substitutions

    if [[ "$1" == "config" ]]; then
        auth="-Y EXTERNAL"
    elif [[ "$1" == "admin" && -n "${OLC_ROOT_DN}" && \
        -n "${OLC_ROOT_DN_PASSWORD}" ]]; then
        auth="-D ${OLC_ROOT_DN} -x -w ${OLC_ROOT_DN_PASSWORD}"
    else
        return 0
    fi

    shift 1

    for ldif in "$@"; do
        [[ -f "${ldif}" ]] || continue

        # Copy LDIF file to temporary copy.
        newldif="/tmp/${ldif##*/}"
        cp "${ldif}" "${newldif}"

        # Find any substitutions that need to be made.
        substitutions=( `grep -oE '%%.+%%' "${newldif}" | tr -d %` )

        # Loop over the substitutions and use sed in place to make the
        # substitutions.
        for s in "${substitutions[@]}"; do
            # If the substitution ends in _FILE then use the text from
            # the file pointed to by that environment variable. Otherwise
            # use the text from the environment variable itself.
            if [[ ! "${s%_FILE}" == "${s}" ]]; then
                replacement=`cat "${!s}"`
            else
                replacement=${!s}
            fi

            sed -i s@%%"${s}"%%@"${replacement}"@g "${newldif}"
        done

        ldapmodify -c ${auth} -H ldapi:/// -f "${newldif}" > "${OUTPUT}" 2>&1

        rm -f "${newldif}" > "${OUTPUT}" 2>&1
    done
}

##########################################
# Process LDIF.
# Globals:
#   LDAP_BOOTSTRAP
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_ldap_utils::process_ldif() {
    local ldif_files
    local ldif

    # Only process files in ../first during bootstrap.
    if [[ -n "${LDAP_BOOTSTRAP}" ]]; then
        ldif_files=/ldif/config/first/*.ldif
        comanage_ldap_utils::loop_ldapmodify "config" ${ldif_files}

        ldif_files=/ldif/admin/first/*.ldif
        comanage_ldap_utils::loop_ldapmodify "admin" ${ldif_files}
    fi

    # Process files at each startup.
    ldif_files=/ldif/config/*.ldif
    comanage_ldap_utils::loop_ldapmodify "config" ${ldif_files}

    ldif_files=/ldif/admin/*.ldif
    comanage_ldap_utils::loop_ldapmodify "admin" ${ldif_files}
}

##########################################
# Determine if TLS attribute already exists.
# Globals:
#   None
# Arguments:
#   TLS attribute name
# Returns:
#   None
##########################################
function comanage_ldap_utils::tls_attribute_exists() {
    local attribute="$1"
    ldapsearch -LLL -Y EXTERNAL -H ldapi:/// \
        -b cn=config -s base $attribute 2>"${OUTPUT}" \
        | grep $attribute > "${OUTPUT}" 2>&1
}

##########################################
# Determine if a schema is installed.
# Globals:
#   None
# Arguments:
#   schema name
# Returns:
#   None
##########################################
function comanage_ldap_utils::schema_installed() {
    local schema_name="$1"
    local filter="(&(cn={*}$schema_name)(objectClass=olcSchemaConfig))"

    ldapsearch -LLL -Y EXTERNAL -H ldapi:/// \
        -b cn=schema,cn=config $filter dn 2>"${OUTPUT}" \
        | grep $schema_name > "${OUTPUT}" 2>&1
}

##########################################
# Start slapd listening only on UNIX socket.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_ldap_utils::start_slapd_socket() {
    slapd -h ldapi:/// -u openldap -g openldap > "${OUTPUT}" 2>&1
}

##########################################
# Stop slapd.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
##########################################
function comanage_ldap_utils::stop_slapd_socket() {
    kill -INT `cat /var/run/slapd/slapd.pid`
    sleep 1
}
