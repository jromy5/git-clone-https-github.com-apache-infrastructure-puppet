#!/bin/sh
############################################################################
# Licensed to the Apache Software Foundation (ASF) under one or more       #
# contributor license agreements.  See the NOTICE file distributed with    #
# this work for additional information regarding copyright ownership.      #
# The ASF licenses this file to you under the Apache License, Version 2.0  #
# (the "License"); you may not use this file except in compliance with     #
# the License.  You may obtain a copy of the License at                    #
#                                                                          #
#     http://www.apache.org/licenses/LICENSE-2.0                           #
#                                                                          #
# Unless required by applicable law or agreed to in writing, software      #
# distributed under the License is distributed on an "AS IS" BASIS,        #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. #
# See the License for the specific language governing permissions and      #
# limitations under the License.                                           #
############################################################################

# Updates all Git mirrors.
START=$(date +%s);
cd /x1/git/mirrors
for git in *.git; do
    cd /x1/git/mirrors/$git
     URL=`git config remote.origin.url`
    if test -n "$URL"; then
        echo "$git is a git mirror, no need to update it..."
    else
        URL=`git config svn-remote.svn.fetch`
        CMPLX=`echo "$URL" | grep ".*/.*/.*:refs"`
        if test -n "$CMPLX"; then
            echo "$git is a complex-path subversion mirror, checking for changes..."
            /x1/git/bin/update-mirror.sh $git
        else
            echo "$git is a TLP svn repo, we know how to update this real-time, skipping..."
        fi
    fi
done
END=$(date +%s);
DIFF=$(( $END - $START ))
echo "Done in $(($DIFF/60)) minutes"
