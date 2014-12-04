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
DAY=`/bin/date +%d`

if [ -n "$DATASET" ]; then
    # loop over existing snapshots for this day in the last month and destroy them
    for SNAP in `/sbin/zfs list -t snapshot -Ho name | grep "$DATASET@[0-9]\{6\}$DAY"`; do 
        /usr/local/bin/sudo /sbin/zfs destroy -r $SNAP
    done

    # Note: if you change this, see the comment in /root/bin/delete_snapshots.sh
    /usr/local/bin/sudo /sbin/zfs snapshot -r $DATASET@`/bin/date +%Y%m%d`
else
    echo "Usage:"
    echo "$0 ZFS_DATASET"
fi
