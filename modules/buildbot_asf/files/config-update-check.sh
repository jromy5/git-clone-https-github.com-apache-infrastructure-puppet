#!/bin/sh

### WARNING THIS FILE IS MANAGED BY PUPPET ###
### See the buildbot_asf module ###

# Perform an svn up on config files
# But only if there has been a change.
cd /x1/buildmaster/master1 || exit 1

svn st -u projects public_html | fgrep '*'
if [ $? -eq 0 ]; then

 svn up projects public_html --username=buildbot

 # check if any changes break the config
 output=`/usr/bin/buildbot checkconfig 2>&1`
 error=$?

 if [ $error -eq 0 ]; then
    /usr/bin/buildbot reconfig .
 else
    echo "was a failure" >> failure.txt
    if [ ! -t 0 ]; then
      victim=`svn log --quiet --limit=1 | grep '^r' | cut -d'|' -f2 | xargs`
      printf "%s\n" "$output" | mail -s "Buildbot Configuration Error" infrastructure-cvs@apache.org ${victim}@apache.org
    fi
 fi

else
 echo "no changes" >> changes.txt
fi

