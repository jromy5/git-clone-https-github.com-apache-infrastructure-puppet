#!/bin/sh

if [ -z "$SUDO_USER" ]; then
  echo "Usage: sudo $0"
  exit 1
fi


# loki is in UTC
date=$(date +"%Y%m%d%H%M%S")
username=$SUDO_USER
snapname="${username}_${date}UTC"

paths="zroot/usr/ports zroot/usr/src zroot/usr/obj zroot/fus zroot/fus/dist zroot/var/db/mysql"

for path in $paths; do
   zfs snapshot ${path}@${snapname}
done

builds=$(/space/scripts/tc listBuilds)
for build in $builds; do
   zfs snapshot zroot/usr/home/ftp/pub/FreeBSD/ports/packages/${build}@${snapname}
done
