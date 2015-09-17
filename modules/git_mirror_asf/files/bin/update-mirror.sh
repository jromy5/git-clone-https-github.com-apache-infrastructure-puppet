#!/usr/local/bin/bash 
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

# Update a Git mirror.

GIT_MIRRORS="/x1/git/mirrors"
GIT_AUTHORS="/x1/git/authors.txt"

if test -n "$1"; then
    cd "$GIT_MIRRORS"
    GIT_DIR="$1"
    export GIT_DIR
fi

GIT_NAME=`basename "$GIT_DIR"`
GIT_EXEC="git"

if test -n "$2"; then
    GIT_EXEC = "$2"
fi

# This script updates the Git mirror identified by the
# $GIT_DIR environment variable. The authors.txt file is
# expected to be located at $GIT_AUTHORS.

test -f "$GIT_AUTHORS"  || exit 1
test -f "$GIT_DIR/HEAD" || exit 1

# Lock the repository directory
tmpfile=$GIT_DIR/update-repo.lock.$$
lockfile=$GIT_DIR/update-repo.lock
svnlockfile=$GIT_DIR/svn/trunk/index.lock

# check if we have a lock that is over 2hrs old, if so remove it. 99% case it is hung
if test -f $lockfile ; then
  if /usr/bin/perl -MFile::stat -e 'exit 1 if (stat(shift)->mtime > (time - 720)); exit 0' $lockfile; then
    echo "Removing stale lock: $lockfile"
    rm -f $lockfile $GIT_DIR/update-repo.lock*
  fi
fi

# Check for and clean up any stale svn locks 
if test -f $svnlockfile ; then
  if /usr/bin/perl -MFile::stat -e 'exit 1 if (stat(shift)->mtime > (time - 720)); exit 0' $svnlockfile; then
    echo "Removing stale svn lock: $svnlockfile"
    rm -f $svnlockfile 
  fi
fi

# Create lock file
echo "Locked by pid $$ at $(date)" > $tmpfile
if ! ln $tmpfile $lockfile 2>/dev/null ; then
    echo "$GIT_DIR: Already locked: $(<$lockfile)"
    rm $tmpfile
    exit
fi

trap "rm -f ${tmpfile} ${lockfile} " EXIT
trap "rm -f ${tmpfile} ${lockfile} ; exit 1" INT QUIT TERM CHLD

echo "$GIT_DIR: Updating repository..."

URL=`git config remote.origin.url`
if test -n "$URL"; then
    echo "Fetching changes from canonical git repo..."
    git fetch
    git fetch --tags
    git fetch --prune
else
    echo "Fetching changes from Subversion..."
    git svn fetch --authors-file "$GIT_AUTHORS" --authors-prog=/x1/git/bin/missing-authors.sh --log-window-size=10000

    # Map the remote branches to local ones
    git for-each-ref refs/remotes | cut -d / -f 3- | grep -v @ | grep -v tags/ | while read ref
    do
        git update-ref "refs/heads/$ref" "refs/remotes/$ref"
    done
    git for-each-ref refs/heads | cut -d / -f 3- | while read ref
    do
        git rev-parse "refs/remotes/$ref" > /dev/null 2>&1 ||
            git update-ref -d "refs/heads/$ref" "refs/heads/$ref"
    done

    # Map git-svn pseudo-tags from refs/remotes/tags/* to real Git tags
    git for-each-ref refs/remotes/tags | cut -d / -f 4- | grep -v @ | while read tag
    do
        n=`git for-each-ref --format="%(committername)" "refs/remotes/tags/$tag"`
        e=`git for-each-ref --format="%(committeremail)" "refs/remotes/tags/$tag"`
        d=`git for-each-ref --format="%(committerdate)" "refs/remotes/tags/$tag"`
        GIT_COMMITTER_NAME="$n" GIT_COMMITTER_EMAIL="$e" GIT_COMMITTER_DATE="$d" \
            git tag -f -m "$tag" "$tag" "refs/remotes/tags/$tag"
    done
    git tag | while read tag
    do
        git rev-parse "refs/remotes/tags/$tag" > /dev/null 2>&1 ||
            git tag -d "$tag"
    done
fi

git update-server-info
echo "GC'ing..."
git gc --auto
if git ls-remote "git@github.com:apache/$GIT_NAME" HEAD > /dev/null; then
  echo "Pushing changeset to GitHub..."
  git push -q --mirror "git@github.com:apache/$GIT_NAME"
fi

# Unlock the repository and exit
rm $lockfile $tmpfile
echo "Done!"
exit 0

