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

# Usage message
if test -z "$1" -o -z "$2"; then
    cat <<EOT
usage:
    create-mirror-from-git-wip.sh git-wip-project-name.git 'Project Name'

examples:
    create-mirror-from-git-wip.sh incubator-drill.git 'Apache Drill (Incubating)'

EOT
    exit 1
fi
GIT_MIRRORS="/x1/git/mirrors"
GIT_DIR="$1"
CLONE_URL="https://git-wip-us.apache.org/repos/asf/$1"
DESCRIPTION="$2"
export GIT_DIR

# Avoid recreating an existing mirror
cd "$GIT_MIRRORS"
if test -d "$GIT_DIR"; then
    echo "$GIT_DIR: Mirror already exists, aborting."
    exit 1
fi

echo "$GIT_DIR: Creating mirror $GIT_DIR..."

git clone --mirror $CLONE_URL

git config gitweb.owner "The Apache Software Foundation"
echo "git://git.apache.org/$GIT_DIR" > "$GIT_DIR/cloneurl"
echo "http://git.apache.org/$GIT_DIR" >> "$GIT_DIR/cloneurl"
echo "$DESCRIPTION" > "$GIT_DIR/description"
touch "$GIT_DIR/git-daemon-export-ok"
git update-server-info

echo
echo "$GIT_DIR: Mirror synchronized, updating http://git.apache.org/"
/x1/git/bin/update-index.sh

echo
echo "The mirror is now available at git://git.apache.org/$GIT_DIR"
echo
exit 0
