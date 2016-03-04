#!/bin/sh

# Script to move 1st day of month snapshots to archive area
# Runs from buildmaster cron @monthly.

cd /x1/buildmaster/master1/public_html/projects/ofbiz/snapshots

find *-*-*-*-01-*.* -type f -exec mv {} ../archive/snapshots/ \;

# now run the snapshots re-index page to bring it upto date.

cd ..
./create-ofbiz-snapshots-index.sh

