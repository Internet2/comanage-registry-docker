#!/bin/bash

# COmanage Regsitry script to send TIER beacon
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

LOGHOST="collector.testbed.tier.internet2.edu"
LOGPORT="5001"

messagefile="/tmp/beaconmsg"

if [ -z "$TIER_BEACON_OPT_OUT" ]; then
    cat > $messagefile <<EOF
{
    "msgType"          : "TIERBEACON",
    "msgName"          : "TIER",
    "msgVersion"       : "1.0",
    "tbProduct"        : "COmanage Registry",
    "tbProductVersion" : "$COMANAGE_REGISTRY_VERSION",
    "tbTIERRelease"    : "$TIER_RELEASE",
    "tbMaintainer"     : "$TIER_MAINTAINER"
}
EOF

    curl -s -XPOST "${LOGHOST}:${LOGPORT}/" -H 'Content-Type: application/json' -T $messagefile 1>/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "tier_beacon;none;$ENV;$USERTOKEN;"`date`"; TIER beacon sent"
    else
        echo "tier_beacon;none;$ENV;$USERTOKEN;"`date`"; Failed to send TIER beacon"
    fi

    rm -f $messagefile 1>/dev/null 2>&1
  
fi
