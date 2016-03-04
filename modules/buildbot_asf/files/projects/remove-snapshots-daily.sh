#!/bin/sh

# Script to run daily to delete anything over 29 days old. 
# Runs from buildmaster cron @daily.

cd /x1/buildmaster/master1/public_html/projects/ofbiz/snapshots

find . -maxdepth 1 -mtime +29 -exec rm -f {} \;

# now run the snapshots re-index page to bring it upto date.

cd ..
./create-ofbiz-snapshots-index.sh

