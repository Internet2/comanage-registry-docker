#!/bin/bash

# COmanage Registry shell script to install TIER beacon crontab
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

CRONFILE='/tmp/cronfile'

# Build and install crontab file with random start time
# between midnight and 3:59am.
echo '#send daily beacon to TIER Central' > "${CRONFILE}"
echo $(expr $RANDOM % 59) $(expr $RANDOM % 3) "* * * /usr/local/bin/sendtierbeacon.sh >> /tmp/logpipe 2>&1" >> "${CRONFILE}"
chmod 644 "${CRONFILE}"
crontab "${CRONFILE}"
