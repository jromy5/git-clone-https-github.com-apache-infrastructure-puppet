#!/bin/sh
################################################################
# Licensed to the Apache Software Foundation (ASF) under one   #
# or more contributor license agreements.  See the NOTICE file #
# distributed with this work for additional information        #
# regarding copyright ownership.  The ASF licenses this file   #
# to you under the Apache License, Version 2.0 (the            #
# "License"); you may not use this file except in compliance   #
# with the License.  You may obtain a copy of the License at   #
#                                                              #
#   http://www.apache.org/licenses/LICENSE-2.0                 #
#                                                              #
# Unless required by applicable law or agreed to in writing,   #
# software distributed under the License is distributed on an  #
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY       #
# KIND, either express or implied.  See the License for the    #
# specific language governing permissions and limitations      #
# under the License.                                           #
################################################################

DATASET=$1
PATH=/bin:/sbin:/usr/bin:/usr/sbin

# This script is allegedly used on bia.

if [ -n "$DATASET" ]; then
    zfs list -r -t snapshot $DATASET \
    | perl -le '@s=sort map {(split)[0]} <>; print for @s[1..($#s - 60)]' \
    | xargs -n 1 zfs destroy
    # This sorts snapshots alphabetically, so the daily `date +%Y%m%d` snapshots
    # sort first and are those that get deleted.
    zfs snapshot $DATASET@`/usr/bin/date +%Y%m%d`
else
    echo "Usage:"
    echo "$0 ZFSDATASET"
fi

