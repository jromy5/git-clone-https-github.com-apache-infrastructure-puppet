#!/bin/bash

GIT_URL='git.apache.org'
GIT_REPO='infrastructure-puppet.git'

# run git ls-remote to check if the service is working right
git ls-remote git://$GIT_URL/$GIT_REPO > /dev/null 2>&1

# If command does not exit successfully, restart the daemon
if [ $? -ne 0 ]; then
    sleep 5
    # Run again just to double check it isn't responding
    git ls-remote git://$GIT_URL/$GIT_REPO > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        logger "Restarting git-daemon"
        service git-daemon stop >/dev/null 2>&1
        sleep 1
        # Get list of stale git connections to kill
        for i in $(ps aux --sort=lstart | grep git | egrep "daemon|upload" | awk '{ print $2 }'); 
        do 
            kill -9 $i
        done
        sleep 1
        logger "Starting git-daemon again"
        service git-daemon start >/dev/null 2>&1
    fi
fi

