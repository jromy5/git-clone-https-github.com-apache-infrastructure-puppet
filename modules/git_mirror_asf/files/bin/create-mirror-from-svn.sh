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
if test -z "$1" -o -z "$2" -o -z "$3"; then
    cat <<EOT
usage:
    create-mirror.sh project.git path/to/project 'Project Name' ['optional trunk path']

examples:
    create-mirror.sh jackrabbit.git jackrabbit 'Apache Jackrabbit'
    create-mirror.sh tika.git lucene/tika 'Apache Tika'
    create-mirror.sh esme.git incubator/esme 'Apache ESME (incubating)'
    create-mirror.sh click.git click 'Apache Click' 'trunk/click'

EOT
    exit 1
fi
GIT_MIRRORS="/x1/git/mirrors"
GIT_DIR="$1"
SVN_URL="https://svn.apache.org/repos/asf/$2"
DESCRIPTION="$3"
TRUNKPATH="$4"
export GIT_DIR

# Avoid recreating an existing mirror
cd "$GIT_MIRRORS"
if test -d "$GIT_DIR"; then
    echo "$GIT_DIR: Mirror already exists, aborting."
    exit 1
fi

echo "$GIT_DIR: Creating mirror $GIT_DIR..."

# git svn init -b branches -t tags/java/sca -T java/sca "$SVN_URL"
# git svn init -b branches/c -t tags/c -T trunk/c "$SVN_URL"
# git svn init -b branches -t releases -T trunk "$SVN_URL"
# git svn init -T '' "$SVN_URL"
if test -n "$TRUNKPATH"; then
    echo "Using $TRUNKPATH as trunk path"
    git svn init -b branches -t tags -T "$TRUNKPATH" "$SVN_URL"
else
    git svn init -s "$SVN_URL"
fi

git config gitweb.owner "The Apache Software Foundation"
echo "git://git.apache.org/$GIT_DIR" > "$GIT_DIR/cloneurl"
echo "http://git.apache.org/$GIT_DIR" >> "$GIT_DIR/cloneurl"
echo "$DESCRIPTION" > "$GIT_DIR/description"
touch "$GIT_DIR/git-daemon-export-ok"
echo "ref: refs/heads/trunk" > "$GIT_DIR/HEAD"
git update-server-info

echo
echo "$GIT_DIR: Mirror created, doing the initial svn sync..."
/x1/git/bin/update-mirror.sh $GIT_DIR

echo
echo "$GIT_DIR: Mirror synchronized, updating http://git.apache.org/"
/x1/git/bin/update-index.sh

echo
echo "The mirror is now available at git://git.apache.org/$GIT_DIR"
echo
exit 0

