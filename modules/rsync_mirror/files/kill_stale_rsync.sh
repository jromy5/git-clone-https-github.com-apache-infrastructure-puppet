#!/bin/bash

# Get list of stale rsync PIDs to kill
to_kill=$(/usr/local/bin/rsync_hang.pl | tail -1)

# Check if list of PIDs iis empty, kill if not empty
if [ ! -z "$to_kill" ]; then
    echo "Killing stale rsync PIDs $to_kill" | logger
    kill -15 $to_kill
fi
